extends CharacterBody3D
class_name Player

## ITEMS (DRIVE AND LED)

@onready var drive: MeshInstance3D = $Campivot/Camera3D/Drive
@onready var led: Sprite3D = $Campivot/Camera3D/Drive/LED
@onready var sanity_bar: ProgressBar = $"../UI/SanityBar"

# Цвета для LED в зависимости от категории сайта
const LED_COLORS = {
	"normal": Color(0.0, 0.5, 1.0),     # Синий
	"suspicious": Color(1.0, 1.0, 0.0), # Жёлтый
	"dangerous": Color(1.0, 0.0, 0.0),  # Красный
	"none": Color(0.2, 0.2, 0.2)        # Тёмный (выключен)
}

# =================== Звук врага ===================
@export var max_hear_distance: float = 20.0
@onready var terror_radius: AudioStreamPlayer = $AudioStreamPlayer
@export var max_terror_volume_db: float = -6.0

# =================== Движение ===================
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var slow_walk_speed: float = 1.5
@export var mouse_sensitivity: float = 0.004
@export var gravity: float = 18.0

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

# =================== Взаимодействие ===================
@export_group("Interaction")
@onready var interaction_shape: ShapeCast3D = $Campivot/Camera3D/Interaction_Ray

# =================== Притяжение камеры ===================
@export_group("Camera Attraction")
@export var attraction_enabled: bool = true
@export var attraction_radius: float = 5.0
@export var attraction_strength: float = 2.0
@export var attraction_max_angle: float = 30.0

# =================== Состояние ===================
var current_sanity: float = 100.0
var _sanity_drain_active: bool = false
var _sanity_regen_timer: float = 0.0
var _target_h_rotation: float = 0.0
var _target_v_rotation: float = 0.0
var controls_locked: bool = false

var _attraction_target: Node3D = null
var _attraction_target_visible: bool = false

# =================== Ноды ===================
@onready var camera: Camera3D = $Campivot/Camera3D
@onready var camera_pivot: Node3D = $Campivot

# =================== Инициализация ===================
func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_sanity = max_sanity
	_target_h_rotation = rotation.y
	_target_v_rotation = camera.rotation.x
	sanity_updated.emit(current_sanity, max_sanity)
	
	# Инициализируем полоску рассудка
	if sanity_bar:
		sanity_bar.max_value = max_sanity
		sanity_bar.value = current_sanity
	
	# Подключаемся к сигналам FlashDriveManager
	if FlashDriveManager:
		FlashDriveManager.flash_drive_collected.connect(_on_flash_drive_collected)
		FlashDriveManager.flash_drive_inserted.connect(_on_flash_drive_inserted)
		FlashDriveManager.flash_drive_ejected.connect(_on_flash_drive_ejected)
		FlashDriveManager.flash_drive_consumed.connect(_on_flash_drive_consumed)
	
	# Подключаем собственный сигнал sanity_updated к обновлению бара
	sanity_updated.connect(_on_sanity_updated)
	
	# Флешка скрыта по умолчанию
	_hide_drive()

# =====================================================
#  SANITY BAR
# =====================================================

func _on_sanity_updated(current: float, max_val: float) -> void:
	if sanity_bar:
		sanity_bar.max_value = max_val
		sanity_bar.value = current
		
		# Меняем цвет в зависимости от уровня
		var t = current / max_val
		if t > 0.5:
			sanity_bar.modulate = Color.GREEN
		elif t > 0.25:
			sanity_bar.modulate = Color.YELLOW
		else:
			sanity_bar.modulate = Color.RED

# =====================================================
#  FLASH DRIVE VISUALS
# =====================================================

func _show_drive() -> void:
	drive.visible = true
	led.visible = true
	print("[Player] Flash drive shown")

func _hide_drive() -> void:
	drive.visible = false
	led.visible = false
	print("[Player] Flash drive hidden")

func _set_led_color(color_key: String) -> void:
	print("[Player] Setting LED color to: ", color_key)
	
	var color = LED_COLORS.get(color_key, LED_COLORS["none"])
	
	if not led:
		print("[Player] ERROR: LED not found!")
		return
	
	var material: StandardMaterial3D
	
	if led.material_override:
		material = led.material_override
	else:
		material = StandardMaterial3D.new()
		led.material_override = material
	
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 13.0
	material.albedo_color = color

func _on_flash_drive_collected(color: String) -> void:
	print("[Player] Flash drive collected: ", color)
	_show_drive()
	
	match color:
		"blue": _set_led_color("normal")
		"red": _set_led_color("suspicious")
		"green": _set_led_color("dangerous")
		_: _set_led_color("none")

func _on_flash_drive_inserted(site: PageContent) -> void:
	print("[Player] Flash drive inserted into terminal")
	_hide_drive()

func _on_flash_drive_ejected() -> void:
	print("[Player] Flash drive ejected")
	_hide_drive()
	_set_led_color("none")

func _on_flash_drive_consumed() -> void:
	print("[Player] Flash drive consumed")
	_hide_drive()
	_set_led_color("none")

# =================== Инпут ===================
func _unhandled_input(event: InputEvent) -> void:
	if controls_locked:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		_target_h_rotation -= event.relative.x * mouse_sensitivity
		_target_v_rotation -= event.relative.y * mouse_sensitivity
		_target_v_rotation = clamp(_target_v_rotation, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("interact"):
		_try_interact()

# =================== Процесс ===================
func _process(delta: float) -> void:
	if controls_locked:
		return
	
	rotation.y = _target_h_rotation
	camera.rotation.x = _target_v_rotation
	
	if attraction_enabled and _attraction_target and is_instance_valid(_attraction_target) and _attraction_target_visible:
		_apply_camera_attraction(delta)

func _physics_process(delta: float) -> void:
	if not controls_locked:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		var wish_dir := global_transform.basis * Vector3(
			Input.get_axis("move_left", "move_right"),
			0.0,
			Input.get_axis("move_forward", "move_back")
		)
		if wish_dir.length() > 1.0:
			wish_dir = wish_dir.normalized()

		var current_walk_speed = slow_walk_speed if Input.is_action_pressed("walk") else walk_speed
		velocity.x = wish_dir.x * current_walk_speed
		velocity.z = wish_dir.z * current_walk_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_update_sanity(delta)

	if bob_enabled and not controls_locked:
		_headbob_effect(delta)

	if interaction_shape:
		interaction_shape.global_position = camera.global_position
		interaction_shape.global_transform.basis = camera.global_transform.basis
	
	_update_attraction_target()

# =================== Притяжение камеры ===================
func _is_enemy_visible(enemy: Node3D) -> bool:
	var cam = camera
	var to_enemy = (enemy.global_position - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	
	if rad_to_deg(to_enemy.angle_to(cam_forward)) > attraction_max_angle:
		return false
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, enemy.global_position)
	query.exclude = [self, enemy]
	return space.intersect_ray(query).is_empty()

func _update_attraction_target() -> void:
	if not attraction_enabled:
		return
	
	var closest_enemy: Node3D = null
	var closest_dist: float = attraction_radius + 1.0
	var closest_visible: bool = false
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < attraction_radius and dist < closest_dist:
			var enemy_visible = _is_enemy_visible(enemy)
			if enemy_visible:
				closest_dist = dist
				closest_enemy = enemy
				closest_visible = true
	
	_attraction_target = closest_enemy
	_attraction_target_visible = closest_visible

func _apply_camera_attraction(delta: float) -> void:
	if not _attraction_target:
		return
	
	var to_target = (_attraction_target.global_position - camera.global_position).normalized()
	var camera_forward = -camera.global_transform.basis.z
	
	var angle_to_target = rad_to_deg(to_target.angle_to(camera_forward))
	
	if angle_to_target > attraction_max_angle:
		return
	
	var dist = global_position.distance_to(_attraction_target.global_position)
	var strength_mult = clamp(1.0 - (dist / attraction_radius), 0.3, 1.0)
	var current_strength = attraction_strength * strength_mult * delta
	
	var target_angle_h = atan2(to_target.x, to_target.z)
	var current_angle_h = atan2(camera_forward.x, camera_forward.z)
	var angle_diff = target_angle_h - current_angle_h
	
	if angle_diff > PI:
		angle_diff -= PI * 2
	if angle_diff < -PI:
		angle_diff += PI * 2
	
	_target_h_rotation += angle_diff * current_strength * 2.0
	
	var vertical_diff = to_target.y - camera_forward.y
	_target_v_rotation += vertical_diff * current_strength * 0.01
	_target_v_rotation = clamp(_target_v_rotation, deg_to_rad(-89.0), deg_to_rad(89.0))

# =================== Взаимодействие ===================
func _try_interact() -> void:
	if not interaction_shape:
		return

	interaction_shape.force_shapecast_update()

	var result = interaction_shape.get_collision_result()
	if result.is_empty():
		return

	var collider = result[0]["collider"]
	
	# Поддержка и StaticBody3D (терминалы) и Area3D (зона восстановления)
	if collider.has_method("interact"):
		collider.interact()

# =================== Покачивание ===================
func _headbob_effect(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horizontal_speed < 0.1:
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 6.0)
		return
	_headbob_time += delta * horizontal_speed
	camera.transform.origin = Vector3(
		cos(_headbob_time * bob_freq * 0.5) * bob_amount,
		sin(_headbob_time * bob_freq) * bob_amount,
		0.0
	)

# =================== Рассудок ===================
func _update_sanity(delta: float) -> void:
	if _sanity_drain_active:
		current_sanity = max(current_sanity - sanity_drain_rate * delta, 0.0)
		_sanity_regen_timer = sanity_regen_delay
	else:
		if _sanity_regen_timer > 0.0:
			_sanity_regen_timer -= delta
		else:
			current_sanity = min(current_sanity + sanity_regen_rate * delta, max_sanity)
	sanity_updated.emit(current_sanity, max_sanity)

func set_sanity_drain(active: bool) -> void:
	_sanity_drain_active = active

func add_sanity(amount: float) -> void:
	current_sanity = min(current_sanity + amount, max_sanity)
	sanity_updated.emit(current_sanity, max_sanity)

func get_sanity() -> float:
	return current_sanity

# =================== Блокировка управления ===================
func lock_controls() -> void:
	controls_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls() -> void:
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func is_controls_locked() -> bool:
	return controls_locked

# =================== Звук врага ===================
func update_terror_radius(enemy_pos: Vector3) -> void:
	var dist = global_position.distance_to(enemy_pos)
	var t = 1.0 - clamp(dist / max_hear_distance, 0.0, 1.0)
	var target_db = linear_to_db(t)
	terror_radius.volume_db = clamp(target_db, -80.0, max_terror_volume_db)
	if t > 0.0 and not terror_radius.playing:
		terror_radius.play()
	elif t <= 0.0 and terror_radius.playing:
		terror_radius.stop()
		

func drain_sanity(amount: float) -> void:
	current_sanity = max(current_sanity - amount, 0.0)
	_sanity_regen_timer = sanity_regen_delay
	sanity_updated.emit(current_sanity, max_sanity)
