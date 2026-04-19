extends StaticBody3D
class_name Monitor

@export var ui_scene: PackedScene
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

var ui_initialized: bool = false
var fade_overlay: ColorRect
var fade_tween: Tween
var is_screen_on: bool = false

func _ready():
	_setup_mesh_size()
	_setup_camera()
	_setup_viewport()
	_setup_fade_overlay()
	
	self.input_event.connect(_on_input_event)
	_update_plane()

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

func _setup_ui():
	if not ui_scene:
		return
	
	if not ui_initialized:
		ui_instance = ui_scene.instantiate()
		viewport.add_child(ui_instance)
		
		if ui_instance is Control:
			ui_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		viewport.move_child(fade_overlay, viewport.get_child_count())
		ui_initialized = true

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
		exit_monitor_mode()
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

func _world_to_viewport(world_pos: Vector3) -> Vector2:
	var local_pos = screen_mesh.global_transform.affine_inverse() * world_pos
	
	var uv = Vector2(
		(local_pos.x / mesh_size.x) + 0.5,
		0.5 - (local_pos.y / mesh_size.y)
	)
	
	return Vector2(uv.x * viewport.size.x, uv.y * viewport.size.y)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if not is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activate_monitor_mode(_camera)

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

func activate_monitor_mode(camera: Node):
	if camera is Camera3D:
		player_camera = camera
	
	_setup_ui()
	
	if ui_instance and ui_instance.has_method("activate"):
		ui_instance.activate()
	
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

func exit_monitor_mode():
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

func close_terminal():
	exit_monitor_mode()

func interact():
	activate_monitor_mode(player.camera)
