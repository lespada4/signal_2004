extends Resource
class_name PageContent

# =====================================================
#  СИМПТОМЫ
# =====================================================

enum Symptom {
	NONE,
	ZALGO,
	SANITY_DRAIN,
	TEXT_UNSTABLE,
	IMAGE_GLITCH,
	CPU_SPIKE,
	LOG_CORRUPTED
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
@export var image_path: String = ""  # "tech", "anomaly", "webcore" etc.

# =====================================================
#  ТЕГИ (для подбора картинок из атласов)
# =====================================================
@export var tags: Array[String] = []

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
@export var category: int = 0  # SiteCategory.NORMAL

# =====================================================
#  БЛЕК-ЛИСТ
# =====================================================
@export var blacklisted: bool = false

# =====================================================
#  СИМПТОМЫ
# =====================================================
@export var symptoms: Array[int] = []

func has_symptom(symptom: Symptom) -> bool:
	return symptoms.has(symptom)

func add_symptom(symptom: Symptom) -> void:
	if not symptoms.has(symptom):
		symptoms.append(symptom)

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

func get_image_path() -> String:
	return image_path

# =====================================================
#  НОВОСТИ
# =====================================================

func get_news_count() -> int:
	return news_items.size()

func get_news_item(index: int) -> Dictionary:
	if index >= 0 and index < news_items.size():
		return news_items[index]
	return {}

# =====================================================
#  ФОРУМ
# =====================================================

func get_threads_count() -> int:
	return threads.size()

func get_thread(index: int) -> Dictionary:
	if index >= 0 and index < threads.size():
		return threads[index]
	return {}
