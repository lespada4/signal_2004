extends Resource
class_name PageContent

# =====================================================
#  СИМПТОМЫ
# =====================================================

enum Symptom {
	NONE,
	ZALGO_LIGHT,
	ZALGO_HEAVY,
	IMAGE_GLITCH,
	TEXT_UNSTABLE,
	SANITY_DRAIN_LIGHT,
	SANITY_DRAIN_HEAVY,
	CPU_ANOMALY,
	BLACKLIST_ELEMENT
}

# =====================================================
#  ОСНОВНЫЕ ПОЛЯ
# =====================================================
@export var title: String = ""
@export var body: String = ""
@export var site_title: String = ""
@export var author: String = ""
@export var date: String = ""

# =====================================================
#  ИЗОБРАЖЕНИЯ
# =====================================================
@export var image: Texture2D = null
@export var image_path: String = ""

# =====================================================
#  ДЛЯ ФОРУМА
# =====================================================
@export var threads: Array[Dictionary] = []

# =====================================================
#  ДЛЯ НОВОСТЕЙ
# =====================================================
@export var news_items: Array[Dictionary] = []

# =====================================================
#  ТИП КОНТЕНТА
# =====================================================
enum ContentType {
	FORUM,
	NEWS,
	ARTICLE,
	SIMPLE
}
@export var content_type: ContentType = ContentType.SIMPLE

# =====================================================
#  КАТЕГОРИЯ САЙТА
# =====================================================
@export var category: int = 0

# =====================================================
#  СИМПТОМЫ
# =====================================================
@export var symptoms: Array[int] = []

func has_symptom(symptom: Symptom) -> bool:
	return symptoms.has(symptom)

func add_symptom(symptom: Symptom) -> void:
	if not symptoms.has(symptom):
		symptoms.append(symptom)

func get_symptom_count() -> int:
	return symptoms.size()

# =====================================================
#  МЕТОДЫ ДОСТУПА
# =====================================================

func get_title() -> String:
	return title if title != "" else "Untitled"

func get_body() -> String:
	return body if body != "" else "No content"

func get_site_title() -> String:
	return site_title if site_title != "" else "Knowledge Base"

func get_author() -> String:
	return author if author != "" else "Unknown"

func get_date() -> String:
	return date if date != "" else "No date"

# =====================================================
#  ИЗОБРАЖЕНИЯ
# =====================================================

func has_image() -> bool:
	return image != null

func get_image() -> Texture2D:
	return image

func set_image(tex: Texture2D, img_path: String = "") -> void:
	image = tex
	image_path = img_path

func get_image_path() -> String:
	return image_path

func is_image_suspicious() -> bool:
	return image_path == "suspicious"

func is_image_dangerous() -> bool:
	return image_path == "dangerous"

func is_image_normal() -> bool:
	return image_path == "normal"

# =====================================================
#  НОВОСТИ
# =====================================================

func get_news_count() -> int:
	return news_items.size()

func get_news_item(index: int) -> Dictionary:
	if index >= 0 and index < news_items.size():
		return news_items[index]
	return {}

func has_news_images() -> bool:
	for news in news_items:
		if news.has("image") and news["image"] != null:
			return true
	return false

# =====================================================
#  ФОРУМ
# =====================================================

func get_threads_count() -> int:
	return threads.size()

func get_thread(index: int) -> Dictionary:
	if index >= 0 and index < threads.size():
		return threads[index]
	return {}

# =====================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# =====================================================

func get_content_type_name() -> String:
	match content_type:
		ContentType.FORUM: return "Forum"
		ContentType.NEWS: return "News"
		ContentType.ARTICLE: return "Article"
		ContentType.SIMPLE: return "Simple"
		_: return "Unknown"

func has_any_image() -> bool:
	if has_image():
		return true
	for news in news_items:
		if news.has("image") and news["image"] != null:
			return true
	return false

func clear_images() -> void:
	image = null
	image_path = ""
	for news in news_items:
		if news.has("image"):
			news.erase("image")
