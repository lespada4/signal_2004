extends Control

@onready var day_label: Label = $Panel/VBoxContainer/DayLabel
@onready var quota_label: Label = $Panel/VBoxContainer/QuotaLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar

func _ready() -> void:
	refresh()

func refresh() -> void:
	if not DailyManager:
		return
	
	var progress = DailyManager.get_progress()
	
	day_label.text = "DAY " + str(progress["day"])
	
	var score = progress["score"]
	var quota = progress["quota"]
	var remaining = quota - score
	
	quota_label.text = "QUOTA: " + str(quota) + " pts"
	score_label.text = str(score) + " / " + str(quota)
	
	progress_bar.max_value = quota
	progress_bar.value = score
	
	if remaining <= 0:
		score_label.text += " — COMPLETE!"
		score_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		score_label.text += " — " + str(remaining) + " pts remaining"
		score_label.add_theme_color_override("font_color", Color.WHITE)
