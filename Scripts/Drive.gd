extends Node

signal flash_drive_collected(color: String)
signal flash_drive_inserted(site: PageContent)
signal flash_drive_ejected()
signal flash_drive_consumed()

var _collected_flash_drives: Array[String] = []
var _current_site: PageContent = null
var _generator: ContentGenerator
var _has_active_flash_drive: bool = false
var _site_loaded: bool = false

func _ready() -> void:
	_generator = ContentGenerator.new()
	print("[FlashDriveManager] Ready")

# =====================================================
#  ПОЛУЧЕНИЕ ФЛЕШКИ
# =====================================================

func can_collect_flash_drive() -> bool:
	return not _has_active_flash_drive and not _site_loaded

func collect_flash_drive(color: String) -> bool:
	if not can_collect_flash_drive():
		print("[FlashDriveManager] Cannot collect: already have active flash drive or site loaded")
		return false
	
	_collected_flash_drives.append(color)
	_has_active_flash_drive = true
	_site_loaded = false
	
	print("[FlashDriveManager] Collected ", color, " flash drive")
	flash_drive_collected.emit(color)
	return true

# =====================================================
#  ГЕНЕРАЦИЯ САЙТА
# =====================================================

func _generate_site_for_color(color: String) -> PageContent:
	match color:
		"blue":
			return _generator.generate_site(ContentGenerator.SiteCategory.NORMAL)
		"red":
			return _generator.generate_site(ContentGenerator.SiteCategory.SUSPICIOUS)
		"green":
			return _generator.generate_site(ContentGenerator.SiteCategory.DANGEROUS)
		_:
			return _generator.generate_site(ContentGenerator.SiteCategory.NORMAL)

# =====================================================
#  ВСТАВКА ФЛЕШКИ
# =====================================================

func can_insert_flash_drive() -> bool:
	return _has_active_flash_drive and not _site_loaded

func get_current_flash_drive_color() -> String:
	if _collected_flash_drives.is_empty():
		return ""
	return _collected_flash_drives.back()

func insert_latest_flash_drive() -> bool:
	if not can_insert_flash_drive():
		print("[FlashDriveManager] Cannot insert: no active flash drive or site already loaded")
		return false
	
	var color = _collected_flash_drives.back()
	_current_site = _generate_site_for_color(color)
	
	print("[FlashDriveManager] Inserted ", color, " flash drive")
	print("[FlashDriveManager] Generated site: ", _current_site.title)
	
	flash_drive_inserted.emit(_current_site)
	return true

# =====================================================
#  ПОДТВЕРЖДЕНИЕ ВСТАВКИ
# =====================================================

func confirm_insertion() -> void:
	if not _collected_flash_drives.is_empty():
		_collected_flash_drives.pop_back()
		_has_active_flash_drive = false
		flash_drive_consumed.emit()
		print("[FlashDriveManager] Flash drive consumed. Remaining: ", _collected_flash_drives.size())

func confirm_site_loaded() -> void:
	_site_loaded = true
	print("[FlashDriveManager] Site loaded in terminal")
	_clear_flash_drive()

func _clear_flash_drive() -> void:
	if not _collected_flash_drives.is_empty():
		_collected_flash_drives.pop_back()
	
	_has_active_flash_drive = false
	flash_drive_consumed.emit()
	print("[FlashDriveManager] Flash drive cleared")

# =====================================================
#  ИЗВЛЕЧЕНИЕ ФЛЕШКИ
# =====================================================

func eject_flash_drive() -> void:
	if _site_loaded:
		_current_site = null
		_site_loaded = false
		_has_active_flash_drive = false
		print("[FlashDriveManager] Ejected: site cleared, drive empty")
	else:
		_has_active_flash_drive = false
		_current_site = null
		print("[FlashDriveManager] Ejected: drive removed")
	
	flash_drive_ejected.emit()

# =====================================================
#  СБРОС ПОСЛЕ МИНИ-ИГРЫ
# =====================================================

func reset_for_new_flash_drive() -> void:
	if _site_loaded:
		print("[FlashDriveManager] Reset: clearing loaded site for new flash drive")
		_current_site = null
		_site_loaded = false
		flash_drive_ejected.emit()

# =====================================================
#  ГЕТТЕРЫ
# =====================================================

func has_collected_flash_drives() -> bool:
	return _has_active_flash_drive

func get_current_site() -> PageContent:
	return _current_site

func get_collected_count() -> int:
	return _collected_flash_drives.size()

func is_site_loaded() -> bool:
	return _site_loaded

func has_active_flash_drive() -> bool:
	return _has_active_flash_drive
