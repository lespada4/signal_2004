extends StaticBody3D
class_name SanityRestoreStation

@export var sanity_restore_amount: float = 30.0
@export var restore_duration: float = 10.0
@export var cooldown_duration: float = 30.0
@export var audio_fade_duration: float = 0.5
@export var water_flow_speed: float = -256

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Label3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _is_active: bool = false
var _is_on_cooldown: bool = false
var _timer: float = 0.0
var _original_label_text: String = ""
var _player: Player = null
var _restore_rate: float = 0.0
var _audio_tween: Tween

# Для анимации воды
var _noise_texture: NoiseTexture2D
var _water_offset: float = 0.0

# Ссылка на EnemyManager
var _enemy_manager: EnemyManager

func _ready() -> void:
	sprite_3d.visible = false
	
	if label_3d:
		_original_label_text = label_3d.text
	
	_restore_rate = sanity_restore_amount / restore_duration
	
	if audio_stream_player_3d:
		audio_stream_player_3d.volume_db = -80.0
		audio_stream_player_3d.stop()
	
	_setup_water_material()
	_find_enemy_manager()
	
	print("[SanityRestore] Ready")

func _find_enemy_manager() -> void:
	# Ищем EnemyManager в сцене
	_enemy_manager = get_tree().get_first_node_in_group("enemy_manager")
	
	if not _enemy_manager:
		# Пробуем найти по имени
		var root = get_tree().current_scene
		if root:
			_enemy_manager = root.get_node_or_null("EnemyManager")
	
	if _enemy_manager:
		print("[SanityRestore] EnemyManager found")
	else:
		print("[SanityRestore] WARNING: EnemyManager not found!")

func _setup_water_material() -> void:
	if not sprite_3d:
		return
	
	if sprite_3d.texture and sprite_3d.texture is NoiseTexture2D:
		_noise_texture = sprite_3d.texture as NoiseTexture2D
		print("[SanityRestore] Found NoiseTexture2D from sprite texture")
	else:
		print("[SanityRestore] WARNING: Sprite texture is not a NoiseTexture2D!")

func _process(delta: float) -> void:
	# Анимация воды - течёт вниз
	if _is_active and _noise_texture:
		_water_offset += delta * water_flow_speed
		_noise_texture.noise.offset.y = _water_offset
	
	if _is_active and _player:
		_timer -= delta
		
		if _timer <= 0.0:
			_deactivate()
		else:
			if _player.has_method("add_sanity"):
				_player.add_sanity(_restore_rate * delta)
			
			if label_3d:
				label_3d.text = "слушай воду %.1fs" % _timer
	
	elif _is_on_cooldown:
		_timer -= delta
		
		if _timer <= 0.0:
			_is_on_cooldown = false
			if label_3d:
				label_3d.text = _original_label_text
			print("[SanityRestore] Cooldown finished")
		else:
			if label_3d:
				label_3d.text = "перезарядка душа: %.1fs" % _timer

func interact() -> void:
	print("[SanityRestore] interact() called")
	
	if _is_active:
		print("[SanityRestore] Already active")
		return
	
	if _is_on_cooldown:
		print("[SanityRestore] On cooldown")
		return
	
	_player = get_tree().get_first_node_in_group("player") as Player
	
	if not _player:
		print("[SanityRestore] Player not found!")
		return
	
	_activate()

func _activate() -> void:
	_is_active = true
	_timer = restore_duration
	
	sprite_3d.visible = true
	_water_offset = 0.0
	
	if label_3d:
		label_3d.text = "слушай воду %.1fs" % _timer
	
	_play_audio()
	
	print("[SanityRestore] Activated! Restoring sanity...")

func _deactivate() -> void:
	_is_active = false
	_is_on_cooldown = true
	_timer = cooldown_duration
	
	sprite_3d.visible = false
	
	if _noise_texture:
		_noise_texture.noise.offset.y = 0.0
	_water_offset = 0.0
	
	if label_3d:
		label_3d.text = "перезарядка душа: %.1fs" % _timer
	
	_stop_audio()
	
	# ВОССТАНАВЛИВАЕМ ЭЛЕКТРОНИКУ И УБИРАЕМ ВРАГОВ
	_restore_world()
	
	_player = null
	
	print("[SanityRestore] Deactivated, world restored")
func _restore_world() -> void:
	"""Восстанавливает электронику и убирает всех врагов"""
	
	# Обновляем ссылку если потеряли
	if not _enemy_manager or not is_instance_valid(_enemy_manager):
		_find_enemy_manager()
	
	if _enemy_manager:
		# Удаляем всех врагов
		if _enemy_manager.has_method("debug_clear_all_enemies"):
			_enemy_manager.debug_clear_all_enemies()
			print("[SanityRestore] All enemies cleared")
		
		# Восстанавливаем электронику
		if _enemy_manager.has_method("debug_restore_electronics"):
			_enemy_manager.debug_restore_electronics()
			print("[SanityRestore] Electronics restored")
	else:
		print("[SanityRestore] WARNING: Cannot restore world - EnemyManager not found!")

func _play_audio() -> void:
	if not audio_stream_player_3d:
		return
	
	if _audio_tween and _audio_tween.is_valid():
		_audio_tween.kill()
	
	audio_stream_player_3d.volume_db = -80.0
	audio_stream_player_3d.play()
	
	_audio_tween = create_tween()
	_audio_tween.tween_property(audio_stream_player_3d, "volume_db", -20.0, audio_fade_duration)
	
	print("[SanityRestore] Audio playing")

func _stop_audio() -> void:
	if not audio_stream_player_3d:
		return
	
	if _audio_tween and _audio_tween.is_valid():
		_audio_tween.kill()
	
	_audio_tween = create_tween()
	_audio_tween.tween_property(audio_stream_player_3d, "volume_db", -80.0, audio_fade_duration)
	_audio_tween.tween_callback(audio_stream_player_3d.stop)
	
	print("[SanityRestore] Audio stopping")

func force_reset() -> void:
	_is_active = false
	_is_on_cooldown = false
	_timer = 0.0
	_water_offset = 0.0
	
	if _noise_texture:
		_noise_texture.noise.offset.y = 0.0
	
	sprite_3d.visible = false
	if label_3d:
		label_3d.text = _original_label_text
	
	_stop_audio()
	
	print("[SanityRestore] Force reset")
