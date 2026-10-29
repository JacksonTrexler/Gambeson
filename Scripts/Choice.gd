class_name Choice
extends VBoxContainer

# A prompt with one-of-many options (icon + text). `value` holds the pick; changed() announces it.
signal changed(was: Variant, now: Variant)

@export var prompt := "":
	set(v):
		prompt = v
		if is_node_ready():
			$Prompt.text = v

var value: Variant = null
var _group := ButtonGroup.new()


func _ready() -> void:
	$Prompt.text = prompt


func add(text: String, icon: Texture2D = null, v: Variant = text) -> Button:
	var b := Button.new()
	b.text = text
	b.icon = icon
	b.toggle_mode = true
	b.button_group = _group
	b.custom_minimum_size = Vector2(0, 34)
	b.set_meta(&"value", v)
	b.toggled.connect(func(on: bool) -> void:  # toggled: clicks, keys and code all count
		if on and v != value:
			var was: Variant = value
			value = v
			changed.emit(was, v))
	$Options.add_child(b)
	return b


# Picks the option holding v, as if it were clicked. False if there's none.
func pick(v: Variant) -> bool:
	for b: Button in $Options.get_children():
		if b.has_meta(&"value") and b.get_meta(&"value") == v:
			b.button_pressed = true
			return true
	return false
