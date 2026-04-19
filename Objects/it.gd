extends CharacterBody3D

@export var fov_angle: float = 90.0
@export var teleport_interval: float = 3.0
@export var kill_distance: float = 1.5
@export var min_spawn_distance: float = 3.0
@export var teleport_radius: float = 15.0
@export var search_radius: float = 8.0  # Радиус для режима "ищет"

enum Behavior { SEARCH, ATTACK }
var current_behavior: Behavior = Behavior.SEARCH
var behavior_timer: float = 0.0
var behavior_duration: float = 5.0  # Длительность каждого поведения

var player: Player
var spawn_points: Array[Marker3D] = []
var _timer: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	for node in get_tree().get_nodes_in_group("enemy_spawns"):
		if node is Marker3D:
			spawn_points.append(node)
	add_to_group("enemy")
	
	# Случайный выбор первого поведения
	_switch_behavior()

func _process(delta: float) -> void:
	if not player:
		return
	
	player.update_terror_radius(global_position)
	
	# Смена поведения по таймеру
	behavior_timer += delta
	if behavior_timer >= behavior_duration:
		_switch_behavior()
	
	if _is_visible_to_player():
		_timer = 0.0
		return
	
	_timer += delta
	if _timer >= teleport_interval:
		_timer = 0.0
		var new_pos = _get_teleport_point()
		if new_pos != global_position:
			global_position = new_pos
	
	if global_position.distance_to(player.global_position) < kill_distance:
		_on_player_contact()

func _switch_behavior() -> void:
	behavior_timer = 0.0
	
	# Чередуем поведения
	if current_behavior == Behavior.SEARCH:
		current_behavior = Behavior.ATTACK
		behavior_duration = randf_range(4.0, 8.0)
		print("Враг перешёл в режим АТАКИ")
	else:
		current_behavior = Behavior.SEARCH
		behavior_duration = randf_range(3.0, 6.0)
		print("Враг перешёл в режим ПОИСКА")

func _get_teleport_point() -> Vector3:
	match current_behavior:
		Behavior.SEARCH:
			return _get_search_point()
		Behavior.ATTACK:
			return _get_attack_point()
	return global_position

func _get_search_point() -> Vector3:
	"""Режим поиска: телепортируемся БЛИЖЕ к игроку"""
	if spawn_points.is_empty():
		return global_position
	
	var valid_spots: Array[Marker3D] = []
	for spot in spawn_points:
		if not spot:
			continue
		var dist_to_player = spot.global_position.distance_to(player.global_position)
		
		# Ищем точки в радиусе search_radius
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
		# Если нет точек в радиусе, ищем любую подходящую
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
	
	# Сортируем по близости к игроку (чем ближе, тем лучше)
	valid_spots.sort_custom(func(a, b):
		return a.global_position.distance_to(player.global_position) < \
			   b.global_position.distance_to(player.global_position)
	)
	
	# Берём самую близкую
	return valid_spots[0].global_position

func _get_attack_point() -> Vector3:
	"""Режим атаки: телепортируемся ЗА СПИНУ игроку"""
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
		
		# Проверяем, насколько точка за спиной
		var to_spot = (spot.global_position - player_pos).normalized()
		var behind_score = (1.0 - to_spot.dot(cam_forward)) / 2.0
		
		# Только точки за спиной (score > 0.6)
		if behind_score > 0.6:
			valid_spots.append(spot)
	
	if valid_spots.is_empty():
		return _get_search_point()  # fallback
	
	# Сортируем по углу за спиной (чем больше, тем лучше)
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
	
	if rad_to_deg(to_enemy.angle_to(cam_forward)) > fov_angle / 2.0:
		return false
	
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
	var new_pos = _get_search_point()  # При контакте — паника, уходим в поиск
	if new_pos != global_position:
		global_position = new_pos
		_timer = 0.0
