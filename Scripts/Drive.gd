extends Node

signal disk_inserted(site: PageContent)

var _current_disk: DiskItem = null
var _current_site: PageContent = null
var _generator: ContentGenerator
var _base_disk: DiskItem

# Кэш сайтов: один диск = один сайт НАВСЕГДА
var _disk_site_cache: Dictionary = {}  # Dictionary[DiskItem, PageContent]

func _ready() -> void:
	_generator = ContentGenerator.new()
	_base_disk = load("res://Objects/items/drive.tres") as DiskItem
	print("[DiskManager] Ready")

# =====================================================
#  ВЫДАЧА ПУСТОГО ДИСКА
# =====================================================

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

# =====================================================
#  ЗАПОЛНЕНИЕ ДИСКА ПОСЛЕ МИНИ-ИГРЫ
# =====================================================

func fill_pending_disk(color_name: String) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return false
	
	var disk = player.inventory.get_empty_disk()
	if not disk:
		print("[DiskManager] No empty disk to fill!")
		return false
	
	match color_name:
		"blue": disk.color = DiskItem.DiskColor.BLUE
		"red": disk.color = DiskItem.DiskColor.RED
		"green": disk.color = DiskItem.DiskColor.GREEN
	
	disk.fill()
	
	# Берём сайт из DailyManager вместо генерации нового
	var site: PageContent = null
	if DailyManager and DailyManager.has_sites_remaining():
		site = DailyManager.get_next_site()
		print("[DiskManager] Got site from DailyManager: ", site.title)
	else:
		# Фоллбэк если DailyManager пуст
		site = _generator.generate_site(disk.get_site_category(), DailyManager.current_day if DailyManager else 1)
		print("[DiskManager] DailyManager empty, generated fallback site")
	
	# Кэшируем сайт для этого диска
	_disk_site_cache[disk] = site
	
	print("[DiskManager] Disk filled with ", color_name, " data")
	return true

# =====================================================
#  ВСТАВКА ДИСКА
# =====================================================

func insert_disk(disk: DiskItem) -> bool:
	if disk.is_empty():
		print("[DiskManager] Cannot insert empty disk!")
		return false
	
	_current_disk = disk
	
	# Достаём сайт из кэша (должен быть там после fill)
	if _disk_site_cache.has(disk):
		_current_site = _disk_site_cache[disk]
		print("[DiskManager] Using CACHED site: ", _current_site.title)
	else:
		# На всякий случай генерируем если нет в кэше
		_current_site = _generator.generate_site(disk.get_site_category())
		_disk_site_cache[disk] = _current_site
		print("[DiskManager] Generated NEW site: ", _current_site.title)
	
	disk_inserted.emit(_current_site)
	print("[DiskManager] Disk inserted")
	return true

func get_current_site() -> PageContent:
	return _current_site

func confirm_site_loaded() -> void:
	_current_disk = null
	print("[DiskManager] Disk consumed")

func has_disk_inserted() -> bool:
	return _current_disk != null


func clear_disk(disk: DiskItem) -> bool:
	if disk.is_empty():
		print("[DiskManager] Disk is already empty!")
		return false
	
	# Удаляем сайт из кэша
	if _disk_site_cache.has(disk):
		_disk_site_cache.erase(disk)
		print("[DiskManager] Cached site removed")
	
	# Очищаем диск
	disk.clear()
	print("[DiskManager] Disk cleared and ready for new data")
	return true
