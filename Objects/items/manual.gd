extends Item
class_name NoteItem

@export_multiline var page1_text: String = """FIELD MANUAL v1.0 - RULES

TODAY'S CRITERIA:
- Author must be in whitelist
- Date must be before 2015
- Domain must be civilian
- Image must not be corrupted"""

@export_multiline var page2_text: String = """FIELD MANUAL v1.0 - REFERENCES

WHITELIST — Trusted Authors:
• Dr. Sarah Chen, PhD
• Marcus Webb
• Elena Vasquez
• Prof. James Morrison

BLACKLIST — Anomalous Dates:
• 2012 — First Wave
• 2013 — The Silence
• 2020 — Echo Anomaly

SUSPICIOUS DOMAINS:
• .mil — Military (RESTRICTED)
• .onion — Dark web (DANGER)
• .local — Internal (SUSPICIOUS)"""

var _manual_ui: ManualUI = null
var _is_manual_open: bool = false

func on_equip(player: Player) -> void:
	if scene:
		var instance = scene.instantiate()
		player.item_holder.add_child(instance)
		player.current_item_instance = instance
		instance.position = Vector3(0.2, -0.1, -0.4)

func on_unequip(player: Player) -> void:
	_close_manual()
	if player.current_item_instance:
		player.current_item_instance.queue_free()
		player.current_item_instance = null

func on_use(player: Player) -> bool:
	if _manual_ui and is_instance_valid(_manual_ui):
		_close_manual()
	else:
		_manual_ui = null
		_is_manual_open = false
		_open_manual(player)
	return true

func _open_manual(player: Player) -> void:
	if _is_manual_open or (_manual_ui and is_instance_valid(_manual_ui)):
		return
	
	var ui_scene = load("res://Objects/items/manual_ui.tscn")
	_manual_ui = ui_scene.instantiate()
	_manual_ui._player = player
	_manual_ui.closed_by_user.connect(_close_manual)
	
	var ui_root = player.ui_root if player.ui_root else player
	ui_root.add_child(_manual_ui)
	
	_manual_ui.open_with_pages([page1_text, page2_text], "FIELD MANUAL v1.0")
	_is_manual_open = true

func _close_manual() -> void:
	_is_manual_open = false
	if _manual_ui:
		_manual_ui.close()
		_manual_ui.queue_free()
		_manual_ui = null
