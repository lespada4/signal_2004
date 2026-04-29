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
@onready var blacklisted_check: CheckButton = $VBoxContainer/BlacklistedCheck
@onready var refresh_button: Button = $VBoxContainer/RefreshButton
@onready var diag_button: Button = $VBoxContainer/DiagButton
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var log_panel: Panel = $LogPanel
@onready var log_label: Label = $LogPanel/MarginContainer/Label

var _category_chosen: bool = false
var _sanity_drain_active: bool = false
var _sanity_drain_rate: float = 0.0
var _times_refreshed: int = 0
var _log_shown: bool = false

func _ready() -> void:
	normal_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.NORMAL))
	anomaly_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.SUSPICIOUS))
	dangerous_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.DANGEROUS))
	refresh_button.pressed.connect(_on_refresh_pressed)
	diag_button.pressed.connect(_on_diag_pressed)
	
	# Доступность кнопок по дням
	var day = DailyManager.current_day if DailyManager else 1
	
	# REFRESH доступен с Дня 1
	refresh_button.visible = true
	
	# BLACKLIST доступен с Дня 2
	blacklisted_check.visible = day >= 2
	
	# DIAGNOSTIC доступен с Дня 3
	diag_button.visible = day >= 3
	
	if content:
		_apply_content(content)
	else:
		_apply_content(ContentGenerator.new().generate_site())
	
	super._ready()
	
	log_panel.visible = false
	if result_label:
		result_label.visible = false

func _apply_content(data: PageContent) -> void:
	content = data
	_category_chosen = false
	_times_refreshed = 0
	_log_shown = false
	
	title_label.text = data.get_title()
	author_label.text = "Author: " + data.get_author()
	date_label.text = data.get_date()
	body_label.text = data.get_body()
	
	normal_btn.disabled = false
	anomaly_btn.disabled = false
	dangerous_btn.disabled = false
	blacklisted_check.button_pressed = false
	blacklisted_check.disabled = false
	
	log_panel.visible = false
	
	if result_label:
		result_label.visible = false
	
	if data.has_image():
		image.texture = data.get_image()
		image.visible = true
		image.self_modulate = Color.WHITE
	else:
		image.visible = false
	
	_sanity_drain_active = false
	set_zalgo_enabled(false)
	
	print("[ArticlePage] ==================================")
	print("[ArticlePage] Site: ", data.title)
	print("[ArticlePage] Category: ", ContentGenerator.SiteCategory.keys()[data.category])
	print("[ArticlePage] Symptoms: ", data.symptoms.size())
	
	if data.has_symptom(PageContent.Symptom.ZALGO):
		set_zalgo_enabled(true)
		set_zalgo_concentration(50)
		print("[ArticlePage]   -> ZALGO active")
	
	if data.has_symptom(PageContent.Symptom.SANITY_DRAIN):
		_sanity_drain_active = true
		_sanity_drain_rate = 5.0
		print("[ArticlePage]   -> SANITY DRAIN active")
	
	if data.has_symptom(PageContent.Symptom.IMAGE_GLITCH):
		if data.has_image():
			image.self_modulate = Color(1.0, 0.8, 0.8)
			print("[ArticlePage]   -> IMAGE GLITCH active")
	
	if data.has_symptom(PageContent.Symptom.TEXT_UNSTABLE):
		print("[ArticlePage]   -> TEXT UNSTABLE")
	
	if data.has_symptom(PageContent.Symptom.CPU_LOG_SUSPICIOUS):
		print("[ArticlePage]   -> CPU LOG SUSPICIOUS")
	
	if data.has_symptom(PageContent.Symptom.CPU_LOG_DANGEROUS):
		print("[ArticlePage]   -> CPU LOG DANGEROUS")
	
	if data.has_symptom(PageContent.Symptom.NORMAL):
		print("[ArticlePage]   -> NORMAL site")
	
	print("[ArticlePage] Image: ", data.image_path)
	print("[ArticlePage] ==================================")

func _process(delta: float) -> void:
	if _sanity_drain_active:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("drain_sanity"):
			player.drain_sanity(_sanity_drain_rate * delta)

# =====================================================
#  REFRESH
# =====================================================

func _on_refresh_pressed() -> void:
	_times_refreshed += 1
	
	if content.has_symptom(PageContent.Symptom.TEXT_UNSTABLE):
		_scramble_text(0.5)
		if content.has_symptom(PageContent.Symptom.IMAGE_GLITCH):
			_apply_random_glitch()
	
	print("[ArticlePage] Refreshed x", _times_refreshed)

func _scramble_text(intensity: float) -> void:
	var text = body_label.text
	var bytes = text.to_utf8_buffer()
	for i in range(bytes.size()):
		if randf() < intensity:
			bytes[i] = randi_range(33, 126)
	body_label.text = bytes.get_string_from_utf8()

func _apply_random_glitch() -> void:
	if not image.visible:
		return
	image.modulate = Color(randf_range(0.5, 1), randf_range(0.5, 1), randf_range(0.5, 1))
# =====================================================
#  DIAGNOSTIC
# =====================================================

func _on_diag_pressed() -> void:
	_log_shown = !_log_shown
	
	if _log_shown:
		log_label.text = _generate_diagnostic()
		log_panel.visible = true
	else:
		log_panel.visible = false

func _generate_diagnostic() -> String:
	# Если сайт DANGEROUS — лог всегда DANGEROUS
	if content.category == ContentGenerator.SiteCategory.DANGEROUS:
		return _generate_log(ContentGenerator.SiteCategory.DANGEROUS)
	
	# Если есть лог-симптом — он определяет категорию лога
	if content.has_symptom(PageContent.Symptom.CPU_LOG_DANGEROUS):
		return _generate_log(ContentGenerator.SiteCategory.DANGEROUS)
	
	if content.has_symptom(PageContent.Symptom.CPU_LOG_SUSPICIOUS):
		return _generate_log(ContentGenerator.SiteCategory.SUSPICIOUS)
	
	# SUSPICIOUS сайт — лог SUSPICIOUS
	if content.category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return _generate_log(ContentGenerator.SiteCategory.SUSPICIOUS)
	
	# NORMAL сайт — чистый лог
	return _generate_log(ContentGenerator.SiteCategory.NORMAL)

func _generate_log(site_category: int) -> String:
	var cpu = _generate_cpu(site_category)
	var ram = _generate_ram(site_category)
	var temp = _generate_temp(site_category)
	var fan = _generate_fan(site_category)
	var net = _generate_net(site_category)
	
	return "CPU: %s | RAM: %s\nTEMP: %s | FAN: %s\nNET: %s" % [cpu, ram, temp, fan, net]

func _generate_cpu(category: int) -> String:
	if category == ContentGenerator.SiteCategory.NORMAL:
		return str(randi_range(5, 25)) + "%"
	elif category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return str(randi_range(65, 85)) + "%"
	else:
		if randf() < 0.7:
			return str(randi_range(90, 100)) + "%"
		else:
			return "███"

func _generate_ram(category: int) -> String:
	if category == ContentGenerator.SiteCategory.NORMAL:
		return str(randi_range(16, 64)) + "MB"
	elif category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return str(randi_range(128, 512)) + "MB"
	else:
		if randf() < 0.5:
			return str(randi_range(1024, 4096)) + "MB"
		elif randf() < 0.8:
			return "CORRUPTED"
		else:
			return str(randi_range(1024, 4096)) + "MB [MEMETIC]"

func _generate_temp(category: int) -> String:
	if category == ContentGenerator.SiteCategory.NORMAL:
		return str(randi_range(30, 60)) + "°C"
	elif category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return str(randi_range(70, 90)) + "°C"
	else:
		if randf() < 0.6:
			return str(randi_range(453, 3425)) + "°C"
		else:
			return "ERR"

func _generate_fan(category: int) -> String:
	if category == ContentGenerator.SiteCategory.NORMAL:
		return ["OK", "NORMAL"][randi() % 2]
	elif category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return ["HIGH", "MAX"][randi() % 2]
	else:
		return ["FAILING", "ERR", "██", "OFF"][randi() % 4]

func _generate_net(category: int) -> String:
	if category == ContentGenerator.SiteCategory.NORMAL:
		return "STABLE | PING: " + str(randi_range(10, 50)) + "ms"
	elif category == ContentGenerator.SiteCategory.SUSPICIOUS:
		return ["INTERMITTENT", "UNSTABLE"][randi() % 2] + " | PING: " + str(randi_range(100, 500)) + "ms"
	else:
		return ["RECURSIVE LOOP", "OUTBOUND TO ?", "TRANSMITTING", "████████"][randi() % 4]

# =====================================================
#  CATEGORY
# =====================================================

func _on_category_pressed(chosen_category: ContentGenerator.SiteCategory) -> void:
	if _category_chosen:
		return
	
	_category_chosen = true
	_sanity_drain_active = false
	
	var is_correct = (chosen_category == content.category)
	var player_marked_blacklisted = blacklisted_check.button_pressed
	
	normal_btn.disabled = true
	anomaly_btn.disabled = true
	dangerous_btn.disabled = true
	blacklisted_check.disabled = true
	
	if result_label:
		result_label.visible = true
		result_label.text = "✓ CORRECT!" if is_correct else "✗ INCORRECT!"
	
	if not is_correct:
		var em = get_tree().get_first_node_in_group("enemy_manager")
		if em and em.has_method("on_site_misidentified"):
			em.on_site_misidentified(content.category)
	
	if DailyManager:
		DailyManager.complete_site(content, chosen_category, player_marked_blacklisted)
	
	if DiskManager:
		DiskManager.confirm_site_loaded()
		var disk = DiskManager.eject_disk()
		if disk:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.inventory:
				player.inventory.add_item(disk)
				print("[ArticlePage] Used disk returned to inventory")

func deactivate() -> void:
	_sanity_drain_active = false

func update_content(new_content: PageContent) -> void:
	_apply_content(new_content)
