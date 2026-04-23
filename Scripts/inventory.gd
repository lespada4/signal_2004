extends Node
class_name Inventory

const SLOT_COUNT: int = 4

signal slot_changed(slot: int, item: Item)
signal active_slot_changed(slot: int)
signal item_equipped(item: Item)      # ← ДОБАВИТЬ
signal item_unequipped()              # ← ДОБАВИТЬ

var _slots: Array[Item] = []
var _active_slot: int = 0
var _player: Player

func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(null)

func setup(player: Player) -> void:
	_player = player

# =====================================================
#  ДОБАВЛЕНИЕ / УДАЛЕНИЕ
# =====================================================

func add_item(item: Item) -> bool:
	for i in range(SLOT_COUNT):
		if _slots[i] == null:
			_slots[i] = item
			slot_changed.emit(i, item)
			
			# Если это первый предмет — автоматически экипируем
			if get_total_items() == 1:
				set_active_slot(i)
			
			print("[Inventory] Added ", item.display_name, " to slot ", i + 1)
			return true
	print("[Inventory] No free slots!")
	return false

func remove_item(item: Item) -> void:
	for i in range(SLOT_COUNT):
		if _slots[i] == item:
			var was_active = (_active_slot == i)
			_slots[i] = null
			slot_changed.emit(i, null)
			
			if was_active:
				_unequip_current()
				# Найти следующий непустой слот
				for j in range(SLOT_COUNT):
					if _slots[j] != null:
						set_active_slot(j)
						break
			
			print("[Inventory] Removed from slot ", i + 1)
			return

func remove_from_slot(slot: int) -> Item:
	if slot < 0 or slot >= SLOT_COUNT:
		return null
	var item = _slots[slot]
	_slots[slot] = null
	slot_changed.emit(slot, null)
	if _active_slot == slot:
		_unequip_current()
	return item

func _unequip_current() -> void:
	var item = _slots[_active_slot]
	if item and _player:
		item.on_unequip(_player)
	item_unequipped.emit()

# =====================================================
#  ПЕРЕКЛЮЧЕНИЕ СЛОТОВ
# =====================================================

func set_active_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	
	# Снимаем экипировку со старого слота
	_unequip_current()
	
	_active_slot = slot
	active_slot_changed.emit(slot)
	
	# Экипируем предмет из нового слота
	var item = _slots[slot]
	if item and _player:
		item.on_equip(_player)
		item_equipped.emit(item)
	
	print("[Inventory] Active slot: ", slot + 1)

func next_slot() -> void:
	set_active_slot((_active_slot + 1) % SLOT_COUNT)

func prev_slot() -> void:
	set_active_slot((_active_slot - 1 + SLOT_COUNT) % SLOT_COUNT)

# =====================================================
#  ИСПОЛЬЗОВАНИЕ
# =====================================================

func use_active_item() -> bool:
	var item = _slots[_active_slot]
	if item and _player:
		return item.on_use(_player)
	return false

# =====================================================
#  ГЕТТЕРЫ
# =====================================================

func get_item(slot: int) -> Item:
	if slot < 0 or slot >= SLOT_COUNT:
		return null
	return _slots[slot]

func get_active_item() -> Item:
	return _slots[_active_slot]

func get_active_slot() -> int:
	return _active_slot

func get_free_slot() -> int:
	for i in range(SLOT_COUNT):
		if _slots[i] == null:
			return i
	return -1

func is_full() -> bool:
	return get_free_slot() == -1

func get_total_items() -> int:
	var count = 0
	for item in _slots:
		if item != null:
			count += 1
	return count

func clear() -> void:
	_unequip_current()
	for i in range(SLOT_COUNT):
		_slots[i] = null
		slot_changed.emit(i, null)
	_active_slot = 0
	active_slot_changed.emit(0)
