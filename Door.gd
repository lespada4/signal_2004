extends StaticBody3D
class_name Door

@export var open_angle: float = 90.0
@export var open_speed: float = 2.0
@export var flip: bool = false
@export var pitch_min: float = 0.8
@export var pitch_max: float = 1.2
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@onready var handle: Node3D = $Handle
@onready var door_sounds: AudioStreamPlayer3D = $DoorSounds
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var _is_open: bool = false
var _is_animating: bool = false
var _initial_basis: Basis
var _target_basis: Basis

func _ready() -> void:
	_initial_basis = global_transform.basis
	_target_basis = _initial_basis

func interact() -> void:
	if _is_animating:
		return
	
	_is_open = !_is_open
	var angle = deg_to_rad(open_angle) * (-1.0 if flip else 1.0)
	
	if _is_open:
		_target_basis = _initial_basis.rotated(global_transform.basis.y, angle)
		_animate_handle()
		_play_sound("open")
		_start_animation()  # Отключаем коллизию только при открытии
	else:
		_target_basis = _initial_basis
		_play_sound("close")
		# При закрытии коллизию не трогаем

func _start_animation() -> void:
	_is_animating = true
	collision_shape_3d.disabled = true

func _stop_animation() -> void:
	_is_animating = false
	collision_shape_3d.disabled = false

func _play_sound(action: String) -> void:
	var stream_to_play: AudioStream
	
	match action:
		"open":
			stream_to_play = open_sound
		"close":
			stream_to_play = close_sound
		_:
			return
	
	if stream_to_play == null:
		return
	
	door_sounds.stream = stream_to_play
	door_sounds.pitch_scale = randf_range(pitch_min, pitch_max)
	door_sounds.play()

func _animate_handle() -> void:
	var tween = create_tween()
	tween.tween_property(handle, "rotation:z", deg_to_rad(45.0), 0.15)
	tween.tween_property(handle, "rotation:z", 0.0, 0.2)

func _process(delta: float) -> void:
	var current = global_transform.basis.orthonormalized()
	var target = _target_basis.orthonormalized()
	var new_basis = current.slerp(target, open_speed * delta)
	global_transform.basis = new_basis
	
	if _is_animating:
		var dot = new_basis.x.dot(target.x)
		if dot > 0.999:
			_stop_animation()
