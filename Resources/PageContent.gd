extends Resource
class_name PageContent

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
@export var image_path: String = ""  # "normal", "suspicious", "dangerous"

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
#  МЕТОДЫ ДОСТУПА
# =====================================================

func get_title() -> String:
	return title if title != "" else "Без названия"

func get_body() -> String:
	return body if body != "" else "Нет содержимого"

func get_site_title() -> String:
	return site_title if site_title != "" else "Информационная панель"

func get_author() -> String:
	return author if author != "" else "Автор не указан"

func get_date() -> String:
	return date if date != "" else "Дата не указана"

# =====================================================
#  МЕТОДЫ ДЛЯ ИЗОБРАЖЕНИЙ
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
#  МЕТОДЫ ДЛЯ НОВОСТЕЙ
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
#  МЕТОДЫ ДЛЯ ФОРУМА
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
		ContentType.FORUM:
			return "Форум"
		ContentType.NEWS:
			return "Новости"
		ContentType.ARTICLE:
			return "Статья"
		ContentType.SIMPLE:
			return "Простая страница"
		_:
			return "Неизвестно"

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
