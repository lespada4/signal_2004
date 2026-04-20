extends Control
class_name ZalgoSite

@export var zalgo_resource: ZalgoEffect

var _zalgo_applied: bool = false

func _ready():
	_apply_zalgo_from_resource()

func _apply_zalgo_from_resource() -> void:
	if zalgo_resource and not _zalgo_applied:
		zalgo_resource.apply_to(self)
		_zalgo_applied = true

func _process(delta: float) -> void:
	if zalgo_resource and _zalgo_applied:
		zalgo_resource.update(delta)

func refresh_zalgo() -> void:
	if zalgo_resource and _zalgo_applied:
		zalgo_resource.refresh_texts()
		zalgo_resource._apply_to_all()

func set_zalgo_enabled(enabled: bool) -> void:
	if zalgo_resource:
		zalgo_resource.enabled = enabled
		if enabled:
			zalgo_resource.apply_to(self)
		else:
			zalgo_resource.remove()

func set_zalgo_concentration(value: int) -> void:
	if zalgo_resource:
		zalgo_resource.set_concentration(value)
