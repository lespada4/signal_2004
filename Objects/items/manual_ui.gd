extends Control
class_name ManualUI

signal closed_by_user

@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var body: Label = $Panel/MarginContainer/VBoxContainer/Body
@onready var close_button: Button = $Panel/CloseButton
@onready var next_button: Button = $Panel/NextButton

var _is_open: bool = false
var _player: Player = null
var _aim_node: CanvasItem = null
var _pages: Array[String] = []
var _current_page: int = 0
var _page_title: String = ""

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	next_button.pressed.connect(_on_next_pressed)
	visible = false
	call_deferred("_find_aim")

func _find_aim() -> void:
	var root = get_tree().current_scene
	if root:
		_aim_node = root.get_node_or_null("UI/Aim") as CanvasItem

func open_with_pages(pages: Array[String], page_title: String = "FIELD MANUAL") -> void:
	_pages = pages
	_page_title = page_title
	_current_page = 0
	_show_current_page()

func _show_current_page() -> void:
	if _pages.is_empty():
		return
	
	title.text = _page_title + " - Page " + str(_current_page + 1) + "/" + str(_pages.size())
	body.text = _pages[_current_page]
	visible = true
	_is_open = true
	
	if not _aim_node:
		_find_aim()
	if _aim_node:
		_aim_node.modulate.a = 0.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_next_pressed() -> void:
	_current_page = (_current_page + 1) % _pages.size()
	_show_current_page()

func close() -> void:
	visible = false
	_is_open = false
	_pages.clear()
	_current_page = 0
	
	if _aim_node:
		_aim_node.modulate.a = 1.0
	
	if _player and is_instance_valid(_player):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed() -> void:
	closed_by_user.emit()

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("use_item"):
		closed_by_user.emit()
		accept_event()
