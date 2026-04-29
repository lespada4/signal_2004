extends StaticBody3D
class_name DiskDispenser

@export var can_dispense: bool = true
@export var require_return: bool = true
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Label3D

var _items_ready: bool = false
var _items_dispensed_today: bool = false
var _disk_returned: bool = false
var _manual_returned: bool = false

func _ready() -> void:
	sprite_3d.visible = false
	
	if label_3d:
		label_3d.text = "NO ITEMS"
	
	if DailyManager:
		DailyManager.day_started.connect(_on_day_started)
		DailyManager.day_completed.connect(_on_day_completed)
	
	_items_dispensed_today = false

func _on_day_started(_day: int) -> void:
	_items_ready = true
	_items_dispensed_today = false
	_disk_returned = false
	_manual_returned = false
	
	if sprite_3d:
		sprite_3d.visible = true
	
	if label_3d:
		label_3d.text = "PRESS LMB TO TAKE ITEMS"
	
	print("[DiskDispenser] Items ready - Day ", _day)

func _on_day_completed(_day: int, _score: int, _quota: int) -> void:
	_items_ready = false
	
	if sprite_3d:
		sprite_3d.visible = false
	
	if label_3d:
		label_3d.text = "DAY COMPLETE"
	
	print("[DiskDispenser] Day completed")

func interact() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory: return
	
	# Сдавать можно только если квота выполнена
	if _items_dispensed_today and require_return:
		if DailyManager and DailyManager.current_score >= DailyManager.daily_quota:
			_try_return_items(player)
		else:
			if label_3d:
				label_3d.text = "QUOTA NOT MET YET"
				await get_tree().create_timer(2.0).timeout
				if label_3d:
					label_3d.text = "RETURN ITEMS TO END DAY"
		return
	
	# Выдача предметов
	if not _items_ready: return
	if _items_dispensed_today: return
	if not can_dispense: return
	_dispense_all()

func _try_return_items(player: Player) -> void:
	if DailyManager and DailyManager.current_score < DailyManager.daily_quota:
		if label_3d:
			label_3d.text = "QUOTA NOT MET YET"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "RETURN ITEMS TO END DAY"
		return
	
	var disk: DiskItem = null
	var manual: NoteItem = null
	
	for i in range(4):
		var item = player.inventory.get_item(i)
		if item is DiskItem and not _disk_returned:
			disk = item
		elif item is NoteItem and not _manual_returned:
			manual = item
	
	if not disk and not manual:
		if label_3d:
			label_3d.text = "NOTHING TO RETURN"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "RETURN ITEMS TO END DAY"
		return
	
	if disk:
		player.inventory.remove_item(disk)
		_disk_returned = true
	if manual:
		player.inventory.remove_item(manual)
		_manual_returned = true
	
	_update_return_status()

func _update_return_status() -> void:
	if _disk_returned and _manual_returned:
		if label_3d:
			label_3d.text = "ALL ITEMS RETURNED"
		if DailyManager:
			DailyManager.is_day_completed = true
			DailyManager.day_completed.emit(DailyManager.current_day, DailyManager.current_score, DailyManager.daily_quota)
	elif label_3d:
		var parts = []
		if not _disk_returned: parts.append("DISK")
		if not _manual_returned: parts.append("MANUAL")
		label_3d.text = "RETURN: " + ", ".join(parts)

func _dispense_all() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory: return
	
	var free_slots = 0
	for i in range(4):
		if player.inventory.get_item(i) == null:
			free_slots += 1
	
	if free_slots < 2:
		if label_3d:
			label_3d.text = "NEED 2 FREE SLOTS"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "PRESS LMB TO TAKE ITEMS"
		return
	
	var disk_awarded = false
	if DiskManager:
		var disk = DiskManager.award_empty_disk()
		disk_awarded = disk != null
	
	var manual_awarded = false
	var manual = _create_manual_item()
	if manual:
		manual_awarded = player.inventory.add_item(manual)
	
	if disk_awarded and manual_awarded:
		_items_dispensed_today = true
		
		if sprite_3d:
			sprite_3d.visible = false
		
		if label_3d:
			label_3d.text = "RETURN ITEMS TO END DAY"

func _create_manual_item() -> NoteItem:
	var manual = load("res://Objects/items/manual.tres").duplicate() as NoteItem
	return manual
