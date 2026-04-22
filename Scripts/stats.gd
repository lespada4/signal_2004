extends Control

@onready var day_label: Label = $Panel/VBoxContainer/DayLabel
@onready var progress_label: Label = $Panel/VBoxContainer/ProgressLabel
@onready var normal_label: Label = $Panel/VBoxContainer/NormalLabel
@onready var rare_label: Label = $Panel/VBoxContainer/RareLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar

func _ready() -> void:
	refresh()

func refresh() -> void:
	if not DailyManager:
		return
	
	var progress = DailyManager.get_progress()
	
	day_label.text = "DAY " + str(progress["day"])
	
	var normal_done = progress["normal_completed"]
	var normal_req = progress["normal_required"]
	var rare_done = progress["rare_completed"]
	var rare_req = progress["rare_required"]
	
	normal_label.text = "Normal sites: " + str(normal_done) + " / " + str(normal_req)
	rare_label.text = "Rare sites: " + str(rare_done) + " / " + str(rare_req)
	
	var total_done = normal_done + rare_done
	var total_req = normal_req + rare_req
	
	progress_label.text = "Progress: " + str(total_done) + " / " + str(total_req)
	progress_bar.max_value = total_req
	progress_bar.value = total_done
	
	if total_done >= total_req:
		progress_label.text += " - DAY COMPLETE!"
