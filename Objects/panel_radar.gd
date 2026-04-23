extends StaticBody3D
class_name BrowserTerminal

enum TerminalMode {
	GAME,           # Мини-игра (WaveTuner)
	FLASH_DRIVE,    # Приём дисков
	STATS           # Статистика дня
}

@export var mode: TerminalMode = TerminalMode.FLASH_DRIVE
@export var ui_scene: PackedScene          # ArticlePage или WaveTuner
@export var no_flash_drive_scene: PackedScene  # NoFlashDriveScene
@export var stats_scene: PackedScene       # StatsScene
@export var viewport_size: Vector2 = Vector2(1920, 1080)
@export var monitor_camera: Camera3D
@export var exit_key: Key = KEY_ESCAPE
@export var fade_duration: float = 0.5

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

var fade_overlay: ColorRect
var fade_tween: Tween
var is_screen_on: bool = false
var _disabled: bool = false

func _ready():
	_setup_mesh_size()
	_setup_camera()
	_setup_viewport()
	_setup_fade_overlay()
	
	self.input_event.connect(_on_input_event)
	_update_plane()
	
	# Подключаем сигналы только для режима дисков
	if mode == TerminalMode.FLASH_DRIVE and DiskManager:
		DiskManager.disk_inserted.connect(_on_disk_inserted)

func _setup_mesh_size():
	if screen_mesh.mesh is PlaneMesh or screen_mesh.mesh is QuadMesh:
		mesh_size = screen_mesh.mesh.size
	else:
		mesh_size = Vector2(2, 2)

func _setup_camera():
	if not monitor_camera:
		monitor_camera = find_child("MonitorCamera", true, false)
	if monitor_camera:
		monitor_camera.current = false

func _setup_fade_overlay():
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate = Color.BLACK
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(fade_overlay)

func _update_plane():
	var normal = -screen_mesh.global_transform.basis.z.normalized()
	plane = Plane(normal, screen_mesh.global_position)

func _setup_viewport():
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.gui_disable_input = false
	viewport.gui_embed_subwindows = true
	viewport.size_2d_override = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(_delta):
	if not is_active:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	_process_mouse_motion(mouse_pos)

func _process_mouse_motion(screen_pos: Vector2):
	var from = monitor_camera.project_ray_origin(screen_pos)
	var dir = monitor_camera.project_ray_normal(screen_pos)
	var intersection = plane.intersects_ray(from, dir)
	
	if not intersection:
		return
	
	var viewport_pos = _world_to_viewport(intersection)
	
	if viewport_pos.distance_to(last_viewport_pos) < 0.5:
		return
	
	var final_pos = viewport_pos.clamp(Vector2.ZERO, viewport.size)
	
	var motion_event = InputEventMouseMotion.new()
	motion_event.position = final_pos
	motion_event.global_position = final_pos
	motion_event.relative = final_pos - last_viewport_pos
	
	viewport.push_input(motion_event)
	last_viewport_pos = final_pos

func _input(event):
	if not is_active:
		return
	
	if event is InputEventKey and event.keycode == exit_key and event.pressed:
		exit_terminal()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

func _handle_mouse_button(event: InputEventMouseButton):
	var screen_pos = get_viewport().get_mouse_position()
	var from = monitor_camera.project_ray_origin(screen_pos)
	var dir = monitor_camera.project_ray_normal(screen_pos)
	var intersection = plane.intersects_ray(from, dir)
	
	if not intersection:
		return
	
	var viewport_pos = _world_to_viewport(intersection)
	
	if viewport_pos.x < 0 or viewport_pos.x > viewport.size.x or \
	   viewport_pos.y < 0 or viewport_pos.y > viewport.size.y:
		return
	
	var new_event = event.duplicate()
	new_event.position = viewport_pos
	new_event.global_position = viewport_pos
	
	last_viewport_pos = viewport_pos
	viewport.push_input(new_event)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if _disabled:
		return
	if not is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activate_terminal(_camera)

func _world_to_viewport(world_pos: Vector3) -> Vector2:
	var local_pos = screen_mesh.global_transform.affine_inverse() * world_pos
	
	var uv = Vector2(
		(local_pos.x / mesh_size.x) + 0.5,
		0.5 - (local_pos.y / mesh_size.y)
	)
	
	return Vector2(uv.x * viewport.size.x, uv.y * viewport.size.y)

func _fade_to_black():
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "modulate", Color.BLACK, fade_duration)
	is_screen_on = false
	
	await fade_tween.finished

func _fade_to_clear():
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "modulate", Color(0, 0, 0, 0), fade_duration)
	is_screen_on = true

func _clear_viewport():
	for child in viewport.get_children():
		if child != fade_overlay:
			child.queue_free()

func _load_scene(scene: PackedScene) -> Control:
	if not scene:
		return null
	
	var instance = scene.instantiate()
	viewport.add_child(instance)
	
	if instance is Control:
		instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	viewport.move_child(fade_overlay, viewport.get_child_count())
	
	return instance

func _load_default_ui():
	_clear_viewport()
	ui_instance = _load_scene(ui_scene)
	
	if ui_instance and ui_instance.has_method("activate"):
		ui_instance.activate()

func _load_site(site: PageContent):
	_clear_viewport()
	ui_instance = _load_scene(ui_scene)
	
	if not ui_instance:
		return
	
	if ui_instance.has_method("update_content"):
		ui_instance.update_content(site)
	elif ui_instance.has_method("_apply_content"):
		ui_instance._apply_content(site)
	elif ui_instance.get("content") != null:
		ui_instance.content = site
	
	if DiskManager:
		DiskManager.confirm_site_loaded()
		print("[BrowserTerminal] Site confirmed loaded")

func _on_disk_inserted(site: PageContent):
	if is_active and mode == TerminalMode.FLASH_DRIVE:
		_load_site(site)
		_fade_to_clear()

func activate_terminal(camera: Node):
	if _disabled:
		return
		
	if camera is Camera3D:
		player_camera = camera
	
	match mode:
		TerminalMode.GAME:
			_clear_viewport()
			ui_instance = _load_scene(ui_scene)
			if ui_instance and ui_instance.has_method("activate"):
				ui_instance.activate()
				
		TerminalMode.STATS:
			_clear_viewport()
			ui_instance = _load_scene(stats_scene)
			if ui_instance and ui_instance.has_method("refresh"):
				ui_instance.refresh()
				
		TerminalMode.FLASH_DRIVE:
			if DiskManager and DiskManager.get_current_site():
				_load_site(DiskManager.get_current_site())
			elif DiskManager and DiskManager.has_disk_inserted():
				# Диск вставлен, но сайт ещё не сгенерирован? Ждём сигнала
				pass
			else:
				_clear_viewport()
				ui_instance = _load_scene(no_flash_drive_scene)
	
	if player.has_method("set_shader_visible"):
		player.set_shader_visible(false)
	elif player.get("shader"):
		player.shader.visible = false
	
	if aim_ui:
		aim_ui.visible = false
	
	if player.has_method("lock_controls"):
		player.lock_controls()
	
	if monitor_camera:
		_switch_camera(monitor_camera)
		is_active = true
		_update_plane()
		last_viewport_pos = Vector2.ZERO
	
	_fade_to_clear()

func exit_terminal():
	if not is_active:
		return
	
	if ui_instance and ui_instance.has_method("deactivate"):
		ui_instance.deactivate()
	
	if is_screen_on:
		await _fade_to_black()
	
	if player.has_method("set_shader_visible"):
		player.set_shader_visible(true)
	elif player.get("shader"):
		player.shader.visible = true
	
	if aim_ui:
		aim_ui.visible = true
	
	_switch_camera(player_camera)
	is_active = false
	
	if player.has_method("unlock_controls"):
		player.unlock_controls()

func _switch_camera(to_camera: Camera3D):
	if not to_camera:
		return
	
	var active_camera = get_viewport().get_camera_3d()
	if active_camera:
		active_camera.current = false
	
	to_camera.current = true

func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	if disabled and is_active:
		exit_terminal()

func interact():
	if _disabled:
		return
	activate_terminal(player.camera)

func close_terminal():
	exit_terminal()
