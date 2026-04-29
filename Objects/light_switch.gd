extends StaticBody3D
class_name LightSwitch

@export var lights: Array[Node3D] = []
@export var switch_angle: float = 7.0
@export var start_on: bool = true
@export var sound_on: AudioStream
@export var sound_off: AudioStream

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var switch_mesh: MeshInstance3D = $Base/Switch_Mesh

var _is_on: bool

func _ready() -> void:
	_is_on = start_on
	_set_lights(_is_on)
	_update_switch_visual()

func interact() -> void:
	_is_on = !_is_on
	_set_lights(_is_on)
	_update_switch_visual()
	_play_switch_sound()
	print("[LightSwitch] Lights ", "ON" if _is_on else "OFF")

func _play_switch_sound() -> void:
	var sound = sound_on if _is_on else sound_off
	if sound and audio_stream_player_3d:
		var player = AudioStreamPlayer3D.new()
		player.stream = sound
		player.pitch_scale = randf_range(0.9, 1.1)
		add_child(player)
		player.global_position = audio_stream_player_3d.global_position
		player.finished.connect(player.queue_free)
		player.play()

func _set_lights(on: bool) -> void:
	for light in lights:
		if is_instance_valid(light):
			light.visible = on

func _update_switch_visual() -> void:
	switch_mesh.rotation.z = deg_to_rad(switch_angle) if _is_on else 0.0
