extends RichTextLabel

const ZALGO_UP = [
	0x0300, 0x0301, 0x0302, 0x0303, 0x0304, 0x0305, 0x0306, 0x0307,
	0x0308, 0x0309, 0x030A, 0x030B, 0x030C, 0x030D, 0x030E, 0x030F,
	0x0310, 0x0311, 0x0312, 0x0313, 0x0314, 0x033D, 0x033E, 0x033F,
	0x0340, 0x0341, 0x0342, 0x0343, 0x0344, 0x0346, 0x034A, 0x034B, 0x034C
]
const ZALGO_DOWN = [
	0x0316, 0x0317, 0x0318, 0x0319, 0x031C, 0x031D, 0x031E, 0x031F,
	0x0320, 0x0324, 0x0325, 0x0326, 0x0329, 0x032A, 0x032B, 0x032C,
	0x032D, 0x032E, 0x032F, 0x0330, 0x0331, 0x0332, 0x0333, 0x0339,
	0x033A, 0x033B, 0x033C, 0x0345
]
const ZALGO_MID = [
	0x0315, 0x031B, 0x0340, 0x0341, 0x0358, 0x0321, 0x0322, 0x0327, 0x0328
]

@export var zalgo_enabled: bool = true
@export var zalgo_intensity: int = 5
@export var update_interval: float = 0.1
@export var source_text: String = ""
@export var base_font_size: int = 16
var _timer: float = 0.0

func _process(delta: float) -> void:
	add_theme_font_size_override("normal_font_size", base_font_size)
	
	if not zalgo_enabled:
		return
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		text = zalgofy(source_text)

func set_zalgo(enabled: bool) -> void:
	zalgo_enabled = enabled
	if not enabled:
		text = source_text  

func zalgofy(input: String) -> String:
	var result = ""
	for c in input:
		result += c
		var up_count = randi() % zalgo_intensity
		for i in range(up_count):
			result += char(ZALGO_UP[randi() % ZALGO_UP.size()])
		var down_count = randi() % zalgo_intensity
		for i in range(down_count):
			result += char(ZALGO_DOWN[randi() % ZALGO_DOWN.size()])
		if randf() > 0.7:
			result += char(ZALGO_MID[randi() % ZALGO_MID.size()])
	return result
