extends CharacterBody3D
class_name Player

## UI
@onready var ui_root: Control = $"../UI"
@onready var item_holder: Marker3D = $Campivot/Camera3D/ItemHolder
@onready var sanity_bar: ProgressBar = $"../UI/SanityBar"
@onready var inventory: Inventory = $Inventory
@onready var pause_menu: Control = $"../UI/Control"
@export var death_screen_scene: PackedScene
var _just_exited_terminal: bool = false
var current_item_instance: Node3D = null

# =================== Движение ===================
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var slow_walk_speed: float = 1.5
@export var mouse_sensitivity: float = 0.004
@export var gravity: float = 18.0

# =================== Звук шагов ===================
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@export var footstep_carpet: Array[AudioStream] = []
@export var footstep_tile: Array[AudioStream] = []
@export var footstep_interval: float = 0.4
var _footstep_timer: float = 0.0

# =================== Покачивание ===================
@export_group("Headbob")
@export var bob_enabled: bool = true
@export var bob_freq: float = 1.8
@export var bob_amount: float = 0.04
var _headbob_time: float = 0.0

# =================== Рассудок ===================
@export_group("Sanity")
@export var max_sanity: float = 100.0
@export var sanity_drain_rate: float = 2.0
@export var sanity_regen_rate: float = 1.0
@export var sanity_regen_delay: float = 5.0
@onready var shader = $Shader
signal sanity_updated(current: float, max_val: float)
var _slowed: bool = false
var _slow_multiplier: float = 1.0

# =================== Взаимодействие ===================
@export_group("Interaction")
@onready var interaction_shape: RayCast3D = $Campivot/Camera3D/Interaction_Ray

# =================== Притяжение камеры ===================
@export_group("Camera Attraction")
@export var attraction_enabled: bool = true
@export var attraction_radius: float = 5.0
@export var attraction_strength: float = 2.0
@export var attraction_max_angle: float = 30.0
var _look_at_enemy_time: float = 0.0
const LOOK_LOCK_THRESHOLD: float = 1.0  # Было 1.0 — уменьшил для более быстрого захвата
const CHASE_LOCK_MULTIPLIER: float = 3.0  # Множитель силы захвата при погоне
const MAX_LOCK_STRENGTH: float = 3.0 
# =================== Состояние ===================
var current_sanity: float = 100.0
var _sanity_drain_active: bool = false
var _sanity_regen_timer: float = 0.0
var _target_h_rotation: float = 0.0
var _target_v_rotation: float = 0.0
var controls_locked: bool = false
var _is_dead: bool = false
var _is_paused: bool = false

var _attraction_target: Node3D = null
var _attraction_target_visible: bool = false

@onready var camera: Camera3D = $Campivot/Camera3D

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_sanity = max_sanity
	_target_h_rotation = rotation.y
	_target_v_rotation = camera.rotation.x
	sanity_updated.emit(current_sanity, max_sanity)
	
	if sanity_bar:
		sanity_bar.max_value = max_sanity
		sanity_bar.value = current_sanity
	
	if not inventory:
		inventory = Inventory.new()
		add_child(inventory)
	
	inventory.setup(self)
	inventory.item_equipped.connect(_on_item_equipped)
	inventory.item_unequipped.connect(_on_item_unequipped)
	
	sanity_updated.connect(_on_sanity_updated)
	
	if pause_menu:
		pause_menu.visible = false

func hide_ui() -> void:
	if ui_root: ui_root.visible = false

func show_ui() -> void:
	if ui_root: ui_root.visible = true

func _on_sanity_updated(current: float, max_val: float) -> void:
	if sanity_bar:
		sanity_bar.max_value = max_val
		sanity_bar.value = current
		var t = current / max_val
		sanity_bar.modulate = Color.GREEN if t > 0.5 else (Color.YELLOW if t > 0.25 else Color.RED)

func _on_item_equipped(item: Item) -> void:
	if current_item_instance: current_item_instance.queue_free()
	current_item_instance = null
	item.on_equip(self)

func _on_item_unequipped() -> void:
	if current_item_instance: current_item_instance.queue_free()
	current_item_instance = null

func show_disk(disk: DiskItem) -> void:
	if disk.scene:
		current_item_instance = disk.scene.instantiate()
		item_holder.add_child(current_item_instance)
		current_item_instance.position = Vector3.ZERO

func hide_disk() -> void:
	if current_item_instance: current_item_instance.queue_free()
	current_item_instance = null

func try_insert_disk(disk: DiskItem) -> bool:
	if not interaction_shape: return false
	
	interaction_shape.force_raycast_update()
	var collider = interaction_shape.get_collider()
	
	if not collider:
		print("[Player] Not looking at terminal")
		return false
	
	if collider is BrowserTerminal:
		if DiskManager:
			var success = DiskManager.insert_disk(disk)
			if success:
				collider.activate_terminal(camera)
				inventory.remove_item(disk)
			return success
	
	return false
func _toggle_pause() -> void:
	if not pause_menu: return
	
	if _is_paused:
		_is_paused = false
		pause_menu.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		_is_paused = true
		pause_menu.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead: return
	
	if event.is_action_pressed("ui_cancel"):
		if _just_exited_terminal: return
		if not controls_locked:
			_toggle_pause()
			return  # ← return только если ОТКРЫЛИ/ЗАКРЫЛИ паузу
		# Если controls_locked — терминал сам обработает, не делаем return
	
	if _is_paused: return
	if controls_locked: return
	
	if event is InputEventMouseMotion:
		_target_h_rotation -= event.relative.x * mouse_sensitivity
		_target_v_rotation -= event.relative.y * mouse_sensitivity
		_target_v_rotation = clamp(_target_v_rotation, deg_to_rad(-89.0), deg_to_rad(89.0))
	if event.is_action_pressed("interact"): _try_interact()
	if event.is_action_pressed("slot_1"): inventory.set_active_slot(0)
	elif event.is_action_pressed("slot_2"): inventory.set_active_slot(1)
	elif event.is_action_pressed("slot_3"): inventory.set_active_slot(2)
	elif event.is_action_pressed("slot_4"): inventory.set_active_slot(3)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: inventory.prev_slot()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: inventory.next_slot()
	if event.is_action_pressed("use_item"): inventory.use_active_item()

func _process(delta: float) -> void:
	if _is_paused: return
	if controls_locked or _is_dead: return
	rotation.y = _target_h_rotation
	camera.rotation.x = _target_v_rotation
	if _attraction_target and _attraction_target_visible:
		_apply_camera_attraction(delta)
		# Проверяем, в погоне ли враг
		if _attraction_target.has_method("get_behavior") and _attraction_target.get_behavior() == 2:  # CHASE
			_look_at_enemy_time += delta * CHASE_LOCK_MULTIPLIER  # Быстрее накапливается при погоне

func _physics_process(delta: float) -> void:
	
	if _is_paused: return
	if _is_dead: return
	if not controls_locked:
		if not is_on_floor(): velocity.y -= gravity * delta
		else: velocity.y = 0.0
		var wish_dir = global_transform.basis * Vector3(Input.get_axis("move_left", "move_right"), 0.0, Input.get_axis("move_forward", "move_back"))
		if wish_dir.length() > 1.0: wish_dir = wish_dir.normalized()
		var speed = (slow_walk_speed if Input.is_action_pressed("walk") else walk_speed) * _slow_multiplier
		velocity.x = wish_dir.x * speed
		velocity.z = wish_dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_update_sanity(delta)
	if bob_enabled and not controls_locked: _headbob_effect(delta)
	if interaction_shape:
		interaction_shape.global_position = camera.global_position
		interaction_shape.global_transform.basis = camera.global_transform.basis
	_update_attraction_target()
	
	var speed = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and speed > 0.1:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = footstep_interval / (speed / walk_speed)
			_play_footstep()
	else:
		_footstep_timer = 0.0

func _is_enemy_visible(enemy: Node3D) -> bool:
	var cam = camera
	var to_enemy = (enemy.global_position - cam.global_position).normalized()
	if rad_to_deg(to_enemy.angle_to(-cam.global_transform.basis.z)) > attraction_max_angle: return false
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, enemy.global_position)
	query.exclude = [self, enemy]
	return space.intersect_ray(query).is_empty()

func _update_attraction_target() -> void:
	if not attraction_enabled: return
	var closest: Node3D = null
	var closest_dist = attraction_radius + 1.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy): continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist and _is_enemy_visible(enemy):
			closest = enemy
			closest_dist = dist
	_attraction_target = closest
	_attraction_target_visible = closest != null

func _apply_camera_attraction(delta: float) -> void:
	if not _attraction_target: return
	
	var to_target = (_attraction_target.global_position - camera.global_position).normalized()
	var cam_forward = -camera.global_transform.basis.z
	var angle = rad_to_deg(to_target.angle_to(cam_forward))
	
	var looking_directly = angle < 20.0
	
	if looking_directly:
		_look_at_enemy_time += delta
	else:
		_look_at_enemy_time = max(0.0, _look_at_enemy_time - delta * 2.0)
	
	if angle > attraction_max_angle:
		_look_at_enemy_time = 0.0
		return
	
	var dist = global_position.distance_to(_attraction_target.global_position)
	var base_strength = clamp(1.0 - dist / attraction_radius, 0.3, 1.0)
	var strength = attraction_strength * base_strength * delta * 0.5
	
	if _look_at_enemy_time > 0.5:
		var lock_factor = min(1.0 + _look_at_enemy_time * 3.0, MAX_LOCK_STRENGTH)  # ← Потолок
		strength *= lock_factor
	
	var target_h = atan2(to_target.x, to_target.z)
	var current_h = atan2(cam_forward.x, cam_forward.z)
	var diff_h = target_h - current_h
	if diff_h > PI: diff_h -= PI * 2
	if diff_h < -PI: diff_h += PI * 2
	
	_target_h_rotation += diff_h * strength * 2.0
	_target_v_rotation = clamp(_target_v_rotation + (to_target.y - cam_forward.y) * strength * 0.5, deg_to_rad(-89.0), deg_to_rad(89.0))

func _try_interact() -> void:
	if not interaction_shape: return
	interaction_shape.force_raycast_update()
	if not interaction_shape.is_colliding(): return
	var collider = interaction_shape.get_collider()
	if collider.has_method("interact"): collider.interact()

func _headbob_effect(delta: float) -> void:
	var speed = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or speed < 0.1:
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 6.0)
		return
	_headbob_time += delta * speed
	camera.transform.origin = Vector3(cos(_headbob_time * bob_freq * 0.5) * bob_amount, sin(_headbob_time * bob_freq) * bob_amount, 0.0)

func _update_sanity(delta: float) -> void:
	if _is_dead: return
	if _sanity_drain_active:
		current_sanity = max(current_sanity - sanity_drain_rate * delta, 0.0)
		_sanity_regen_timer = sanity_regen_delay
	else:
		if _sanity_regen_timer > 0.0: _sanity_regen_timer -= delta
		else: current_sanity = min(current_sanity + sanity_regen_rate * delta, max_sanity)
	sanity_updated.emit(current_sanity, max_sanity)
	if current_sanity <= 0.0: _die()

func set_sanity_drain(active: bool) -> void: _sanity_drain_active = active

func add_sanity(amount: float) -> void:
	if _is_dead: return
	current_sanity = min(current_sanity + amount, max_sanity)
	sanity_updated.emit(current_sanity, max_sanity)

func drain_sanity(amount: float) -> void:
	if _is_dead: return
	current_sanity = max(current_sanity - amount, 0.0)
	_sanity_regen_timer = sanity_regen_delay
	sanity_updated.emit(current_sanity, max_sanity)
	if current_sanity <= 0.0: _die()

func get_sanity() -> float: return current_sanity

func _die() -> void:
	if _is_dead: return
	_is_dead = true
	controls_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hide_ui()
	
	if death_screen_scene:
		var death_screen = death_screen_scene.instantiate()
		add_child(death_screen)
		await get_tree().create_timer(3.0).timeout
	
	_restart_scene()


func _restart_scene() -> void:
	if DailyManager:
		DailyManager.current_day = 1
		DailyManager.start_new_day()
	get_tree().reload_current_scene()

func lock_controls() -> void:
	controls_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls() -> void:
	if _is_dead: return
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func is_controls_locked() -> bool: return controls_locked

func _play_footstep() -> void:
	var type = _get_floor_type()
	var sounds = footstep_carpet if type == "carpet" else footstep_tile
	if sounds.is_empty(): return
	footstep_player.stream = sounds[randi() % sounds.size()]
	footstep_player.pitch_scale = randf_range(0.9, 1.1)
	footstep_player.play()

func _get_floor_type() -> String:
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 1.2)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	if result.is_empty(): return "tile"
	var collider = result["collider"]
	var mesh: MeshInstance3D = null
	if collider is MeshInstance3D:
		mesh = collider
	elif collider is StaticBody3D:
		for child in collider.get_children():
			if child is MeshInstance3D:
				mesh = child
				break
	if mesh:
		var mat = mesh.get_active_material(0)
		if mat and mat.resource_path:
			if "yfloor" in mat.resource_path.to_lower(): return "carpet"
	return "tile"

func _on_terminal_exit() -> void:
	_just_exited_terminal = true
	await get_tree().process_frame
	_just_exited_terminal = false

func set_slow(active: bool, multiplier: float = 0.6) -> void:
	_slowed = active
	_slow_multiplier = multiplier if active else 1.0
