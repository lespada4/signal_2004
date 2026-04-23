extends Resource
class_name Item

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var scene: PackedScene  # 3D модель в руках

func on_equip(_player: Player) -> void:
	pass

func on_unequip(_player: Player) -> void:
	pass

func on_use(_player: Player) -> bool:
	return false
