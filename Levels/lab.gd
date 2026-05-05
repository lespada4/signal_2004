extends Node3D
class_name EnemyManager

signal electronics_jammed(duration: float)
signal electronics_restored()

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var jumpscare_manager: JumpscareManager = $UI/JumpscareManager

@export var enemy_scene: PackedScene
@export var jam_duration: float = 8.0
@export var spawn_distance: float = 10.0
@export var min_spawn_distance: float = 5.0
@export var light_flicker_interval: float = 0.15
@export var environment_transition_duration: float = 2.0
@export var jammed_jumpscare_interval_min: float = 0.6
@export var jammed_jumpscare_interval_max: float = 1.2

const JAMMED_BRIGHTNESS: float = 0.35
const JAMMED_SATURATION: float = 0.35
const JAMMED_CONTRAST: float = 1.1
const NORMAL_BRIGHTNESS: float = 0.45
const NORMAL_SATURATION: float = 0.65
const NORMAL_CONTRAST: float = 0.9

@onready var lights: Node3D = $Lights

var _is_jammed: bool = false
var _jam_timer: float = 0.0
var _active_enemies: Array[Node3D] = []
var _player: Player = null
var _light_timer: float = 0.0
var _terminals: Array[BrowserTerminal] = []
var _environment_tween: Tween
var _last_spawn_time: float = 0.0
const SPAWN_COOLDOWN: float = 2.0

func _ready() -> void:
	add_to_group("enemy_manager")
	
	print("[EnemyManager] Ready")
	DailyManager.start_new_day()
	
	_player = get_tree().get_first_node_in_group("player") as Player
	
	for node in get_tree().get_nodes_in_group("terminals"):
		if node is BrowserTerminal:
			_terminals.append(node)
	
	print("[EnemyManager] Lights node: ", lights)
	if lights:
		print("[EnemyManager] Lights children count: ", lights.get_child_count())
	else:
		print("[EnemyManager] WARNING: 'Lights' node not found!")
	
	print("[EnemyManager] Found ", _terminals.size(), " terminals")
	
	_set_environment_normal()
	
	if jumpscare_manager:
		jumpscare_manager.enabled = false

func _process(delta: float) -> void:
	if _is_jammed:
		_jam_timer -= delta
		
		_light_timer += delta
		if _light_timer >= light_flicker_interval:
			_light_timer = 0.0
			_flicker_lights()
		
		if _jam_timer <= 0.0:
			_restore_electronics()

func _set_environment_jammed() -> void:
	if not world_environment or not world_environment.environment: return
	_kill_env_tween()
	_environment_tween = create_tween()
	_environment_tween.set_parallel(true)
	_environment_tween.tween_property(world_environment.environment, "adjustment_brightness", JAMMED_BRIGHTNESS, environment_transition_duration)
	_environment_tween.tween_property(world_environment.environment, "adjustment_saturation", JAMMED_SATURATION, environment_transition_duration)
	_environment_tween.tween_property(world_environment.environment, "adjustment_contrast", JAMMED_CONTRAST, environment_transition_duration)

func _set_environment_normal() -> void:
	if not world_environment or not world_environment.environment: return
	_kill_env_tween()
	_environment_tween = create_tween()
	_environment_tween.set_parallel(true)
	_environment_tween.tween_property(world_environment.environment, "adjustment_brightness", NORMAL_BRIGHTNESS, environment_transition_duration)
	_environment_tween.tween_property(world_environment.environment, "adjustment_saturation", NORMAL_SATURATION, environment_transition_duration)
	_environment_tween.tween_property(world_environment.environment, "adjustment_contrast", NORMAL_CONTRAST, environment_transition_duration)

func _kill_env_tween() -> void:
	if _environment_tween and _environment_tween.is_valid():
		_environment_tween.kill()

func on_site_misidentified(site_category: ContentGenerator.SiteCategory) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_spawn_time < SPAWN_COOLDOWN:
		print("[EnemyManager] Spawn on cooldown, ignoring")
		return
	_last_spawn_time = now
	
	if site_category == ContentGenerator.SiteCategory.SUSPICIOUS or site_category == ContentGenerator.SiteCategory.DANGEROUS:
		print("[EnemyManager] MISIDENTIFICATION! Jamming electronics...")
		_jam_electronics()
		_spawn_enemy()
	else:
		print("[EnemyManager] NORMAL site misidentified - no jam")

func _jam_electronics() -> void:
	if _is_jammed:
		_jam_timer = jam_duration
		return
	
	_is_jammed = true
	_jam_timer = jam_duration
	_light_timer = 0.0
	
	for terminal in _terminals:
		if is_instance_valid(terminal):
			terminal.set_disabled(true)
	
	_set_environment_jammed()
	
	if jumpscare_manager:
		jumpscare_manager.enabled = true
		jumpscare_manager.min_interval = jammed_jumpscare_interval_min
		jumpscare_manager.max_interval = jammed_jumpscare_interval_max
	
	print("[EnemyManager] Electronics JAMMED for ", jam_duration, " seconds")
	electronics_jammed.emit(jam_duration)

func _restore_electronics() -> void:
	_is_jammed = false
	
	if lights:
		for child in lights.get_children():
			if child is Node3D:
				child.visible = true
	
	for terminal in _terminals:
		if is_instance_valid(terminal):
			terminal.set_disabled(false)
	
	_set_environment_normal()
	
	if jumpscare_manager:
		jumpscare_manager.enabled = false
	
	print("[EnemyManager] Electronics RESTORED")
	electronics_restored.emit()

func _flicker_lights() -> void:
	if not lights: return
	for child in lights.get_children():
		if child is Node3D:
			child.visible = randf() > 0.3

func _spawn_enemy() -> void:
	if not enemy_scene: return
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Player
		if not _player: return
	
	var spawn_pos = _find_spawn_position()
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	_active_enemies.append(enemy)
	print("[EnemyManager] Enemy spawned at: ", spawn_pos)

func _find_spawn_position() -> Vector3:
	if not _player: return Vector3.ZERO
	var player_pos = _player.global_position
	for i in range(10):
		var angle = randf() * PI * 2
		var distance = randf_range(min_spawn_distance, spawn_distance)
		var offset = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var spawn_pos = player_pos + offset
		if not _is_position_visible(spawn_pos, player_pos):
			return spawn_pos
	var angle = randf() * PI * 2
	return player_pos + Vector3(cos(angle) * spawn_distance, 0.0, sin(angle) * spawn_distance)

func _is_position_visible(pos: Vector3, from: Vector3) -> bool:
	var space = get_tree().root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, pos)
	query.exclude = [_player]
	return space.intersect_ray(query).is_empty()

func register_enemy_death(enemy: Node3D) -> void:
	var index = _active_enemies.find(enemy)
	if index != -1:
		_active_enemies.remove_at(index)
	if _active_enemies.size() == 0 and not _is_jammed:
		_set_environment_normal()
		if jumpscare_manager:
			jumpscare_manager.enabled = false

func is_electronics_jammed() -> bool:
	return _is_jammed

func force_restore_electronics() -> void:
	_restore_electronics()

func force_clear_all_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	_active_enemies.clear()
	if not _is_jammed:
		_set_environment_normal()
		if jumpscare_manager:
			jumpscare_manager.enabled = false

func force_jam_electronics() -> void:
	_jam_electronics()

func force_spawn_enemy() -> void:
	_spawn_enemy()
	_set_environment_jammed()

func get_active_enemies_count() -> int:
	return _active_enemies.size()

#func _input(event: InputEvent) -> void:
	#if Input.is_action_just_pressed("reloader_debug"):
		#_start_hunt()

func _start_hunt() -> void:
	print("[EnemyManager] HUNT ACTIVATED!")
	if not _is_jammed:
		_jam_electronics()
		_spawn_enemy()
	if jumpscare_manager:
		jumpscare_manager.enabled = true
		jumpscare_manager.min_interval = 0.4
		jumpscare_manager.max_interval = 0.8

func debug_restore_electronics() -> void: force_restore_electronics()
func debug_clear_all_enemies() -> void: force_clear_all_enemies()
func debug_jam_electronics() -> void: force_jam_electronics()
func debug_spawn_enemy() -> void: force_spawn_enemy()
