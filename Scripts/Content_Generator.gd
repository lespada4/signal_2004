extends Node
class_name ContentGenerator

# =====================================================
#  КАТЕГОРИИ САЙТОВ
# =====================================================

enum SiteCategory {
	NORMAL,
	SUSPICIOUS,
	DANGEROUS
}

# =====================================================
#  ПУТИ
# =====================================================

const IMAGES_NORMAL_PATH: String = "res://Web images/normal/"
const IMAGES_SUSPICIOUS_PATH: String = "res://Web images/sus/"
const IMAGES_DANGEROUS_PATH: String = "res://Web images/dang/"

const ARTICLES_NORMAL_PATH: String = "res://Text_Files_Web/normal/"
const ARTICLES_SUSPICIOUS_PATH: String = "res://Text_Files_Web/anomal/"
const ARTICLES_DANGEROUS_PATH: String = "res://Text_Files_Web/danger/"

# =====================================================
#  КЭШ
# =====================================================

var _normal_images: Array[String] = []
var _suspicious_images: Array[String] = []
var _dangerous_images: Array[String] = []

var _normal_articles: Array[String] = []
var _suspicious_articles: Array[String] = []
var _dangerous_articles: Array[String] = []

var _loaded: bool = false

# =====================================================
#  ЗАГРУЗКА ВСЕХ РЕСУРСОВ
# =====================================================

func _load_all() -> void:
	if _loaded:
		return
	
	_normal_images = _load_files_from_directory(IMAGES_NORMAL_PATH, ["png", "jpg", "jpeg", "webp"])
	_suspicious_images = _load_files_from_directory(IMAGES_SUSPICIOUS_PATH, ["png", "jpg", "jpeg", "webp"])
	_dangerous_images = _load_files_from_directory(IMAGES_DANGEROUS_PATH, ["png", "jpg", "jpeg", "webp"])
	
	_normal_articles = _load_files_from_directory(ARTICLES_NORMAL_PATH, ["txt"])
	_suspicious_articles = _load_files_from_directory(ARTICLES_SUSPICIOUS_PATH, ["txt"])
	_dangerous_articles = _load_files_from_directory(ARTICLES_DANGEROUS_PATH, ["txt"])
	
	_loaded = true
	
	print("[ContentGenerator] Loaded:")
	print("  Normal: ", _normal_images.size(), " images, ", _normal_articles.size(), " articles")
	print("  Suspicious: ", _suspicious_images.size(), " images, ", _suspicious_articles.size(), " articles")
	print("  Dangerous: ", _dangerous_images.size(), " images, ", _dangerous_articles.size(), " articles")

func _load_files_from_directory(path: String, extensions: Array[String]) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	
	if not dir:
		print("[ContentGenerator] WARNING: Cannot open: ", path)
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			for ext in extensions:
				if file_name.ends_with("." + ext):
					files.append(path + file_name)
					break
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

# =====================================================
#  ПАРСИНГ СТАТЬИ ИЗ TXT
# =====================================================

func _parse_article_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("[ContentGenerator] ERROR: Cannot read: ", file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var result: Dictionary = {
		"title": "Untitled",
		"author": "Unknown",
		"body": ""
	}
	
	var lines = content.split("\n")
	var body_started = false
	var body_lines: Array[String] = []
	
	for line in lines:
		if line.begins_with("Title:"):
			result["title"] = line.substr(6).strip_edges()
		elif line.begins_with("Author:"):
			result["author"] = line.substr(7).strip_edges()
		elif line.begins_with("Body:"):
			body_started = true
		elif body_started:
			body_lines.append(line)
	
	result["body"] = "\n".join(body_lines).strip_edges()
	
	return result

# =====================================================
#  ПОЛУЧЕНИЕ СЛУЧАЙНЫХ РЕСУРСОВ
# =====================================================

func get_random_image(category: SiteCategory) -> Texture2D:
	_load_all()
	
	var images: Array[String]
	match category:
		SiteCategory.DANGEROUS:  images = _dangerous_images
		SiteCategory.SUSPICIOUS: images = _suspicious_images
		_:                      images = _normal_images
	
	if images.is_empty():
		return null
	
	return load(images[randi() % images.size()]) as Texture2D

func get_random_article(category: SiteCategory) -> Dictionary:
	_load_all()
	
	var articles: Array[String]
	match category:
		SiteCategory.DANGEROUS:  articles = _dangerous_articles
		SiteCategory.SUSPICIOUS: articles = _suspicious_articles
		_:                      articles = _normal_articles
	
	if articles.is_empty():
		print("[ContentGenerator] WARNING: No articles for category ", SiteCategory.keys()[category])
		return _get_fallback_article()
	
	return _parse_article_file(articles[randi() % articles.size()])

func _get_fallback_article() -> Dictionary:
	return {
		"title": "Missing Article",
		"author": "System",
		"body": "The requested article could not be loaded. Database corruption suspected."
	}

# =====================================================
#  ГЕНЕРАЦИЯ САЙТА
# =====================================================

func generate_site(category: SiteCategory) -> PageContent:
	_load_all()
	
	var article_data = get_random_article(category)
	
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.ARTICLE
	content.site_title = "Knowledge Base"
	content.category = category
	content.title = article_data["title"]
	content.author = article_data["author"]
	content.body = article_data["body"]
	content.date = _get_random_date()
	
	var img = get_random_image(category)
	if img:
		content.image = img
		content.image_path = SiteCategory.keys()[category].to_lower()
	
	return content

# =====================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# =====================================================

func _get_random_date() -> String:
	var year = randi() % 12 + 2000
	var month = randi() % 12 + 1
	var day = randi() % 28 + 1
	return "%d-%02d-%02d" % [year, month, day]

func generate() -> PageContent:
	return generate_site(SiteCategory.NORMAL)

func debug_print_site(content: PageContent) -> void:
	print("=================================")
	print("       SITE ANALYSIS")
	print("=================================")
	print("Title: ", content.title)
	print("Author: ", content.author)
	print("Category: ", SiteCategory.keys()[content.category])
	print("Image: ", content.image_path)
	print("=================================\n")
