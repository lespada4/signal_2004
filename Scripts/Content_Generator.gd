extends Node
class_name ContentGenerator

# =====================================================
#  ПУТИ К ИЗОБРАЖЕНИЯМ
# =====================================================

const IMAGES_NORMAL_PATH: String = "res://Web images/normal/"
const IMAGES_SUSPICIOUS_PATH: String ="res://Web images/sus/"
const IMAGES_DANGEROUS_PATH: String = "res://Web images/dang/"

# Кэш для загруженных путей к изображениям
var _normal_images: Array[String] = []
var _suspicious_images: Array[String] = []
var _dangerous_images: Array[String] = []
var _images_loaded: bool = false

# =====================================================
#  ПОДОЗРИТЕЛЬНЫЕ ЭЛЕМЕНТЫ
# =====================================================

const SUSPICIOUS_KEYWORDS = [
	"секретно", "бункер", "мутант", "аномалия", "излучение",
	"вирус", "эксперимент", "заговор", "военные", "лаборатория",
	"протокол X", "пропажа", "не вышли на связь", "странные символы",
	"шорохи", "неопознанный",
]

const DANGEROUS_KEYWORDS = [
	"оружие", "база данных", "пароль", "доступ", "администратор",
	"root", "взлом", "уязвимость", "код доступа", "терминал", "система защиты",
]

const SUSPICIOUS_AUTHORS = [
	"Разведчик", "Хакер", "Дезертир", "Неизвестный", "Аноним",
]

const SUSPICIOUS_YEARS = ["2012", "2013", "2020"]

const SUSPICIOUS_THRESHOLD: int = 2
const DANGEROUS_THRESHOLD: int = 4

# =====================================================
#  ПРЕСЕТЫ ДЛЯ SIMPLE
# =====================================================

const SIMPLE_TITLES = [
	"Отчёт за третий квартал",
	"Инструкция по эксплуатации",
	"Уведомление системы",
	"Техническое задание №4",
	"Протокол проверки №7",
	"Служебная записка",
]

const SIMPLE_BODIES = [
	"Данный документ содержит сведения о результатах проверки системы за указанный период.",
	"Для корректной работы устройства необходимо выполнить следующие шаги в указанном порядке.",
	"Система обнаружила нарушение целостности данных. Требуется вмешательство администратора.",
	"Все требования к проекту изложены в приложении. Срок сдачи — пятница.",
	"Плановое техническое обслуживание завершено. Все системы функционируют штатно.",
	"Доступ к запрашиваемым данным ограничен. Обратитесь к системному администратору.",
]

const SUSPICIOUS_SIMPLE_TITLES = [
	"Отчёт по объекту X-13 [СЕКРЕТНО]",
	"Протокол вскрытия №77",
	"Уведомление о нарушении периметра",
	"Список персонала бункера",
	"Отчёт об аномальной активности",
]

const SUSPICIOUS_SIMPLE_BODIES = [
	"Объект проявляет признаки нестабильности. Уровень излучения превышает допустимые нормы в 3 раза.",
	"При вскрытии обнаружены следы мутации. Образцы отправлены в лабораторию для дальнейшего анализа.",
	"В 03:47 зафиксировано движение в запретной зоне. Группа реагирования не обнаружила нарушителя.",
	"Трое сотрудников не вышли на связь после экспедиции в сектор 7. Поиски продолжаются.",
	"Система зафиксировала неопознанный сигнал на частоте 142.8 МГц. Источник не установлен.",
]

# =====================================================
#  ПРЕСЕТЫ ДЛЯ NEWS
# =====================================================

const NEWS_TITLES = [
	"Прорыв в энергетике",
	"Новые поселения на юге",
	"Встреча выживших",
	"Обновление систем безопасности",
	"Пропажа каравана",
]

const SUSPICIOUS_NEWS_TITLES = [
	"Странные символы на стенах бункера",
	"Мутанты замечены у восточных ворот",
	"Загадочное исчезновение разведгруппы",
	"Секретный протокол активирован",
	"Аномалия в секторе 7 расширяется",
]

const NEWS_AUTHORS = [
	"Пресс-служба",
	"Информационный отдел",
	"Корреспондент",
	"Аналитический центр",
]

const NEWS_BODIES = [
	"Учёные из убежища разработали новый источник питания, способный работать годами без обслуживания.",
	"На южных территориях обнаружены следы человеческой активности. Отправлена разведывательная группа.",
	"Завтра в 19:00 состоится общее собрание жителей в центральном зале.",
	"Система фильтрации воды требует планового обслуживания. Приносим извинения за временные неудобства.",
	"Караван с припасами не вышел на связь уже трое суток. Всем, кто обладает информацией, просьба сообщить.",
]

const SUSPICIOUS_NEWS_BODIES = [
	"Ночью на стенах убежища появились неизвестные символы. Охрана утверждает, что ничего не слышала.",
	"Охотники сообщают о появлении мутировавших существ в восточном секторе. Жителям рекомендуется не покидать убежище.",
	"Группа из пяти опытных сталкеров пропала во время исследования заброшенной лаборатории. Связь прервалась внезапно.",
	"Система безопасности автоматически активировала протокол 'Чёрное небо'. Причина не разглашается.",
	"Энергетическая аномалия в секторе 7 увеличилась на 40%. Эвакуация прилегающих районов отложена.",
]

# =====================================================
#  ПРЕСЕТЫ ДЛЯ ARTICLE
# =====================================================

const ARTICLE_TITLES = [
	"История Великого Отключения",
	"Технологии прошлого: что мы потеряли",
	"Как выжить в новых условиях",
	"Психология постапокалипсиса",
	"Оружие и защита: руководство",
]

const SUSPICIOUS_ARTICLE_TITLES = [
	"Эксперименты за закрытыми дверями",
	"Правда о военных базах",
	"Заговор учёных: кто управляет убежищем",
	"Мутации: случайность или план",
	"Код доступа: что скрывает администрация",
]

const ARTICLE_AUTHORS = [
	"Летописец",
	"Техномант",
	"Сталкер",
	"Учёный",
]

const ARTICLE_BODIES = [
	"Великое Отключение произошло 15 лет назад. В один момент мир погрузился во тьму, электричество исчезло, а люди остались один на один с хаосом...",
	"До падения люди обладали невероятными технологиями. Сегодня большая часть этих знаний утеряна, но некоторые артефакты всё ещё можно найти...",
	"Выживание — это искусство. В этом руководстве мы рассмотрим основные принципы: поиск воды, добыча пищи, создание укрытия...",
	"Жизнь после апокалипсиса меняет психику. Как сохранить рассудок и не потерять человеческий облик? Наши психологи делятся рекомендациями...",
	"От ножа до самодельного арбалета — обзор доступного оружия и средств защиты в условиях отсутствия промышленности.",
]

const SUSPICIOUS_ARTICLE_BODIES = [
	"Источники внутри убежища сообщают о секретных экспериментах над людьми. Официальные лица отрицают все обвинения.",
	"Военные базы, которые считались заброшенными, на самом деле функционируют. Кто-то продолжает охранять их тайны.",
	"Совет убежища скрывает правду о происходящем снаружи. У нас есть доказательства существования других поселений.",
	"Участившиеся случаи мутаций не случайны. Кто-то намеренно заражает воду и пищу. Мы нашли источник.",
	"Администраторы системы имеют доступ ко всем данным жителей. Ваши сообщения читают. За вами следят.",
]

# =====================================================
#  ПРЕСЕТЫ ДЛЯ FORUM
# =====================================================

const FORUM_THREADS = [
	{"title": "Проблемы с генератором", "author": "Сталкер", "replies": 5},
	{"title": "Где найти еду?", "author": "Охотник", "replies": 3},
	{"title": "Секретный бункер", "author": "Разведчик", "replies": 12},
	{"title": "Ночные шорохи", "author": "Новичок", "replies": 7},
	{"title": "Ремонт радиостанции", "author": "Техник", "replies": 2},
	{"title": "Странные символы", "author": "Учёный", "replies": 9},
	{"title": "Встреча с мутантом", "author": "Охотник", "replies": 4},
	{"title": "Запасы воды", "author": "Сталкер", "replies": 6},
]

const SUSPICIOUS_FORUM_THREADS = [
	{"title": "Взлом терминала безопасности", "author": "Хакер", "replies": 15},
	{"title": "Пароль от склада 7", "author": "Дезертир", "replies": 23},
	{"title": "Как отключить камеры", "author": "Аноним", "replies": 8},
	{"title": "Доступ к базе данных", "author": "Неизвестный", "replies": 31},
	{"title": "Уязвимость в системе охраны", "author": "Разведчик", "replies": 19},
]

# =====================================================
#  ЗАГРУЗКА ИЗОБРАЖЕНИЙ
# =====================================================

func _load_images_from_directory(path: String) -> Array[String]:
	var images: Array[String] = []
	var dir = DirAccess.open(path)
	
	if not dir:
		print("[ContentGenerator] ОШИБКА: Не удалось открыть папку: ", path)
		return images
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or \
			   file_name.ends_with(".jpeg") or file_name.ends_with(".webp"):
				images.append(path + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("[ContentGenerator] Загружено ", images.size(), " изображений из: ", path)
	return images

func _ensure_images_loaded() -> void:
	if _images_loaded:
		return
	
	_normal_images = _load_images_from_directory(IMAGES_NORMAL_PATH)
	_suspicious_images = _load_images_from_directory(IMAGES_SUSPICIOUS_PATH)
	_dangerous_images = _load_images_from_directory(IMAGES_DANGEROUS_PATH)
	
	_images_loaded = true

func get_random_normal_image() -> Texture2D:
	_ensure_images_loaded()
	if _normal_images.is_empty():
		return null
	return load(_normal_images[randi() % _normal_images.size()]) as Texture2D

func get_random_suspicious_image() -> Texture2D:
	_ensure_images_loaded()
	if _suspicious_images.is_empty():
		return null
	return load(_suspicious_images[randi() % _suspicious_images.size()]) as Texture2D

func get_random_dangerous_image() -> Texture2D:
	_ensure_images_loaded()
	if _dangerous_images.is_empty():
		return null
	return load(_dangerous_images[randi() % _dangerous_images.size()]) as Texture2D

func get_image_for_site(is_suspicious: bool, is_dangerous: bool = false) -> Texture2D:
	if is_dangerous:
		return get_random_dangerous_image()
	elif is_suspicious:
		return get_random_suspicious_image()
	else:
		return get_random_normal_image()

func add_image_to_content(content: PageContent, is_suspicious: bool, is_dangerous: bool = false) -> void:
	var image = get_image_for_site(is_suspicious, is_dangerous)
	if image:
		content.image = image
		if is_dangerous:
			content.image_path = "dangerous"
		elif is_suspicious:
			content.image_path = "suspicious"
		else:
			content.image_path = "normal"
		print("[ContentGenerator] Added image: ", content.image_path)
	else:
		# Если изображение не найдено, пробуем загрузить обычное как запасной вариант
		print("[ContentGenerator] WARNING: No image for ", 
			"dangerous" if is_dangerous else ("suspicious" if is_suspicious else "normal"),
			", using normal as fallback")
		var fallback = get_random_normal_image()
		if fallback:
			content.image = fallback
			content.image_path = "normal"
		else:
			print("[ContentGenerator] ERROR: No fallback image available!")

# =====================================================
#  АНАЛИЗ ПОДОЗРИТЕЛЬНОСТИ
# =====================================================

func _calculate_suspicious_score(content: PageContent) -> int:
	var score = 0
	
	for keyword in SUSPICIOUS_KEYWORDS:
		if content.title.to_lower().contains(keyword.to_lower()):
			score += 1
			break
	
	for keyword in SUSPICIOUS_KEYWORDS:
		if content.body.to_lower().contains(keyword.to_lower()):
			score += 1
			break
	
	for keyword in DANGEROUS_KEYWORDS:
		if content.body.to_lower().contains(keyword.to_lower()):
			score += 2
			break
	
	if content.author in SUSPICIOUS_AUTHORS:
		score += 1
	
	for year in SUSPICIOUS_YEARS:
		if content.date.contains(year):
			score += 1
			break
	
	for news in content.news_items:
		var title = news.get("title", "")
		var author = news.get("author", "")
		
		for keyword in SUSPICIOUS_KEYWORDS:
			if title.to_lower().contains(keyword.to_lower()):
				score += 1
				break
		
		if author in SUSPICIOUS_AUTHORS:
			score += 1
	
	for thread in content.threads:
		var author = thread.get("author", "")
		
		if author in SUSPICIOUS_AUTHORS:
			score += 1
		if thread.get("replies", 0) > 20:
			score += 1
	
	if content.has_image():
		if content.image_path == "dangerous":
			score += 3
		elif content.image_path == "suspicious":
			score += 2
	
	return score

func get_suspicious_elements(content: PageContent) -> Array[String]:
	var elements: Array[String] = []
	
	for keyword in SUSPICIOUS_KEYWORDS:
		if content.title.to_lower().contains(keyword.to_lower()):
			elements.append("Подозрительный заголовок: '" + keyword + "'")
			break
	
	for keyword in SUSPICIOUS_KEYWORDS:
		if content.body.to_lower().contains(keyword.to_lower()):
			elements.append("Подозрительное содержание: '" + keyword + "'")
			break
	
	if content.author in SUSPICIOUS_AUTHORS:
		elements.append("Подозрительный автор: " + content.author)
	
	for keyword in DANGEROUS_KEYWORDS:
		if content.body.to_lower().contains(keyword.to_lower()):
			elements.append("Опасное ключевое слово: '" + keyword + "'")
			break
	
	if content.has_image():
		if content.image_path == "dangerous":
			elements.append("Опасное изображение (искажённое/пугающее)")
		elif content.image_path == "suspicious":
			elements.append("Подозрительное изображение (искажённое)")
	
	return elements

func is_content_suspicious(content: PageContent) -> bool:
	var score = _calculate_suspicious_score(content)
	return score >= SUSPICIOUS_THRESHOLD and score < DANGEROUS_THRESHOLD

func is_content_dangerous(content: PageContent) -> bool:
	var score = _calculate_suspicious_score(content)
	return score >= DANGEROUS_THRESHOLD

func is_content_normal(content: PageContent) -> bool:
	var score = _calculate_suspicious_score(content)
	return score < SUSPICIOUS_THRESHOLD

# =====================================================
#  ДЕБАГ
# =====================================================

func debug_print_site_type(content: PageContent) -> void:
	var score = _calculate_suspicious_score(content)
	
	print("=================================")
	print("       АНАЛИЗ САЙТА")
	print("=================================")
	print("Заголовок: ", content.title if content.title else content.site_title)
	print("Тип контента: ", PageContent.ContentType.keys()[content.content_type])
	print("Очки подозрительности: ", score)
	
	if content.has_image():
		print("Изображение: ", content.image_path)
	
	if score >= DANGEROUS_THRESHOLD:
		print(">>> КАТЕГОРИЯ: ОПАСНЫЙ САЙТ <<<")
	elif score >= SUSPICIOUS_THRESHOLD:
		print(">>> КАТЕГОРИЯ: ПОДОЗРИТЕЛЬНЫЙ САЙТ <<<")
	else:
		print(">>> КАТЕГОРИЯ: ОБЫЧНЫЙ САЙТ <<<")
	
	var elements = get_suspicious_elements(content)
	if elements.size() > 0:
		print("\nПодозрительные элементы:")
		for element in elements:
			print("  • ", element)
	
	print("=================================\n")

func debug_print_image_stats() -> void:
	_ensure_images_loaded()
	print("=================================")
	print("       СТАТИСТИКА ИЗОБРАЖЕНИЙ")
	print("=================================")
	print("Обычные: ", _normal_images.size())
	print("Подозрительные: ", _suspicious_images.size())
	print("Опасные: ", _dangerous_images.size())
	print("=================================\n")

# =====================================================
#  МЕТОДЫ ГЕНЕРАЦИИ
# =====================================================

func generate_simple(is_suspicious: bool = false, is_dangerous: bool = false) -> PageContent:
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.SIMPLE
	content.site_title = "Информационная панель"
	
	if is_suspicious or is_dangerous:
		content.title = SUSPICIOUS_SIMPLE_TITLES[randi() % SUSPICIOUS_SIMPLE_TITLES.size()]
		content.body = SUSPICIOUS_SIMPLE_BODIES[randi() % SUSPICIOUS_SIMPLE_BODIES.size()]
	else:
		content.title = SIMPLE_TITLES[randi() % SIMPLE_TITLES.size()]
		content.body = SIMPLE_BODIES[randi() % SIMPLE_BODIES.size()]
	
	if randf() < 0.5:
		add_image_to_content(content, is_suspicious, is_dangerous)
	
	return content

func generate_news(count: int = 3, is_suspicious: bool = false, is_dangerous: bool = false) -> PageContent:
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.NEWS
	content.site_title = "Лента новостей"
	
	for i in range(count):
		var news = {}
		if is_suspicious or is_dangerous:
			news["title"] = SUSPICIOUS_NEWS_TITLES[randi() % SUSPICIOUS_NEWS_TITLES.size()]
			news["body"] = SUSPICIOUS_NEWS_BODIES[randi() % SUSPICIOUS_NEWS_BODIES.size()]
		else:
			news["title"] = NEWS_TITLES[randi() % NEWS_TITLES.size()]
			news["body"] = NEWS_BODIES[randi() % NEWS_BODIES.size()]
		
		news["author"] = NEWS_AUTHORS[randi() % NEWS_AUTHORS.size()]
		news["date"] = _get_random_date()
		
		# ВАЖНО: Каждая новость получает СВОЁ случайное изображение
		# Используем заново случайный выбор для каждой новости
		var img = get_random_image_for_news(is_suspicious, is_dangerous)
		if img:
			news["image"] = img
			print("[ContentGenerator] News ", i, " got image")
		
		content.news_items.append(news)
	
	# Главное изображение для всей ленты
	add_image_to_content(content, is_suspicious, is_dangerous)
	
	return content

# Новая функция для получения случайного изображения для отдельной новости
func get_random_image_for_news(is_suspicious: bool, is_dangerous: bool = false) -> Texture2D:
	_ensure_images_loaded()
	
	var images_array: Array[String]
	var category = "normal"
	
	if is_dangerous and not _dangerous_images.is_empty():
		images_array = _dangerous_images
		category = "dangerous"
	elif is_suspicious and not _suspicious_images.is_empty():
		images_array = _suspicious_images
		category = "suspicious"
	elif not _normal_images.is_empty():
		images_array = _normal_images
	else:
		print("[ContentGenerator] ERROR: No images available!")
		return null
	
	print("[ContentGenerator] Selecting from ", images_array.size(), " ", category, " images")
	
	if images_array.size() == 1:
		print("[ContentGenerator] WARNING: Only one image in ", category, " folder! Add more images for variety.")
	
	var random_path = images_array[randi() % images_array.size()]
	print("[ContentGenerator] Selected: ", random_path.get_file())
	
	return load(random_path) as Texture2D

func generate_article(is_suspicious: bool = false, is_dangerous: bool = false) -> PageContent:
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.ARTICLE
	content.site_title = "База знаний"
	
	if is_suspicious or is_dangerous:
		content.title = SUSPICIOUS_ARTICLE_TITLES[randi() % SUSPICIOUS_ARTICLE_TITLES.size()]
		content.body = SUSPICIOUS_ARTICLE_BODIES[randi() % SUSPICIOUS_ARTICLE_BODIES.size()]
	else:
		content.title = ARTICLE_TITLES[randi() % ARTICLE_TITLES.size()]
		content.body = ARTICLE_BODIES[randi() % ARTICLE_BODIES.size()]
	
	content.author = ARTICLE_AUTHORS[randi() % ARTICLE_AUTHORS.size()]
	content.date = _get_random_date()
	
	# У артикля ВСЕГДА есть картинка
	add_image_to_content(content, is_suspicious, is_dangerous)
	print("[ContentGenerator] Article generated with image: ", content.image_path)
	
	return content

func generate_forum(count: int = 5, is_suspicious: bool = false) -> PageContent:
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.FORUM
	content.site_title = "Форум выживших"
	
	var threads_source = SUSPICIOUS_FORUM_THREADS if is_suspicious else FORUM_THREADS
	var shuffled = threads_source.duplicate()
	shuffled.shuffle()
	
	for i in range(min(count, shuffled.size())):
		var thread = shuffled[i]
		content.threads.append({
			"title": thread["title"],
			"author": thread["author"],
			"replies": thread["replies"],
			"last_post": _get_random_date()
		})
	
	if randf() < 0.2:
		add_image_to_content(content, is_suspicious, false)
	
	return content

func generate_by_type(type: PageContent.ContentType, is_suspicious: bool = false, is_dangerous: bool = false) -> PageContent:
	match type:
		PageContent.ContentType.SIMPLE:
			return generate_simple(is_suspicious, is_dangerous)
		PageContent.ContentType.NEWS:
			return generate_news(randi() % 3 + 3, is_suspicious, is_dangerous)
		PageContent.ContentType.ARTICLE:
			return generate_article(is_suspicious, is_dangerous)
		PageContent.ContentType.FORUM:
			return generate_forum(randi() % 4 + 3, is_suspicious)
		_:
			return generate_simple(is_suspicious, is_dangerous)

func generate_website(force_suspicious: bool = false, force_dangerous: bool = false) -> PageContent:
	var is_suspicious = force_suspicious or force_dangerous or (randf() < 0.3)
	var is_dangerous = force_dangerous
	
	var types = [
		PageContent.ContentType.SIMPLE,
		PageContent.ContentType.NEWS,
		PageContent.ContentType.ARTICLE,
		PageContent.ContentType.FORUM,
	]
	
	var selected_type = types[randi() % types.size()]
	return generate_by_type(selected_type, is_suspicious, is_dangerous)

func generate_daily_websites() -> Array[PageContent]:
	var websites: Array[PageContent] = []
	
	for i in range(2):
		websites.append(generate_website(false, false))
	
	var is_dangerous = randf() < 0.3
	websites.append(generate_website(true, is_dangerous))
	
	websites.shuffle()
	return websites

# =====================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# =====================================================

func _get_random_date() -> String:
	var year = randi() % 12 + 2000
	var month = randi() % 12 + 1
	var day = randi() % 28 + 1
	return "%d-%02d-%02d" % [year, month, day]

func generate() -> PageContent:
	return generate_simple()
