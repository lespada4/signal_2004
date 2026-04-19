extends StaticBody3D
class_name Door

@export var open_angle: float = 90.0
@export var open_speed: float = 2.0
@export var flip: bool = false

var _is_open: bool = false
var _initial_basis: Basis
var _target_basis: Basis

func _ready() -> void:
	_initial_basis = global_transform.basis
	_target_basis = _initial_basis

func interact() -> void:
	_is_open = !_is_open
	var angle = deg_to_rad(open_angle) * (-1.0 if flip else 1.0)
	if _is_open:
		_target_basis = _initial_basis.rotated(global_transform.basis.y, angle)
	else:
		_target_basis = _initial_basis

func _process(delta: float) -> void:
	var current = global_transform.basis.orthonormalized()
	var target = _target_basis.orthonormalized()
	global_transform.basis = current.slerp(target, open_speed * delta)
