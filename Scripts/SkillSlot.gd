class_name SkillSlot
extends Button

# One hotbar slot: its number key, the skill in it (or nothing), and that skill's state. Skills are
# dragged in from the spellbook or another slot; dragging one off the bar, or right-clicking it,
# empties the slot. Clicking it (or its number key) uses it - see HUD.use_slot().

signal dropped(index: int, skill: Skill, from: int)  # from: the slot it came from, -1 the spellbook
signal cleared(index: int)

const PLAIN_TINT := Color("#8a90a0")
const GOLD := Color("#e8c547")
const ON := Color("#3fbf4f")
const CLOVER := Color("#5fd068")  # the clover slot a lucky unit gets (Unit.clover()); brighter than Specialist green
# Typed slots (Unit.granted_slots()): dull red, purple and green. Skill trees colour their roots the same.
const TYPES := {&"martial": Color("#b0574f"), &"magical": Color("#8d6bc9"), &"specialist": Color("#6b9a5e")}
const LENT := Color("#8fb8d8")  # the pale blue ring of a skill an item lends (Unit.lent_by()), apart from the gold diamond of a worn emblem
const NO_LUCK := "The clover slot only works while this unit is lucky"
const MUTED_TEXT := Color(0.6, 0.63, 0.7)  # an always-on passive's name and numeral (muted()): nothing to select (the user, 2026-11-20)
const MUTED_GOLD := Color("#a8996a")
const FLASH := 0.8  # seconds a passive's slot stays lit after it acts (flash())
const OFTEN := 4.0  # acting again within this many seconds, it only unmutes: no rim
const ROW := 13.0  # a slot's height; one that spans several is drawn as one tall button

var index := 0
var skill: Skill
var rank := 0
var armed := false  # waiting for a target
var on := false  # a toggled passive that's switched on
var usable := true  # the unit can use it now (takes orders, can pay)
var editable := true  # skills can be dragged in and out
var locked := false  # out of reach of the leader's orders (Command.slots())
var kind := &""  # its unit's slot kind (Unit.slot_kinds()): &"" plain, &"clover", or a type (magical...)
var clover := false  # the unit's clover slot
var works := true  # false: a clover slot whose unit isn't lucky now - greyed out until it is
var off := 0  # turns its skill is disabled for (Brainfog: Unit.disabled); 0: it isn't - dimmed while it is
var off_by: Skill  # what disabled it, if it said (Unit.disabled_by): its mark rides the icon, its name the tooltip
var cursed := false  # a curse disabled it (Brainfog), or sealed the slot (a level curse: Unit.sealed()): it quivers gently
var sealed := false  # a level curse took the slot: it stays, unusable, till the curse ends
var bonus := &""  # a bonus slot's type (Unit.bonus_slots(): Cram's caster bonus slots, magical), &"" none: a dashed rim in its colour
var bonus_rank := 0  # ...and the rank wear on its skill is multiplied by
var bonus_why := ""  # why its skill doesn't work there now (Unit.bonus_why()), "" it does: dimmed, as a disabled one
var label := ""  # the name it goes by for its unit (Unit.skill_name(): Decisive Strike, Firestrike); empty: its own
var exhausted := 0.0  # uses counted against its skill (Exhaustion.of()): a pip each, a half pip for a half - its raised cost without words
var switching := false  # its passive is a switch of what the unit runs on (Mana, Stamina) in progress: a turning arc and a pulsing rim until the channel ends
var holder: Unit  # whose slot it is: its tooltip describes the skill as this unit has it (Skill.markup())
var modded := false  # a worn emblem puts a modifier on its skill (Unit.mods()): a small gold diamond, the tooltip's symbols without hovering
var lent := ""  # the item lending its skill (Unit.lent_by()): a small pale ring at the slot's lower right, and its tooltip says whose
var cover: Skill  # the skill before it that spans this slot (Unit.skill_at(): one that takes several), whose continuation it draws; skill is null
var trait_slot := false  # in the band after the hotbar (HUD.band(): a trait, a free lend): no drag, no clearing, drawn in the trait colour; a number only if its skill is cast or switched (keyed())
var sense := 2  # how much of the skill the player's side makes out (HUD.skill_sense()): 2 all, 1 its name, 0 nothing
var _dragging := false
var _lit := -100.0  # when (s) its passive last acted (flash()); -100: not lately
var _rim := false  # ...and whether that lighting draws a gold rim (not when it acts often)


# Stripe colour: the tag that marks the skill (Tags.mark(), as an item's trim), else PLAIN_TINT.
static func tint(s: Skill) -> Color:
	var t := Tags.mark(s.tags)
	return Tags.color(t) if t else PLAIN_TINT


# A small label for dragging a skill around.
static func chip(s: Skill, th: Theme) -> Control:
	var p := PanelContainer.new()
	p.theme = th
	p.theme_type_variation = &"Tip"
	var l := Label.new()
	l.text = s.name
	l.add_theme_color_override(&"font_color", tint(s).lerp(Color.WHITE, 0.4))
	p.add_child(l)
	return p


func _init() -> void:
	custom_minimum_size = Vector2(0, 13)
	focus_mode = FOCUS_NONE
	gui_input.connect(_on_gui_input)


func set_state(i: int, s: Skill, r: int, is_armed: bool, is_on: bool, can_use: bool, can_edit: bool,
		is_locked := false, knows := 2, mods := "", who: Unit = null) -> void:
	index = i
	holder = who
	skill = s
	rank = r
	armed = is_armed
	on = is_on
	usable = can_use
	editable = can_edit
	locked = is_locked
	sense = knows
	modded = mods != ""
	var key := _tag()
	if not s:
		tooltip_text = "[%s] Empty - drag a skill here from the spellbook (B)" % _key()
	elif sense == 0:
		tooltip_text = "%s Something it can do; your side can't make out what" % key
	elif sense == 1:
		tooltip_text = "%s %s\nYour side can't make out more of it" % [key, s.name]
	else:
		tooltip_text = "%s %s %s%s\n%s" % [key, s.title(), Skill.roman(r), "  " + mods if mods else "", s.markup(r, true, holder)]  # its modifiers, as symbols (Modifiers.label())
	queue_redraw()


# This slot is covered by a skill spanning several slots (Unit.covered()): marked, and the tooltip says whose it is.
func set_cover(s: Skill, n: int) -> void:
	cover = s
	if s:
		tooltip_text = "[%s] Taken by %s, which holds %d slots side by side: right-click to unequip it\n" % [_key(), s.name, n]
	queue_redraw()


# Its skill is lent by this item (empty: it isn't): marked, and the tooltip names it.
func set_lent(item_name: String) -> void:
	lent = item_name
	if lent != "":
		tooltip_text += "\nLent by %s while it's worn: it ranks with the item, and goes when the item does" % lent
	queue_redraw()


# The slot's kind on its unit (plain, clover or typed), and whether it works now.
func set_kind(k: StringName, does_work: bool) -> void:
	kind = k
	clover = k == &"clover"
	works = does_work
	if clover:
		tooltip_text = "Clover slot: luck rounds this unit's slots up\n" + (tooltip_text if works else NO_LUCK)
	elif k in TYPES:
		var cat: String = Skill.CATEGORIES.get(k, String(k))
		tooltip_text = "%s slot: holds only %s skills\n%s" % [cat, cat.to_lower(), tooltip_text]
	queue_redraw()


# Marks a bonus slot (Unit.bonus_slots()): its type, the rank its wear is multiplied by, and why its skill doesn't
# work there now ("" it does). type &"": a plain slot.
func set_bonus(type: StringName, r: int, why: String) -> void:
	bonus = type
	bonus_rank = r
	bonus_why = why
	if bonus != &"":
		var cat: String = Skill.CATEGORIES.get(bonus, String(bonus))
		var cast := "caster" if bonus == &"magical" else cat.to_lower()
		tooltip_text = "%s bonus slot: only %s skills work here, and none while a pillar skill is disabled; wear here x%d%s\n%s" % [
			cast.capitalize(), cast, r, ("\nNot working: " + why) if why != "" and skill else "", tooltip_text]
	queue_redraw()


# Its skill is disabled for n more turns (0: it isn't): dimmed. Cursed (Brainfog), or a slot a level
# curse sealed, it also quivers gently.
func set_off(n: int, by_curse := false, is_sealed := false, src: Skill = null) -> void:
	off = n
	off_by = src if n > 0 else null
	sealed = is_sealed
	cursed = (by_curse and n > 0) or is_sealed
	if n > 0:
		tooltip_text = "%s%s for %d more turn%s\n%s" % ["Cursed" if by_curse else "Disabled", " by " + src.name if src else "", n, "" if n == 1 else "s", tooltip_text]
	if sealed:
		tooltip_text = "Sealed by a curse on its level: it comes back as the curse ends\n" + tooltip_text
	set_process(cursed or switching or _glow() > 0.0)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()  # quivering, a switch turning, or a passive lit
	if not (cursed or switching) and _glow() <= 0.0:
		set_process(false)


# An always-on passive: it can't be selected as an active, so its name and numeral are muted (unmuted a moment as it acts).
static func muted(s: Skill) -> bool:
	return s != null and s.passive and not s.toggle and not s.hybrid


# Its passive just acted (HUD._on_passive(), Battle.passive_fired): lit up a moment, with a gold rim unless it acted
# within OFTEN seconds (a frequent one only unmutes).
func flash() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_rim = now - _lit > OFTEN
	_lit = now
	set_process(true)
	queue_redraw()


# How lit it is now: 1 as it acts, fading to 0 over FLASH seconds.
func _glow() -> float:
	return clampf(1.0 - (Time.get_ticks_msec() / 1000.0 - _lit) / FLASH, 0.0, 1.0)


# Marks (or clears) the slot of a Mana / Stamina toggle while its switch channels; to: what it
# switches to, as named in the tooltip.
func set_switching(to: String) -> void:
	switching = to != ""
	if switching:
		tooltip_text = "Switching to %s: takes effect as the channel ends\n%s" % [to, tooltip_text]
	set_process(cursed or switching or _glow() > 0.0)
	queue_redraw()


# The colour that marks its kind, or null for a plain slot.
func _mark() -> Variant:
	if trait_slot:
		return Tags.color(&"trait")
	if clover:
		return CLOVER
	return TYPES.get(kind)


func _draw() -> void:
	var font := get_theme_font(&"font")
	var fs := 6
	var h := minf(size.y, ROW)  # a slot spanning several (rows()) draws its content as one row's, centred
	var top := (size.y - h) / 2.0
	var mid := top + (h - font.get_height(fs)) / 2.0 + font.get_ascent(fs)
	if cursed:  # a gentle quiver
		var t := Time.get_ticks_msec() / 1000.0
		draw_set_transform(Vector2(sin(t * 23.0) * 0.6, sin(t * 17.0 + 1.3) * 0.35))
	var fade := 1.0 if works and not sealed else 0.4
	var tone: Variant = _mark()
	if tone != null:
		draw_rect(Rect2(Vector2.ZERO, size), Color(tone, 0.12 * fade))
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(tone, 0.5 * fade), false, 1.0)
	draw_rect(Rect2(2, 2, 9, size.y - 4), Color(tone, 0.3 * fade) if tone != null else Color(1, 1, 1, 0.07))
	if bonus != &"":  # a bonus slot: a dashed rim in its type's colour, over whatever marks the slot
		_dashed_rim(Color(TYPES.get(bonus, PLAIN_TINT), 0.85 * fade))
	if trait_slot and not keyed():  # a diamond where the number would be: it has no key
		var at := Vector2(6.5, size.y / 2.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -2.5), at + Vector2(2.5, 0), at + Vector2(0, 2.5), at + Vector2(-2.5, 0)]), Color(tone.lightened(0.35), fade))
	elif locked:
		_lock(Vector2(6.5, size.y / 2.0 + 1.0))
	else:
		var key_col := Color(tone.lightened(0.35), fade) if tone != null else Color(1, 1, 1, 0.55)
		draw_string(font, Vector2(2, mid), _key(), HORIZONTAL_ALIGNMENT_CENTER, 9, fs, key_col)
	if not skill and cover:
		draw_rect(Rect2(12, 2, 1.5, size.y - 4), tint(cover) * Color(1, 1, 1, 0.5))
		draw_string(font, Vector2(15, mid + 0.5), "(continued)", HORIZONTAL_ALIGNMENT_LEFT, size.x - 18, 7, Color(0.92, 0.93, 0.96, 0.4))
		return
	if not skill:
		var blank := "sealed" if sealed else "needs luck" if not works else ("%s only" % Skill.CATEGORIES[kind].to_lower() if kind in TYPES else "%s bonus" % ("caster" if bonus == &"magical" else String(bonus)) if bonus != &"" else "empty")
		draw_string(font, Vector2(15, mid), blank, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.22))
		return
	var dim := brightness()
	if sense == 0:
		draw_string(font, Vector2(16, mid + 0.5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.35))
		return
	draw_rect(Rect2(12, 2, 1.5, size.y - 4), tint(skill) * Color(1, 1, 1, dim))
	var right := size.x - 3
	var numeral := Skill.roman(rank) if sense == 2 else ""
	var nw := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var hush := 1.0 - _glow() if muted(skill) else 0.0  # muted, and how far: less while it's lit
	draw_string(font, Vector2(right - nw, mid), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD.lerp(MUTED_GOLD, hush) * Color(1, 1, 1, dim))
	right -= nw + 2
	if lent != "" and sense == 2:  # the item's ring sits on the numeral's baseline, just left of it
		draw_arc(Vector2(right - 1.7, mid - 1.9), 1.7, 0.0, TAU, 10, Color(LENT, 0.95), 1.0)
		right -= 5
	if shows_switch():  # only a switch shows on/off; an always-on passive just works
		var dot := Vector2(right - 2, size.y / 2.0)
		draw_circle(dot, 1.6, ON if on else Color(1, 1, 1, 0.25))
		if switching:  # the switch turns: a ring round the dot, with an arc running round it
			var t := Time.get_ticks_msec() / 1000.0
			draw_arc(dot, 3.2, t * 5.0, t * 5.0 + PI * 1.3, 10, GOLD, 1.0)
		right -= 6
	var left := 16.0
	var tex := skill.icon()
	if tex:  # its icon before its name
		var side := h - 4.0
		Skill.draw_icon(self, tex, Rect2(15, top + 2, side, side), Color(0.92, 0.93, 0.96, dim), 1.0, dim, icon_look(), off_by.mark().left(1) if off_by and off > 0 else "")
		left += side + 1.0
	var shown := label if label else skill.name
	draw_string(font, Vector2(left, mid + 0.5), shown, HORIZONTAL_ALIGNMENT_LEFT, right - left, name_font(font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, right - left),
			Color(0.92, 0.93, 0.96).lerp(MUTED_TEXT, hush) * Color(1, 1, 1, dim))
	if exhausted > 0.0001:
		_pips()
	if modded and sense == 2:
		var at := Vector2(size.x - 10.0, 4.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -2), at + Vector2(2, 0), at + Vector2(0, 2), at + Vector2(-2, 0)]), Color(GOLD, 0.85))
	if switching:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(GOLD, 0.35 + 0.25 * sin(Time.get_ticks_msec() / 220.0)), false, 1.0)
	if armed:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), GOLD, false, 1.0)
	elif _rim and _glow() > 0.0:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(GOLD, _glow()), false, 1.0)


# How brightly its skill is drawn: dimmed for a skill that can't be used now, a switched-off toggle, a disabled or
# sealed one. An always-on passive says nothing of on or off (the user, 2026-11-18): it is drawn the same whether or not
# its unit can act now, so only a disabling (or a clover slot without luck) dims it. A trait is its own: dim while suppressed.
func brightness() -> float:
	if off > 0 or sealed or (bonus_why != "" and skill != null):
		return 0.25
	var steady := skill != null and skill.passive and not skill.toggle and not trait_slot
	return 1.0 if works and (steady or (usable and (on or not skill.passive))) else 0.45


# Its icon's look (Skill.LOOK_*): disabled, or an untoggled toggle; zero is the plain one.
func icon_look() -> Vector2:
	if off > 0 or sealed or (bonus_why != "" and skill != null):
		return Skill.LOOK_DISABLED
	if shows_switch() and not on:
		return Skill.LOOK_UNTOGGLED
	return Vector2.ZERO


# A bonus slot's rim: dashes along its edge.
func _dashed_rim(col: Color) -> void:
	var r := Rect2(Vector2(0.5, 0.5), size - Vector2.ONE)
	for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
		draw_dashed_line(edge[0], edge[1], col, 1.0, 3.0)


# Whether the slot shows the on/off dot: a toggled passive only.
func shows_switch() -> bool:
	return skill != null and skill.passive and skill.toggle


func set_exhausted(n: float) -> void:
	if not is_equal_approx(n, exhausted):
		exhausted = n
		queue_redraw()


# The exhausted skill's pips: a dot per use counted against it (a smaller one for a half), along the
# slot's bottom edge from the left.
func _pips() -> void:
	var whole := floori(exhausted + 0.0001)
	var x := 16.0
	for i in mini(whole, 6):
		draw_circle(Vector2(x, size.y - 1.5), 1.1, Color("#ff9a5e"))
		x += 3.0
	if exhausted - whole > 0.25:
		draw_circle(Vector2(x, size.y - 1.5), 0.7, Color("#ff9a5e"))


# A small padlock centred on at.
func _lock(at: Vector2) -> void:
	var col := Color(1, 1, 1, 0.45)
	draw_arc(at + Vector2(0, -1.5), 1.6, PI, TAU, 6, col, 1.0)
	draw_rect(Rect2(at + Vector2(-2.5, -1.5), Vector2(5, 4)), col)


func _key() -> String:
	return str((index + 1) % 10)


# How many slots tall it is drawn now (SlotColumns lays a skill that takes several as one tall button over them): 1 for most.
func rows() -> int:
	return maxi(1, roundi((size.y + SlotColumns.GAP) / (ROW + SlotColumns.GAP)))


# The slot under y (in this control): its own for a plain one, else the slot of the span it's over: a tall button answers
# for every slot it covers, so a drop, a right-click or a tooltip there is as on that slot.
func slot_at(y: float) -> int:
	var n := rows()
	return index + clampi(floori(y / (ROW + SlotColumns.GAP)), 0, n - 1)


# The font size a name of width w (at 7) takes in room: 7, shrunk (down to 4) to fit rather than cut ("Starpower Generator").
static func name_font(w: float, room: float) -> int:
	return 7 if w <= room else clampi(floori(7.0 * room / w), 4, 7)


# The width its content wants (a column of slots is this wide, or the names are cut): the key, icon, whole name, numeral, a
# switch's dot and an item's ring, as _draw() lays them out. 0 until it's in the tree (no font yet) or holds nothing.
func want_width() -> float:
	var font := get_theme_font(&"font")
	if not skill or not font or sense == 0:
		return 0.0
	var w := 16.0 + 3.0
	if skill.icon():
		w += ROW - 4.0 + 1.0
	w += font.get_string_size(label if label else skill.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	if sense == 2:
		w += font.get_string_size(Skill.roman(rank), HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x + 2.0
		w += 5.0 if lent != "" else 0.0
	w += 6.0 if shows_switch() else 0.0
	return ceilf(w)


# What its tooltip leads with: its number key, or for a band slot with none "Trait" (a trait) or "Free" (a free lend).
func _tag() -> String:
	if keyed():
		return "[%s]" % _key()
	return "Trait" if not skill or skill.is_trait() else "Free"


# Whether it has a number key: every hotbar slot, and a band slot whose skill is cast or switched (not muted()).
func keyed() -> bool:
	return not trait_slot or (skill != null and not muted(skill))


func _get_drag_data(_at: Vector2) -> Variant:
	if not skill or not editable:
		return null
	_dragging = true
	set_drag_preview(chip(skill, theme_of(self)))
	return {skill = skill, from = index}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return editable and data is Dictionary and data.get("skill") is Skill and (holder.slot_cost(data.skill) > 0 if holder else data.skill.fits_bar())


func _drop_data(at: Vector2, data: Variant) -> void:
	dropped.emit(slot_at(at.y), data.skill, data.from)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		if not get_viewport().gui_is_drag_successful():
			cleared.emit(index)  # dropped off the bar


func _on_gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and (skill or cover) and editable:
		cleared.emit(slot_at(e.position.y))
		accept_event()


# The theme a control draws with: its own, or the nearest ancestor's (for drag previews, which
# live outside the HUD).
# A skill dragged out of the skills screen (SkillWheel, SkillGrid) to equip it: one u has (learned or
# lent) that goes on the bar. Null for anything else.
static func drag_learned(from: Control, u: Unit, s: Skill) -> Variant:
	if not u or not s or u.base_rank(s) == 0 or u.slot_cost(s) == 0:
		return null
	from.set_drag_preview(chip(s, theme_of(from)))
	return {skill = s, from = -1}


static func theme_of(n: Node) -> Theme:
	while n:
		if n is Control and n.theme:
			return n.theme
		n = n.get_parent()
	return null


# Its tooltips are Glossary markup, shown rich.
func _make_custom_tooltip(for_text: String) -> Object:
	return Glossary.tooltip(for_text)
