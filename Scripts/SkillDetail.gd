class_name SkillDetail
extends VBoxContainer

# What a skill is, wherever it's looked at - the skills screen's footer and the spellbook's: its name
# and rank, where it stands for the unit (its tier, learned, what it needs), its spec as chips (target,
# range, AP, cost - the same order on every skill), what it does in Glossary markup (terms, offense and
# defense mods, rank in colour), and on the skills screen its Unlock or Rank up button with the cost in
# a square, lit when it can be bought. A term clicked opens the Guide on it.

signal acted  # its button pressed (SkillTree._act())

var unit: Unit
var title_label: Label
var state_label: Label
var act: CostButton
var spec: HBoxContainer
var text_label: RichTextLabel


func _init() -> void:
	add_theme_constant_override(&"separation", 1)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 6)
	add_child(head)
	title_label = Label.new()
	title_label.theme_type_variation = &"Title"
	head.add_child(title_label)
	state_label = Label.new()
	state_label.size_flags_horizontal = SIZE_EXPAND_FILL
	state_label.size_flags_vertical = SIZE_SHRINK_CENTER
	state_label.theme_type_variation = &"Muted"
	state_label.add_theme_color_override(&"font_color", Color(0.91, 0.77, 0.28))
	state_label.clip_text = true
	head.add_child(state_label)
	act = CostButton.new()
	act.pressed.connect(acted.emit)
	head.add_child(act)
	spec = HBoxContainer.new()
	spec.add_theme_constant_override(&"separation", 2)
	add_child(spec)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 32)
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	text_label = RichTextLabel.new()
	text_label.size_flags_horizontal = SIZE_EXPAND_FILL
	text_label.add_theme_color_override(&"default_color", Color(0.604, 0.627, 0.682))
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.meta_clicked.connect(_term)
	scroll.add_child(text_label)


# s as u stands with it. can_spend: its button may buy it (the skills screen, for a party member);
# offers false: no button at all (the spellbook).
func show_skill(u: Unit, s: Skill, can_spend: bool, offers := true) -> void:
	unit = u
	visible = s != null
	if not s:
		return
	var r := u.base_rank(s)
	title_label.text = s.title() + (" " + Skill.roman(r) if r else "")
	state_label.text = SkillDetail.state(u, s)
	_fill_spec(s)
	text_label.text = Glossary.rich(s.plan if s.stub else s.markup(maxi(r, 1), false))
	act.visible = offers and not s.stub and (r == 0 or u.can_raise(s))
	var cost := u.raise_cost(s)
	var why := ""
	if not can_spend:
		why = "Only your party's skills can be chosen"
	elif r == 0 and u.missing(s) != "":
		why = u.missing(s)
	elif u.skill_points < cost:
		why = "Needs %d skill point%s" % [cost, "" if cost == 1 else "s"]
	act.set_offer("Unlock" if r == 0 else "Rank %s" % Skill.roman(r + 1), cost)
	act.disabled = why != ""
	act.tooltip_text = why if why else ("Learn %s for %d point%s" % [s.name, cost, "" if cost == 1 else "s"] if r == 0
			else "Raise %s to rank %s for %d points" % [s.name, Skill.roman(r + 1), cost])


# Tree t of choice c, offered to u to pick (a click on its root in the choice's box).
func show_tree(u: Unit, c: TreeChoice, t: SkillTab, can_spend: bool) -> void:
	unit = u
	visible = true
	title_label.text = t.title()
	var why := u.pick_missing(c, t)
	state_label.text = "T0 · " + (why if why else "%s: pick up to %d" % [c.name, u.pick_cap(c)])
	for x in spec.get_children():
		x.queue_free()
	var text := SkillTree.opens(t)
	if c.affinity:
		text += "\nA guest tree: its skills rank at %+d Affinity" % c.affinity
	text_label.text = Glossary.rich(text)
	act.visible = why != "Picked"
	if not can_spend:
		why = "Only your party's skills can be chosen"
	act.set_offer("Pick", 0)
	act.disabled = why != ""
	act.tooltip_text = why if why else "Pick %s: its tab opens" % t.title()


# Where s stands for u, in a line: its tier, then learned (or at its highest rank), or what it needs.
# Nothing more when it can be learned now: the button says so.
static func state(u: Unit, s: Skill) -> String:
	var tier := "T%d" % u.tier(s)
	if s.stub:
		return tier + " · Not built yet. " + s.waits()
	var r := u.base_rank(s)
	if r > 0:
		return tier + (" · Learned" if u.can_raise(s) else " · Highest rank")
	var why := u.missing(s)
	return tier + (" · " + why if why else "")


func _fill_spec(s: Skill) -> void:
	for c in spec.get_children():
		spec.remove_child(c)
		c.queue_free()
	for part in s.spec():
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.scroll_active = false
		l.add_theme_font_size_override(&"normal_font_size", 6)
		l.text = Glossary.rich(Skill.spec_part(part))
		l.meta_clicked.connect(_term)
		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.06)
		style.set_corner_radius_all(2)
		style.content_margin_left = 3
		style.content_margin_right = 3
		chip.add_theme_stylebox_override(&"panel", style)
		chip.add_child(l)
		spec.add_child(chip)


# A term clicked: the Guide's page for it.
func _term(meta: Variant) -> void:
	var id := StringName(String(meta).trim_prefix("term:"))
	get_tree().call_group(&"guide", &"open_guide", Glossary.page(id), id)
