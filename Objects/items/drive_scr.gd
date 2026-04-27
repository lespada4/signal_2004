extends Item
class_name DiskItem

enum DiskColor { BLUE, RED, GREEN }
enum DiskState { EMPTY, FILLED }

@export var color: DiskColor = DiskColor.BLUE
@export var state: DiskState = DiskState.EMPTY

func get_site_category() -> ContentGenerator.SiteCategory:
	match color:
		DiskColor.BLUE: return ContentGenerator.SiteCategory.NORMAL
		DiskColor.RED: return ContentGenerator.SiteCategory.SUSPICIOUS
		DiskColor.GREEN: return ContentGenerator.SiteCategory.DANGEROUS
		_: return ContentGenerator.SiteCategory.NORMAL

func get_color_name() -> String:
	match color:
		DiskColor.BLUE: return "blue"
		DiskColor.RED: return "red"
		DiskColor.GREEN: return "green"
		_: return "unknown"

func is_empty() -> bool:
	return state == DiskState.EMPTY

func is_filled() -> bool:
	return state == DiskState.FILLED

func fill() -> void:
	state = DiskState.FILLED

func get_display_name() -> String:
	if state == DiskState.EMPTY:
		return "Empty Disk"
	else:
		return get_color_name().capitalize() + " Disk"

func on_equip(player: Player) -> void:
	player.show_disk(self)

func on_unequip(player: Player) -> void:
	player.hide_disk()

func on_use(player: Player) -> bool:
	if is_empty():
		print("[DiskItem] Cannot use empty disk!")
		return false
	player.try_insert_disk(self)
	return true


func clear() -> void:
	state = DiskState.EMPTY
	color = DiskColor.BLUE
	print("[DiskItem] Disk cleared - ready for new data")
