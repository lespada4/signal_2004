extends Control
class_name JumpscareManager

@export var jumpscare_textures: Array[Texture2D] = []
@export var min_interval: float = 0.1
@export var max_interval: float = 0.3
@export var flash_duration: float = 0.04  # 1 кадр при 25 FPS

@onready var jumpscare_rect: TextureRect = $JumpscareRect
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@export var enabled: bool = true
var _timer: float = 0.0
var _is_flashing: bool = false

func _ready() -> void:
	jumpscare_rect.visible = false
	jumpscare_rect.modulate.a = 0.0
	_reset_timer()



func _process(delta: float) -> void:
	if not enabled: return
	if jumpscare_textures.is_empty(): return
	
	_timer -= delta
	if _timer <= 0.0 and not _is_flashing:
		_trigger_jumpscare()
		_reset_timer()

func _reset_timer() -> void:
	_timer = randf_range(min_interval, max_interval)

func _trigger_jumpscare() -> void:
	_is_flashing = true
	
	# Случайная текстура
	jumpscare_rect.texture = jumpscare_textures[randi() % jumpscare_textures.size()]
	jumpscare_rect.visible = true
	jumpscare_rect.modulate.a = 1.0
	
	# Звук
	if audio_player and audio_player.stream:
		audio_player.play()
	
	# Убираем через 1 кадр
	await get_tree().create_timer(flash_duration).timeout
	jumpscare_rect.visible = false
	jumpscare_rect.modulate.a = 0.0
	_is_flashing = false
