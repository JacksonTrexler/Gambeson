class_name PartyPanel
extends PanelContainer

# The Party screen, off the entry screen: the roster (Game.roster), one box each, ticked for those who go into battle
# (Game.party) - the leader always, the rest while there's room (Game.leader_party_size()). Done closes it; the
# choice is saved.

signal closed

var boxes: Array[CheckBox] = []
var count: Label


func _ready() -> void:
	name = &"PartyPanel"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var col := VBoxContainer.new()
	add_child(col)
	var title := Label.new()
	title.text = "Party"
	title.add_theme_font_size_override(&"font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	count = Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(count)
	var grid := GridContainer.new()
	grid.columns = 2
	col.add_child(grid)
	var picked := Game.party_now()
	for i in Game.roster.size():
		var d: Dictionary = Game.roster[i]
		var r = load(d.role) if ResourceLoader.exists(str(d.get("role", ""))) else null
		var box := CheckBox.new()
		box.text = "%s, %s, level %d" % [d.get("name", "?"), r.name if r else "?", int(d.get("level", 1))]
		box.button_pressed = i in picked
		box.disabled = i == 0  # the leader goes
		box.toggled.connect(_toggled.unbind(1))
		grid.add_child(box)
		boxes.append(box)
	var done := Button.new()
	done.name = &"Done"
	done.text = "Done"
	done.pressed.connect(_done)
	col.add_child(done)
	_toggled()


# The ticks as the party, the leader first; past the size it may have, the rest can't be ticked.
func _toggled() -> void:
	var picked: Array[int] = []
	for i in boxes.size():
		if boxes[i].button_pressed:
			picked.append(i)
	Game.party = picked
	var cap := Game.leader_party_size()
	for i in range(1, boxes.size()):
		boxes[i].disabled = not boxes[i].button_pressed and picked.size() >= cap
	count.text = "%d of %d" % [picked.size(), cap]


func _done() -> void:
	Save.save()
	closed.emit()
	queue_free()
