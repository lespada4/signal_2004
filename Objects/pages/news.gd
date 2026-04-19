extends Control
class_name NewsFeed

@export var content: PageContent
@export var zalgo_resource: ZalgoEffect
@export var randomize_news_count: bool = true
@export_range(3, 20, 1) var min_news: int = 3
@export_range(3, 20, 1) var max_news: int = 12

@onready var title_label = $Header/Title
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

var _zalgo_applied: bool = false

func _ready():
	# Разрешаем получение фокуса
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	if content:
		_load_content(content)
	else:
		var generator = ContentGenerator.new()
		var generated = generator.generate_news(max_news)  # ← генерируем максимум
		_load_content(generated)
	
	_apply_zalgo_from_resource()

func _apply_zalgo_from_resource() -> void:
	if zalgo_resource and not _zalgo_applied:
		zalgo_resource.apply_to(self)
		_zalgo_applied = true

func _process(delta: float) -> void:
	if zalgo_resource and _zalgo_applied:
		zalgo_resource.update(delta)

func _load_content(data: PageContent) -> void:
	print("=== LOADING NEWS ===")
	print("Site title: ", data.site_title)
	print("Total available news: ", data.news_items.size())
	
	# ДЕБАГ: Определяем тип сайта
	var generator = ContentGenerator.new()
	generator.debug_print_site_type(data)
	
	title_label.text = data.site_title if data.site_title != "" else "Лента новостей"
	
	for child in v_box_container.get_children():
		child.queue_free()
	
	# Выбираем новости для отображения
	var news_to_show = data.news_items.duplicate()
	
	if randomize_news_count and news_to_show.size() > 0:
		news_to_show.shuffle()
		var available = news_to_show.size()
		var target_count = randi() % (max_news - min_news + 1) + min_news
		var final_count = clamp(target_count, min_news, available)
		news_to_show = news_to_show.slice(0, final_count)
		print("Showing ", news_to_show.size(), " news (randomized)")
	else:
		print("Showing all ", news_to_show.size(), " news")
	
	for news in news_to_show:
		var news_item = _create_news_item()
		if news_item:
			v_box_container.add_child(news_item)
			await get_tree().process_frame
			news_item.setup(news)
	
	if zalgo_resource and _zalgo_applied:
		zalgo_resource.refresh_texts()
		zalgo_resource._apply_to_all()

func _create_news_item():
	var news_scene = load("res://Objects/pages/new.tscn")
	if news_scene:
		return news_scene.instantiate()
	else:
		print("Failed to load NewsItem.tscn")
		return null

func update_content(new_content: PageContent) -> void:
	content = new_content
	_load_content(new_content)

func set_zalgo_enabled(enabled: bool) -> void:
	if zalgo_resource:
		zalgo_resource.enabled = enabled
		if enabled:
			zalgo_resource.apply_to(self)
		else:
			zalgo_resource.remove()

func set_zalgo_concentration(value: int) -> void:
	if zalgo_resource:
		zalgo_resource.set_concentration(value)

func _gui_input(event: InputEvent):
	# Логи для отладки
	if event is InputEventMouseButton:
		print("Click at: ", event.position)
	elif event is InputEventMouseMotion:
		print("Mouse move at: ", event.position)
