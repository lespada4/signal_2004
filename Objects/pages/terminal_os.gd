extends Control
class_name TerminalOS

@onready var os_content_panel_placer: Panel = $VBoxContainer/HBoxContainer/OS_Content_Panel_Placer
@onready var category_panel: Panel = $VBoxContainer/HBoxContainer/Category_Panel
@onready var normal_button: Button = $VBoxContainer/HBoxContainer/Category_Panel/VBoxContainer/NORMAL_BUTTON
@onready var anomaly_button: Button = $VBoxContainer/HBoxContainer/Category_Panel/VBoxContainer/ANOMALY_BUTTON
@onready var dangerous_button: Button = $VBoxContainer/HBoxContainer/Category_Panel/VBoxContainer/DANGEROUS_BUTTON
@onready var blacklisted_checkbox: CheckBox = $VBoxContainer/HBoxContainer/Category_Panel/VBoxContainer/VBoxContainer/BLACKLISTED_CHECKBOX
@onready var page_panel: Panel = $VBoxContainer/Page_Panel
@onready var web_button: Button = $VBoxContainer/Page_Panel/HBoxContainer/WebButton
@onready var manual_button: Button = $VBoxContainer/Page_Panel/HBoxContainer/ManualButton
@onready var quota_button: Button = $VBoxContainer/Page_Panel/HBoxContainer/QuotaButton
@onready var manager_call_checkbutton: CheckButton = $VBoxContainer/Page_Panel/HBoxContainer/Panel/MANAGER_CALL_CHECKBUTTON




func _ready() -> void:
	pass
