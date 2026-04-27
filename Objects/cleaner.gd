extends StaticBody3D
class_name DiskCleaner

@export var can_clean: bool = true
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var label_3d: Label3D = $Label3D

var _player: Player = null
var _is_cleaning: bool = false

func _ready() -> void:
	sprite_3d.visible = true
	
	if label_3d:
		label_3d.text = "DISK CLEANER"
	
	print("[DiskCleaner] Ready")

func interact() -> void:
	print("[DiskCleaner] interact() called")
	
	if _is_cleaning:
		print("[DiskCleaner] Already cleaning")
		return
	
	if not can_clean:
		print("[DiskCleaner] Cleaner disabled")
		return
	
	# Ищем заполненный диск в инвентаре игрока
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		print("[DiskCleaner] Player inventory not found!")
		return
	
	var disk = player.inventory.get_filled_disk()
	if not disk:
		print("[DiskCleaner] No filled disk to clean!")
		if label_3d:
			label_3d.text = "NO FILLED DISKS"
			await get_tree().create_timer(2.0).timeout
			if label_3d:
				label_3d.text = "DISK CLEANER"
		return
	
	# Начинаем очистку
	_is_cleaning = true
	
	if sprite_3d:
		sprite_3d.modulate = Color.RED
	
	if label_3d:
		label_3d.text = "CLEANING..."
	
	print("[DiskCleaner] Cleaning disk: ", disk.get_color_name())
	
	# Имитация процесса очистки (3 секунды)
	await get_tree().create_timer(3.0).timeout
	
	# Очищаем диск
	if DiskManager:
		DiskManager.clear_disk(disk)
		print("[DiskCleaner] Disk cleaned!")
	
	# Возвращаем в исходное состояние
	_is_cleaning = false
	
	if sprite_3d:
		sprite_3d.modulate = Color.WHITE
	
	if label_3d:
		label_3d.text = "DISK CLEANED!"
		await get_tree().create_timer(2.0).timeout
		if label_3d:
			label_3d.text = "DISK CLEANER"
