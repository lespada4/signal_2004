extends Node

# =====================================================
#  СИГНАЛЫ
# =====================================================

signal day_started(day: int)
signal sites_generated(sites: Array[PageContent])
signal site_completed(site: PageContent, category: ContentGenerator.SiteCategory)
signal day_completed(day: int, normal_completed: int, rare_completed: int)

# =====================================================
#  СОСТОЯНИЕ
# =====================================================

var current_day: int = 1
var sites_today: Array[PageContent] = []
var sites_completed: Array[PageContent] = []

var normal_sites_required: int = 2
var rare_sites_required: int = 1

var normal_completed: int = 0
var rare_completed: int = 0

var generator: ContentGenerator

# =====================================================
#  ИНИЦИАЛИЗАЦИЯ
# =====================================================

func _ready() -> void:
	generator = ContentGenerator.new()
	print("[DailyManager] Ready")

# =====================================================
#  ГЕНЕРАЦИЯ ДНЯ
# =====================================================

func start_new_day() -> void:
	print("")
	print("[DailyManager] ╔══════════════════════════════════════════════╗")
	print("[DailyManager] ║              DAY ", current_day, " STARTED                   ║")
	print("[DailyManager] ╚══════════════════════════════════════════════╝")
	print("[DailyManager]")
	print("[DailyManager] 📋 TODAY'S TASKS:")
	print("[DailyManager]    • Normal sites required:  ", normal_sites_required)
	print("[DailyManager]    • Rare sites required:    ", rare_sites_required)
	print("[DailyManager]")
	
	sites_today.clear()
	sites_completed.clear()
	normal_completed = 0
	rare_completed = 0
	
	# 2 обычных сайта
	print("[DailyManager] 🔄 Generating normal sites...")
	for i in range(normal_sites_required):
		var site = generator.generate_site(ContentGenerator.SiteCategory.NORMAL)
		sites_today.append(site)
		print("[DailyManager]    ", i + 1, ". ", site.title, " (", site.author, ")")
	
	# 1 редкий сайт (подозрительный или опасный)
	print("[DailyManager] 🔄 Generating rare site...")
	var rare_category = ContentGenerator.SiteCategory.DANGEROUS if randf() < 0.3 else ContentGenerator.SiteCategory.SUSPICIOUS
	var rare_site = generator.generate_site(rare_category)
	sites_today.append(rare_site)
	
	var category_name = "DANGEROUS" if rare_category == ContentGenerator.SiteCategory.DANGEROUS else "SUSPICIOUS"
	print("[DailyManager]    → ", rare_site.title, " (", category_name, ")")
	
	# Перемешиваем порядок
	sites_today.shuffle()
	
	print("[DailyManager]")
	print("[DailyManager] 📦 Total sites in queue: ", sites_today.size())
	print("[DailyManager]")
	print("[DailyManager] 🎯 OBJECTIVE: Find and report ALL sites!")
	print("[DailyManager]    • Normal sites: 0/", normal_sites_required)
	print("[DailyManager]    • Rare sites:   0/", rare_sites_required)
	print("[DailyManager]")
	
	day_started.emit(current_day)
	sites_generated.emit(sites_today)

# =====================================================
#  ПОЛУЧЕНИЕ САЙТОВ
# =====================================================

func get_next_site() -> PageContent:
	if sites_today.is_empty():
		print("[DailyManager] ⚠️ No more sites for today!")
		return null
	
	var site = sites_today.pop_front()
	var category_name = ContentGenerator.SiteCategory.keys()[site.category]
	print("[DailyManager] 📤 Next site: ", site.title, " (", category_name, ")")
	print("[DailyManager]    Remaining in queue: ", sites_today.size())
	return site

func get_remaining_sites() -> Array[PageContent]:
	return sites_today.duplicate()

func has_sites_remaining() -> bool:
	return not sites_today.is_empty()

# =====================================================
#  ЗАВЕРШЕНИЕ САЙТА
# =====================================================

func complete_site(site: PageContent, chosen_category: ContentGenerator.SiteCategory) -> void:
	var is_correct = (chosen_category == site.category)
	
	if is_correct:
		match site.category:
			ContentGenerator.SiteCategory.NORMAL:
				normal_completed += 1
			_:
				rare_completed += 1
	
	sites_completed.append(site)
	site_completed.emit(site, chosen_category)
	
	_check_day_completion()

func _check_day_completion() -> void:
	if normal_completed >= normal_sites_required and rare_completed >= rare_sites_required:
		print("")
		print("[DailyManager] ╔══════════════════════════════════════════════╗")
		print("[DailyManager] ║              DAY ", current_day, " COMPLETED!              ║")
		print("[DailyManager] ╚══════════════════════════════════════════════╝")
		print("[DailyManager]")
		print("[DailyManager] 🏆 FINAL RESULTS:")
		print("[DailyManager]    • Normal sites found: ", normal_completed, "/", normal_sites_required)
		print("[DailyManager]    • Rare sites found:   ", rare_completed, "/", rare_sites_required)
		print("[DailyManager]    • Total reported:     ", sites_completed.size())
		print("[DailyManager]")
		print("[DailyManager] 🎉 Day ", current_day, " successfully completed!")
		print("[DailyManager]")
		
		day_completed.emit(current_day, normal_completed, rare_completed)
		current_day += 1
	else:
		var remaining_normal = normal_sites_required - normal_completed
		var remaining_rare = rare_sites_required - rare_completed
		
		if remaining_normal > 0:
			print("[DailyManager] 🔍 Still need to find ", remaining_normal, " normal site(s)")
		if remaining_rare > 0:
			print("[DailyManager] 🔍 Still need to find ", remaining_rare, " rare site(s)")

# =====================================================
#  ПРОГРЕСС
# =====================================================

func get_progress() -> Dictionary:
	return {
		"day": current_day,
		"normal_completed": normal_completed,
		"normal_required": normal_sites_required,
		"rare_completed": rare_completed,
		"rare_required": rare_sites_required,
		"sites_remaining": sites_today.size()
	}

func get_completion_percent() -> float:
	var total_required = normal_sites_required + rare_sites_required
	var total_completed = normal_completed + rare_completed
	return float(total_completed) / float(total_required) * 100.0

# =====================================================
#  ДЕБАГ
# =====================================================

func debug_print_status() -> void:
	print("[DailyManager] === DAY ", current_day, " STATUS ===")
	print("[DailyManager] Normal: ", normal_completed, "/", normal_sites_required)
	print("[DailyManager] Rare: ", rare_completed, "/", rare_sites_required)
	print("[DailyManager] Sites remaining in queue: ", sites_today.size())
	print("[DailyManager] Total completed: ", sites_completed.size())
	print("[DailyManager] =================================")
