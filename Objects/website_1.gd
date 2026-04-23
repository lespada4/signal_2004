extends Control

@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var drive_info: Label = $Panel/VBoxContainer/DriveInfo
@onready var av_checkbox: CheckBox = $Panel/VBoxContainer/AVCheckBox
@onready var insert_button: Button = $Panel/VBoxContainer/InsertButton
@onready var warning_label: Label = $Panel/VBoxContainer/WarningLabel

var current_site: PageContent = null
var av_enabled: bool = false

func _ready() -> void:
	# Подключаем сигналы
	av_checkbox.toggled.connect(_on_av_toggled)
	insert_button.pressed.connect(_on_insert_pressed)
	
	# Проверяем флешку
	if DiskManager:
		var site = DiskManager.get_current_site()
		if site:
			current_site = site
			_update_for_site(site)
		else:
			_update_no_site()
	else:
		_update_no_site()

func _update_for_site(site: PageContent) -> void:
	var category = site.category
	
	match category:
		ContentGenerator.SiteCategory.NORMAL:
			status_label.text = "FLASH DRIVE DETECTED"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
			drive_info.text = "Safe content - Ready to insert"
			av_checkbox.visible = false
			insert_button.disabled = false
			insert_button.text = "INSERT"
			
		ContentGenerator.SiteCategory.SUSPICIOUS:
			status_label.text = "⚠️ SUSPICIOUS DRIVE ⚠️"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
			drive_info.text = "AV protection required"
			av_checkbox.visible = true
			av_checkbox.text = "Enable SomnoProtecta AV"
			av_checkbox.button_pressed = false
			insert_button.disabled = true
			insert_button.text = "AV REQUIRED"
			
		ContentGenerator.SiteCategory.DANGEROUS:
			status_label.text = "🔴 CRITICAL THREAT 🔴"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			drive_info.text = "Maximum protection active"
			av_checkbox.visible = true
			av_checkbox.text = "SomnoProtecta AV (MANDATORY)"
			av_checkbox.button_pressed = true
			av_checkbox.disabled = true
			av_enabled = true
			insert_button.disabled = false
			insert_button.text = "INSERT WITH AV"

func _update_no_site() -> void:
	status_label.text = "NO FLASH DRIVE"
	status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	drive_info.text = "Insert a flash drive to continue"
	av_checkbox.visible = false
	insert_button.disabled = true
	insert_button.text = "WAITING..."

func _on_av_toggled(button_pressed: bool) -> void:
	av_enabled = button_pressed
	
	if current_site and current_site.category == ContentGenerator.SiteCategory.SUSPICIOUS:
		insert_button.disabled = not button_pressed
		insert_button.text = "INSERT WITH AV" if button_pressed else "AV REQUIRED"
		
		if warning_label:
			warning_label.visible = false

func _on_insert_pressed() -> void:
	if not current_site:
		return
	
	if current_site.category == ContentGenerator.SiteCategory.SUSPICIOUS and not av_enabled:
		if warning_label:
			warning_label.text = "Enable AV protection first!"
			warning_label.visible = true
			await get_tree().create_timer(2.0).timeout
			if warning_label:
				warning_label.visible = false
		return
	
	# Вставка
	if DiskManager:
		DiskManager.confirm_insertion()
		DiskManager.flash_drive_inserted.emit(current_site)

func update_drive(site: PageContent) -> void:
	current_site = site
	_update_for_site(site)
