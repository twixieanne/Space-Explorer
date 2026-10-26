
extends TextureRect

func _ready() -> void:
	fit_background()
	get_viewport().size_changed.connect(fit_background)


func fit_background() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	stretch_mode = TextureRect.STRETCH_SCALE
