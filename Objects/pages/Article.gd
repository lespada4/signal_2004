extends Control
class_name ArticlePage

@export var content: PageContent
@export var force_suspicious: bool = false  # Для тестирования
@export var force_dangerous: bool = false    # Для тестирования

@onready var title_label = $Panel/MarginContainer/VBoxContainer/Title
@onready var author_label = $Panel/MarginContainer/VBoxContainer/Author  
@onready var date_label = $Panel/MarginContainer/VBoxContainer/Date      
@onready var body_label = $Panel/MarginContainer/VBoxContainer/BodyText   
@onready var image: TextureRect = $Panel/Panel/TextureRect

func _ready() -> void:
	if content:
		_apply_content(content)
	else:
		var generator = ContentGenerator.new()
		
		# Принудительно выводим статистику изображений
		generator.debug_print_image_stats()
		
		# Генерируем случайный тип статьи
		var rand_val = randf()
		var generated
		
		if force_dangerous:
			generated = generator.generate_article(true, true)
			print("=== FORCED DANGEROUS ARTICLE ===")
		elif force_suspicious:
			generated = generator.generate_article(true, false)
			print("=== FORCED SUSPICIOUS ARTICLE ===")
		else:
			# Случайный выбор с весами: 40% обычная, 40% подозрительная, 20% опасная
			if rand_val < 0.4:
				generated = generator.generate_article(false, false)
				print("=== GENERATED NORMAL ARTICLE ===")
			elif rand_val < 0.8:
				generated = generator.generate_article(true, false)
				print("=== GENERATED SUSPICIOUS ARTICLE ===")
			else:
				generated = generator.generate_article(true, true)
				print("=== GENERATED DANGEROUS ARTICLE ===")
		
		_apply_content(generated)
func _apply_content(data: PageContent) -> void:
	title_label.text = data.get_title()
	author_label.text = "Автор: " + data.get_author()
	date_label.text = data.get_date()
	body_label.text = data.get_body()
	
	# ДЕБАГ: Анализируем сайт
	var generator = ContentGenerator.new()
	generator.debug_print_site_type(data)
	
	# Загружаем изображение из PageContent
	_load_image(data)

func _load_image(data: PageContent) -> void:
	if not image:
		print("ERROR: Image TextureRect not found!")
		return
	
	print("Loading image...")
	print("  has_image: ", data.has_image())
	print("  image_path: ", data.get_image_path())
	
	if data.has_image():
		image.texture = data.get_image()
		image.visible = true
		
		# Визуальная индикация типа изображения
		match data.get_image_path():
			"suspicious":
				image.self_modulate = Color(1.0, 1.0, 0.7)
				print("  Applied SUSPICIOUS tint")
			"dangerous":
				image.self_modulate = Color(1.0, 0.7, 0.7)
				print("  Applied DANGEROUS tint")
			_:
				image.self_modulate = Color.WHITE
				print("  Applied NORMAL tint")
	else:
		image.visible = false
		print("  Image hidden")

func update_content(new_content: PageContent) -> void:
	content = new_content
	_apply_content(new_content)

func setup(news_data: Dictionary) -> void:
	call_deferred("_setup_deferred", news_data)

func _setup_deferred(news_data: Dictionary) -> void:
	title_label.text = news_data.get("title", "Без названия")
	author_label.text = "Автор: " + news_data.get("author", "Неизвестен")
	date_label.text = news_data.get("date", "Дата не указана")
	body_label.text = news_data.get("body", "Нет содержимого")
	
	if news_data.has("image") and news_data["image"] != null:
		image.texture = news_data["image"]
		image.visible = true
	else:
		image.visible = false

func set_image_texture(texture: Texture2D) -> void:
	if image and texture:
		image.texture = texture
		image.visible = true

func hide_image() -> void:
	if image:
		image.visible = false

func show_image() -> void:
	if image and image.texture:
		image.visible = true

func get_image_texture() -> Texture2D:
	if image:
		return image.texture
	return null
