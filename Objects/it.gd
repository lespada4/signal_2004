extends CharacterBody3D

@export var fov_angle: float = 90.0
@export var teleport_interval: float = 3.0
@export var kill_distance: float = 1.5
@export var min_spawn_distance: float = 3.0
@export var teleport_radius: float = 15.0
@export var search_radius: float = 8.0
@export var spawn_delay: float = 3.0
@export var audio_fade_duration: float = 2.0
@export var chase_speed: float = 2.0
@export var look_away_penalty: float = 10.0

@onready var animation_player: AnimationPlayer = $it/AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer

@export var footstep_sounds: Array[AudioStream] = []
@export var footstep_interval: float = 0.5
var _footstep_timer: float = 0.0

@export var sanity_drain_radius: float = 20.0
@export var base_drain_rate: float = 20.0
@export var attack_mode_multiplier: float = 1.5
@export var distance_multiplier: float = 1.5

enum Behavior { SEARCH, ATTACK, CHASE }
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

var _chase_stare_time: float = 0.0
var _last_seen_position: Vector3
var _chase_lost_timer: float = 0.0
const CHASE_STARE_THRESHOLD: float = 2.0
const CHASE_LOST_DELAY: float = 2.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	for node in get_tree().get_nodes_in_group("enemy_spawns"):
		if node is Marker3D: spawn_points.append(node)
	add_to_group("enemy")
	visible = false
	spawn_timer = spawn_delay
	if audio_stream_player_3d:
		audio_stream_player_3d.volume_db = -80.0
		audio_stream_player_3d.play()

func _process(delta: float) -> void:
	if not player: return
	
	if spawn_state == SpawnState.SPAWNING:
		spawn_timer -= delta
		_update_spawn_audio()
		if spawn_timer <= 0.0: _activate()
		return
	
	_is_visible = _is_visible_to_player()
	
	# Всегда смотрим на игрока
	look_at(player.global_position, Vector3.UP)
	rotation.y += deg_to_rad(180)
	
	# Погоня
	if current_behavior == Behavior.CHASE:
		_play_animation("Chasing")
		_process_chase(delta)
		_update_footsteps(delta)
		if global_position.distance_to(player.global_position) < kill_distance:
			if _is_visible:
				player._die()
			else:
				var new_pos = _get_teleport_point()
				if new_pos != global_position:
					global_position = new_pos
				_stop_chase()
		return
	
	# Обычное поведение — Idle
	_play_animation("Idle")
	
	if _is_visible:
		_update_sanity_drain(delta)
		
		if player.has_method("set_slow"):
			player.set_slow(true, 0.6)
		
		_chase_stare_time += delta
		if _chase_stare_time >= CHASE_STARE_THRESHOLD:
			_start_chase()
		_timer = 0.0
		return
	
	if player.has_method("set_slow"):
		player.set_slow(false)
	
	_chase_stare_time = 0.0
	
	behavior_timer += delta
	if behavior_timer >= behavior_duration:
		_switch_behavior()
	
	_timer += delta
	if _timer >= teleport_interval:
		_timer = 0.0
		var new_pos = _get_teleport_point()
		if new_pos != global_position:
			global_position = new_pos
	
	if global_position.distance_to(player.global_position) < kill_distance:
		var new_pos = _get_search_point()
		if new_pos != global_position:
			global_position = new_pos
		_timer = 0.0

func get_behavior() -> int:
	return current_behavior

func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func _update_footsteps(delta: float) -> void:
	if not footstep_player or footstep_sounds.is_empty(): return
	
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = footstep_interval
		footstep_player.stream = footstep_sounds[randi() % footstep_sounds.size()]
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		footstep_player.play()

func _process_chase(delta: float) -> void:
	if _is_visible:
		_chase_lost_timer = 0.0
		_last_seen_position = player.global_position
		
		var dir = (player.global_position - global_position).normalized()
		var target_pos = global_position + dir * chase_speed * delta
		target_pos.y = global_position.y
		global_position = target_pos
		
		var dist = global_position.distance_to(player.global_position)
		if dist <= sanity_drain_radius:
			var drain = base_drain_rate * 2.0 * (1.0 + distance_multiplier)
			if player.has_method("drain_sanity"):
				player.drain_sanity(drain * delta)
		
		if dist < kill_distance:
			player._die()
	else:
		_chase_lost_timer += delta
		if _chase_lost_timer >= CHASE_LOST_DELAY:
			if _is_visible_to_player_no_ray():
				pass
			else:
				if player.has_method("drain_sanity"):
					player.drain_sanity(look_away_penalty)
			_stop_chase()

func _start_chase() -> void:
	current_behavior = Behavior.CHASE
	_chase_lost_timer = 0.0
	_last_seen_position = player.global_position
	print("[Enemy] CHASE STARTED!")

func _stop_chase() -> void:
	current_behavior = Behavior.SEARCH
	_chase_stare_time = 0.0
	_play_animation("Idle")
	
	await get_tree().create_timer(2.0).timeout
	
	if spawn_points.size() > 0:
		global_position = spawn_points[randi() % spawn_points.size()].global_position
	print("[Enemy] CHASE ENDED")

func _is_visible_to_player_no_ray() -> bool:
	var cam = player.camera
	var to_enemy = (global_position - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	if rad_to_deg(to_enemy.angle_to(cam_forward)) > fov_angle / 2.0: return false
	if global_position.distance_to(cam.global_position) > sanity_drain_radius: return false
	return true

func _update_spawn_audio() -> void:
	if not audio_stream_player_3d: return
	var progress = 1.0 - (spawn_timer / spawn_delay)
	audio_stream_player_3d.volume_db = lerp(-80.0, -2.0, progress)

func _activate() -> void:
	spawn_state = SpawnState.ACTIVE
	visible = true
	_switch_behavior()
	if audio_stream_player_3d: audio_stream_player_3d.volume_db = -2.0

func _update_sanity_drain(delta: float) -> void:
	if not _is_visible: return
	var dist = global_position.distance_to(player.global_position)
	if dist > sanity_drain_radius: return
	var distance_factor = 1.0 + (1.0 - dist / sanity_drain_radius) * distance_multiplier
	var drain_rate = base_drain_rate * distance_factor
	if current_behavior == Behavior.ATTACK: drain_rate *= attack_mode_multiplier
	if player.has_method("drain_sanity"): player.drain_sanity(drain_rate * delta)

func _switch_behavior() -> void:
	behavior_timer = 0.0
	if current_behavior == Behavior.SEARCH:
		current_behavior = Behavior.ATTACK
		behavior_duration = randf_range(4.0, 8.0)
	else:
		current_behavior = Behavior.SEARCH
		behavior_duration = randf_range(3.0, 6.0)

func _get_teleport_point() -> Vector3:
	match current_behavior:
		Behavior.SEARCH: return _get_search_point()
		Behavior.ATTACK: return _get_attack_point()
	return global_position

func _get_search_point() -> Vector3:
	if spawn_points.is_empty(): return global_position
	var valid_spots: Array[Marker3D] = []
	for spot in spawn_points:
		if not spot: continue
		var dist = spot.global_position.distance_to(player.global_position)
		if dist > search_radius or dist < min_spawn_distance: continue
		if spot.global_position.distance_to(global_position) < 0.5: continue
		if _is_point_visible(spot.global_position): continue
		valid_spots.append(spot)
	if valid_spots.is_empty():
		for spot in spawn_points:
			if not spot: continue
			if spot.global_position.distance_to(player.global_position) < min_spawn_distance: continue
			if spot.global_position.distance_to(global_position) < 0.5: continue
			if _is_point_visible(spot.global_position): continue
			valid_spots.append(spot)
	if valid_spots.is_empty(): return global_position
	valid_spots.sort_custom(func(a, b): return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
	return valid_spots[0].global_position

func _get_attack_point() -> Vector3:
	if spawn_points.is_empty(): return global_position
	var cam = player.camera
	var cam_forward = -cam.global_transform.basis.z
	var player_pos = player.global_position
	var valid_spots: Array[Marker3D] = []
	for spot in spawn_points:
		if not spot: continue
		var dist = spot.global_position.distance_to(player_pos)
		if dist < min_spawn_distance or dist > teleport_radius: continue
		if spot.global_position.distance_to(global_position) < 0.5: continue
		if _is_point_visible(spot.global_position): continue
		var to_spot = (spot.global_position - player_pos).normalized()
		if (1.0 - to_spot.dot(cam_forward)) / 2.0 > 0.6: valid_spots.append(spot)
	if valid_spots.is_empty(): return _get_search_point()
	valid_spots.sort_custom(func(a, b):
		var to_a = (a.global_position - player_pos).normalized()
		var to_b = (b.global_position - player_pos).normalized()
		return (1.0 - to_a.dot(cam_forward)) > (1.0 - to_b.dot(cam_forward)))
	return valid_spots[0].global_position

func _is_visible_to_player() -> bool:
	var cam = player.camera
	var to_enemy = (global_position - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	if rad_to_deg(to_enemy.angle_to(cam_forward)) > fov_angle / 2.0: return false
	if global_position.distance_to(cam.global_position) > sanity_drain_radius: return false
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, global_position)
	query.exclude = [self, player]
	return space.intersect_ray(query).is_empty()

func _is_point_visible(pos: Vector3) -> bool:
	var cam = player.camera
	var to_point = (pos - cam.global_position).normalized()
	var cam_forward = -cam.global_transform.basis.z
	if rad_to_deg(to_point.angle_to(cam_forward)) > fov_angle / 2.0: return false
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, pos)
	query.exclude = [self, player]
	return space.intersect_ray(query).is_empty()

func _on_player_contact() -> void:
	if current_behavior == Behavior.CHASE:
		player._die()
	else:
		var new_pos = _get_search_point()
		if new_pos != global_position:
			global_position = new_pos
		_timer = 0.0
