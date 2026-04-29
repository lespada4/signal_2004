extends Node

signal disk_inserted(site: PageContent)

var _current_disk: DiskItem = null
var _current_site: PageContent = null
var _generator: ContentGenerator
var _base_disk: DiskItem
var _disk_site_cache: Dictionary = {}
var _used_disks: Array[DiskItem] = []

func _ready() -> void:
	_generator = ContentGenerator.new()
	_base_disk = load("res://Objects/items/drive.tres") as DiskItem
	print("[DiskManager] Ready")

func award_empty_disk() -> DiskItem:
	if not _base_disk:
		print("[DiskManager] ERROR: Base disk not loaded!")
		return null
	var disk = _base_disk.duplicate() as DiskItem
	disk.state = DiskItem.DiskState.EMPTY
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		if player.inventory.add_item(disk):
			print("[DiskManager] Awarded empty disk")
			return disk
		else:
			print("[DiskManager] Inventory full!")
			return null
	return null

func fill_pending_disk(color_name: String) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory: return false
	var disk = player.inventory.get_empty_disk()
	if not disk:
		print("[DiskManager] No empty disk to fill!")
		return false
	match color_name:
		"blue": disk.color = DiskItem.DiskColor.BLUE
		"red": disk.color = DiskItem.DiskColor.RED
		"green": disk.color = DiskItem.DiskColor.GREEN
	disk.fill()
	var site: PageContent = null
	if DailyManager and DailyManager.has_sites_remaining():
		site = DailyManager.get_next_site()
		print("[DiskManager] Got site from DailyManager: ", site.title)
	else:
		site = _generator.generate_site(DailyManager.current_day if DailyManager else 1)
		print("[DiskManager] DailyManager empty, generated fallback site")
	_disk_site_cache[disk] = site
	print("[DiskManager] Disk filled with ", color_name, " data")
	return true

func insert_disk(disk: DiskItem) -> bool:
	if disk.is_empty():
		print("[DiskManager] Cannot insert empty disk!")
		return false
	if is_disk_used(disk):
		print("[DiskManager] Disk already used — cannot insert again!")
		return false
	_current_disk = disk
	if _disk_site_cache.has(disk):
		_current_site = _disk_site_cache[disk]
		print("[DiskManager] Using CACHED site: ", _current_site.title)
	else:
		_current_site = _generator.generate_site(DailyManager.current_day if DailyManager else 1)
		_disk_site_cache[disk] = _current_site
		print("[DiskManager] Generated NEW site: ", _current_site.title)
	disk_inserted.emit(_current_site)
	return true

func get_current_site() -> PageContent:
	return _current_site

func confirm_site_loaded() -> void:
	if _current_disk:
		_used_disks.append(_current_disk)
		print("[DiskManager] Disk marked as used: ", _current_disk.get_color_name())
	# НЕ очищаем _current_disk здесь — он ещё нужен для eject

func has_disk_inserted() -> bool:
	return _current_disk != null

func is_disk_used(disk: DiskItem) -> bool:
	return _used_disks.has(disk)



func eject_disk() -> DiskItem:
	var disk = _current_disk
	_current_disk = null
	_current_site = null
	# НЕ удаляем из кэша — сайт должен остаться на диске
	print("[DiskManager] Disk ejected")
	return disk

func clear_disk(disk: DiskItem) -> bool:
	if disk.is_empty():
		print("[DiskManager] Disk is already empty!")
		return false
	if _disk_site_cache.has(disk):
		_disk_site_cache.erase(disk)
	var idx = _used_disks.find(disk)
	if idx != -1:
		_used_disks.remove_at(idx)
		print("[DiskManager] Disk removed from used list")
	disk.clear()
	print("[DiskManager] Disk cleared and ready for new data")
	return true
