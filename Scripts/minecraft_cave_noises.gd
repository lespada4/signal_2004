extends Node
class_name AmbientSoundManager

@export var ambient_sounds: Array[AudioStream] = []
@export var min_interval: float = 15.0
@export var max_interval: float = 40.0
@export var spawn_radius: float = 10.0
@export var min_spawn_radius: float = 3.0
@export var max_distance: float = 20.0
@export var volume_db: float = -10.0

var _player: Player
var _timer: float = 0.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_reset_timer()

func _process(delta: float) -> void:
	if ambient_sounds.is_empty(): return
	if not _player: return
	
	_timer -= delta
	if _timer <= 0.0:
		_play_random_sound()
		_reset_timer()

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("reloader_debug"):
		#_play_random_sound()
		#_reset_timer()

func _reset_timer() -> void:
	_timer = randf_range(min_interval, max_interval)

func _play_random_sound() -> void:
	if ambient_sounds.is_empty(): return
	
	var angle = randf() * PI * 2
	var dist = randf_range(min_spawn_radius, spawn_radius)
	var pos = _player.global_position + Vector3(
		cos(angle) * dist,
		randf_range(-2.0, 2.0),
		sin(angle) * dist
	)
	
	var player = AudioStreamPlayer3D.new()
	player.stream = ambient_sounds[randi() % ambient_sounds.size()]
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.8, 1.2)
	player.max_distance = max_distance
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.area_mask = 0
	
	add_child(player)
	# Устанавливаем позицию ПОСЛЕ добавления в дерево
	player.global_position = pos
	player.finished.connect(player.queue_free)
	player.play()
