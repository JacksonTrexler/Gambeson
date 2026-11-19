class_name CharacterSheet
extends PanelContainer

# The character sheet (the dock's character icon): a unit's equipment and hearts, and the player's
# stash (Game.stash) - items won as drops and scenario rewards. On its side's turn, or once the battle
# is over, a unit of the player's own puts items on from the stash (what they replace goes back
# into it), takes them off, or uses up a consumable (a Heart) or a potion in its trinket slot. In
# battle, putting on or using costs the item's AP (Item.ap_cost()); taking off is free.

signal equipped(u: Unit, it: Item, slot: String)  # slot: one of the armor slots its skills give, or "" for the item's own
signal unequipped(u: Unit, slot: String)
signal used_up(u: Unit, it: Item)
signal unshackled(u: Unit, how: StringName)  # unlock, pick or pry its shackles (Battle.unshackle())

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
# r: how the viewing side reads u (Battle.read()), for a unit that isn't its own; null shows u's whole bio.
func open(u: Unit, editable: bool, r: Read = null) -> void:
	unit = u
	for c in _column.get_children():
		_column.remove_child(c)
		c.queue_free()
	var title := Label.new()
	title.theme_type_variation = &"Title"
	title.text = "Character"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_child(title)
	head.add_child(GuideLink.new(&"character"))
	_column.add_child(head)
	if r:  # someone else's: only what the viewer makes out (the unit card's own gates), no hearts, XP or kit
		var who := r.name if r.name else ("A %s" % r.looks if r.looks else "Something")
		_column.add_child(_muted("%s · Lv %s" % [who, str(r.level) if r.level != null else "?"]))
	else:
		var who := u.nick if u.nick else String(u.name)
		var hearts := " · %d of %d hearts left" % [u.lives_left(), u.lives()] if u.lives() > 0 else ""
		var xp := "max level" if u.level >= Unit.MAX_LEVEL else "%d / %d XP" % [u.xp, Unit.xp_to_next(u.level)]
		_column.add_child(_muted("%s · Lv %d · %s%s" % [who, u.lv(), xp, hearts]))
	var bio := Bio.line(u, r)
	if bio:
		var l := RichTextLabel.new()
		l.name = "Bio"
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.text = Glossary.rich(bio)
		_column.add_child(l)
	for slot in (SLOTS + u.plate_slots()) if r == null else []:
		var it: Item = u.get(slot)
		var row := HBoxContainer.new()
		row.add_child(UnitCard.trim_mark(it.trim() if it else Color(0, 0, 0, 0), it.name if it else "", it.icon() if it else null))
		var l := Label.new()
		l.text = "%s: %s" % [u.slot_label(slot), it.name if it else "none"]
		l.tooltip_text = it.describe() if it else ""
		l.mouse_filter = MOUSE_FILTER_PASS
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(l)
		if it and editable and it.restores and not it.empty:
			row.add_child(_button("Use" + _ap(it), func() -> void: used_up.emit(unit, it)))
		if it and editable and it.binding:  # shackles: locked, pick or pry them; unlocked, off for their rank in AP
			var ap := " · %d AP" % it.rank
			if u.shackled():
				row.add_child(_button("Pick (%s %d)%s" % [Glossary.name_of(it.picks), Difficulty.dc(it.picks, it.rank), ap], func() -> void: unshackled.emit(unit, &"pick")))
				row.add_child(_button("Pry (%s %d)%s" % [Glossary.name_of(it.prised), Difficulty.dc(it.prised, it.rank), ap], func() -> void: unshackled.emit(unit, &"pry")))
			else:
				row.add_child(_button("Take off" + ap, func() -> void: unshackled.emit(unit, &"unlock")))
		elif it and editable:
			row.add_child(_button("Take off", func() -> void: unequipped.emit(unit, slot)))
		_column.add_child(row)
	if r == null:
		_column.add_child(_muted("Stash"))
	if Game.stash.is_empty() and r == null:
		_column.add_child(_muted("Nothing yet"))
	for it in Game.stash if r == null else []:
		var row := HBoxContainer.new()
		row.add_child(UnitCard.trim_mark(it.trim(), it.name, it.icon()))
		var l := Label.new()
		l.text = it.name
		l.tooltip_text = it.describe()
		l.mouse_filter = MOUSE_FILTER_PASS
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(l)
		if editable and it.slot == "consumable":
			row.add_child(_button("Use" + _ap(it), func() -> void: used_up.emit(unit, it)))
		elif editable and u.can_wear(it):
			row.add_child(_button("Equip" + _ap(it), func() -> void: equipped.emit(unit, it, "")))
			for slot in u.plate_slots() if it.slot == "armor" else ([] as Array[StringName]):  # armor goes in a slot its skills give, too
				row.add_child(_button("%s%s" % [u.slot_label(slot), _ap(it)], func() -> void: equipped.emit(unit, it, slot)))
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
