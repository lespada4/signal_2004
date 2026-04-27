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

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("reloader_debug"):
		#get_tree().reload_current_scene()

func _ready() -> void:
	normal_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.NORMAL))
	anomaly_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.SUSPICIOUS))
	dangerous_btn.pressed.connect(_on_category_pressed.bind(ContentGenerator.SiteCategory.DANGEROUS))
	refresh_button.pressed.connect(_on_refresh_pressed)
	diag_button.pressed.connect(_on_diag_pressed)
	
	if content:
		_apply_content(content)
	else:
		_apply_content(ContentGenerator.new().generate_site(ContentGenerator.SiteCategory.NORMAL))
	
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
	
	# Изображение
	if data.has_image():
		image.texture = data.get_image()
		image.visible = true
		image.self_modulate = Color.WHITE
		image.position = Vector2.ZERO
	else:
		image.visible = false
	
	# Сбрасываем эффекты
	_sanity_drain_active = false
	set_zalgo_enabled(false)
	
	# Применяем симптомы
	if data.has_symptom(PageContent.Symptom.ZALGO_LIGHT):
		set_zalgo_enabled(true)
		set_zalgo_concentration(30)
	
	if data.has_symptom(PageContent.Symptom.ZALGO_HEAVY):
		set_zalgo_enabled(true)
		set_zalgo_concentration(70)
	
	if data.has_symptom(PageContent.Symptom.IMAGE_GLITCH):
		if data.has_image():
			image.self_modulate = Color(1.0, 0.7, 0.7)
	
	if data.has_symptom(PageContent.Symptom.SANITY_DRAIN_LIGHT):
		_sanity_drain_active = true
		_sanity_drain_rate = 3.0
	
	if data.has_symptom(PageContent.Symptom.SANITY_DRAIN_HEAVY):
		_sanity_drain_active = true
		_sanity_drain_rate = 8.0

func _process(delta: float) -> void:
	if _sanity_drain_active:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("drain_sanity"):
			player.drain_sanity(_sanity_drain_rate * delta)

# =====================================================
#  REFRESH (День 2)
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
	image.position.x += randf_range(-10, 10)
	image.modulate = Color(randf_range(0.5, 1), randf_range(0.5, 1), randf_range(0.5, 1))

# =====================================================
#  DIAGNOSTIC (День 3)
# =====================================================

func _on_diag_pressed() -> void:
	_log_shown = !_log_shown
	
	if _log_shown:
		log_label.text = _generate_diagnostic()
		log_panel.visible = true
	else:
		log_panel.visible = false

func _generate_diagnostic() -> String:
	if content.has_symptom(PageContent.Symptom.CPU_ANOMALY):
		var logs = [
			"CPU: 99% | RAM: ████\nNET: RECURSIVE LOOP\nCRITICAL: Process 'agent.exe' cannot be terminated",
			"CPU: 88% | RAM: 512MB\nNET: OUTBOUND TO UNKNOWN\nCRITICAL: Memory corruption detected",
			"CPU: 95% | RAM: 1024MB\nNET: TRANSMITTING\nCRITICAL: YOU ARE NOW AN AUTHORIZED READER"
		]
		return logs[randi() % logs.size()]
	else:
		return "CPU: 12% | RAM: 34MB\nNET: STABLE | PING: 24ms\nSTATUS: CLEAN"

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

func deactivate() -> void:
	_sanity_drain_active = false

func update_content(new_content: PageContent) -> void:
	_apply_content(new_content)
