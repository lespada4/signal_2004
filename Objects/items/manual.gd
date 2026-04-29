extends Item
class_name NoteItem

@export_multiline var page1_text: String = ""
@export_multiline var page2_text: String = ""

const DAY_TEXTS = {
	1: {
		"page1": "FIELD MANUAL v1.0 - DAY 1

КРИТЕРИИ АНАЛИЗА:

ОПАСНЫЕ ПРИЗНАКИ:
☐ Zalgo искажение
☐ Утечка рассудка

ПОДОЗРИТЕЛЬНЫЕ ПРИЗНАКИ:
☐ Глитч изображения
☐ Текст меняется при ОБНОВЛЕНИИ

ФОРМУЛА:
1+ ОПАСНЫЙ признак = ОПАСНЫЙ
1+ ПОДОЗРИТЕЛЬНЫЙ (без опасных) = ПОДОЗРИТЕЛЬНЫЙ
Нет признаков = НОРМАЛЬНЫЙ

Блек-листов сегодня нет.",
		
		"page2": "FIELD MANUAL v1.0 - DAY 1

СПРАВОЧНИК:

Все авторы и домены разрешены.

АНОМАЛЬНЫЕ ДАТЫ:
Даты после 2011 — подозрительны."
	},
	2: {
		"page1": "FIELD MANUAL v1.0 - DAY 2

КРИТЕРИИ АНАЛИЗА:

ОПАСНЫЕ ПРИЗНАКИ:
☐ Zalgo искажение
☐ Утечка рассудка

ПОДОЗРИТЕЛЬНЫЕ ПРИЗНАКИ:
☐ Глитч изображения
☐ Текст меняется при ОБНОВЛЕНИИ

БЛЕК-ЛИСТ:
Авторы: Redto Phil, Kyle Saren, Sc44m, Zorro Rumi
Домены: .ab, .??, .end, .brk

ФОРМУЛА:
1+ ОПАСНЫЙ = ОПАСНЫЙ
1+ элемент блек-листа = ПОДОЗРИТЕЛЬНЫЙ",
		
		"page2": "FIELD MANUAL v1.0 - DAY 2

БЛЕК-ЛИСТ:
• Redto Phil, Kyle Saren
• Sc44m, Zorro Rumi
• Домены: .ab, .??, .end, .brk

АНОМАЛЬНЫЕ ДАТЫ: 2012+"
	},
	3: {
		"page1": "FIELD MANUAL v1.0 - DAY 3

КРИТЕРИИ АНАЛИЗА:

ОПАСНЫЕ ПРИЗНАКИ:
☐ Zalgo искажение
☐ Утечка рассудка

ПОДОЗРИТЕЛЬНЫЕ ПРИЗНАКИ:
☐ Глитч изображения
☐ Текст меняется при ОБНОВЛЕНИИ
☐ Аномалии в ЛОГАХ

БЛЕК-ЛИСТ:
Авторы: Dr. Ganium, Abime Historia, Contained Jeremy, Arsi, Shiro, Jay Gail
Домены: .!!, ...

ДИАГНОСТИКА ЛОГОВ:
Высокая температура CPU, повреждённая RAM, странная сеть",
		
		"page2": "FIELD MANUAL v1.0 - DAY 3

БЛЕК-ЛИСТ:
• Dr. Ganium, Abime Historia
• Contained Jeremy, Arsi, Shiro, Jay Gail
• Домены: .!!, ...

АНОМАЛЬНЫЕ ДАТЫ: 2012+

ИНДИКАТОРЫ ЛОГОВ:
ПОДОЗРИТЕЛЬНЫЙ: Высокая температура, вентилятор на максимум
ОПАСНЫЙ: Повреждённая RAM, рекурсивная сеть"
	}
}

var _manual_ui: ManualUI = null
var _is_manual_open: bool = false

func _load_texts_for_day() -> void:
	var day = DailyManager.current_day if DailyManager else 1
	var texts = DAY_TEXTS.get(day, DAY_TEXTS[1])
	page1_text = texts["page1"]
	page2_text = texts["page2"]

func on_equip(player: Player) -> void:
	_load_texts_for_day()
	if scene:
		var instance = scene.instantiate()
		player.item_holder.add_child(instance)
		player.current_item_instance = instance
		instance.position = Vector3(0.2, -0.1, -0.4)

func on_unequip(player: Player) -> void:
	_close_manual()
	if player.current_item_instance:
		player.current_item_instance.queue_free()
		player.current_item_instance = null

func on_use(player: Player) -> bool:
	if _manual_ui and is_instance_valid(_manual_ui):
		_close_manual()
	else:
		_manual_ui = null
		_is_manual_open = false
		_open_manual(player)
	return true

func _open_manual(player: Player) -> void:
	if _is_manual_open or (_manual_ui and is_instance_valid(_manual_ui)):
		return
	
	_load_texts_for_day()
	
	var ui_scene = load("res://Objects/items/manual_ui.tscn")
	_manual_ui = ui_scene.instantiate()
	_manual_ui._player = player
	_manual_ui.closed_by_user.connect(_close_manual)
	
	var ui_root = player.ui_root if player.ui_root else player
	ui_root.add_child(_manual_ui)
	
	_manual_ui.open_with_pages([page1_text, page2_text], "FIELD MANUAL v1.0")
	_is_manual_open = true

func _close_manual() -> void:
	_is_manual_open = false
	if _manual_ui:
		_manual_ui.close()
		_manual_ui.queue_free()
		_manual_ui = null
