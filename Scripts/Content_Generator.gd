extends Node
class_name ContentGenerator

enum SiteCategory {
	NORMAL,
	SUSPICIOUS,
	DANGEROUS
}

const ARTICLES_NORMAL_PATH: String = "res://Text_Files_Web/normal/"
const ARTICLES_SUSPICIOUS_PATH: String = "res://Text_Files_Web/anomal/"
const ARTICLES_DANGEROUS_PATH: String = "res://Text_Files_Web/danger/"
const ATLAS_PATH: String = "res://Web_images/atlas/"

var _normal_articles: Array[String] = []
var _suspicious_articles: Array[String] = []
var _dangerous_articles: Array[String] = []
var _atlases: Dictionary = {}
var _loaded: bool = false

func _load_all() -> void:
	if _loaded:
		return
	
	_normal_articles = _load_files_from_directory(ARTICLES_NORMAL_PATH, ["json"])
	_suspicious_articles = _load_files_from_directory(ARTICLES_SUSPICIOUS_PATH, ["json"])
	_dangerous_articles = _load_files_from_directory(ARTICLES_DANGEROUS_PATH, ["json"])
	_load_atlases()
	
	_loaded = true
	
	print("[ContentGenerator] Loaded:")
	print("  Normal: ", _normal_articles.size(), " articles")
	print("  Suspicious: ", _suspicious_articles.size(), " articles")
	print("  Dangerous: ", _dangerous_articles.size(), " articles")
	print("  Atlases: ", _atlases.keys())

func _load_files_from_directory(path: String, extensions: Array[String]) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	if not dir:
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

func _load_atlases() -> void:
	_atlases.clear()
	var files = _load_files_from_directory(ATLAS_PATH, ["png"])
	for file_path in files:
		var file_name = file_path.get_file().get_basename()
		var tags = _extract_tags(file_name)
		var texture = load(file_path) as Texture2D
		if texture:
			for tag in tags:
				_atlases[tag] = texture

func _extract_tags(file_name: String) -> Array[String]:
	var parts = file_name.split("_")
	var tags: Array[String] = []
	for part in parts:
		if part != "atlas" and not part.is_valid_int():
			tags.append(part)
	return tags

func _parse_article_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return _get_fallback_article()
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		return _get_fallback_article()
	return json.get_data()

func _get_fallback_article() -> Dictionary:
	return {
		"title": "Missing Article",
		"author": "System",
		"date": "0000-00-00",
		"body": "The requested article could not be loaded.",
		"tags": [],
		"blacklisted": false
	}

func get_image_for_tags(tags: Array) -> Texture2D:
	_load_all()
	for tag in tags:
		var tag_str = str(tag)
		if _atlases.has(tag_str):
			var atlas = _atlases[tag_str]
			var region = _get_random_region(atlas.get_size())
			var tex = AtlasTexture.new()
			tex.atlas = atlas
			tex.region = region
			return tex
	if not _atlases.is_empty():
		var atlas = _atlases.values()[0]
		var region = _get_random_region(atlas.get_size())
		var tex = AtlasTexture.new()
		tex.atlas = atlas
		tex.region = region
		return tex
	return null

func _get_random_region(atlas_size: Vector2i) -> Rect2:
	var tile_size = 64
	var cols = atlas_size.x / tile_size
	var rows = atlas_size.y / tile_size
	var col = randi() % cols
	var row = randi() % rows
	return Rect2(col * tile_size, row * tile_size, tile_size, tile_size)

func generate_site(category: SiteCategory) -> PageContent:
	_load_all()
	
	var articles: Array[String]
	match category:
		SiteCategory.DANGEROUS:  articles = _dangerous_articles
		SiteCategory.SUSPICIOUS: articles = _suspicious_articles
		_:                      articles = _normal_articles
	
	if articles.is_empty():
		return _create_page_content(_get_fallback_article(), SiteCategory.NORMAL)
	
	var data = _parse_article_json(articles[randi() % articles.size()])
	return _create_page_content(data, category)

func _create_page_content(data: Dictionary, base_category: SiteCategory = SiteCategory.NORMAL) -> PageContent:
	var content = PageContent.new()
	content.content_type = PageContent.ContentType.ARTICLE
	content.site_title = "Knowledge Base"
	content.title = data.get("title", "Untitled")
	content.author = data.get("author", "Unknown")
	content.body = data.get("body", "")
	content.date = data.get("date", "0000-00-00")
	
	var tags: Array[String] = []
	for tag in data.get("tags", []):
		tags.append(str(tag))
	content.tags = tags
	
	content.blacklisted = data.get("blacklisted", false)
	
	# Двойная статья из JSON
	if data.get("has_second_version", false):
		content.add_symptom(PageContent.Symptom.TEXT_UNSTABLE)
		content.set_meta("body_refresh", data.get("body_refresh", ""))
	
	# Симптомы из JSON (если указаны явно)
	for symptom_str in data.get("symptoms", []):
		match symptom_str:
			"ZALGO": content.add_symptom(PageContent.Symptom.ZALGO)
			"SANITY_DRAIN": content.add_symptom(PageContent.Symptom.SANITY_DRAIN)
			"TEXT_UNSTABLE": content.add_symptom(PageContent.Symptom.TEXT_UNSTABLE)
			"IMAGE_GLITCH": content.add_symptom(PageContent.Symptom.IMAGE_GLITCH)
			"CPU_SPIKE": content.add_symptom(PageContent.Symptom.CPU_SPIKE)
			"LOG_CORRUPTED": content.add_symptom(PageContent.Symptom.LOG_CORRUPTED)
	
	# Если симптомов нет — назначаем случайные
	if content.symptoms.is_empty():
		_assign_random_symptoms(content, base_category)
	
	# Категория по НАИВЫСШЕМУ симптому
	var highest_category = SiteCategory.NORMAL
	
	for symptom in content.symptoms:
		match symptom:
			PageContent.Symptom.ZALGO:
				highest_category = SiteCategory.DANGEROUS
			PageContent.Symptom.SANITY_DRAIN:
				highest_category = SiteCategory.DANGEROUS
			PageContent.Symptom.IMAGE_GLITCH:
				if highest_category < SiteCategory.SUSPICIOUS:
					highest_category = SiteCategory.SUSPICIOUS
			PageContent.Symptom.TEXT_UNSTABLE:
				if highest_category < SiteCategory.SUSPICIOUS:
					highest_category = SiteCategory.SUSPICIOUS
			PageContent.Symptom.CPU_SPIKE:
				if highest_category < SiteCategory.SUSPICIOUS:
					highest_category = SiteCategory.SUSPICIOUS
			PageContent.Symptom.LOG_CORRUPTED:
				highest_category = SiteCategory.DANGEROUS
	
	content.category = highest_category
	
	var img = get_image_for_tags(tags)
	if img:
		content.image = img
		content.image_path = tags[0] if tags.size() > 0 else "default"
	
	return content

func _assign_random_symptoms(content: PageContent, base_category: SiteCategory) -> void:
	var current_day = DailyManager.current_day if DailyManager else 1
	
	var available_symptoms = [
		PageContent.Symptom.ZALGO,
		PageContent.Symptom.SANITY_DRAIN,
		PageContent.Symptom.IMAGE_GLITCH
	]
	
	if current_day >= 2:
		available_symptoms.append(PageContent.Symptom.TEXT_UNSTABLE)
	
	if current_day >= 3:
		available_symptoms.append(PageContent.Symptom.CPU_SPIKE)
		available_symptoms.append(PageContent.Symptom.LOG_CORRUPTED)
	
	var count: int
	match base_category:
		SiteCategory.NORMAL: count = 0
		SiteCategory.SUSPICIOUS: count = randi_range(1, min(2, available_symptoms.size()))
		SiteCategory.DANGEROUS: count = randi_range(2, min(4, available_symptoms.size()))
	
	print("[ContentGenerator] Assigning symptoms: base=", SiteCategory.keys()[base_category], 
		  " day=", current_day, " count=", count, " available=", available_symptoms.size())
	
	if count == 0:
		print("[ContentGenerator]   -> No symptoms (NORMAL)")
		return
	
	available_symptoms.shuffle()
	for i in range(count):
		var symptom = available_symptoms[i]
		content.add_symptom(symptom)
		print("[ContentGenerator]   -> Added symptom: ", PageContent.Symptom.keys()[symptom])

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
