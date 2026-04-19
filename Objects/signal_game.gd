extends Control

# =====================================================
#  NODES
# =====================================================
@onready var graph_area = $GraphArea
@onready var ref_line = $GraphArea/ReferenceLine
@onready var player_line = $GraphArea/PlayerLine

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
const POINTS: int = 100
const WIN_THRESHOLD: float = 20.0
const FREQ_STEP: float = 0.05
const AMP_STEP: float = 1.0

const AMP_INPUT_SPEED_NORMAL: float = 35.0
const FREQ_INPUT_SPEED_NORMAL: float = 8.0
const SPEED_FAST_MULTIPLIER: float = 2.5
const SPEED_SLOW_MULTIPLIER: float = 0.4

# =====================================================
#  LINE CONTROL
# =====================================================
@export var line_margin: float = 20.0

# =====================================================
#  SIGNALS
# =====================================================
signal game_completed(reward: String)
signal level_completed(level_id: int, reward: String)

# =====================================================
#  LIFECYCLE
# =====================================================
func _ready() -> void:
	# Ждём один кадр чтобы размеры применились
	await get_tree().process_frame
	_load_random_level()
	
	# Принудительно перерисовываем при изменении размера
	resized.connect(_on_control_resize)

func _on_control_resize() -> void:
	if is_active or game_won:
		_draw_lines()

func _process(delta: float) -> void:
	if not is_active or game_won:
		return
	
	# Проверяем что размеры валидные
	if graph_area.size.x <= 0 or graph_area.size.y <= 0:
		return

	_handle_input(delta)

	time_ref += delta * ref_speed
	time_player += delta * player_speed

	_draw_lines()
	_check_win(delta)

func _get_current_speed_multiplier() -> float:
	if Input.is_action_pressed("sprint"):
		return SPEED_FAST_MULTIPLIER
	elif Input.is_action_pressed("walk"):
		return SPEED_SLOW_MULTIPLIER
	else:
		return 1.0

func _handle_input(delta: float) -> void:
	if not is_active:
		return

	var speed_mult = _get_current_speed_multiplier()
	var changed = false

	if Input.is_action_pressed("ui_up"):
		player_amp += AMP_STEP * AMP_INPUT_SPEED_NORMAL * speed_mult * delta
		changed = true
	if Input.is_action_pressed("ui_down"):
		player_amp -= AMP_STEP * AMP_INPUT_SPEED_NORMAL * speed_mult * delta
		changed = true

	if Input.is_action_pressed("ui_right"):
		player_freq += FREQ_STEP * FREQ_INPUT_SPEED_NORMAL * speed_mult * delta
		changed = true
	if Input.is_action_pressed("ui_left"):
		player_freq -= FREQ_STEP * FREQ_INPUT_SPEED_NORMAL * speed_mult * delta
		changed = true

	if changed:
		player_amp = clamp(player_amp, 10.0, 80.0)
		player_freq = clamp(player_freq, 0.5, 3.5)

# =====================================================
#  LEVEL MANAGEMENT
# =====================================================
func _load_random_level() -> void:
	# Выбираем случайный пресет
	var random_index = randi() % all_presets.size()
	current_preset = all_presets[random_index].duplicate()
	current_level_index = current_preset["id"]

	ref_freq = current_preset["freq"]
	ref_amp = current_preset["amp"]

	player_line.visible = true

	time_ref = 0.0
	time_player = 0.0
	win_timer = 0.0

	player_freq = 0.5
	player_amp = 10.0

	print("=== СЛУЧАЙНЫЙ УРОВЕНЬ ===")
	print("ID: ", current_level_index + 1)
	print("Частота: ", ref_freq, ", Амплитуда: ", ref_amp)
	print("Награда: флешка (", current_preset["reward"], ")")
	
	# Принудительно рисуем после загрузки
	await get_tree().process_frame
	_draw_lines()

func _give_reward(reward_type: String) -> void:
	match reward_type:
		"blue":
			print("🎁 ПОЛУЧЕНА СИНЯЯ ФЛЕШКА!")
			print("   Сайт: weather.gov")
		"red":
			print("🎁 ПОЛУЧЕНА КРАСНАЯ ФЛЕШКА!")
			print("   Сайт: enemy-database.local")
		"green":
			print("🎁 ПОЛУЧЕНА ЗЕЛЁНАЯ ФЛЕШКА!")
			print("   Сайт: survivor-network.onion")
		_:
			print("🎁 ПОЛУЧЕНА НЕИЗВЕСТНАЯ ФЛЕШКА!")

func _on_level_completed() -> void:
	var reward = current_preset["reward"]
	
	print("=================================")
	print("       УРОВЕНЬ ПРОЙДЕН!")
	print("=================================")
	
	_give_reward(reward)
	
	game_won = true
	player_line.visible = false
	
	level_completed.emit(current_level_index, reward)
	game_completed.emit(reward)

# =====================================================
#  RENDERING
# =====================================================
func _draw_wave(line_node: Line2D, freq: float, amp: float, time_offset: float) -> void:
	if not graph_area:
		return

	var width: float = graph_area.size.x
	var height: float = graph_area.size.y

	if width <= 0 or height <= 0:
		return

	var points = PackedVector2Array()
	var center_y: float = height / 2.0

	var start_x: float = -line_margin
	var end_x: float = width + line_margin
	var step: float = (end_x - start_x) / float(POINTS - 1)

	for i in range(POINTS):
		var x: float = start_x + i * step
		var y: float = sin(x * freq * 0.05 + time_offset) * amp
		points.append(Vector2(x, center_y + y))

	line_node.points = points

func _draw_lines() -> void:
	_draw_wave(ref_line, ref_freq, ref_amp, time_ref)
	_draw_wave(player_line, player_freq, player_amp, time_player)

# =====================================================
#  WIN CONDITION
# =====================================================
func _check_win(delta: float) -> void:
	var ref_points = ref_line.points
	var player_points = player_line.points

	if ref_points.is_empty() or player_points.is_empty():
		win_timer = 0.0
		return

	var max_diff: float = 0.0
	for i in range(min(ref_points.size(), player_points.size())):
		var diff_y: float = abs(ref_points[i].y - player_points[i].y)
		max_diff = max(max_diff, diff_y)

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

	player_line.visible = true

	_load_random_level()
	_draw_lines()

func activate() -> void:
	is_active = true
	_draw_lines()

func deactivate() -> void:
	is_active = false
