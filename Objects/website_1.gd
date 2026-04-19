extends Control

@export var content: PageContent

@onready var title: Label = $VBoxContainer/Title
@onready var body_text: Label = $VBoxContainer/BodyText


func _ready() -> void:
	if content:
		title.text = content.title
		body_text.text = content.body
	else:
		var generated = ContentGenerator.new().generate()
		title.text = generated.title
		body_text.text = generated.body
