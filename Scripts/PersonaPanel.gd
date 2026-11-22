class_name PersonaPanel
extends PanelContainer

# Personify's active half: what a unit's persona puts forward, as far as its rank allows - its vibe
# (I), its stance (Friendly from II, the wrong team from III), the level it claims (II), its identity
# tags and the name it goes by (III, from its pools). Vibe words and tags come from lists: type to
# filter, Enter takes the top match, a picked one's chip takes it off. Up to its Personify rank of
# changes a use (Battle.persona_changes()): Done is off past that. It advertises while it puts
# anything forward; holding Clear takes everything off at once. Done pays the AP (Battle.personify());
# Cancel changes nothing.

signal done(changes: Dictionary)

# Every vibe word and identity tag a persona can put forward, besides those units in the battle show:
# the ones set on units, ground and skill looks so far (Briny, Smouldering, Serene...; monster, holy...)
# and a few givens.
const VIBES := ["Beautiful", "Briny", "Earthy", "Harmless", "Hungry", "Radiant", "Reeking", "Safe", "Serene",
		"Smouldering", "Unyielding"] + ["Calm", "Cold", "Fierce", "Gentle", "Kind", "Menacing", "Warm"]
const TAGS := [&"golem", &"halfling", &"holy", &"human", &"monster", &"siren", &"undead"] + [&"beast", &"divine", &"fey", &"noble"]
const HOLD_MS := 500  # how long Clear must be held

var _stance: OptionButton
var _level: SpinBox
var _adjective: OptionButton
var _noun: OptionButton
var _vibe: WordPicker
var _tags: WordPicker
var _count: Label
var _ok: Button
var _cleared := false
var _held_at := 0
var _unit: Unit
var _skill: Skill
var _column: VBoxContainer


# Words picked from a list: a filter box (Enter takes the top match), the matches, and the picked
# words as chips (click one to take it off).
class WordPicker:
	extends VBoxContainer

	signal changed

	var picked: Array = []
	var pool: Array = []
	var filter := LineEdit.new()
	var matches := ItemList.new()
	var chips := HFlowContainer.new()

	func _init(words: Array, now: Array, hint: String) -> void:
		pool = words
		picked = now.duplicate()
		filter.placeholder_text = hint
		filter.tooltip_text = "Type to filter; Enter takes the top match"
		filter.text_changed.connect(_refilter.unbind(1))
		filter.text_submitted.connect(func(_t: String) -> void: take_top())
		matches.auto_height = true
		matches.max_columns = 0
		matches.same_column_width = true
		matches.item_clicked.connect(func(i: int, _at: Vector2, _b: int) -> void: add(matches.get_item_text(i)))
		add_child(chips)
		add_child(filter)
		add_child(matches)
		_redraw()

	# The words left to pick that match the filter, best (starting with it) first.
	func options() -> Array:
		var f := filter.text.strip_edges().to_lower()
		var left := pool.filter(func(w): return w not in picked and String(w).to_lower().contains(f))
		left.sort_custom(func(x, y): return int(String(x).to_lower().begins_with(f)) > int(String(y).to_lower().begins_with(f)))
		return left

	func take_top() -> void:
		var o := options()
		if not o.is_empty():
			add(o[0])

	func add(w: Variant) -> void:
		for x in pool:
			if String(x) == String(w) and x not in picked:
				picked.append(x)
		filter.text = ""
		_redraw()
		changed.emit()

	func remove(w: Variant) -> void:
		picked.erase(w)
		_redraw()
		changed.emit()

	func clear() -> void:
		picked.clear()
		_redraw()

	func _refilter() -> void:
		matches.clear()
		for w in options().slice(0, 6):
			matches.add_item(String(w))

	func _redraw() -> void:
		for c in chips.get_children():
			chips.remove_child(c)
			c.queue_free()
		for w in picked:
			var b := Button.new()
			b.text = String(w) + "  x"
			b.tooltip_text = "Take it off"
			b.pressed.connect(remove.bind(w))
			chips.add_child(b)
		_refilter()


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(220, 0)
	set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	_column = VBoxContainer.new()
	_column.add_theme_constant_override(&"separation", 4)
	add_child(_column)


# Shows u's persona as it stands; p: its persona rank with Personify on (Battle.persona_rank()).
func open(u: Unit, s: Skill, p: int) -> void:
	for c in _column.get_children():
		_column.remove_child(c)
		c.queue_free()
	var title := Label.new()
	title.theme_type_variation = &"Title"
	title.text = "Personify"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_child(title)
	head.add_child(GuideLink.new(&"persona"))
	_column.add_child(head)
	_column.add_child(_muted("%s · Persona %s · %s AP" % [u.nick if u.nick else String(u.name), Skill.roman(p), Skill.num(u.ap_cost(s, u.funding(s)))]))
	_unit = u
	_skill = s
	_cleared = false
	_stance = null
	_level = null
	_adjective = null
	_noun = null
	_vibe = null
	_tags = null
	if p >= 1:
		_vibe = WordPicker.new(_pool(VIBES, u, func(o: Unit): return Array(o.shows_vibe) + Array(o.vibe.split(", ", false)).map(func(w: String): return w.capitalize())), u.shows_vibe, "Serene, Safe...")
		_vibe.changed.connect(_recount)
		_column.add_child(_line("Vibe", _vibe))
	if p >= 2:
		_stance = OptionButton.new()
		for x in Battle.stances(p):
			_stance.add_item(x if x else "No stance")
			_stance.set_item_metadata(_stance.item_count - 1, x)
			if x == u.stance:
				_stance.select(_stance.item_count - 1)
		_stance.item_selected.connect(_recount.unbind(1))
		_column.add_child(_line("Stance", _stance))
		_level = SpinBox.new()
		_level.min_value = 0
		_level.max_value = 99
		_level.value = u.shows_level
		_level.tooltip_text = "0: no level claimed (its own, to advertise honestly)"
		_level.value_changed.connect(_recount.unbind(1))
		_column.add_child(_line("Claims level", _level))
	if p >= 3:
		_tags = WordPicker.new(_pool(TAGS, u, func(o: Unit): return Array(o.shows_tags) + Array(o.tags)), u.shows_tags, "holy...")
		_tags.changed.connect(_recount)
		_column.add_child(_line("Identity", _tags))
	if p >= 3 and not (u.shows_adjectives.is_empty() and u.shows_nouns.is_empty()):
		_adjective = _pick([""] + Array(u.shows_adjectives), u.alias.trim_suffix(u.alias_noun).strip_edges())
		_noun = _pick([""] + u.shows_nouns.keys(), u.alias_noun)
		_adjective.item_selected.connect(_recount.unbind(1))
		_noun.item_selected.connect(_recount.unbind(1))
		var name_row := HBoxContainer.new()
		name_row.add_child(_adjective)
		name_row.add_child(_noun)
		_column.add_child(_line("Goes by", name_row))
	_count = _muted("")
	_column.add_child(_count)
	var buttons := HBoxContainer.new()
	var clear := Button.new()
	clear.text = "Clear"
	clear.tooltip_text = "Hold to take everything off: it stops advertising"
	clear.button_down.connect(func() -> void: _held_at = Time.get_ticks_msec())
	clear.button_up.connect(func() -> void:
		if Time.get_ticks_msec() - _held_at >= HOLD_MS:
			clear_all())
	buttons.add_child(clear)
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	buttons.add_child(gap)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(hide)
	_ok = Button.new()
	_ok.text = "Done"
	_ok.pressed.connect(func() -> void:
		hide()
		done.emit(changes()))
	buttons.add_child(cancel)
	buttons.add_child(_ok)
	_column.add_child(buttons)
	_recount()
	reset_size()
	set_anchors_and_offsets_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)
	show()


# What's picked, for Battle.personify().
func changes() -> Dictionary:
	if _cleared:
		return {clear = true}
	var out := {}
	if _stance:
		out.stance = _stance.get_item_metadata(_stance.selected)
		out.shows_level = int(_level.value)
	if _noun:
		out.adjective = _adjective.get_item_metadata(_adjective.selected)
		out.noun = _noun.get_item_metadata(_noun.selected)
	if _vibe:
		out.vibe = _vibe.picked.duplicate()
	if _tags:
		out.tags = _tags.picked.duplicate()
	return out


# Everything off (the held Clear): one change, and it stops advertising.
func clear_all() -> void:
	_cleared = true
	for w in [_vibe, _tags]:
		if w:
			w.clear()
	if _stance:
		_stance.select(0)
		_level.set_value_no_signal(0)
	for o in [_adjective, _noun]:
		if o:
			o.select(0)
	_recount()


# Changes made against the rank's allowance: "Changes: 2 / 3"; Done is off past it.
func _recount() -> void:
	var n := Battle.persona_changes(_unit, _skill, changes())
	var most := _unit.rank(_skill)
	_count.text = "Changes: %d / %d" % [n, most]
	_ok.disabled = n > most


# The words to pick from: `base`, plus whatever units in u's battle show (`of`), sorted.
func _pool(base: Array, u: Unit, of: Callable) -> Array:
	var out := base.duplicate()
	for o in (u.get_parent().get_children() if u.get_parent() else [u]):
		if o is Unit:
			for w in of.call(o):
				if w not in out and String(w) != "":
					out.append(w)
	out.sort_custom(func(x, y): return String(x) < String(y))
	return out


func _pick(options: Array, current: String) -> OptionButton:
	var o := OptionButton.new()
	for x: String in options:
		o.add_item(x if x else "-")
		o.set_item_metadata(o.item_count - 1, x)
		if x == current:
			o.select(o.item_count - 1)
	return o


func _line(label: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := _muted(label)
	l.custom_minimum_size.x = 60
	h.add_child(l)
	control.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(control)
	return h


func _muted(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = &"Muted"
	l.text = text
	return l
