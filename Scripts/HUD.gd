class_name HUD
extends CanvasLayer

# The player's side of a battle. Click a unit to select it. With a unit that takes orders selected,
# hover a tile to plan a move and click to walk there, or press a hotbar number (or click the slot)
# to arm a skill, then click its target; a toggled passive switches instead. B opens the spellbook,
# H holds an ally where it is, P invites it to the party (or lets it go), Tab steps through units
# taking orders, Space ends the turn, Esc or right-click backs out. Command decides who takes
# orders. Allies left without orders act on their own as the turn ends, and other sides play
# themselves, paced so they can be followed. What's shown of other sides is what the player's units
# can make out (Perception), never more.

const NOWHERE := Vector2i(-9999, -9999)
const GOLD := Color("#e8c547")
const MUTED := Color("#9aa0ae")
const FOE := Color("#ff6b5e")
const FRIEND := Color("#6fdc8c")
const AP_COLOR := Color("#7cc4ff")
const MOVE_COLOR := Color("#b8c0cc")

@export var battle: Battle
@export var auto := true  # sides the player doesn't run play themselves
@export var pace := 0.45  # seconds between units acting on their own
@export_file("*.tscn") var menu_scene := "res://Scenes/entry.tscn"

var command: Command
var selected: Unit
var armed: Skill  # waiting for a target
var hover := NOWHERE
var busy := false  # units are acting on their own; the player waits
var plan := {}  # the hovered move, as the selected unit expects it (Battle.walk)
var reach: Dictionary[Vector2i, bool] = {}  # tiles the selected unit expects to reach
var round_no := 0
var overlay: Overlay
var _last_turn := 999  # order index of the previous turn, for counting rounds
var _dirty := true
var _note := ""  # a passing message for the hint line ("Out of reach")
var _mouse := Vector2.ZERO  # last pointer position, in screen (HUD) space

@onready var card: UnitCard = %Card
@onready var bar: VBoxContainer = %Hotbar
@onready var book_button: Button = %BookButton
@onready var hold_button: Button = %HoldButton
@onready var party_button: Button = %PartyButton
@onready var hint: Label = %Hint
@onready var round_label: Label = %Round
@onready var turn_label: Label = %Turn
@onready var order_list: VBoxContainer = %Order
@onready var party_title: Label = %PartyTitle
@onready var roster: VBoxContainer = %Roster
@onready var reach_label: Label = %Reach
@onready var log_box: RichTextLabel = %Log
@onready var end_button: Button = %EndTurn
@onready var banner: Label = %Banner
@onready var tip: PanelContainer = %Tip
@onready var tip_label: Label = %TipLabel
@onready var spellbook: Spellbook = %Spellbook
@onready var over: PanelContainer = %Over


static func shade(c: Color) -> Color:
	return c.lerp(Color.WHITE, 0.35)  # faction colours, lifted to read on dark panels


func _ready() -> void:
	command = Command.new(battle, battle.player if battle.player else _stand_in())
	overlay = Overlay.new()
	overlay.hud = self
	battle.add_child(overlay)
	battle.move_child(overlay, battle.map.get_index() + 1)
	overlay.top = Node2D.new()
	overlay.top.z_index = 10
	battle.add_child(overlay.top)
	battle.turn_changed.connect(_on_turn, CONNECT_DEFERRED)
	battle.phase_changed.connect(_on_phase, CONNECT_DEFERRED)
	battle.traveled.connect(overlay.walk)
	battle.used.connect(_on_used)
	battle.sprung.connect(_on_sprung)
	for u: Unit in battle.get_node("Units").get_children():
		u.hp_changed.connect(_on_hp.bind(u))
		u.energy_changed.connect(_mark.unbind(2))
		u.reserve_changed.connect(_mark.unbind(3))
		u.died.connect(_on_died)
	book_button.pressed.connect(toggle_spellbook)
	hold_button.pressed.connect(hold)
	party_button.pressed.connect(toggle_party)
	end_button.pressed.connect(end_turn)
	spellbook.switched.connect(func(s: Skill): switch(spellbook.unit, s))
	%MenuButton.pressed.connect(func(): get_tree().change_scene_to_file(menu_scene))
	banner.modulate.a = 0.0
	for c: Control in [tip, spellbook, over]:
		c.hide()
	if not battle.rolls.is_empty():
		_log("[color=#6b7180]Initiative: %s[/color]" % ", ".join(battle.order.map(
				func(f: Faction): return "%s %d" % [f.name, battle.total(f)])))
	_log("You lead %s." % _tag(command.leader))
	_rebuild_bar()
	if battle.phase == Battle.Phase.TURNS:
		_on_turn.call_deferred(null, battle.turn)
	elif battle.phase == Battle.Phase.OVER:
		_on_phase.call_deferred(Battle.Phase.TURNS, Battle.Phase.OVER)


func _exit_tree() -> void:
	if is_instance_valid(overlay):
		overlay.top.queue_free()
		overlay.queue_free()


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_refresh()
	if hover != NOWHERE and get_viewport().gui_get_hovered_control():
		hover_cell(NOWHERE)  # the mouse went over a panel
	if tip.visible:
		var room := tip.get_viewport_rect().size - tip.size
		tip.position = Vector2(minf(_mouse.x + 10, room.x - 2), minf(_mouse.y + 10, room.y - 2))


func _input(e: InputEvent) -> void:
	if e is InputEventMouse:
		_mouse = e.position


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover_cell(_cell_at(e.position))
		return
	if e is InputEventMouseButton:
		if not e.pressed or e.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return
		if spellbook.visible:
			spellbook.hide()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			click(_cell_at(e.position))
		else:
			cancel()
		get_viewport().set_input_as_handled()
		return
	if not e.is_pressed() or e.is_echo():
		return
	if e.is_action_pressed(&"cancel"):
		cancel()
	elif e.is_action_pressed(&"spellbook"):
		toggle_spellbook()
	elif e.is_action_pressed(&"end_turn"):
		end_turn()
	elif e.is_action_pressed(&"hold"):
		hold()
	elif e.is_action_pressed(&"party"):
		toggle_party()
	elif e.is_action_pressed(&"next_unit"):
		next_unit()
	else:
		var i := _slot_key(e)
		if i < 0:
			return
		use_slot(i)
	get_viewport().set_input_as_handled()


func _slot_key(e: InputEvent) -> int:
	for i in bar.get_child_count():
		var action := "hotbar_%d" % (i + 1)
		if InputMap.has_action(action) and e.is_action_pressed(action):
			return i
	return -1


# The map cell under a point on screen (event positions, not the OS cursor: input can be synthetic).
func _cell_at(p: Vector2) -> Vector2i:
	var world := battle.get_viewport().get_canvas_transform().affine_inverse() * p
	var c := battle.map.local_to_map(battle.map.to_local(world))
	return c if battle.on_map(c) else NOWHERE


# --- What the player can do

func select(u: Unit) -> void:
	selected = u if u and u.is_alive() else null
	armed = null
	_note = ""
	_rebuild_bar()
	_replan()
	_mark()


func click(c: Vector2i) -> void:
	if c == NOWHERE:
		return
	if armed:
		_use_on(c)
		return
	var u := unit_seen(c)
	if u:
		select(u)
	elif selected and known(selected) and battle.turn == command.faction():
		if _orders(selected):
			_move(selected, c)
		else:
			_say(_why_no_orders(selected))
	else:
		select(null)


func hover_cell(c: Vector2i) -> void:
	if c == hover:
		return
	hover = c
	_replan()
	_update_tip()


# A hotbar slot's key or click: arms an active (again: disarms it), switches a toggled passive.
func use_slot(i: int) -> void:
	var u := selected
	if not u or not known(u) or i < 0 or i >= u.hotbar.size() or not u.hotbar[i]:
		return
	var s: Skill = u.hotbar[i]
	if not _orders(u):
		_say(_why_no_orders(u))
	elif s.passive:
		switch(u, s)
	elif armed == s:
		disarm()
	elif not u.can_afford(s):
		_say(_short(u, s))
	else:
		armed = s
		_note = ""
		_replan()
		_mark()


func disarm() -> void:
	armed = null
	_replan()
	_mark()


func switch(u: Unit, s: Skill) -> void:
	if not _orders(u) or not u.toggle(s):
		return
	_log("%s: %s %s" % [_tag(u), s.name, "on" if u.is_on(s) else "off"])
	_mark()


func cancel() -> void:
	if spellbook.visible:
		spellbook.hide()
	elif armed:
		disarm()
	else:
		select(null)


func hold() -> void:
	var u := selected
	if not u or u == command.leader or not _orders(u) or u in command.ordered:
		return
	command.order(u)
	_log("%s holds." % _tag(u))
	_mark()


func toggle_party() -> void:
	var u := selected
	if not u or u == command.leader or not my_turn():
		return
	if u in command.party:
		command.leave(u)
		_log("%s leaves your party." % _tag(u))
	elif command.join(u):
		_log("%s joins your party." % _tag(u))
	else:
		_say(_why_no_join(u))
	_mark()


# Tab: the next unit that can still take an order this turn.
func next_unit() -> void:
	var pool := battle.members(command.faction()).filter(func(u: Unit): return _orders(u) and u not in command.ordered)
	if pool.is_empty():
		return
	select(pool[(pool.find(selected) + 1) % pool.size()])


func toggle_spellbook() -> void:
	_mark()
	if spellbook.visible:
		spellbook.hide()
		return
	if not (selected and known(selected)):
		select(command.leader if command.leader.is_alive() else observer())
	if selected:
		_open_book()


func end_turn() -> void:
	if not my_turn():
		return
	spellbook.hide()
	_act_alone(command.faction(), command.idle())


func my_turn() -> bool:
	return not busy and battle.phase == Battle.Phase.TURNS and command.leader.is_alive() \
			and battle.turn == command.faction()


# Units on the player's side: everything about them is known.
func known(u: Unit) -> bool:
	return u.faction == command.faction()


# Whose eyes the player sees through: the leader, or once it falls, any ally still standing.
func observer() -> Unit:
	if command.leader.is_alive():
		return command.leader
	var allies := battle.members(command.faction())
	return allies[0] if allies else null


# The unit at c, if the player's side can make out that something's there.
func unit_seen(c: Vector2i) -> Unit:
	var u := battle.unit_at(c)
	if not u or known(u):
		return u
	var o := observer()
	return u if o and battle.read(o, u).located() else null


# Units the armed skill could be used on, as far as the player can tell.
func targets() -> Array[Unit]:
	var out: Array[Unit] = []
	if selected and armed and not armed.zone:
		for t: Unit in battle.units.values():
			if unit_seen(t.cell) == t and why_not(selected, armed, t) == "":
				out.append(t)
	return out


# Why using s on target (a Unit, or a cell for area skills) wouldn't work, as far as the player can
# tell; "" if it looks like it would.
func why_not(u: Unit, s: Skill, target: Variant) -> String:
	if target is Unit:
		if not target.is_alive():
			return "Already fallen"
		var ally: bool = target.faction == u.faction if known(target) else _reads_as_ally(target)
		if s.hostile and ally:
			return "%s is for foes" % s.name
		if not s.hostile and not ally:
			return "%s is for allies" % s.name
		if not battle.in_reach(u, s, target):
			return "Out of reach"
	elif target is Vector2i:
		if not battle.on_map(target) or Vector2(u.cell).distance_to(Vector2(target)) > battle.area_reach(u, s) + 0.0001:
			return "Out of reach"
	else:
		return "Pick a unit"
	return _short(u, s) if not u.can_afford(s) else ""


# --- Acting

func _use_on(c: Vector2i) -> void:
	var u := selected
	var s := armed
	if not _orders(u):
		disarm()
		return
	var target: Variant = c if s.zone else unit_seen(c)
	var why := why_not(u, s, target)
	if why == "Pick a unit" or why == "Out of reach" or why == "Already fallen":
		_say(why)
		return
	if not (battle.cast_at(u, s, c) if s.zone else battle.cast(u, s, target)):
		_say(why if why else "%s doesn't take" % s.name)
		return
	command.order(u)
	armed = null
	_note = ""
	_replan()
	_mark()


func _move(u: Unit, c: Vector2i) -> void:
	if c == u.cell:
		return
	if battle.travel(u, c).is_empty():
		_say("Can't get any closer" if u.move_left() > 0.0001 else "No movement left this turn")
		return
	command.order(u)
	_note = ""
	_replan()
	_mark()


# Units acting on their own (AI), one at a time so it can be followed; then f's turn ends.
func _act_alone(f: Faction, units: Array[Unit]) -> void:
	busy = true
	armed = null
	plan = {}
	_mark()
	for u in units:
		if battle.phase != Battle.Phase.TURNS or battle.turn != f:
			break
		if not u.is_alive():
			continue
		if pace > 0.0:
			await get_tree().create_timer(pace).timeout
			if not is_inside_tree():
				return
		select(u if unit_seen(u.cell) == u else null)
		AI.act(battle, u)
		_mark()
	if pace > 0.0 and battle.phase == Battle.Phase.TURNS:
		await get_tree().create_timer(pace).timeout
		if not is_inside_tree():
			return
	busy = false
	_mark()
	if battle.phase == Battle.Phase.TURNS and battle.turn == f:
		battle.end_turn()


# --- Battle events

func _on_turn(_was: Faction, now: Faction) -> void:
	if battle.phase != Battle.Phase.TURNS or now != battle.turn:
		return  # stale: the turn moved on before this ran
	var i := battle.order.find(now)
	if i <= _last_turn:
		round_no += 1
	_last_turn = i
	var mine := now == command.faction() and command.leader.is_alive()
	_log("[color=#6b7180]Round %d · %s[/color]" % [round_no, now.name])
	_banner("Your turn" if mine else "%s's turn" % now.name, GOLD if mine else shade(now.primary))
	if mine:
		command.new_turn()
		select(command.leader)
	elif auto:
		_act_alone(now, battle.members(now))
	_mark()


func _on_phase(_was: Battle.Phase, now: Battle.Phase) -> void:
	if now != Battle.Phase.OVER:
		return
	var left := battle.units.values()
	var winner: Faction = left[0].faction if left else null
	%OverTitle.text = "Victory" if winner == command.faction() else "Defeat"
	%OverText.text = "%s holds the field." % winner.name if winner else "No one is left standing."
	_log("[color=#e8c547]%s[/color]" % %OverText.text)
	spellbook.hide()
	select(null)
	over.show()
	_mark()


func _on_used(caster: Unit, skill: Skill, at: Variant, dealt: int) -> void:
	var text := "%s uses %s %s" % [_tag(caster), skill.name, Skill.roman(caster.rank(skill))]
	if at is Unit and at != caster:
		text += " on " + _tag(at)
	if dealt > 0:
		text += " [color=#ff6b5e]-%d[/color]" % dealt
	_log(text)
	_mark()


func _on_sprung(_c: Vector2i, by: Unit) -> void:
	overlay.float_text(by, "Trap!", GOLD)
	_log("A trap springs under %s!" % _tag(by))


func _on_hp(was: int, now: int, u: Unit) -> void:
	if now < was:
		overlay.float_text(u, "-%d" % (was - now), FOE)
	elif now > was:
		overlay.float_text(u, "+%d" % (now - was), FRIEND)
	_mark()


func _on_died(u: Unit) -> void:
	command.leave(u)
	overlay.fade(u)
	_log("%s falls." % _tag(u))
	if u == selected:
		select(null)
	if u == command.leader:
		_banner("%s has fallen" % _name(u), FOE)
		_log("Your allies fight on alone.")
		if auto and battle.phase == Battle.Phase.TURNS and battle.turn == command.faction() and not busy:
			_act_alone.call_deferred(command.faction(), command.idle())
	_mark()


# --- Showing it

func _mark() -> void:
	_dirty = true


func _refresh() -> void:
	_find_reach()
	card.set_info(_info(selected) if selected else {})
	_refresh_bar()
	_refresh_buttons()
	_refresh_side()
	if spellbook.visible:
		if selected and known(selected):
			_open_book()
		else:
			spellbook.hide()
	_update_tip()


func _open_book() -> void:
	spellbook.open(selected, _name(selected), _editable(selected), _orders(selected))


func _rebuild_bar() -> void:
	var n := selected.bar_size() if selected and known(selected) else Unit.HOTBAR
	if bar.get_child_count() == n:
		return
	for c in bar.get_children():
		bar.remove_child(c)
		c.queue_free()
	for i in n:
		var s := SkillSlot.new()
		s.index = i
		s.pressed.connect(use_slot.bind(i))
		s.dropped.connect(_on_dropped)
		s.cleared.connect(_on_cleared)
		bar.add_child(s)


func _refresh_bar() -> void:
	var u := selected if selected and known(selected) else null
	bar.visible = u != null or not selected  # other sides' skills aren't the player's to see
	%BarTitle.visible = bar.visible
	var orders := u != null and _orders(u)
	var edit := u != null and _editable(u)
	for slot: SkillSlot in bar.get_children():
		var i := slot.index
		var s: Skill = u.hotbar[i] if u and i < u.hotbar.size() else null
		var usable := orders and s != null and (s.passive or u.can_afford(s))
		slot.set_state(i, s, u.rank(s) if s else 0, s != null and s == armed, s != null and u.is_on(s), usable, edit)


func _on_dropped(i: int, s: Skill, _from: int) -> void:
	if selected and _editable(selected):
		if not selected.bar_place(s, i):
			_say("%s doesn't know %s" % [_name(selected), s.name])
		_mark()


func _on_cleared(i: int) -> void:
	if selected and _editable(selected):
		if armed and selected.hotbar[i] == armed:
			armed = null
		selected.bar_clear(i)
		_mark()


func _refresh_buttons() -> void:
	var u := selected
	hold_button.disabled = not (u and u != command.leader and _orders(u) and u not in command.ordered)
	var member := u != null and u in command.party
	party_button.text = "Dismiss" if member else "Invite"
	party_button.disabled = not (u and my_turn() and (member or command.can_join(u)))
	party_button.tooltip_text = "Let %s go from your party (P)" % _name(u) if member else \
			"Invite the selected ally to your party (P)\n%s" % (_why_no_join(u) if u else "Select an ally first")
	hint.text = _note if _note else _hint()
	hint.add_theme_color_override(&"font_color", GOLD if _note else MUTED)
	end_button.disabled = not my_turn()


func _hint() -> String:
	if battle.phase == Battle.Phase.OVER:
		return "The battle is over."
	if not command.leader.is_alive():
		return "Your leader has fallen; your allies fight on."
	if busy:
		return "%s acting..." % ("Your allies are" if battle.turn == command.faction() else battle.turn.name + " is")
	if battle.turn != command.faction():
		return "Waiting for %s." % battle.turn.name
	var u := selected
	if not u:
		return "Click a unit to select it. Tab steps through units taking orders."
	if armed:
		return "Click a target for %s. Esc or right-click cancels." % armed.name
	if _orders(u):
		return "Hover a tile to plan, click to move. Keys 1-%d use skills." % u.bar_size()
	if known(u):
		return "Too far to hear you. Bring %s within %s." % [_name(command.leader),
				_tiles(command.party_reach() if u in command.party else float(command.reach()))]
	return "What %s can make out." % _name(observer()) if observer() else ""


func _refresh_side() -> void:
	round_label.text = "Round %d" % maxi(round_no, 1)
	var mine := battle.turn == command.faction() and command.leader.is_alive()
	if battle.phase == Battle.Phase.OVER:
		turn_label.text = "Battle over"
		turn_label.add_theme_color_override(&"font_color", MUTED)
	elif battle.turn:
		turn_label.text = "Your turn" if mine else "%s's turn" % battle.turn.name
		turn_label.add_theme_color_override(&"font_color", GOLD if mine else shade(battle.turn.primary))
	_clear(order_list)
	for f in battle.order:
		var l := Label.new()
		l.theme_type_variation = &"Muted"
		l.text = "%s %s  %d" % ["•" if f == battle.turn else " ", f.name, battle.total(f) if f in battle.rolls else 0]
		l.add_theme_color_override(&"font_color", shade(f.primary) if f == battle.turn else MUTED)
		l.tooltip_text = "Initiative: the side's d20s plus its best bonus"
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		order_list.add_child(l)
	party_title.text = "PARTY  %d/%d" % [command.party.size(), command.party_size()]
	_clear(roster)
	for u in [command.leader] + command.party:
		var b := Button.new()
		b.text = _name(u)
		b.icon = u.sprite.sprite_frames.get_frame_texture(&"default", 0)
		b.expand_icon = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 14
		b.clip_text = true
		b.disabled = not u.is_alive()
		b.tooltip_text = "%s · HP %d/%d\n%s" % [_name(u), u.hp, u.max_hp, "Leader" if u == command.leader else
				"Party member: hears orders from %s" % _tiles(command.party_reach())]
		b.pressed.connect(select.bind(u))
		var hp := ProgressBar.new()
		hp.show_percentage = false
		hp.max_value = u.max_hp
		hp.value = u.hp
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hp)
		hp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hp.offset_left = 3
		hp.offset_right = -3
		hp.offset_top = -3
		hp.offset_bottom = -2
		roster.add_child(b)
	if command.party.size() < command.party_size():
		var l := Label.new()
		l.theme_type_variation = &"Muted"
		l.text = "Select an ally nearby and press P to invite it."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		roster.add_child(l)
	reach_label.text = "Orders reach %s; party %s." % [_tiles(command.reach()), Skill.num(command.party_reach())]


static func _tiles(n: float) -> String:
	return "%s %s" % [Skill.num(n), "tile" if is_equal_approx(n, 1.0) else "tiles"]


func _clear(box: Container) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _info(u: Unit) -> Dictionary:
	var info := {look = u.sprite.sprite_frames.get_frame_texture(&"default", 0)}
	var chips := []
	if known(u):
		info.name = _name(u)
		var kind := " ".join([u.race.name if u.race else "", u.role.name if u.role else ""]).strip_edges()
		info.sub = "Lv %d %s" % [u.level, kind if kind else ", ".join(u.tags)]
		if u == command.leader:
			chips.append(["Leader", GOLD])
		elif u in command.party:
			chips.append(["Party", GOLD])
		else:
			chips.append(["Ally", shade(u.faction.primary)])
		if battle.turn == command.faction() and battle.phase == Battle.Phase.TURNS and u != command.leader:
			if u in command.ordered:
				chips.append(["Ordered", MUTED])
			elif command.can_order(u):
				chips.append(["Takes orders", FRIEND])
			else:
				chips.append(["Out of range", MUTED])
		var rows := [["HP", u.hp, u.max_hp, Unit.HP_COLOR]]
		var main := u.main_reserve()
		if main:
			rows.append([main.name.left(2).to_upper(), u.store(main), u.reserves[main], main.color])
		rows.append(["EN", u.energy, u.max_energy, Unit.ENERGY_COLOR])
		rows.append(["AP", u.ap_left(), u.full_ap(), AP_COLOR])
		rows.append(["MV", maxf(u.move_left(), 0.0), u.stat(&"movement"), MOVE_COLOR])
		info.rows = rows
	else:
		var o := observer()
		var r: Read = battle.read(o, u) if o else Read.new()
		info.name = r.name if r.name else "Unknown"
		var parts: PackedStringArray = []
		if r.level != null:
			parts.append("Lv %d" % r.level)
		if r.role:
			parts.append(r.role.name)
		elif not r.tags.is_empty():
			parts.append(" ".join(r.tags.map(func(t): return String(t).capitalize())))
		if not parts:
			parts.append(r.hint.capitalize() if r.hint else ("Kind unknown" if r.name else "Hard to make out"))
		info.sub = " ".join(parts)
		if r.faction == null:
			chips.append(["Unknown", MUTED])
		elif r.faction == command.faction():
			chips.append(["Friendly", FRIEND])
		else:
			chips.append(["Enemy", FOE])
		if r.vibe:
			chips.append([r.vibe, MUTED])
		var rows := []
		if r.hp != null:
			rows.append(["HP", r.hp, r.max_hp, Unit.HP_COLOR])
		elif r.healthy != null:
			rows.append(["HP", "Healthy" if r.healthy else "Bloodied", null, Unit.HP_COLOR if r.healthy else FOE])
		else:
			rows.append(["HP", "?", null, MUTED])
		if r.energy != null:
			rows.append(["EN", r.energy, null, Unit.ENERGY_COLOR])
		info.rows = rows
	info.chips = chips
	return info


func _update_tip() -> void:
	var text := "" if spellbook.visible else _tip_text()
	tip.visible = text != ""
	if tip.visible:
		tip_label.text = text
		tip.reset_size()


func _tip_text() -> String:
	if hover == NOWHERE:
		return ""
	var u := unit_seen(hover)
	if armed and selected:
		var target: Variant = hover if armed.zone else u
		var why := why_not(selected, armed, target)
		var head := armed.name + (" on " + _name(u) if u and not armed.zone else "")
		return "%s\n%s" % [head, why if why else _forecast(selected, armed)]
	if u:
		return _unit_line(u)
	var o := observer()
	var r: Read = battle.read(o, hover) if o else Read.new()
	var text: String = r.name if r.name else "Unknown ground"
	if r.cost != null:
		text += " · %d move" % r.cost
	if r.hint:
		text += "\n" + r.hint
	if not plan.is_empty():
		var cost: float = plan.costs.reduce(func(sum, x): return sum + x, 0.0)
		var path: Array = plan.path
		if path.is_empty():
			text += "\nCan't get closer"
		elif path[-1] == hover:
			text += "\nWalk here: %s of %s" % [Skill.num(cost), Skill.num(selected.move_left())]
		else:
			text += "\nStops %d short (%s move)" % [plan.line.size() - path.size(), Skill.num(cost)]
	return text


func _unit_line(u: Unit) -> String:
	if known(u):
		return "%s\nHP %d/%d" % [_name(u), u.hp, u.max_hp]
	var o := observer()
	var r: Read = battle.read(o, u) if o else Read.new()
	var text: String = r.name if r.name else "Something"
	if r.hp != null:
		text += "\nHP %d/%d" % [r.hp, r.max_hp]
	elif r.healthy != null:
		text += "\n" + ("Healthy" if r.healthy else "Bloodied")
	if r.vibe:
		text += "\n" + r.vibe
	return text


# What using s would cost and roughly do (before mitigation and luck).
func _forecast(u: Unit, s: Skill) -> String:
	var fund: Variant = u.funding(s)
	var text := "%s AP" % Skill.num(u.ap_cost(s, fund))
	if s.cost:
		text += ", %d %s" % [s.cost, fund.name if fund is Reserve else "energy"]
	var t := s.tier(u.rank(s))
	if t:
		var hits := u.rank(s) if s.hits_per_rank else 1
		var bonus := u.mod(t.stat, s.tags) if t.stat else 0
		var lo := maxi(t.power + t.dice.x + bonus, 0) * hits
		var hi := maxi(t.power + t.dice.x * t.dice.y + bonus, 0) * hits
		text += " · %s damage" % (str(lo) if lo == hi else "%d-%d" % [lo, hi])
	return "Click to use: " + text


# --- Rules of thumb for the player

func _orders(u: Unit) -> bool:
	return u != null and my_turn() and command.can_order(u)


func _editable(u: Unit) -> bool:
	return u != null and known(u) and not busy and (command.ours(u) or command.can_order(u))


func _why_no_orders(u: Unit) -> String:
	if battle.phase != Battle.Phase.TURNS:
		return "The battle is over"
	if not known(u):
		return "Not yours to command"
	if not command.leader.is_alive():
		return "Your leader has fallen"
	if busy or battle.turn != command.faction():
		return "Wait for your turn"
	if not u.is_alive():
		return "Fallen"
	return "Too far: bring %s within %s" % [_name(command.leader),
			_tiles(command.party_reach() if u in command.party else float(command.reach()))]


func _why_no_join(u: Unit) -> String:
	if not known(u) or u == command.leader:
		return "Only allies can join"
	if command.party.size() >= command.party_size():
		return "Party full (%d/%d)" % [command.party.size(), command.party_size()]
	if Command.tiles(command.leader.cell, u.cell) > command.reach():
		return "Must be within %s of %s" % [_tiles(command.reach()), _name(command.leader)]
	return ""


func _short(u: Unit, s: Skill) -> String:
	return "Not enough %s for %s" % ["energy" if u.funding(s) == null else "AP", s.name]


func _reads_as_ally(t: Unit) -> bool:
	var o := observer()
	return o != null and battle.read(o, t).faction == command.faction()


func _find_reach() -> void:
	reach.clear()
	var u := selected
	if not u or armed or not _orders(u) or u.move_left() <= 0.0001:
		return
	for c in battle.map.get_used_cells():
		if c != u.cell and not unit_seen(c):
			var path: Array = battle.walk(u, c, true).path
			if not path.is_empty() and path[-1] == c:
				reach[c] = true


func _replan() -> void:
	plan = {}
	var u := selected
	if hover == NOWHERE or not u or armed or not _orders(u) or hover == u.cell or unit_seen(hover):
		return
	plan = battle.walk(u, hover, true)


# Without a starter (the scene run on its own) the player leads the highest-level unit.
func _stand_in() -> Unit:
	var best: Unit = null
	for u: Unit in battle.units.values():
		if best == null or u.level > best.level:
			best = u
	return best


func _name(u: Unit) -> String:
	if not u:
		return ""
	if known(u):
		return u.nick if u.nick else String(u.name)
	var o := observer()
	var r: Read = battle.read(o, u) if o else null
	return r.name if r and r.name else "Something"


# A name for the log, in its side's colour as far as the player can tell.
func _tag(u: Unit) -> String:
	var f: Faction = u.faction
	if not known(u):
		var o := observer()
		f = battle.read(o, u).faction if o else null
	var col := shade(f.primary) if f else MUTED
	return "[color=#%s]%s[/color]" % [col.to_html(false), _name(u).replace("[", "[lb]")]


func _log(text: String) -> void:
	log_box.append_text(text + "\n")


func _say(text: String) -> void:
	_note = text
	_mark()


func _banner(text: String, col: Color) -> void:
	banner.text = text
	banner.add_theme_color_override(&"font_color", col)
	var tw := banner.create_tween()
	banner.modulate.a = 0.0
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.9)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
