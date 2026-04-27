extends StaticBody3D
class_name DiskDispenser

@export var can_dispense: bool = true
@export_multiline var manual_text: String = "FIELD MANUAL v1.0\n\nToday's Criteria:\n- Check author\n- Check date"
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Label3D

var _items_ready: bool = false
var _items_dispensed_today: bool = false

func _ready() -> void:
	sprite_3d.visible = false
	
	if label_3d:
		label_3d.text = "NO ITEMS"
	
	if DailyManager:
		DailyManager.day_started.connect(_on_day_started)
		DailyManager.day_completed.connect(_on_day_completed)
	
	print("[DiskDispenser] Ready")

func _on_day_started(_day: int) -> void:
	_items_ready = true
	_items_dispensed_today = false
	
	if sprite_3d:
		sprite_3d.visible = true
	
	if label_3d:
		label_3d.text = "PRESS E TO TAKE ITEMS"
	
	print("[DiskDispenser] Items ready - Day ", _day)

func _on_day_completed(_day: int, _normal: int, _rare: int) -> void:
	_items_ready = false
	
	if sprite_3d:
		sprite_3d.visible = false
	
	if label_3d:
		label_3d.text = "NO ITEMS"
	
	print("[DiskDispenser] Day completed")

func interact() -> void:
	print("[DiskDispenser] interact() called")
	
	if not _items_ready:
		print("[DiskDispenser] No items available")
		return
	
	if _items_dispensed_today:
		print("[DiskDispenser] Already took items today")
		return
	
	if not can_dispense:
		print("[DiskDispenser] Dispenser disabled")
		return
	
	_dispense_all()

func _dispense_all() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		print("[DiskDispenser] Player inventory not found!")
		return
	
	# Проверяем, есть ли 2 свободных слота
	var free_slots = 0
	for i in range(4):
		if player.inventory.get_item(i) == null:
			free_slots += 1
	
	if free_slots < 2:
		print("[DiskDispenser] Need 2 free inventory slots!")
		if label_3d:
			label_3d.text = "NEED 2 FREE SLOTS"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "PRESS E TO TAKE ITEMS"
		return
	
	# Выдаём диск
	var disk_awarded = false
	if DiskManager:
		var disk = DiskManager.award_empty_disk()
		disk_awarded = disk != null
	
	# Выдаём мануал
	var manual_awarded = false
	var manual = _create_manual_item()
	if manual:
		manual_awarded = player.inventory.add_item(manual)
	
	if disk_awarded and manual_awarded:
		print("[DiskDispenser] Disk and manual dispensed!")
		_items_dispensed_today = true
		
		if sprite_3d:
			sprite_3d.visible = false
		
		if label_3d:
			label_3d.text = "ITEMS TAKEN"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "COME BACK TOMORROW"
	else:
		print("[DiskDispenser] Failed to dispense all items!")
		if label_3d:
			label_3d.text = "ERROR - TRY AGAIN"

func _create_manual_item() -> NoteItem:
	var manual = load("res://Objects/items/manual.tres").duplicate() as NoteItem
	manual.page1_text = manual_text
	return manual
