class_name PartyPanel
extends Control

# The Party screen, off the entry screen: the roster (Game.roster), one box each, ticked for those who go into battle
# (Game.party) - the leader always, the rest while there's room (Game.leader_party_size()). Done closes it; the
# choice is saved. Each member has an Outfit button: the stash screen (CharacterSheet) on that roster member, who puts on
# and takes off what's in the stash (Game.stash) and uses a Heart, saved through its roster entry (Game.roster) - the
# leader's too, which also keeps what it has on (Game.outfit), its bar and hearts as a battle does.

signal closed

var boxes: Array[CheckBox] = []
var count: Label
var sheet := CharacterSheet.new()
var member := -1  # the roster entry the sheet shows
var unit: Unit  # standing for it while the sheet is open (in the tree: its bar follows what its items lend)


func _ready() -> void:
	name = &"PartyPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	var title := Label.new()
	title.text = "Party"
	title.add_theme_font_size_override(&"font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	count = Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(count)
	var grid := GridContainer.new()
	grid.columns = 3
	col.add_child(grid)
	var picked := Game.party_now()
	for i in Game.roster.size():
		var d: Dictionary = Game.roster[i]
		var r = load(d.role) if ResourceLoader.exists(str(d.get("role", ""))) else null
		var box := CheckBox.new()
		var who := str(d.get("name", "?"))
		box.text = "%s, level %d" % [who if r and who == r.name else "%s, %s" % [who, r.name if r else "?"], int(d.get("level", 1))]
		box.button_pressed = i in picked
		box.disabled = i == 0  # the leader goes
		box.toggled.connect(_toggled.unbind(1))
		grid.add_child(box)
		boxes.append(box)
		var wear := Button.new()
		wear.name = "Outfit%d" % i
		wear.text = "Outfit"
		wear.pressed.connect(outfit.bind(i))
		grid.add_child(wear)
		var gap := Control.new()  # (the grid's third column: the next member's box starts a row)
		grid.add_child(gap)
	var done := Button.new()
	done.name = &"Done"
	done.text = "Done"
	done.pressed.connect(_done)
	col.add_child(done)
	sheet.between = true
	sheet.hide()
	sheet.equipped.connect(_on_equipped)
	sheet.unequipped.connect(_on_unequipped)
	sheet.used_up.connect(_on_used_up)
	sheet.visibility_changed.connect(_sheet_shut)
	add_child(sheet)
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
	count.text = "Going solo: no one to bring yet" if cap <= 1 else "%d of %d" % [picked.size(), cap]


func _done() -> void:
	Save.save()
	closed.emit()
	queue_free()


# Opens the stash screen on roster entry i: a unit of its class made from the entry (as a battle fields it), in the tree
# so what its items lend reaches its bar.
func outfit(i: int) -> Unit:
	_drop()
	if i < 0 or i >= Game.roster.size() or not ResourceLoader.exists(str(Game.roster[i].get("role", ""))):
		return null
	var d: Dictionary = Game.roster[i]
	var u: Unit = Battle.UNIT.instantiate()
	var nick := str(d.get("name", ""))
	u.name = nick.validate_node_name()
	u.nick = nick
	u.faction = load(d.faction) if ResourceLoader.exists(str(d.get("faction", ""))) else null
	u.role = load(d.role)
	u.max_hp = Unit.CLASS_HP
	for k in u.role.stats:
		u.set(k, u.role.stats[k])
	u.reserves.merge(u.role.reserves)
	var class_hearts := u.hearts
	u.from_dict(d)
	if i == 0:  # the leader as a battle starts it (Battle.starter()): its own fields win over its entry
		u.hearts = class_hearts + Game.hearts
		u.level = clampi(Game.level, 1, Unit.MAX_LEVEL)
		u.xp = Game.xp
		for slot in Game.outfit:
			u.set(slot, Game.outfit[slot])
		u.lapses_in(Game.lapses)
		if not Game.equipped.is_empty():
			u.ready.connect(func(): u.set_equipped(Game.equipped), CONNECT_ONE_SHOT)
	Battle.refill(u)
	add_child(u)
	unit = u
	member = i
	sheet.open(u, true)
	return u


# What a change did: back into the roster entry, and the leader's own fields.
func _keep() -> void:
	if unit == null:
		return
	if member == 0:
		Game.outfit = {}
		for slot in CharacterSheet.SLOTS + Array(unit.plating.keys()):
			if unit.get(slot):
				Game.outfit[slot] = unit.get(slot)
		Game.equipped = unit.get_equipped()
	Game.roster[member] = unit.to_dict()
	Save.save()
	sheet.open(unit, true)


func _on_equipped(u: Unit, it: Item, slot := "") -> void:
	if u != unit or it not in Game.stash or not u.can_wear(it):
		return
	var there: Item = u.get(slot if slot else it.slot)
	if there and there.binding:
		return
	var old := u.equip(it, slot)
	if old == null and u.get(slot if slot else it.slot) != it:
		return
	Game.stash.erase(it)
	if old:
		Game.stash.append(old)
	_keep()


func _on_unequipped(u: Unit, slot: String) -> void:
	var it: Item = u.get(slot) if u == unit else null
	if it == null or it.binding:
		return
	Game.stash.append(u.unequip(slot))
	_keep()


# A Heart from the stash: an extra life for good (the leader's are Game.hearts, as in battle).
func _on_used_up(u: Unit, it: Item) -> void:
	if u != unit or it not in Game.stash or it.slot != "consumable" or it.hearts <= 0:
		return
	Game.stash.erase(it)
	u.hearts += it.hearts
	if member == 0:
		Game.hearts += it.hearts
	_keep()


func _sheet_shut() -> void:
	if not sheet.visible:
		_drop()


func _drop() -> void:
	if unit:
		unit.queue_free()
	unit = null
	member = -1
