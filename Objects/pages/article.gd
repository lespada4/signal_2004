extends ZalgoSite
class_name ArticlePage

@export var content: PageContent

@onready var title_label = $Panel/MarginContainer/VBoxContainer/Title
@onready var author_label = $Panel/MarginContainer/VBoxContainer/Author
@onready var date_label = $Panel2/Date
@onready var body_label = $Panel/MarginContainer/VBoxContainer/BodyText
@onready var image: TextureRect = $Panel/Panel2/TextureRect
@onready var normal_btn: Button = $VBoxContainer/Normal
@onready var anomaly_btn: Button = $VBoxContainer/Anomaly
@onready var dangerous_btn: Button = $VBoxContainer/Dangerous
@onready var result_label: Label = $VBoxContainer/ResultLabel

var _category_chosen: bool = false

func _ready() -> void:
	# Подключаем кнопки
	normal_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.NORMAL))
	anomaly_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.SUSPICIOUS))
	dangerous_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.DANGEROUS))
	
	# СНАЧАЛА загружаем контент
	if content:
		_apply_content(content)
	else:
		var generator = ContentGenerator.new()
		var generated = generator.generate_site(ContentGenerator.SiteCategory.NORMAL)
		_apply_content(generated)
	
	# ПОТОМ вызываем родительский _ready для Zalgo
	super._ready()
	
	# Скрываем результат по умолчанию
	if result_label:
		result_label.visible = false

func _apply_content(data: PageContent) -> void:
	content = data
	_category_chosen = false
	
	title_label.text = data.get_title()
	author_label.text = "Author: " + data.get_author()
	date_label.text = data.get_date()
	body_label.text = data.get_body()
	
	# Включаем кнопки
	normal_btn.disabled = false
	anomaly_btn.disabled = false
	dangerous_btn.disabled = false
	
	# Скрываем результат
	if result_label:
		result_label.visible = false
	
	# Загружаем изображение
	if data.has_image():
		image.texture = data.get_image()
		image.visible = true
		
		match data.image_path:
			"suspicious":
				image.self_modulate = Color(1.0, 1.0, 0.7)
			"dangerous":
				image.self_modulate = Color(1.0, 0.7, 0.7)
			_:
				image.self_modulate = Color.WHITE
	else:
		image.visible = false
	
	# Настраиваем Zalgo ПОСЛЕ загрузки текста
	call_deferred("_apply_zalgo_for_category", data.category)

func _apply_zalgo_for_category(category: ContentGenerator.SiteCategory) -> void:
	# Сначала обновляем оригинальные тексты
	refresh_zalgo()
	
	match category:
		ContentGenerator.SiteCategory.SUSPICIOUS:
			set_zalgo_enabled(true)
			set_zalgo_concentration(30)  # Лёгкое искажение (0-100)
			print("[ArticlePage] Zalgo enabled for SUSPICIOUS site")
			
		ContentGenerator.SiteCategory.DANGEROUS:
			set_zalgo_enabled(true)
			set_zalgo_concentration(70)  # Сильное искажение
			print("[ArticlePage] Zalgo enabled for DANGEROUS site")
			
		_:
			set_zalgo_enabled(false)
			print("[ArticlePage] Zalgo disabled for NORMAL site")

func _on_category_pressed(chosen_category: ContentGenerator.SiteCategory) -> void:
	if _category_chosen:
		return
	
	_category_chosen = true
	var actual_category = content.category
	var is_correct = (chosen_category == actual_category)
	
	print("[ArticlePage] Category chosen: ", ContentGenerator.SiteCategory.keys()[chosen_category])
	print("[ArticlePage] Actual category: ", ContentGenerator.SiteCategory.keys()[actual_category])
	print("[ArticlePage] Is correct: ", is_correct)
	
	# Блокируем кнопки
	normal_btn.disabled = true
	anomaly_btn.disabled = true
	dangerous_btn.disabled = true
	
	# Показываем результат
	if result_label:
		result_label.visible = true
		if is_correct:
			result_label.text = "✓ CORRECT!"
			result_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			result_label.text = "✗ INCORRECT!"
			result_label.add_theme_color_override("font_color", Color.RED)
			
			# Ищем EnemyManager в ГЛАВНОМ дереве сцены
			var enemy_manager = _find_enemy_manager()
			if enemy_manager and enemy_manager.has_method("on_site_misidentified"):
				print("[ArticlePage] Found EnemyManager, calling on_site_misidentified")
				enemy_manager.on_site_misidentified(actual_category)
			else:
				print("[ArticlePage] ERROR: EnemyManager not found!")
	
	# Отправляем в DailyManager
	if DailyManager:
		DailyManager.complete_site(content, chosen_category)
		print("[ArticlePage] Site reported to DailyManager")
	
	# Сообщаем FlashDriveManager что сайт обработан
	if FlashDriveManager:
		FlashDriveManager.eject_flash_drive()

func _find_enemy_manager() -> Node:
	# Способ 1: Ищем через группу
	var managers = get_tree().get_nodes_in_group("enemy_manager")
	if not managers.is_empty():
		print("[ArticlePage] Found EnemyManager via group")
		return managers[0]
	
	# Способ 2: Ищем по имени в корне главного дерева
	var root = get_tree().root
	for child in root.get_children():
		if child is EnemyManager:
			print("[ArticlePage] Found EnemyManager via root search")
			return child
		# Рекурсивно ищем в детях
		var found = _find_in_children(child)
		if found:
			return found
	
	# Способ 3: Ищем во всей главной сцене
	var main_scene = get_tree().current_scene
	if main_scene:
		if main_scene is EnemyManager:
			return main_scene
		var found = _find_in_children(main_scene)
		if found:
			return found
	
	return null

func _find_in_children(node: Node) -> Node:
	for child in node.get_children():
		if child is EnemyManager:
			return child
		var found = _find_in_children(child)
		if found:
			return found
	return null
func update_content(new_content: PageContent) -> void:
	_apply_content(new_content)
