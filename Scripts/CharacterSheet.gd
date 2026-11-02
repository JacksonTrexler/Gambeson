class_name CharacterSheet
extends PanelContainer

# The character sheet (the dock's character icon): a unit's equipment and hearts, and the player's
# stash (Game.stash) - items won as drops and scenario rewards. On its side's turn, or once the battle
# is over, a unit of the player's own puts items on from the stash (what they replace goes back
# into it), takes them off, or uses up a consumable (a Heart) or a potion in its trinket slot. In
# battle, putting on or using costs the item's AP (Item.ap_cost()); taking off is free.

signal equipped(u: Unit, it: Item)
signal unequipped(u: Unit, slot: String)
signal used_up(u: Unit, it: Item)

const SLOTS := ["weapon", "armor", "trinket"]

var unit: Unit
var ap_of := func(_it: Item, _u: Unit) -> float: return 0.0  # AP an item takes its unit to put on or use now (HUD: Battle.item_ap())
var _column: VBoxContainer


func _init() -> void:
	custom_minimum_size = Vector2(220, 0)
	set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", 4)
	add_child(_column)


# Shows u's sheet; editable: its items can be changed now.
func open(u: Unit, editable: bool) -> void:
	unit = u
	for c in _column.get_children():
		_column.remove_child(c)
		c.queue_free()
	var title := Label.new()
	title.theme_type_variation = &"Title"
	title.text = "Character"
	_column.add_child(title)
	var who := u.nick if u.nick else String(u.name)
	var hearts := " · %d of %d hearts left" % [u.lives_left(), u.lives()] if u.lives() > 0 else ""
	_column.add_child(_muted("%s · Lv %d%s" % [who, u.lv(), hearts]))
	for slot in SLOTS:
		var it: Item = u.get(slot)
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s: %s" % [slot.capitalize(), it.name if it else "none"]
		l.tooltip_text = it.describe() if it else ""
		l.mouse_filter = MOUSE_FILTER_PASS
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(l)
		if it and editable and it.restores and not it.empty:
			row.add_child(_button("Use" + _ap(it), func() -> void: used_up.emit(unit, it)))
		if it and editable:
			row.add_child(_button("Take off", func() -> void: unequipped.emit(unit, slot)))
		_column.add_child(row)
	_column.add_child(_muted("Stash"))
	if Game.stash.is_empty():
		_column.add_child(_muted("Nothing yet: bosses, commanders and\nwon battles give items"))
	for it in Game.stash:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = it.name
		l.tooltip_text = it.describe()
		l.mouse_filter = MOUSE_FILTER_PASS
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(l)
		if editable and it.slot == "consumable":
			row.add_child(_button("Use" + _ap(it), func() -> void: used_up.emit(unit, it)))
		elif editable and u.can_wear(it):
			row.add_child(_button("Equip" + _ap(it), func() -> void: equipped.emit(unit, it)))
		_column.add_child(row)
	var close := _button("Close", hide)
	close.size_flags_horizontal = SIZE_SHRINK_END
	_column.add_child(close)
	show()
	reset_size()
	set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)


# " · 3 AP" in battle; "" once it's free.
func _ap(it: Item) -> String:
	var n: float = ap_of.call(it, unit)
	return " · %s AP" % Skill.num(n) if n > 0.0 else ""


func _button(text: String, then: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(then)
	return b


func _muted(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"Muted"
	l.text = text
	return l
