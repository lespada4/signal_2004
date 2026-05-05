extends StaticBody3D
class_name BrowserTerminal

enum TerminalMode { GAME, FLASH_DRIVE, STATS }

@export var mode: TerminalMode = TerminalMode.FLASH_DRIVE
@export var ui_scene: PackedScene
@export var article_scene: PackedScene
@export var terminal_os_scene: PackedScene
@export var no_flash_drive_scene: PackedScene
@export var stats_scene: PackedScene
@export var day_over_scene: PackedScene
@export var monitor_camera: Camera3D
@export var exit_key: Key = KEY_ESCAPE

@onready var player = $"../Player"
@onready var viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $ScreenMesh
@onready var aim_ui = $"../UI/Aim"

var ui_instance: Control = null
var player_camera: Camera3D = null
var is_active: bool = false
var mesh_size: Vector2
var plane: Plane
var last_viewport_pos: Vector2 = Vector2.ZERO
var _disabled: bool = false
var _current_site: PageContent = null

func _ready():
	_setup_mesh_size()
	_setup_camera()
	_setup_viewport()
	self.input_event.connect(_on_input_event)
	_update_plane()
	
	if mode == TerminalMode.FLASH_DRIVE and DiskManager:
		DiskManager.disk_inserted.connect(_on_disk_inserted)
	if DailyManager:
		DailyManager.day_completed.connect(_on_day_completed)
	
	match mode:
		TerminalMode.GAME:
			_clear_viewport()
			ui_instance = _load_scene(ui_scene)
		TerminalMode.STATS:
			_clear_viewport()
			ui_instance = _load_scene(stats_scene)
		TerminalMode.FLASH_DRIVE:
			_clear_viewport()
			if DiskManager and DiskManager.get_current_site():
				_load_site(DiskManager.get_current_site())
			else:
				ui_instance = _load_scene(no_flash_drive_scene)

func _setup_mesh_size():
	if screen_mesh.mesh is PlaneMesh or screen_mesh.mesh is QuadMesh:
		mesh_size = screen_mesh.mesh.size
	else:
		mesh_size = Vector2(2, 2)

func _setup_camera():
	if not monitor_camera: monitor_camera = find_child("MonitorCamera", true, false)
	if monitor_camera: monitor_camera.current = false

func _update_plane():
	var normal = -screen_mesh.global_transform.basis.z.normalized()
	plane = Plane(normal, screen_mesh.global_position)

func _setup_viewport():
	viewport.transparent_bg = true
	viewport.gui_disable_input = false
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(_delta):
	if ui_instance and ui_instance.has_method("_process_equalizer"):
		ui_instance._process_equalizer(_delta)
	if not is_active: return
	_process_mouse_motion(get_viewport().get_mouse_position())

func _process_mouse_motion(screen_pos: Vector2):
	var from = monitor_camera.project_ray_origin(screen_pos)
	var dir = monitor_camera.project_ray_normal(screen_pos)
	var intersection = plane.intersects_ray(from, dir)
	if not intersection: return
	var viewport_pos = _world_to_viewport(intersection)
	if viewport_pos.distance_to(last_viewport_pos) < 0.5: return
	var final_pos = viewport_pos.clamp(Vector2.ZERO, viewport.size)
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = final_pos
	motion_event.global_position = final_pos
	motion_event.relative = final_pos - last_viewport_pos
	viewport.push_input(motion_event)
	last_viewport_pos = final_pos

func _input(event):
	if not is_active: return
	if event is InputEventKey:
		viewport.push_input(event)
	if event is InputEventKey and event.keycode == exit_key and event.pressed:
		exit_terminal()
		if player.has_method("_toggle_pause"):
			player._toggle_pause()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

func _handle_mouse_button(event: InputEventMouseButton):
	var screen_pos = get_viewport().get_mouse_position()
	var from = monitor_camera.project_ray_origin(screen_pos)
	var dir = monitor_camera.project_ray_normal(screen_pos)
	var intersection = plane.intersects_ray(from, dir)
	if not intersection: return
	var viewport_pos = _world_to_viewport(intersection)
	if viewport_pos.x < 0 or viewport_pos.x > viewport.size.x or viewport_pos.y < 0 or viewport_pos.y > viewport.size.y: return
	var new_event = event.duplicate()
	new_event.position = viewport_pos
	new_event.global_position = viewport_pos
	last_viewport_pos = viewport_pos
	viewport.push_input(new_event)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if _disabled: return
	if not is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activate_terminal(_camera)

func _world_to_viewport(world_pos: Vector3) -> Vector2:
	var local_pos = screen_mesh.global_transform.affine_inverse() * world_pos
	return Vector2((local_pos.x / mesh_size.x + 0.5) * viewport.size.x, (0.5 - local_pos.y / mesh_size.y) * viewport.size.y)

func _clear_viewport():
	for child in viewport.get_children():
		child.queue_free()

func _load_scene(scene: PackedScene) -> Control:
	if not scene: return null
	var instance = scene.instantiate()
	viewport.add_child(instance)
	if instance is Control: instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return instance

func _load_site(site: PageContent):
	_clear_viewport()
	_current_site = site
	
	if terminal_os_scene:
		var terminal_os = terminal_os_scene.instantiate()
		viewport.add_child(terminal_os)
		terminal_os.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if terminal_os is TerminalOS:
			terminal_os.command_executed.connect(_on_os_command)
			ui_instance = terminal_os
			_reload_site_in_terminal()
	
	if DiskManager:
		DiskManager.confirm_site_loaded()

func _reload_site_in_terminal() -> void:
	var terminal = ui_instance as TerminalOS
	if not terminal or not _current_site or not article_scene: return
	
	terminal._clear_site_view()
	
	var article = article_scene.instantiate()
	terminal.show_site(article)
	
	await get_tree().process_frame
	
	if article.has_method("update_content"):
		article.update_content(_current_site)
	elif article.has_method("_apply_content"):
		article._apply_content(_current_site)

func _on_os_command(command: String, flags: Array[String]) -> void:
	var terminal = ui_instance as TerminalOS
	if not terminal: return
	
	match command:
		"/insert":
			if _current_site:
				_reload_site_in_terminal()
				terminal._output("Site loaded.")
			elif DiskManager and DiskManager.get_current_site():
				_current_site = DiskManager.get_current_site()
				_reload_site_in_terminal()
				terminal._output("Disk inserted. Site loaded.")
			else:
				terminal._output("No disk. Use inventory to insert disk.")
		
		"/refresh":
			var article = terminal.get_site_child()
			if article and article.has_method("_on_refresh_pressed"):
				article._on_refresh_pressed()
				terminal._output("Page refreshed")
		
		"/diagnostic":
			var article = terminal.get_site_child()
			if article:
				if article.has_method("_on_diag_pressed"):
					article._on_diag_pressed()
				if article.has_method("_generate_diagnostic"):
					terminal._output(article._generate_diagnostic())
		
		"/assign":
			_handle_assign(flags, terminal)
		
		"/eject":
			if DiskManager:
				DiskManager.eject_disk()
			_current_site = null
			terminal._clear_site_view()
			terminal._output("Disk ejected")

func _handle_assign(flags: Array[String], terminal: TerminalOS) -> void:
	if not _current_site: return
	
	var category = ContentGenerator.SiteCategory.NORMAL
	var is_bl = false
	
	for flag in flags:
		match flag:
			"-normal": category = ContentGenerator.SiteCategory.NORMAL
			"-anomaly": category = ContentGenerator.SiteCategory.SUSPICIOUS
			"-dangerous": category = ContentGenerator.SiteCategory.DANGEROUS
			"-bl": is_bl = true
	
	if DailyManager:
		DailyManager.complete_site(_current_site, category, is_bl)
		terminal._output("Site assigned: " + ContentGenerator.SiteCategory.keys()[category])
		_current_site = null

func _on_disk_inserted(site: PageContent):
	_load_site(site)

func _on_day_completed(_day: int, _score: int, _quota: int) -> void:
	if is_active: exit_terminal()
	if mode == TerminalMode.FLASH_DRIVE:
		_clear_viewport()
		ui_instance = _load_scene(day_over_scene)

func activate_terminal(camera: Node):
	if _disabled: return
	if DailyManager and DailyManager.is_day_completed:
		if mode == TerminalMode.GAME or mode == TerminalMode.FLASH_DRIVE: return
	if camera is Camera3D: player_camera = camera
	
	match mode:
		TerminalMode.GAME:
			if ui_instance and ui_instance.has_method("activate"):
				ui_instance.activate()
		TerminalMode.STATS:
			if ui_instance and ui_instance.has_method("refresh"):
				ui_instance.refresh()
		TerminalMode.FLASH_DRIVE:
			if DiskManager and DiskManager.get_current_site():
				if not ui_instance or not (ui_instance is TerminalOS):
					_load_site(DiskManager.get_current_site())
			else:
				_clear_viewport()
				ui_instance = _load_scene(no_flash_drive_scene)
	
	if player.has_method("set_shader_visible"): player.set_shader_visible(false)
	elif player.get("shader"): player.shader.visible = false
	if aim_ui: aim_ui.visible = false
	if player.has_method("lock_controls"): player.lock_controls()
	if monitor_camera:
		_switch_camera(monitor_camera)
		is_active = true
		_update_plane()
		last_viewport_pos = Vector2.ZERO

func exit_terminal():
	if not is_active: return
	if ui_instance and ui_instance.has_method("deactivate"): ui_instance.deactivate()
	if player.has_method("set_shader_visible"): player.set_shader_visible(true)
	elif player.get("shader"): player.shader.visible = true
	if aim_ui: aim_ui.visible = true
	if player.has_method("unlock_controls"): player.unlock_controls()
	_switch_camera(player_camera)
	is_active = false
	_current_site = null
	if player.has_method("show_ui"): player.show_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _switch_camera(to_camera: Camera3D):
	if not to_camera: return
	var active_camera = get_viewport().get_camera_3d()
	if active_camera: active_camera.current = false
	to_camera.current = true

func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	if disabled and is_active: exit_terminal()

func interact():
	if _disabled or (DailyManager and DailyManager.is_day_completed and (mode == TerminalMode.GAME or mode == TerminalMode.FLASH_DRIVE)): return
	activate_terminal(player.camera)

func close_terminal(): exit_terminal()
