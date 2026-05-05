extends StaticBody3D
class_name DiskCleaner

@export var can_clean: bool = true
@export var clean_duration: float = 1.0
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Label3D

var _is_cleaning: bool = false
var _cleaned_disk: DiskItem = null

func _ready() -> void:
	sprite_3d.visible = true
	if label_3d:
		label_3d.text = "INSERT DISK"

func interact() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory: return
	
	# Если очистка завершена — забираем готовый диск
	if _is_cleaning and _cleaned_disk:
		_give_back_disk(player)
		return
	
	# Если идёт очистка — ничего не делаем
	if _is_cleaning:
		return
	
	if not can_clean: return
	
	# Ищем заполненный диск
	var disk = player.inventory.get_filled_disk()
	if not disk:
		if label_3d:
			label_3d.text = "NO FILLED DISKS"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "INSERT DISK"
		return
	
	# Сохраняем диск ДО удаления из инвентаря
	_cleaned_disk = disk
	
	# Забираем диск из инвентаря
	player.inventory.remove_item(disk)
	_start_cleaning()

func _start_cleaning() -> void:
	_is_cleaning = true
	
	if sprite_3d:
		sprite_3d.modulate = Color.RED
	
	if label_3d:
		label_3d.text = "CLEANING..."
	
	print("[DiskCleaner] Cleaning disk...")
	await get_tree().create_timer(clean_duration).timeout
	
	# Очищаем диск (с проверкой)
	if _cleaned_disk and DiskManager:
		DiskManager.clear_disk(_cleaned_disk)
	
	if sprite_3d:
		sprite_3d.modulate = Color.GREEN
	
	if label_3d:
		label_3d.text = "TAKE DISK"

func _give_back_disk(player: Player) -> void:
	if _cleaned_disk:
		player.inventory.add_item(_cleaned_disk)
	_cleaned_disk = null
	_is_cleaning = false
	
	if sprite_3d:
		sprite_3d.modulate = Color.WHITE
	
	if label_3d:
		label_3d.text = "INSERT DISK"
	
	print("[DiskCleaner] Disk returned to inventory")
