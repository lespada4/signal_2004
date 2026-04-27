extends CharacterBody3D

@export var fov_angle: float = 90.0
@export var teleport_interval: float = 3.0
@export var kill_distance: float = 1.5
@export var min_spawn_distance: float = 3.0
@export var teleport_radius: float = 15.0
@export var search_radius: float = 8.0
@export var spawn_delay: float = 3.0
@export var audio_fade_duration: float = 2.0

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

# =====================================================
#  ВЛИЯНИЕ НА РАССУДОК (ТОЛЬКО В ПОЛЕ ЗРЕНИЯ)
# =====================================================
@export var sanity_drain_radius: float = 20.0  # Радиус, в котором враг ВИДЕН
@export var base_drain_rate: float = 20.0  # Базовая скорость дренажа в поле зрения
@export var attack_mode_multiplier: float = 1.5  # Множитель в режиме АТАКИ
@export var distance_multiplier: float = 1.5  # Множитель за близость (чем ближе — тем сильнее)

enum Behavior { SEARCH, ATTACK }
enum SpawnState { SPAWNING, ACTIVE }
var current_behavior: Behavior = Behavior.SEARCH
var spawn_state: SpawnState = SpawnState.SPAWNING
var behavior_timer: float = 0.0
var behavior_duration: float = 5.0
var spawn_timer: float = 0.0

var player: Player
var spawn_points: Array[Marker3D] = []
var _timer: float = 0.0
var _is_visible: bool = false
var _audio_tween: Tween

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	for node in get_tree().get_nodes_in_group("enemy_spawns"):
		if node is Marker3D:
			spawn_points.append(node)
	add_to_group("enemy")
	
	visible = false
	spawn_timer = spawn_delay
	
	if audio_stream_player_3d:
		audio_stream_player_3d.volume_db = -80.0
		audio_stream_player_3d.play()
	
	print("[Enemy] Spawned, waiting ", spawn_delay, " seconds...")

func _process(delta: float) -> void:
	if not player:
		return
	
	# Обработка фазы появления
	if spawn_state == SpawnState.SPAWNING:
		spawn_timer -= delta
		_update_spawn_audio()
		
		if spawn_timer <= 0.0:
			_activate()
		return
	
	# Активная фаза
	_is_visible = _is_visible_to_player()
	
	
	# Влияние на рассудок ТОЛЬКО если виден
	if _is_visible:
		_update_sanity_drain(delta)
	
	behavior_timer += delta
	if behavior_timer >= behavior_duration:
		_switch_behavior()
	
	# Если игрок смотрит на врага — враг НЕ телепортируется
	if _is_visible:
		_timer = 0.0
		return
	
	# Телепортация только когда не виден
	_timer += delta
	if _timer >= teleport_interval:
		_timer = 0.0
		var new_pos = _get_teleport_point()
		if new_pos != global_position:
			global_position = new_pos
	
	if global_position.distance_to(player.global_position) < kill_distance:
		_on_player_contact()

# =====================================================
#  ФАЗА ПОЯВЛЕНИЯ
# =====================================================

func _update_spawn_audio() -> void:
	if not audio_stream_player_3d:
		return
	
	var progress = 1.0 - (spawn_timer / spawn_delay)
	var target_volume = lerp(-80.0, -2.0, progress)
	audio_stream_player_3d.volume_db = target_volume

func _activate() -> void:
	spawn_state = SpawnState.ACTIVE
	visible = true
	_switch_behavior()
	
	if audio_stream_player_3d:
		audio_stream_player_3d.volume_db = -2.0
	
	print("[Enemy] Activated! Now hunting...")

# =====================================================
#  ВЛИЯНИЕ НА РАССУДОК (ТОЛЬКО КОГДА ВИДЕН)
# =====================================================

func _update_sanity_drain(delta: float) -> void:
	if not _is_visible:
		return  # Не виден — не влияет
	
	var dist = global_position.distance_to(player.global_position)
	
	# Если слишком далеко — не влияет
	if dist > sanity_drain_radius:
		return
	
	# Множитель расстояния: чем ближе, тем сильнее (от 1.0 до 2.0+)
	var distance_factor = 1.0 + (1.0 - dist / sanity_drain_radius) * distance_multiplier
	
	# Множитель режима атаки
	var behavior_factor = 1.0
	if current_behavior == Behavior.ATTACK:
		behavior_factor = attack_mode_multiplier
	
	# Итоговая скорость дренажа
	var drain_rate = base_drain_rate * distance_factor * behavior_factor
	
	if player.has_method("drain_sanity"):
		player.drain_sanity(drain_rate * delta)
	
	# Отладка (можно убрать)
	# print("[Enemy] Drain: ", drain_rate, " (dist: ", dist, ", visible: ", _is_visible, ")")

func _switch_behavior() -> void:
	behavior_timer = 0.0
	
	if current_behavior == Behavior.SEARCH:
		current_behavior = Behavior.ATTACK
		behavior_duration = randf_range(4.0, 8.0)
		print("[Enemy] Entered ATTACK mode")
	else:
		current_behavior = Behavior.SEARCH
		behavior_duration = randf_range(3.0, 6.0)
		print("[Enemy] Entered SEARCH mode")

func _get_teleport_point() -> Vector3:
	match current_behavior:
		Behavior.SEARCH:
			return _get_search_point()
		Behavior.ATTACK:
			return _get_attack_point()
	return global_position

func _get_search_point() -> Vector3:
	if spawn_points.is_empty():
		return global_position
	
	var valid_spots: Array[Marker3D] = []
	for spot in spawn_points:
		if not spot:
			continue
		var dist_to_player = spot.global_position.distance_to(player.global_position)
		
		if dist_to_player > search_radius:
			continue
		if dist_to_player < min_spawn_distance:
			continue
		if spot.global_position.distance_to(global_position) < 0.5:
			continue
		if _is_point_visible(spot.global_position):
			continue
		valid_spots.append(spot)
	
	if valid_spots.is_empty():
		for spot in spawn_points:
			if not spot:
				continue
			var dist_to_player = spot.global_position.distance_to(player.global_position)
			if dist_to_player < min_spawn_distance:
				continue
			if spot.global_position.distance_to(global_position) < 0.5:
				continue
			if _is_point_visible(spot.global_position):
				continue
			valid_spots.append(spot)
	
	if valid_spots.is_empty():
		return global_position
	
	valid_spots.sort_custom(func(a, b):
		return a.global_position.distance_to(player.global_position) < \
			   b.global_position.distance_to(player.global_position)
	)
	
	return valid_spots[0].global_position

func _get_attack_point() -> Vector3:
	if spawn_points.is_empty():
		return global_position
	
	var cam = player.camera
	var cam_forward = -cam.global_transform.basis.z
	var player_pos = player.global_position
	
	var valid_spots: Array[Marker3D] = []
	for spot in spawn_points:
		if not spot:
			continue
		var dist_to_player = spot.global_position.distance_to(player_pos)
		
		if dist_to_player < min_spawn_distance:
			continue
		if dist_to_player > teleport_radius:
			continue
		if spot.global_position.distance_to(global_position) < 0.5:
			continue
		if _is_point_visible(spot.global_position):
			continue
		
		var to_spot = (spot.global_position - player_pos).normalized()
		var behind_score = (1.0 - to_spot.dot(cam_forward)) / 2.0
		
		if behind_score > 0.6:
			valid_spots.append(spot)
	
	if valid_spots.is_empty():
		return _get_search_point()
	
	valid_spots.sort_custom(func(a, b):
		var to_a = (a.global_position - player_pos).normalized()
		var to_b = (b.global_position - player_pos).normalized()
		var score_a = (1.0 - to_a.dot(cam_forward)) / 2.0
		var score_b = (1.0 - to_b.dot(cam_forward)) / 2.0
		return score_a > score_b
	)
	
	return valid_spots[0].global_position

func _is_visible_to_player() -> bool:
	var cam = player.camera
	var to_enemy = (global_position - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	
	# Проверка угла обзора
	if rad_to_deg(to_enemy.angle_to(cam_forward)) > fov_angle / 2.0:
		return false
	
	# Проверка расстояния
	if global_position.distance_to(cam.global_position) > sanity_drain_radius:
		return false
	
	# Проверка прямой видимости (нет препятствий)
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, global_position)
	query.exclude = [self, player]
	return space.intersect_ray(query).is_empty()

func _is_point_visible(pos: Vector3) -> bool:
	var cam = player.camera
	var to_point = (pos - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	
	if rad_to_deg(to_point.angle_to(cam_forward)) > fov_angle / 2.0:
		return false
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, pos)
	query.exclude = [self, player]
	return space.intersect_ray(query).is_empty()

func _on_player_contact() -> void:
	var new_pos = _get_search_point()
	if new_pos != global_position:
		global_position = new_pos
		_timer = 0.0
