extends Control
class_name PauseMenu

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_toggle_pause"):
		player._toggle_pause()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Levels/Menu.tscn")
