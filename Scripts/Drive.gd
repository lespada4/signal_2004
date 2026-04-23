extends Node


signal disk_inserted(site: PageContent)

var _current_disk: DiskItem = null
var _current_site: PageContent = null
var _generator: ContentGenerator
var _base_disk: DiskItem  # Базовый ресурс диска

func _ready() -> void:
	_generator = ContentGenerator.new()
	_base_disk = load("res://Objects/items/drive.tres") as DiskItem
	print("[DiskManager] Ready")

func award_disk(color_name: String) -> DiskItem:
	if not _base_disk:
		print("[DiskManager] ERROR: Base disk not loaded!")
		return null
	
	# Клонируем базовый диск
	var disk = _base_disk.duplicate() as DiskItem
	
	# Устанавливаем цвет
	match color_name:
		"blue": disk.color = DiskItem.DiskColor.BLUE
		"red": disk.color = DiskItem.DiskColor.RED
		"green": disk.color = DiskItem.DiskColor.GREEN
		_: disk.color = DiskItem.DiskColor.BLUE
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		if player.inventory.add_item(disk):
			print("[DiskManager] Awarded ", disk.get_color_name(), " disk")
			return disk
		else:
			print("[DiskManager] Inventory full!")
			return null
	
	return null

func insert_disk(disk: DiskItem) -> bool:
	_current_disk = disk
	_current_site = _generator.generate_site(disk.get_site_category())
	disk_inserted.emit(_current_site)
	print("[DiskManager] Disk inserted, site generated: ", _current_site.title)
	return true

func get_current_site() -> PageContent:
	return _current_site

func confirm_site_loaded() -> void:
	_current_disk = null
	print("[DiskManager] Disk consumed")

func has_disk_inserted() -> bool:
	return _current_disk != null
