extends Control

# =====================================================
#  NODES
# =====================================================
@onready var graph_area = $GraphArea

@onready var freq_slider: VSlider = $Control/Panel3/MarginContainer/HBoxContainer/FreqSlider
@onready var freq_label: Label = $Control/Panel3/MarginContainer/HBoxContainer/FreqSlider/FreqLabel
@onready var amp_slider: VSlider = $Control/Panel3/MarginContainer/HBoxContainer/AmpSlider
@onready var amp_label: Label = $Control/Panel3/MarginContainer/HBoxContainer/AmpSlider/AmpLabel

# =====================================================
#  EQUALIZER
# =====================================================
@export_group("Equalizer")
@export var bar_count: int = 40
@export var bar_width: float = 8.0
@export var bar_gap: float = 2.0
@export var ref_color: Color = Color.ORANGE
@export var player_color: Color = Color.CYAN

var _ref_bars: Array[ColorRect] = []
var _player_bars: Array[ColorRect] = []

# =====================================================
#  GAME STATE
# =====================================================
var time_ref: float = 0.0
var time_player: float = 0.0
var game_won: bool = false
var is_active: bool = false
var current_level_index: int = 0
var win_timer: float = 0.0
const WIN_DELAY: float = 0.5

# =====================================================
#  FOUR FIXED PRESETS
# =====================================================
var all_presets: Array[Dictionary] = [
	{"freq": 1.0, "amp": 30, "id": 0, "reward": "blue"},
	{"freq": 2.0, "amp": 40, "id": 1, "reward": "red"},
	{"freq": 3.0, "amp": 50, "id": 2, "reward": "green"},
	{"freq": 1.2, "amp": 70, "id": 3, "reward": "blue"},
]

var current_preset: Dictionary = {}

# =====================================================
#  REFERENCE LINE
# =====================================================
var ref_freq: float = 2.0
var ref_amp: float = 30.0
var ref_speed: float = 1.0

# =====================================================
#  PLAYER LINE
# =====================================================
var player_freq: float = 1.0
var player_amp: float = 20.0
var player_speed: float = 1.0

# =====================================================
#  CONSTANTS
# =====================================================
const WIN_THRESHOLD: float = 20.0
const FREQ_STEP: float = 0.05
const AMP_STEP: float = 1.0

# =====================================================
#  SIGNALS
# =====================================================
signal game_completed(reward: String)
signal level_completed(level_id: int, reward: String)

# =====================================================
#  LIFECYCLE
# =====================================================
func _ready() -> void:
	_setup_equalizer()
	_setup_sliders()
	await get_tree().process_frame
	_load_random_level()
	resized.connect(_on_control_resize)

func _setup_sliders() -> void:
	# Частота
	freq_slider.min_value = 0.5
	freq_slider.max_value = 3.5
	freq_slider.step = FREQ_STEP
	freq_slider.value = player_freq
	freq_slider.value_changed.connect(_on_freq_changed)
	
	# Амплитуда
	amp_slider.min_value = 10.0
	amp_slider.max_value = 80.0
	amp_slider.step = AMP_STEP
	amp_slider.value = player_amp
	amp_slider.value_changed.connect(_on_amp_changed)
	
	_update_labels()

func _on_freq_changed(value: float) -> void:
	player_freq = value
	_update_labels()

func _on_amp_changed(value: float) -> void:
	player_amp = value
	_update_labels()

func _update_labels() -> void:
	if freq_label:
		freq_label.text = "%.2f" % player_freq
	if amp_label:
		amp_label.text = "%.0f" % player_amp

func _setup_equalizer() -> void:
	for child in graph_area.get_children():
		child.queue_free()
	
	_ref_bars.clear()
	_player_bars.clear()
	
	for i in range(bar_count):
		var ref_bar = ColorRect.new()
		ref_bar.color = ref_color
		ref_bar.size.x = bar_width
		graph_area.add_child(ref_bar)
		_ref_bars.append(ref_bar)
		
		var player_bar = ColorRect.new()
		player_bar.color = player_color
		player_bar.modulate.a = 0.7
		player_bar.size.x = bar_width * 0.6
		graph_area.add_child(player_bar)
		_player_bars.append(player_bar)

func _on_control_resize() -> void:
	if is_active or game_won:
		_draw_equalizer()

func _process(delta: float) -> void:
	if not is_active or game_won:
		return
	
	if graph_area.size.x <= 0 or graph_area.size.y <= 0:
		return

	time_ref += delta * ref_speed
	time_player += delta * player_speed

	_draw_equalizer()
	_check_win(delta)

# =====================================================
#  LEVEL MANAGEMENT
# =====================================================
func _load_random_level() -> void:
	var random_index = randi() % all_presets.size()
	current_preset = all_presets[random_index].duplicate()
	current_level_index = current_preset["id"]

	ref_freq = current_preset["freq"]
	ref_amp = current_preset["amp"]

	time_ref = 0.0
	time_player = 0.0
	win_timer = 0.0

	player_freq = 0.5
	player_amp = 10.0
	
	# Обновляем слайдеры
	freq_slider.value = player_freq
	amp_slider.value = player_amp

	print("=== СЛУЧАЙНЫЙ УРОВЕНЬ ===")
	print("ID: ", current_level_index + 1)
	print("Частота: ", ref_freq, ", Амплитуда: ", ref_amp)
	print("Награда: диск (", current_preset["reward"], ")")
	
	await get_tree().process_frame
	_draw_equalizer()

func _has_empty_disk() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		return player.inventory.get_empty_disk() != null
	return false

func _show_no_disk_warning() -> void:
	var label = Label.new()
	label.text = "NO EMPTY DISK!\nCLEAN A DISK FIRST"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.RED)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(label):
		label.queue_free()

func _give_reward(reward_type: String) -> void:
	if not _has_empty_disk():
		print("[WaveTuner] ⚠️ No empty disk! Use Disk Cleaner first!")
		_show_no_disk_warning()
		game_won = true
		return
	
	match reward_type:
		"blue": print("📀 ДАННЫЕ ЗАПИСАНЫ НА ДИСК!")
		"red": print("📀 ДАННЫЕ ЗАПИСАНЫ НА ДИСК!")
		"green": print("📀 ДАННЫЕ ЗАПИСАНЫ НА ДИСК!")
	
	if DiskManager:
		var success = DiskManager.fill_pending_disk(reward_type)
		if success:
			print("[WaveTuner] Disk filled successfully!")
		else:
			print("[WaveTuner] Failed to fill disk!")

func _on_level_completed() -> void:
	var reward = current_preset["reward"]
	
	print("=================================")
	print("       УРОВЕНЬ ПРОЙДЕН!")
	print("=================================")
	
	_give_reward(reward)
	
	game_won = true
	
	level_completed.emit(current_level_index, reward)
	game_completed.emit(reward)

# =====================================================
#  EQUALIZER RENDERING
# =====================================================

func _draw_equalizer() -> void:
	var width = graph_area.size.x
	var height = graph_area.size.y
	var center_y = height / 2.0
	
	if width <= 0 or height <= 0:
		return
	
	var total_width = bar_count * (bar_width + bar_gap)
	var start_x = (width - total_width) / 2.0
	
	for i in range(bar_count):
		var x = start_x + i * (bar_width + bar_gap)
		
		# Эталон
		var ref_h = abs(sin(i * ref_freq * 0.05 + time_ref)) * ref_amp
		_ref_bars[i].position = Vector2(x, center_y - ref_h)
		_ref_bars[i].size.y = ref_h * 2
		
		# Игрок
		var player_h = abs(sin(i * player_freq * 0.05 + time_player)) * player_amp
		_player_bars[i].position = Vector2(x + bar_width * 0.2, center_y - player_h)
		_player_bars[i].size.y = player_h * 2

# =====================================================
#  WIN CONDITION
# =====================================================
func _check_win(delta: float) -> void:
	var max_diff: float = 0.0
	
	for i in range(bar_count):
		var ref_h = _ref_bars[i].size.y
		var player_h = _player_bars[i].size.y
		max_diff = max(max_diff, abs(ref_h - player_h))
	
	if max_diff < WIN_THRESHOLD:
		win_timer += delta
		if win_timer >= WIN_DELAY:
			_on_level_completed()
	else:
		win_timer = 0.0

# =====================================================
#  PUBLIC API
# =====================================================
func reset_game() -> void:
	game_won = false
	win_timer = 0.0
	player_freq = 0.5
	player_amp = 10.0
	player_speed = ref_speed
	
	freq_slider.value = player_freq
	amp_slider.value = player_amp
	
	_load_random_level()
	_draw_equalizer()

func activate() -> void:
	if not _has_empty_disk():
		print("[WaveTuner] Cannot activate: no empty disk!")
		_show_no_disk_warning()
		return
	
	is_active = true
	_draw_equalizer()
	print("[WaveTuner] Activated")

func deactivate() -> void:
	is_active = false
