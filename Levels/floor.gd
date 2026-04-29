extends StaticBody3D
class_name FloorSurface

@export var floor_type: String = "tile"
@export var footstep_sounds: Array[AudioStream] = []

func get_floor_type() -> String:
	return floor_type

func get_random_sound() -> AudioStream:
	if footstep_sounds.is_empty():
		return null
	return footstep_sounds[randi() % footstep_sounds.size()]
