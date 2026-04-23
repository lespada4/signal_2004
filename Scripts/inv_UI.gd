extends Panel
class_name InventoryUI

var slots: Array[Panel] = []
var icons: Array[TextureRect] = []
var labels: Array[Label] = []
var _inventory: Inventory = null

func _ready() -> void:
	# Сначала находим все ноды вручную
	_find_slots()
	
	await get_tree().process_frame
	
	_set_shortcut_labels()
	_setup_inventory()

func _find_slots() -> void:
	slots.clear()
	icons.clear()
	labels.clear()
	
	var hbox = $MarginContainer/HBoxContainer
	
	# Пробуем найти слоты
	for i in range(1, 5):
		var slot_path = "Slot" + str(i)
		var slot = hbox.get_node_or_null(slot_path)
		
		if slot and slot is Panel:
			slots.append(slot as Panel)
			print("[InventoryUI] Found ", slot_path)
			
			var icon = slot.get_node_or_null("Icon")
			if icon and icon is TextureRect:
				icons.append(icon as TextureRect)
			else:
				icons.append(null)
				print("[InventoryUI] WARNING: Icon not found in ", slot_path)
			
			var label = slot.get_node_or_null("ShortcutLabel")
			if label and label is Label:
				labels.append(label as Label)
			else:
				labels.append(null)
				print("[InventoryUI] WARNING: ShortcutLabel not found in ", slot_path)
		else:
			print("[InventoryUI] ERROR: ", slot_path, " not found or not a Panel!")

func _set_shortcut_labels() -> void:
	var shortcuts = ["1", "2", "3", "4"]
	for i in range(labels.size()):
		if labels[i] != null:
			labels[i].text = shortcuts[i]
			print("[InventoryUI] Set label ", i, " to '", shortcuts[i], "'")

func _setup_inventory() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[InventoryUI] Player not found!")
		return
	
	_inventory = player.get_node_or_null("Inventory")
	if not _inventory:
		print("[InventoryUI] Inventory not found on Player!")
		return
	
	_inventory.slot_changed.connect(_on_slot_changed)
	_inventory.active_slot_changed.connect(_on_active_slot_changed)
	
	for i in range(min(4, slots.size())):
		var item = _inventory.get_item(i)
		_update_slot(i, item)
	
	_on_active_slot_changed(_inventory.get_active_slot())
	
	print("[InventoryUI] Ready")

func _update_slot(slot: int, item: Item) -> void:
	if slot >= slots.size() or slot >= icons.size():
		return
	
	if icons[slot] != null:
		if item and item.icon:
			icons[slot].texture = item.icon
			icons[slot].visible = true
		else:
			icons[slot].texture = null
			icons[slot].visible = false

func _on_slot_changed(slot: int, item: Item) -> void:
	_update_slot(slot, item)

func _on_active_slot_changed(slot: int) -> void:
	for i in range(slots.size()):
		if slots[i] != null:
			if i == slot:
				slots[i].modulate = Color.WHITE
			else:
				slots[i].modulate = Color(0.4, 0.4, 0.4)
