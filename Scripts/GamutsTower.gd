extends Control

# Gamut's Tower: a hall of portals to other places, each at a difficulty you pick (Battle.difficulty:
# Difficulty.AREA). Only the Infernal Meadows, for now; later the overworld's dungeon gates lead here.

const PORTALS := {"Infernal Meadows": "res://Scenes/meadows_play.tscn"}

var difficulty := 1.0
var _pick := ""


func _ready() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.add_theme_constant_override(&"separation", 6)
	add_child(col)
	var title := Label.new()
	title.text = "Gamut's Tower"
	title.add_theme_font_size_override(&"font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var lead := Label.new()
	lead.text = "A hall of portals. Step through one."
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lead)
	var portals := HBoxContainer.new()
	var group := ButtonGroup.new()
	for name in PORTALS:
		var b := Button.new()
		b.text = name
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(func(): _pick = name)
		portals.add_child(b)
		if _pick == "":
			_pick = name
			b.button_pressed = true
	col.add_child(portals)
	var diff := HBoxContainer.new()
	var dgroup := ButtonGroup.new()
	for x in Difficulty.AREA_NAMES:
		var b := Button.new()
		b.text = "%s (%s)" % [Difficulty.AREA_NAMES[x], Skill.num(x)]
		b.toggle_mode = true
		b.button_group = dgroup
		b.button_pressed = is_equal_approx(x, difficulty)
		b.pressed.connect(func(): difficulty = x)
		diff.add_child(b)
	col.add_child(diff)
	var go := Button.new()
	go.name = "Enter"
	go.text = "Enter the portal"
	go.pressed.connect(enter)
	col.add_child(go)


# Through the picked portal, at the picked difficulty.
func enter() -> void:
	Game.difficulty = difficulty
	get_tree().change_scene_to_file(PORTALS[_pick])
