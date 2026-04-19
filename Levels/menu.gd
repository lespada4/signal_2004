extends Control

@export var game_scene: PackedScene

@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/VBoxContainer/VolumeSlider
@onready var resolution_option = $SettingsPanel/VBoxContainer/Resolution

func _ready() -> void:
	settings_panel.hide()
	volume_slider.value = AudioServer.get_bus_volume_db(0)
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("2560x1440")
	
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
	AudioServer.set_bus_volume_db(0, value)

func _on_resolution_selected(index: int) -> void:
	var resolutions = [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440)
	]
	DisplayServer.window_set_size(resolutions[index])
