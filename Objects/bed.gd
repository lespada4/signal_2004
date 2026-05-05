extends StaticBody3D
class_name Bed

@onready var label_3d: Label3D = $Label3D
@export var sleep_duration: float = 3.0

var _is_sleeping: bool = false

func _ready() -> void:
	if label_3d:
		label_3d.text = "QUOTA NOT MET"
	
	if DailyManager:
		DailyManager.day_completed.connect(_on_day_completed)

func _on_day_completed(_day: int, _score: int, _quota: int) -> void:
	if label_3d:
		label_3d.text = "SLEEP"

func interact() -> void:
	if not DailyManager: return
	if _is_sleeping: return
	
	if not DailyManager.is_day_completed:
		print("[Bed] Quota not met — cannot sleep yet")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	
	# Проверяем инвентарь — нельзя спать с вещами
	if player and player.inventory:
		var has_items = false
		for i in range(4):
			if player.inventory.get_item(i) != null:
				has_items = true
				break
		if has_items:
			print("[Bed] Cannot sleep — return items to dispenser first!")
			if label_3d:
				label_3d.text = "RETURN ITEMS FIRST"
				await get_tree().create_timer(2.0).timeout
				if label_3d:
					label_3d.text = "SLEEP"
			return
	
	_is_sleeping = true
	print("[Bed] Going to sleep...")
	
	if player and player.has_method("lock_controls"):
		player.lock_controls()
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	get_tree().current_scene.add_child(canvas)
	
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.modulate.a = 0.0
	black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black_rect)
	
	var label = Label.new()
	label.text = "Sleeping..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.modulate.a = 0.0
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(black_rect, "modulate:a", 1.0, 1.0)
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	
	await get_tree().create_timer(sleep_duration).timeout
	
	DailyManager.current_day += 1
	DailyManager.start_new_day()
	
	label.text = "Waking up..."
	
	await get_tree().create_timer(1.0).timeout
	
	var fade_out = create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(black_rect, "modulate:a", 0.0, 1.0)
	fade_out.tween_property(label, "modulate:a", 0.0, 1.0)
	
	await fade_out.finished
	canvas.queue_free()
	
	if player and player.has_method("unlock_controls"):
		player.unlock_controls()
	
	if label_3d:
		label_3d.text = "QUOTA NOT MET"
	
	_is_sleeping = false
