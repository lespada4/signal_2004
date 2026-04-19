extends Resource
class_name ZalgoEffect

@export var enabled: bool = true
@export_range(0, 100, 1) var concentration: int = 50
@export var intensity: int = 3
@export var update_interval: float = 0.15

var _timer: float = 0.0
var _original_texts: Dictionary = {}
var _target_node: Control = null
var _is_processing: bool = false

func apply_to(node: Control) -> void:
	_target_node = node
	_original_texts.clear()
	_save_original_texts(node)
	_is_processing = true
	if enabled:
		_apply_to_all()

func remove() -> void:
	_restore_all_texts()
	_is_processing = false
	_target_node = null

func update(delta: float) -> void:
	if not enabled or not _is_processing:
		return
	
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_apply_to_all()

func refresh_texts() -> void:
	"""Обновляет список оригинальных текстов (для новых динамических нод)"""
	if _target_node:
		_save_original_texts(_target_node)

func set_concentration(value: int) -> void:
	concentration = value
	if enabled and _is_processing:
		_apply_to_all()

func _save_original_texts(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is RichTextLabel:
			if not _original_texts.has(child):
				_original_texts[child] = child.text
		_save_original_texts(child)

func _apply_to_all() -> void:
	var conc = concentration / 100.0
	for node in _original_texts.keys():
		if is_instance_valid(node):
			var original = _original_texts[node]
			if node is Label:
				node.text = _zalgofy(original, conc)
			elif node is RichTextLabel:
				node.text = _zalgofy(original, conc)

func _restore_all_texts() -> void:
	for node in _original_texts.keys():
		if is_instance_valid(node):
			node.text = _original_texts[node]

# Исправлено: параметр переименован в "conc" чтобы не конфликтовать с переменной класса
func _zalgofy(input: String, conc: float) -> String:
	if conc <= 0.05:
		return input
	
	var result = ""
	var max_chars = max(1, int(round(intensity * conc * 2)))
	
	for c in input:
		result += c
		var up_count = randi() % max_chars
		for i in range(up_count):
			result += char(_get_random_up())
		var down_count = randi() % max_chars
		for i in range(down_count):
			result += char(_get_random_down())
		if randf() < (0.7 * conc):
			result += char(_get_random_mid())
	return result

func _get_random_up() -> int:
	var up = [
		0x0300, 0x0301, 0x0302, 0x0303, 0x0304, 0x0305, 0x0306, 0x0307,
		0x0308, 0x0309, 0x030A, 0x030B, 0x030C, 0x030D, 0x030E, 0x030F,
		0x0310, 0x0311, 0x0312, 0x0313, 0x0314, 0x033D, 0x033E, 0x033F,
		0x0340, 0x0341, 0x0342, 0x0343, 0x0344, 0x0346, 0x034A, 0x034B, 0x034C
	]
	return up[randi() % up.size()]

func _get_random_down() -> int:
	var down = [
		0x0316, 0x0317, 0x0318, 0x0319, 0x031C, 0x031D, 0x031E, 0x031F,
		0x0320, 0x0324, 0x0325, 0x0326, 0x0329, 0x032A, 0x032B, 0x032C,
		0x032D, 0x032E, 0x032F, 0x0330, 0x0331, 0x0332, 0x0333, 0x0339,
		0x033A, 0x033B, 0x033C, 0x0345
	]
	return down[randi() % down.size()]

func _get_random_mid() -> int:
	var mid = [
		0x0315, 0x031B, 0x0340, 0x0341, 0x0358, 0x0321, 0x0322, 0x0327, 0x0328
	]
	return mid[randi() % mid.size()]
