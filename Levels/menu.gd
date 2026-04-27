extends Control

@export var game_scene: PackedScene

@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/VBoxContainer/VolumeSlider
@onready var resolution_option = $SettingsPanel/VBoxContainer/Resolution

var _resolutions = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var _bus_index: int = 0

func _ready() -> void:
	settings_panel.hide()
	
	# Звук
	_bus_index = AudioServer.get_bus_index("Master")
	if _bus_index == -1:
		print("[Menu] WARNING: 'Master' bus not found! Using bus 0")
		_bus_index = 0
	
	# Безопасные пределы громкости
	volume_slider.min_value = -40.0
	volume_slider.max_value = 6.0
	volume_slider.step = 1.0
	volume_slider.value = AudioServer.get_bus_volume_db(_bus_index)
	
	# Если текущая громкость вне диапазона — сбрасываем на 0
	if volume_slider.value > 6.0 or volume_slider.value < -40.0:
		volume_slider.value = 0.0
	
	print("[Menu] Initial volume: ", volume_slider.value)
	
	# Разрешения
	resolution_option.clear()
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("2560x1440")
	
	var current_size = DisplayServer.window_get_size()
	for i in range(_resolutions.size()):
		if _resolutions[i] == current_size:
			resolution_option.select(i)
			break
	
	# Кнопки
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$SettingsPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_settings_pressed() -> void:
	settings_panel.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	settings_panel.hide()

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index, value)
	print("[Menu] Volume changed to: ", value, " dB")

func _on_resolution_selected(index: int) -> void:
	if index >= 0 and index < _resolutions.size():
		var new_size = _resolutions[index]
		DisplayServer.window_set_size(new_size)
