extends Node

# =====================================================
#  СИГНАЛЫ
# =====================================================

signal day_started(day: int)
signal sites_generated(sites: Array[PageContent])
signal site_completed(site: PageContent, chosen_category: ContentGenerator.SiteCategory, is_correct: bool, is_blacklisted_correct: bool, score: int)
signal day_completed(day: int, final_score: int, quota: int)
signal score_updated(current: int, quota: int)

# =====================================================
#  БЛЕК-ЛИСТЫ ПО ДНЯМ
# =====================================================

const BLACKLIST = {
	1: {
		"authors": ["Redto Phil", "Kyle Saren"],
		"domains": [".ab", ".??"],
	},
	2: {
		"authors": ["Sc44m", "Zorro Rumi"],
		"domains": [".end", ".brk"],
	},
	3: {
		"authors": ["Dr. Ganium", "Abime Historia", "Contained Jeremy", "Arsi", "Shiro", "Jay Gail"],
		"domains": [".!!", "..."],
	}
}

# =====================================================
#  ТАБЛИЦА ОЧКОВ
# =====================================================

const SCORE_TABLE = {
	"correct": {
		ContentGenerator.SiteCategory.NORMAL: 25,
		ContentGenerator.SiteCategory.SUSPICIOUS: 40,
		ContentGenerator.SiteCategory.DANGEROUS: 60
	},
	"wrong": {
		ContentGenerator.SiteCategory.NORMAL: -10,
		ContentGenerator.SiteCategory.SUSPICIOUS: -25,
		ContentGenerator.SiteCategory.DANGEROUS: -40
	}
}

# =====================================================
#  СОСТОЯНИЕ
# =====================================================

var current_day: int = 1
var current_score: int = 0
var daily_quota: int = 50
var sites_today: Array[PageContent] = []
var sites_completed: Array[PageContent] = []
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
	current_score = 0
	sites_today.clear()
	sites_completed.clear()
	
	daily_quota = 50 + (current_day - 1) * 30
	
	print("")
	print("[DailyManager] ╔══════════════════════════════════════════════╗")
	print("[DailyManager] ║              DAY ", current_day, " STARTED                 ║")
	print("[DailyManager] ╚══════════════════════════════════════════════╝")
	print("[DailyManager]")
	print("[DailyManager] 📊 DAILY QUOTA: ", daily_quota, " points")
	print("[DailyManager]    NORMAL: +25 / -10")
	print("[DailyManager]    SUSPICIOUS: +40 / -25")
	print("[DailyManager]    DANGEROUS: +60 / -40")
	print("[DailyManager]    BLACKLIST missed: -50% pts")
	
	var bl = get_blacklist_for_day(current_day)
	print("[DailyManager]")
	print("[DailyManager] 📋 BLACKLIST:")
	print("[DailyManager]    Authors: ", ", ".join(bl.get("authors", [])))
	print("[DailyManager]    Domains: ", ", ".join(bl.get("domains", [])))
	print("[DailyManager]    Dates: 2012+")
	print("[DailyManager]")
	
	var site_count = randi_range(3, 4)
	print("[DailyManager] 🔄 Generating ", site_count, " sites...")
	for i in range(site_count):
		var category = _random_category()
		print("[DailyManager] Generating site for day: ", current_day)
		var site = generator.generate_site(category, current_day)
		print("[DailyManager] Site symptoms: ", site.symptoms)
		# С шансом 40% добавляем блек-лист элемент
		if randf() < 0.4:
			_apply_random_blacklist(site)
		sites_today.append(site)
		print("[DailyManager]    ", i + 1, ". ", site.title, " (", ContentGenerator.SiteCategory.keys()[category], ")")
	
	sites_today.shuffle()
	
	day_started.emit(current_day)
	sites_generated.emit(sites_today)
	score_updated.emit(current_score, daily_quota)

func _random_category() -> ContentGenerator.SiteCategory:
	var r = randf()
	if r < 0.5: return ContentGenerator.SiteCategory.NORMAL
	if r < 0.8: return ContentGenerator.SiteCategory.SUSPICIOUS
	return ContentGenerator.SiteCategory.DANGEROUS

func _apply_random_blacklist(site: PageContent) -> void:
	var bl = BLACKLIST.get(current_day, {})
	var choices = []
	
	if not bl.get("authors", []).is_empty():
		choices.append("author")
	if not bl.get("domains", []).is_empty():
		choices.append("domain")
	choices.append("date")
	
	if choices.is_empty():
		return
	
	match choices[randi() % choices.size()]:
		"author":
			site.author = bl["authors"][randi() % bl["authors"].size()]
		"domain":
			var domain = bl["domains"][randi() % bl["domains"].size()]
			site.body += "\n\nDomain: " + domain
		"date":
			site.date = str(randi_range(2012, 2020)) + "-" + str(randi_range(1, 12)).pad_zeros(2) + "-" + str(randi_range(1, 28)).pad_zeros(2)

# =====================================================
#  БЛЕК-ЛИСТ ПРОВЕРКИ
# =====================================================

func _is_date_blacklisted(date: String) -> bool:
	if date.is_empty():
		return false
	var parts = date.split("-")
	if parts.is_empty():
		return false
	var year = parts[0].to_int()
	return year > 2011

func is_site_blacklisted(site: PageContent, day: int) -> bool:
	var bl = BLACKLIST.get(day, {})
	
	for author in bl.get("authors", []):
		if site.author.to_lower().contains(author.to_lower()):
			return true
	
	for domain in bl.get("domains", []):
		if site.body.to_lower().contains(domain.to_lower()):
			return true
	
	if _is_date_blacklisted(site.date):
		return true
	
	return false

func get_blacklist_for_day(day: int) -> Dictionary:
	return BLACKLIST.get(day, {})

# =====================================================
#  ПОЛУЧЕНИЕ САЙТОВ
# =====================================================

func get_next_site() -> PageContent:
	if sites_today.is_empty():
		return null
	return sites_today.pop_front()

func get_remaining_sites() -> Array[PageContent]:
	return sites_today.duplicate()

func has_sites_remaining() -> bool:
	return not sites_today.is_empty()

# =====================================================
#  ЗАВЕРШЕНИЕ САЙТА
# =====================================================

func complete_site(site: PageContent, chosen_category: ContentGenerator.SiteCategory, player_marked_blacklisted: bool) -> void:
	var is_correct = (chosen_category == site.category)
	var is_actually_blacklisted = is_site_blacklisted(site, current_day)
	var is_blacklisted_correct = (player_marked_blacklisted == is_actually_blacklisted)
	
	var score = SCORE_TABLE["correct"][site.category] if is_correct else SCORE_TABLE["wrong"][site.category]
	
	if not is_blacklisted_correct:
		score = score / 2
	
	current_score = max(0, current_score + score)
	sites_completed.append(site)
	
	site_completed.emit(site, chosen_category, is_correct, is_blacklisted_correct, score)
	score_updated.emit(current_score, daily_quota)
	
	print("[DailyManager] ", "✓" if is_correct else "✗", " ", site.title,
		  " | Chosen: ", ContentGenerator.SiteCategory.keys()[chosen_category],
		  " | Actual: ", ContentGenerator.SiteCategory.keys()[site.category],
		  " | BL: ", player_marked_blacklisted, "/", is_actually_blacklisted,
		  " | ", score, " pts | Total: ", current_score, "/", daily_quota)
	
	if current_score >= daily_quota:
		print("")
		print("[DailyManager] ╔══════════════════════════════════════════════╗")
		print("[DailyManager] ║              DAY ", current_day, " COMPLETED!              ║")
		print("[DailyManager] ╚══════════════════════════════════════════════╝")
		print("[DailyManager] 🏆 Final score: ", current_score, " / ", daily_quota)
		print("[DailyManager]")
		day_completed.emit(current_day, current_score, daily_quota)
		current_day += 1

# =====================================================
#  ПРОГРЕСС
# =====================================================

func get_progress() -> Dictionary:
	return {
		"day": current_day,
		"score": current_score,
		"quota": daily_quota,
		"completed": sites_completed.size(),
		"remaining": sites_today.size()
	}

func get_completion_percent() -> float:
	return float(current_score) / float(daily_quota) * 100.0

# =====================================================
#  ДЕБАГ
# =====================================================

func debug_print_status() -> void:
	print("[DailyManager] === DAY ", current_day, " STATUS ===")
	print("[DailyManager] Score: ", current_score, "/", daily_quota)
	print("[DailyManager] Completed: ", sites_completed.size(), " | Remaining: ", sites_today.size())
	print("[DailyManager] =================================")
