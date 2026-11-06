class_name GuideLink
extends Button

# The small "i" in a panel's corner: opens the Guide (Settings) at the page about that panel, through
# whatever's in the "guide" group (the HUD: open_guide()).

@export var page := &""


func _init(at := &"") -> void:
	page = at
	text = "i"
	focus_mode = FOCUS_NONE
	tooltip_text = "Guide"
	custom_minimum_size = Vector2(11, 11)
	size_flags_vertical = SIZE_SHRINK_CENTER
	add_theme_font_size_override(&"font_size", 6)
	pressed.connect(func() -> void: get_tree().call_group(&"guide", &"open_guide", page))
