extends Item
class_name DiskItem

enum DiskColor { BLUE, RED, GREEN }

@export var color: DiskColor = DiskColor.BLUE

func get_site_category() -> ContentGenerator.SiteCategory:
	match color:
		DiskColor.BLUE: 
			return ContentGenerator.SiteCategory.NORMAL
		DiskColor.RED: 
			return ContentGenerator.SiteCategory.SUSPICIOUS
		DiskColor.GREEN: 
			return ContentGenerator.SiteCategory.DANGEROUS
		_: 
			return ContentGenerator.SiteCategory.NORMAL

func get_color_name() -> String:
	match color:
		DiskColor.BLUE: return "blue"
		DiskColor.RED: return "red"
		DiskColor.GREEN: return "green"
		_: return "unknown"

func on_equip(player: Player) -> void:
	player.show_disk(self)

func on_unequip(player: Player) -> void:
	player.hide_disk()

func on_use(player: Player) -> bool:
	player.try_insert_disk(self)
	return true
