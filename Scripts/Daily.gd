extends Node

signal day_started(day: int)
signal sites_generated(sites: Array[PageContent])
signal site_completed(site: PageContent, chosen_category: ContentGenerator.SiteCategory, is_correct: bool, is_blacklisted_correct: bool, score: int)
signal day_completed(day: int, final_score: int, quota: int)
signal score_updated(current: int, quota: int)

const ALL_BLACKLIST_AUTHORS = [
	"Redto Phil", "Kyle Saren", "Sc44m", "Zorro Rumi",
	"Dr. Ganium", "Abime Historia", "Contained Jeremy",
	"Arsi", "Shiro", "Jay Gail"
]

const ALL_BLACKLIST_DOMAINS = [
	".ab", ".??", ".end", ".brk", ".!!", "..."
]

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

var current_day: int = 1
var current_score: int = 0
var daily_quota: int = 100
var sites_today: Array[PageContent] = []
var sites_completed: Array[PageContent] = []
var generator: ContentGenerator
var is_day_completed: bool = false

var blacklist_authors: Array = []
var blacklist_domains: Array = []

func _ready() -> void:
	generator = ContentGenerator.new()
	print("[DailyManager] Ready")

func _is_date_blacklisted(date: String) -> bool:
	if date.is_empty(): return false
	var parts = date.split("-")
	if parts.is_empty(): return false
	return parts[0].to_int() > 2011

func _generate_daily_blacklist() -> void:
	blacklist_authors.clear()
	blacklist_domains.clear()
	
	# Блек-лист только со Дня 2
	if current_day < 2:
		return
	
	var shuffled_authors = ALL_BLACKLIST_AUTHORS.duplicate()
	var shuffled_domains = ALL_BLACKLIST_DOMAINS.duplicate()
	shuffled_authors.shuffle()
	shuffled_domains.shuffle()
	
	blacklist_authors = shuffled_authors.slice(0, 2)
	blacklist_domains = shuffled_domains.slice(0, 2)

func is_site_blacklisted(site: PageContent) -> bool:
	if current_day < 2: return false
	for author in blacklist_authors:
		if site.author.to_lower().contains(author.to_lower()): return true
	for domain in blacklist_domains:
		if site.body.to_lower().contains(domain.to_lower()): return true
	if _is_date_blacklisted(site.date): return true
	return false

func get_blacklist_text() -> String:
	var text = "BLACKLIST:\n"
	if not blacklist_authors.is_empty():
		text += "Authors: " + ", ".join(blacklist_authors) + "\n"
	if not blacklist_domains.is_empty():
		text += "Domains: " + ", ".join(blacklist_domains) + "\n"
	text += "Dates: 2012+"
	return text

func start_new_day() -> void:
	is_day_completed = false
	current_score = 0
	sites_today.clear()
	sites_completed.clear()
	daily_quota = 100 + (current_day - 1) * 50
	_generate_daily_blacklist()
	
	print("")
	print("[DailyManager] ╔══════════════════════════════════════════════╗")
	print("[DailyManager] ║              DAY ", current_day, " STARTED                 ║")
	print("[DailyManager] ╚══════════════════════════════════════════════╝")
	print("[DailyManager] 📊 DAILY QUOTA: ", daily_quota, " points")
	print("[DailyManager]    NORMAL: +25 / -10")
	print("[DailyManager]    SUSPICIOUS: +40 / -25")
	print("[DailyManager]    DANGEROUS: +60 / -40")
	print("[DailyManager]    BLACKLIST missed: -50% pts")
	
	if not blacklist_authors.is_empty():
		print("[DailyManager] 📋 BLACKLIST:")
		print("[DailyManager]    Authors: ", ", ".join(blacklist_authors))
		print("[DailyManager]    Domains: ", ", ".join(blacklist_domains))
		print("[DailyManager]    Dates: 2012+")
	
	print("[DailyManager]")
	
	var site_count = randi_range(3, 4)
	var cats = [ContentGenerator.SiteCategory.NORMAL, ContentGenerator.SiteCategory.SUSPICIOUS, ContentGenerator.SiteCategory.DANGEROUS]
	
	print("[DailyManager] 🔄 Generating ", site_count, " sites...")
	for i in range(site_count):
		var site = generator.generate_site(cats[randi() % cats.size()])
		if randf() < 0.3 and not blacklist_authors.is_empty():
			_apply_random_blacklist(site)
		sites_today.append(site)
		print("[DailyManager]    ", i + 1, ". ", site.title, " (", ContentGenerator.SiteCategory.keys()[site.category], ")")
	
	sites_today.shuffle()
	day_started.emit(current_day)
	sites_generated.emit(sites_today)
	score_updated.emit(current_score, daily_quota)

func _apply_random_blacklist(site: PageContent) -> void:
	if current_day < 2:
		return
	
	var choices = []
	if not blacklist_authors.is_empty(): choices.append("author")
	if not blacklist_domains.is_empty(): choices.append("domain")
	choices.append("date")
	if choices.is_empty(): return
	
	match choices[randi() % choices.size()]:
		"author": site.author = blacklist_authors[randi() % blacklist_authors.size()]
		"domain": site.body += "\n\nDomain: " + blacklist_domains[randi() % blacklist_domains.size()]
		"date": site.date = str(randi_range(2012, 2020)) + "-" + str(randi_range(1, 12)).pad_zeros(2) + "-" + str(randi_range(1, 28)).pad_zeros(2)

func get_next_site() -> PageContent:
	if sites_today.is_empty(): return null
	return sites_today.pop_front()

func get_remaining_sites() -> Array[PageContent]:
	return sites_today.duplicate()

func has_sites_remaining() -> bool:
	return not sites_today.is_empty()

func complete_site(site: PageContent, chosen_category: ContentGenerator.SiteCategory, player_marked_blacklisted: bool) -> void:
	var is_correct = (chosen_category == site.category)
	var is_actually_blacklisted = is_site_blacklisted(site)
	var is_blacklisted_correct = (player_marked_blacklisted == is_actually_blacklisted)
	var score = SCORE_TABLE["correct"][site.category] if is_correct else SCORE_TABLE["wrong"][site.category]
	if not is_blacklisted_correct: score = score / 2
	
	current_score = max(0, current_score + score)
	sites_completed.append(site)
	site_completed.emit(site, chosen_category, is_correct, is_blacklisted_correct, score)
	score_updated.emit(current_score, daily_quota)
	
	print("[DailyManager] ", "✓" if is_correct else "✗", " ", site.title,
		  " | Chosen: ", ContentGenerator.SiteCategory.keys()[chosen_category],
		  " | Actual: ", ContentGenerator.SiteCategory.keys()[site.category],
		  " | BL: ", player_marked_blacklisted, "/", is_actually_blacklisted,
		  " | ", score, " pts | Total: ", current_score, "/", daily_quota)
	
	if current_score >= daily_quota and not is_day_completed:
		is_day_completed = true
		print("[DailyManager] ╔══════════════════════════════════════════════╗")
		print("[DailyManager] ║              DAY ", current_day, " COMPLETED!              ║")
		print("[DailyManager] ╚══════════════════════════════════════════════╝")
		print("[DailyManager] 🏆 Final score: ", current_score, " / ", daily_quota)
		day_completed.emit(current_day, current_score, daily_quota)

func get_progress() -> Dictionary:
	return {"day": current_day, "score": current_score, "quota": daily_quota, "completed": sites_completed.size(), "remaining": sites_today.size()}

func get_completion_percent() -> float:
	return float(current_score) / float(daily_quota) * 100.0

func debug_print_status() -> void:
	print("[DailyManager] === DAY ", current_day, " STATUS ===")
	print("[DailyManager] Score: ", current_score, "/", daily_quota)
	print("[DailyManager] Completed: ", sites_completed.size(), " | Remaining: ", sites_today.size())
