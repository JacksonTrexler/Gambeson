class_name HUD
extends CanvasLayer

# The player's side of a battle. Click a unit to select it. With a unit that takes orders selected,
# hover a tile to plan a move and click to walk there; click a foe to walk into reach and use the
# primary skill (slot 1) on it; or press a hotbar number (or click the slot) to arm a skill, then
# click its target. A toggled passive switches instead. Ctrl-click strikes at a tile whatever seems
# to be there - empty, or only suspected - and Shift-click selects a foe instead of attacking it.
# B opens the spellbook, S the skills (spending skill points), H holds an ally where it is, P invites
# it to the party (or lets it go), Tab steps through units taking orders, Space ends the turn, Esc or
# right-click backs out. The cog opens Settings, with a Guide to all this; nothing on screen
# explains it otherwise. Command decides who takes orders and which of their slots. Allies left
# without orders act on their own as the turn ends, and other sides play themselves, paced so they
# can be followed.
# Other sides are shown only as the player's units make them out (Perception, shared across the
# side): unlocated units aren't drawn, ones whose side can't be told are black shapes, and areas
# where something is only suspected are marked. Ground is judged the same way - safe, unsure (not
# made out, or something may lurk there) or bad (a known trap, or known detrimental) - which colours where a
# unit can walk, puts a '?' on move costs through unsure ground, and heads the tile pane, a corner
# panel with what's known of the hovered tile.

const NOWHERE := Vector2i(-9999, -9999)
const GOLD := Color("#e8c547")
const MUTED := Color("#9aa0ae")
const FOE := Color("#ff6b5e")
const FRIEND := Color("#6fdc8c")
const AP_COLOR := Color("#7cc4ff")
const MOVE_COLOR := Color("#b8c0cc")
const SLEEP := Color("#9db4ff")
const GROUND := {&"safe": Color("#7cc4ff"), &"unsure": Color("#f2c94c"), &"bad": Color("#a32424")}
const PANE_LIST := 34.0  # tallest the tile pane's effect list gets before it scrolls
# The effect list's auto-scroll, when it's too long to show: fade in, hold at the top, scroll down
# (slowest in the middle), hold at the bottom, fade out, and round again from the top.
const TRANSITION := 1.0  # seconds a turn change takes on screen (other sides wait it out)
const SCROLL_HOLD := 2.0  # seconds
const SCROLL_FADE := 0.35
const SCROLL_SPEED := 10.0  # average px a second while scrolling
const SCROLL_EASE := 0.7  # how much faster than average the ends go, and slower the middle

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
var reach: Dictionary[Vector2i, float] = {}  # tiles the selected unit expects to reach, and the cost
var charge := NOWHERE  # the hovered foe (or tile) a click would walk up to and attack
var marked: Array[Unit] = []  # what the armed skill could be used on
var dubious: Dictionary[Vector2i, String] = {}  # tiles where something is only suspected, and the hint
var sleepers: Array[Unit] = []  # units the player can see are asleep, as of the last refresh
var traps: Dictionary[Vector2i, bool] = {}  # traps the player's side knows of: true for ones it laid
var grounds: Dictionary[Vector2i, StringName] = {}  # ground() for every tile, as of the last refresh
var _icons := {}  # [source id, atlas coords] -> AtlasTexture, for the tile pane
var _pane_list := ""  # what the pane's effect list last showed (a new one scrolls from the start)
var _scroll_t := 0.0  # seconds into the effect list's auto-scroll
var _spinning: Array[Label] = []  # initiative dice still rolling
var _intro: Tween  # the initiative roll on screen
var _turn_show: Tween  # the turn change on screen

signal intro_done
var round_no := 0
var overlay: Overlay
var _last_turn := 999  # order index of the previous turn, for counting rounds
var _dirty := true
var _reach_of: Unit  # whose reach `reach` holds, until something changes
var _note := ""  # a passing message for the hint line ("Out of reach")
var _mouse := Vector2.ZERO  # last pointer position, in screen (HUD) space
var _roll := {}  # the attack roll the next used signal is for (_on_attacked())

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
@onready var log_box: RichTextLabel = %Log
@onready var end_button: Button = %EndTurn
@onready var banner: Label = %Banner
@onready var tip: PanelContainer = %Tip
@onready var tip_label: Label = %TipLabel
@onready var spellbook: Spellbook = %Spellbook
@onready var over: PanelContainer = %Over
@onready var pane: PanelContainer = %TilePane
@onready var skills: SkillTree = %Skills
@onready var settings: PanelContainer = %Settings


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
	overlay.top.draw.connect(overlay.draw_top)
	battle.add_child(overlay.top)
	battle.turn_changed.connect(_on_turn, CONNECT_DEFERRED)
	battle.phase_changed.connect(_on_phase, CONNECT_DEFERRED)
	battle.traveled.connect(overlay.walk)
	battle.traveled.connect(_mark.unbind(3))
	battle.attacked.connect(_on_attacked)
	battle.used.connect(_on_used)
	battle.sprung.connect(_on_sprung)
	for u: Unit in battle.get_node("Units").get_children():
		u.hp_changed.connect(_on_hp.bind(u))
		u.energy_changed.connect(_on_energy.bind(u))
		u.reserve_changed.connect(_mark.unbind(3))
		u.died.connect(_on_died)
	book_button.pressed.connect(toggle_spellbook)
	hold_button.pressed.connect(hold)
	party_button.pressed.connect(toggle_party)
	end_button.pressed.connect(end_turn)
	spellbook.switched.connect(func(s: Skill): switch(spellbook.unit, s))
	skills.unlocked.connect(_on_unlocked)
	skills.raised.connect(_on_raised)
	skills.leveled.connect(_on_leveled)
	%SkillsIcon.pressed.connect(toggle_skills)
	%BookIcon.pressed.connect(toggle_spellbook)
	%CogIcon.pressed.connect(toggle_settings)
	%SettingsClose.pressed.connect(_close_panels)
	%CharacterIcon.pressed.connect(_say.bind("The character sheet is coming soon"))
	%MenuButton.pressed.connect(func(): get_tree().change_scene_to_file(menu_scene))
	banner.modulate.a = 0.0
	for c: Control in [tip, spellbook, skills, settings, over]:
		c.hide()
	if not battle.rolls.is_empty():
		_log("[color=#6b7180]Initiative: %s[/color]" % ", ".join(battle.order.map(
				func(f: Faction): return "%s %d" % [f.name, battle.total(f)])))
	_log("You lead %s." % _tag(command.leader))
	_rebuild_bar()
	_begin.call_deferred()


# The battle opens: the initiative roll plays out (when the HUD is paced to be watched), then the
# first turn starts.
func _begin() -> void:
	if pace > 0.0 and battle.phase == Battle.Phase.TURNS and not battle.unit_rolls.is_empty():
		busy = true
		_mark()
		_show_initiative()
		await intro_done
		if not is_inside_tree():
			return
		busy = false
	if battle.phase == Battle.Phase.TURNS:
		_on_turn(null, battle.turn)
	elif battle.phase == Battle.Phase.OVER:
		_on_phase(Battle.Phase.TURNS, Battle.Phase.OVER)


func _exit_tree() -> void:
	if is_instance_valid(overlay):
		overlay.hud = null  # it may draw once more before it goes
		overlay.top.queue_free()
		overlay.queue_free()


func _process(delta: float) -> void:
	for l in _spinning:
		l.text = str(randi_range(1, 20))
	if pane.visible:
		_auto_scroll(delta)
	if _dirty:
		_dirty = false
		_refresh()
	if hover != NOWHERE and get_viewport().gui_get_hovered_control():
		hover_cell(NOWHERE)  # the mouse went over a panel
	if tip.visible:
		var room := tip.get_viewport_rect().size - tip.size
		tip.position = Vector2(minf(_mouse.x + 10, room.x - 2), minf(_mouse.y + 10, room.y - 2))
	if pane.visible:
		_place_pane()


func _input(e: InputEvent) -> void:
	if e is InputEventMouse:
		_mouse = e.position


func _unhandled_input(e: InputEvent) -> void:
	if %Initiative.visible and (e is InputEventKey or e is InputEventMouseButton) and e.is_pressed():
		_end_intro()  # any key or click skips the roll
		get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseMotion:
		hover_cell(_cell_at(e.position))
		return
	if e is InputEventMouseButton:
		if not e.pressed or e.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return
		if _panel_open():
			_close_panels()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			click(_cell_at(e.position), e.ctrl_pressed or e.meta_pressed, e.shift_pressed)
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
	elif e.is_action_pressed(&"skills"):
		toggle_skills()
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


# A click on the map. force (Ctrl): strike at the tile, whatever seems to be there. inspect (Shift):
# select a foe rather than attack it.
func click(c: Vector2i, force := false, inspect := false) -> void:
	if c == NOWHERE:
		return
	if armed:
		_use_on(c, force)
		return
	var u := unit_seen(c)
	var me := selected if _orders(selected) else null
	if me and not inspect and ((force and not (u and known(u))) or foe(u)) and _primary(me):
		_charge(me, c, force)
	elif u:
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
	elif not command.slot_open(u, i):
		_say(_why_locked())
	elif not u.slot_works(i):
		_say(SkillSlot.NO_LUCK)
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
	if not _orders(u) or not command.may_use(u, s) or not u.toggle(s):
		return
	_log("%s: %s %s" % [_tag(u), s.name, "on" if u.is_on(s) else "off"])
	_mark()


func cancel() -> void:
	if _panel_open():
		_close_panels()
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
	else:
		skills.hide()
		settings.hide()
		if not (selected and known(selected)):
			select(observer())
		if selected:
			_open_book()
	_update_tip()


# S or the dock's branch: the selected unit's skill points and what they could unlock (your own
# side's units; another side's selected opens your leader's).
func toggle_skills() -> void:
	_mark()
	if skills.visible:
		skills.hide()
	else:
		spellbook.hide()
		settings.hide()
		if not (selected and known(selected)):
			select(observer())
		if selected:
			_open_skills()
	_update_tip()


func _panel_open() -> bool:
	return spellbook.visible or skills.visible or settings.visible


# The cog: settings, and the Guide to how the game is played.
func toggle_settings() -> void:
	var open := not settings.visible
	_close_panels()
	settings.visible = open
	_update_tip()


func _close_panels() -> void:
	spellbook.hide()
	skills.hide()
	settings.hide()
	_mark()
	_update_tip()


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


# Someone on the player's side still standing: the leader if it can be.
func observer() -> Unit:
	if command.leader.is_alive():
		return command.leader
	var allies := battle.members(command.faction())
	return allies[0] if allies else null


# What the player's side makes out about a unit: the clearest read any of its units has (they
# share what they see). With no one left to look, nothing.
func view(u: Unit) -> Read:
	var best: Read = null
	for o in battle.members(command.faction()):
		var r := battle.read(o, u)
		if best == null or r.net > best.net:
			best = r
	if best == null:
		best = Read.new()
		best.net = -4
	return best


func tile_view(c: Vector2i) -> Read:
	var best: Read = null
	for o in battle.members(command.faction()):
		var r := battle.read(o, c)
		if best == null or r.net > best.net:
			best = r
	return best if best else Read.new()


# How the player's side judges a tile: &"bad" (a known trap, or known to be detrimental), &"unsure"
# (not made out, or something may be lurking there), or &"safe" (most ground: neutral, or beneficial).
func ground(c: Vector2i) -> StringName:
	var r := tile_view(c)
	if r.trap == true or (r.worth != null and r.worth < 0):
		return &"bad"
	if r.net < 0 or r.hint or c in dubious:
		return &"unsure"
	return &"safe"


# The unit at c, if the player's side can make out that something's there.
func unit_seen(c: Vector2i) -> Unit:
	var u := battle.unit_at(c)
	return u if u and (known(u) or view(u).located()) else null


# Asleep, as far as the player can tell (another side's sleep shows only to a close look).
func sleeping(u: Unit) -> bool:
	return u.asleep() if known(u) else view(u).effects.any(func(e: Effect): return e.stat == "sleep")


# A unit the player would attack by clicking it: not on their side, nor reading as a friend.
func foe(u: Unit) -> bool:
	return u != null and not known(u) and view(u).faction != command.faction()


# Units the armed skill could be used on, as far as the player can tell.
func targets() -> Array[Unit]:
	var out: Array[Unit] = []
	if selected and armed and not armed.on_tile():
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
		if ally and not s.for_allies():
			return "%s is for foes" % s.name
		if not ally and not s.for_foes():
			return "%s is for allies" % s.name
		if not battle.in_reach(u, s, target):
			return "Out of reach"
	elif target is Vector2i:
		var span := battle.area_reach(u, s) if s.on_tile() else battle.skill_range(u, s)
		if not battle.on_map(target) or Vector2(u.cell).distance_to(Vector2(target)) > span + 0.0001:
			return "Out of reach"
		if s.lays and (unit_seen(target) or tile_view(target).trap == true):
			return "Can't set a trap there"
	else:
		return "Pick a unit"
	return _short(u, s) if not u.can_afford(s) else ""


# --- Acting

func _use_on(c: Vector2i, force := false) -> void:
	var u := selected
	var s := armed
	if not _orders(u):
		disarm()
		return
	if force and s.for_foes() and not s.on_tile():
		_strike_at(u, s, c)
		return
	var target: Variant = c if s.on_tile() else unit_seen(c)
	var why := why_not(u, s, target)
	if why == "Pick a unit":
		_say("Pick a unit, or Ctrl-click to strike at the tile" if s.for_foes() else why)
		return
	if why == "Out of reach" or why == "Already fallen":
		_say(why)
		return
	if not (battle.cast_at(u, s, c) if s.on_tile() else battle.cast(u, s, target)):
		_say(why if why else "%s doesn't take" % s.name)
		return
	_done(u)


# Strikes at a tile, whatever seems to be there (Battle.attempt).
func _strike_at(u: Unit, s: Skill, c: Vector2i) -> void:
	match battle.attempt(u, s, c):
		&"hit":
			_done(u)
		&"miss":
			_done(u)
			_say("Nothing there")
		_:
			var why := why_not(u, s, c)
			_say(why if why else "Can't strike there")


# The order went through: the unit has acted, and whatever was armed is spent.
func _done(u: Unit) -> void:
	command.order(u)
	armed = null
	_note = ""
	_replan()
	_mark()


# The skill a click on a foe uses: slot 1, if it's an attack the unit may be told to use.
func _primary(u: Unit) -> Skill:
	var s: Skill = u.hotbar[0] if not u.hotbar.is_empty() else null
	return s if s and not s.passive and s.for_foes() and not s.on_tile() and command.slot_open(u, 0) else null


# Where u would walk to use s on whatever is at c: the cheapest tile it expects to reach that has c
# in reach and leaves the AP to use s; failing that, the reachable tile nearest c. Its own tile if
# it's already in reach. {dest, ready}: ready says s should be usable from dest.
func _approach(u: Unit, s: Skill, c: Vector2i) -> Dictionary:
	var span := battle.skill_range(u, s, unit_seen(c))
	var near := func(at: Vector2i) -> bool: return Vector2(at).distance_to(Vector2(c)) <= span + 0.0001
	if near.call(u.cell):
		return {dest = u.cell, ready = u.can_afford(s)}
	_find_reach()
	var best := u.cell
	var best_cost := INF
	var closest := u.cell
	for at in reach:
		if near.call(at) and u.can_afford_after(s, reach[at]) and reach[at] < best_cost:
			best = at
			best_cost = reach[at]
		var d := Vector2(at).distance_to(Vector2(c))
		if d < Vector2(closest).distance_to(Vector2(c)) - 0.0001:
			closest = at
	return {dest = best, ready = true} if best_cost < INF else {dest = closest, ready = false}


# A click on a foe (or a Ctrl-click on a tile): walk into reach and use the primary skill on it. If
# it can't get there this turn, it walks as close as it can.
func _charge(u: Unit, c: Vector2i, force: bool) -> void:
	var s := _primary(u)
	var a := _approach(u, s, c)
	if a.dest != u.cell:
		battle.travel(u, a.dest)
		command.order(u)
	var t := unit_seen(c)
	if force or not t:
		_strike_at(u, s, c)
		return
	var why := why_not(u, s, t)
	if why == "" and battle.cast(u, s, t):
		_done(u)
		return
	_say(why if why else "%s doesn't take" % s.name)
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
func _act_alone(f: Faction, units: Array[Unit], wait := 0.0) -> void:
	busy = true
	armed = null
	plan = {}
	_mark()
	if pace > 0.0 and wait > 0.0:
		await get_tree().create_timer(wait).timeout
		if not is_inside_tree():
			return
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
	_transition(now, mine)
	if mine:
		command.new_turn()
		select(command.leader)
	elif auto:
		_act_alone(now, battle.members(now), TRANSITION)
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
	for u: Unit in battle.get_node("Units").get_children():
		if u.is_alive():
			u.appear(null)  # the battle's over: everyone shows as they are


# An attack roll, kept for the log line _on_used() writes next.
func _on_attacked(caster: Unit, target: Unit, d20: int, total: int, defense: int) -> void:
	_roll = {caster = caster, target = target, d20 = d20, total = total, defense = defense,
			hit = d20 == 20 or total >= defense, crit = d20 == 20}


func _on_used(caster: Unit, skill: Skill, at: Variant, dealt: int) -> void:
	_mark()
	var roll := _roll if _roll.get("caster") == caster and _roll.get("target") == at else {}
	_roll = {}
	if skill.lays and not known(caster):
		if unit_seen(caster.cell) == caster:
			_log("%s is setting something up." % _tag(caster))
		return  # where, and what, is theirs to know
	var text := "%s uses %s %s" % [_tag(caster), skill.name, Skill.roman(caster.rank(skill))]
	if at is Unit and at != caster:
		text += " on " + _tag(at)
	elif at is Vector2i and skill.lays:
		var told: int = battle.snares[at].known.size() - 1 if at in battle.snares else 0
		text = "%s sets a %s%s" % [_tag(caster), skill.lays.name.to_lower(),
				" and tells %d %s where" % [told, "ally" if told == 1 else "allies"] if told > 0 else ""]
	elif at is Vector2i and not skill.on_tile():
		text += ", but strikes only air"
	if not roll.is_empty():
		text += _roll_text(roll, at)
		if not roll.hit:
			if unit_seen(at.cell) == at:
				overlay.float_text(at, "Miss", MUTED)
			_log(text)
			return
		if roll.crit and unit_seen(at.cell) == at:
			overlay.float_text(at, "Critical!", GOLD)
	if at is Unit and dealt > 0:
		if _hp_shows(at):
			text += " [color=#ff6b5e]-%d[/color]" % dealt
		else:
			text += " and lands a hit"
			if known(caster):
				overlay.float_text(at, "Hit!", FOE)
	_log(text)


# " (rolls 14 vs Defense 11)", " (natural 20)", " (rolls 6): misses" - Defense left out when the
# player can't make it out.
func _roll_text(roll: Dictionary, target: Unit) -> String:
	var against := " vs Defense %d" % roll.defense if _defense_shows(target) else ""
	var result := "natural 20" if roll.crit else ("rolls %d%s" % [roll.total, against])
	return " [color=#6b7180](%s)[/color]%s" % [result, "" if roll.hit else ": misses"]


# Whether the player can make out u's Defense: its own side, or one it can identify (armor shows).
func _defense_shows(u: Unit) -> bool:
	return known(u) or view(u).net >= 0


func _on_energy(was: int, now: int, u: Unit) -> void:
	_mark()
	if now > was and battle.phase == Battle.Phase.TURNS and (known(u) or view(u).energy != null):
		overlay.float_text(u, "+%d EN" % (now - was), Unit.ENERGY_COLOR)


func _on_sprung(_c: Vector2i, by: Unit) -> void:
	if unit_seen(by.cell) == by:
		overlay.float_text(by, "Trap!", GOLD)
	_log("A trap springs under %s!" % _tag(by))


func _on_hp(was: int, now: int, u: Unit) -> void:
	_mark()
	if not _hp_shows(u):
		return
	if now < was:
		overlay.float_text(u, "-%d" % (was - now), FOE)
	elif now > was:
		overlay.float_text(u, "+%d" % (now - was), FRIEND)


func _hp_shows(u: Unit) -> bool:
	return known(u) or view(u).hp != null


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
	_reach_of = null


func _refresh() -> void:
	_find_reach()
	_show_units()
	grounds.clear()
	traps.clear()
	for c in battle.map.get_used_cells():
		grounds[c] = ground(c)
		if tile_view(c).trap == true:
			traps[c] = c in battle.snares and battle.snares[c].faction == command.faction()
	marked = targets()
	sleepers.assign(battle.units.values().filter(func(u: Unit): return unit_seen(u.cell) == u and sleeping(u)))
	card.set_info(_info(selected) if selected else {})
	_refresh_bar()
	_refresh_buttons()
	_refresh_side()
	if spellbook.visible:
		if selected and known(selected):
			_open_book()
		else:
			spellbook.hide()
	if skills.visible:
		if selected and known(selected):
			_open_skills()
		else:
			skills.hide()
	var lead := command.leader
	%SkillsIcon.badge = lead.is_alive() and lead.skill_points > 0 or command.party.any(func(u: Unit): return u.skill_points > 0)
	_update_tip()


# Draws other sides as the player's side makes them out, and notes where something is only suspected.
func _show_units() -> void:
	dubious.clear()
	if battle.phase == Battle.Phase.OVER:
		return
	for u: Unit in battle.get_node("Units").get_children():
		if not u.is_alive():
			continue
		if known(u):
			u.appear(null)
			continue
		var r := view(u)
		u.appear(r)
		for c in r.area:
			if battle.on_map(c):
				dubious[c] = r.hint


# The tile pane: what the player's side knows of the hovered tile - its cost, a list of its
# effects (auto-scrolling when long), and notes on what's uncertain about it.
func _show_pane() -> void:
	pane.visible = hover != NOWHERE and not _panel_open()
	if not pane.visible:
		_pane_list = ""
		return
	var c := hover
	var r := tile_view(c)
	var kind := ground(c)
	%TileMark.color = GROUND[kind]
	%TileIcon.texture = _tile_icon(c)
	%TileIcon.self_modulate = battle.map.get_cell_tile_data(c).modulate
	%TileName.text = r.name if r.name else "Unknown ground"
	%TileCost.text = "Move ?" if r.cost == null else "Move %d" % r.cost
	var effects := _tile_effects(c, r)
	var notes := _tile_notes(c, r)
	if effects.is_empty() and notes.is_empty():
		notes.append(["Nothing of note" if kind == &"safe" else "Hard to make out", MUTED])
	var listed := "%s %s" % [c, effects]
	if listed != _pane_list:
		_pane_list = listed
		_scroll_t = 0.0
	_fill_lines(%TileLines, effects)
	_fill_lines(%TileNotes, notes)
	%EffectsTitle.visible = not effects.is_empty()
	%TileScroll.visible = not effects.is_empty()
	_place_pane()


# [text, colour] for each thing the tile is known to do: beneficial or detrimental, a trap,
# conditions on whoever stands there, steps in or ends a turn there (Effect.conditions: Haste's two
# effects are one line), sticky ground, and what whoever stands there is (Moist, Wet).
func _tile_effects(c: Vector2i, r: Read) -> Array:
	var out := []
	if r.worth != null and r.worth != 0:
		out.append(["Beneficial" if r.worth > 0 else "Detrimental", FRIEND if r.worth > 0 else FOE])
	if r.trap == true:
		var t := battle.terrain(c)
		var dmg := "%dd%d" % [t.dice.x, t.dice.y] + (" x%d" % t.times if t.times != 1 else "") + (" %+d" % t.bonus if t.bonus else "")
		out.append(["Trap: %s %s" % [dmg, " ".join(t.damage_tags.filter(func(x): return x != &"trap"))], FOE])
	for group in Effect.conditions(r.effects):
		out.append([Effect.summarize(group), _tone(group)])
	for when in [[r.afflicts, "on entering"], [r.at_end, "at turn end"]]:
		for group in Effect.conditions(when[0]):
			var n: int = group[0].turns if group[0].turns else battle.terrain(c).turns
			out.append(["%s · %d turn%s · %s" % [Effect.summarize(group), n, "" if n == 1 else "s", when[1]], _tone(group)])
	if r.exit:
		out.append(["Sticky: +%d to leave" % r.exit, MUTED])
	for t in r.tags.filter(func(t): return t not in [&"trap", &"sticky"] and String(t) not in r.name.to_lower()):
		out.append([String(t).capitalize(), MUTED])
	return out


func _tone(group: Array[Effect]) -> Color:
	return FRIEND if group.reduce(func(sum: int, e: Effect): return sum + e.helps(), 0) > 0 else FOE


# [text, colour] for what's uncertain about the tile, and how it bears on the selected unit.
func _tile_notes(c: Vector2i, r: Read) -> Array:
	var out := []
	if r.hint:
		out.append([_sentence(r.hint), GROUND[&"unsure"]])
	if c in dubious:
		out.append(["Something may be here" + (": " + dubious[c] if dubious[c] else ""), GROUND[&"unsure"]])
	if c in battle.snares and battle.snares[c].faction == command.faction() and tile_view(c).trap == true:
		out.append(["Set by %s" % _name(battle.snares[c].by), GOLD])
	for z in battle.zones:
		if c in z.levels and z.faction == command.faction():
			out.append(["Your %s cover %d, %d turns left" % [z.kind, z.levels[c], z.turns], MUTED])
	var u := selected if selected and known(selected) else null
	var there := unit_seen(c)
	if u and there and there != u:
		var extra := battle.pass_cost(u, there)
		out.append(["%s through %s: %s%s move" % [_name(u), _name(there), "+" if extra >= 0.0 else "", Skill.num(extra)],
				FRIEND if extra < 0.0 else MUTED])
	if u and r.cost != null:
		var t := battle.terrain(c)
		var own := maxf(t.enter + u.stat(&"move_cost", t.tags), 0.0)
		if not is_equal_approx(own, t.enter):
			out.append(["%s pays %s to enter" % [_name(u), Skill.num(own)], MUTED])
		for skill in u.paused_on(t.tags):
			out.append(["%s's %s stops working here" % [_name(u), skill.name], MUTED])
	return out


func _fill_lines(box: Container, lines: Array) -> void:
	_clear(box)
	for line in lines:
		var l := Label.new()
		l.theme_type_variation = &"Muted"
		l.text = line[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = pane.custom_minimum_size.x - 14  # wrap at the pane's width from the start
		l.add_theme_color_override(&"font_color", line[1])
		box.add_child(l)


func _auto_scroll(delta: float) -> void:
	var lines: Control = %TileLines
	var span: float = lines.get_combined_minimum_size().y - PANE_LIST
	if span <= 0.5:
		%TileScroll.scroll_vertical = 0
		lines.modulate.a = 1.0
		return
	_scroll_t += delta
	var travel := maxf(span / SCROLL_SPEED, 1.0)
	var marks := [SCROLL_FADE, SCROLL_FADE + SCROLL_HOLD, SCROLL_FADE + SCROLL_HOLD + travel,
			SCROLL_FADE + SCROLL_HOLD * 2.0 + travel, SCROLL_FADE * 2.0 + SCROLL_HOLD * 2.0 + travel]
	var t := fmod(_scroll_t, marks[4])
	var down := 0.0
	var alpha := 1.0
	if t < marks[0]:
		alpha = t / SCROLL_FADE
	elif t >= marks[1] and t < marks[2]:
		down = slow_middle((t - marks[1]) / travel)
	elif t >= marks[2]:
		down = 1.0
		if t >= marks[3]:
			alpha = 1.0 - (t - marks[3]) / SCROLL_FADE
	%TileScroll.scroll_vertical = roundi(down * span)
	lines.modulate.a = alpha


# 0..1 -> 0..1, moving fastest at the ends and slowest in the middle.
static func slow_middle(u: float) -> float:
	return u + SCROLL_EASE * sin(TAU * u) / TAU


# In a corner of the map, the one diagonally away from the pointer.
func _place_pane() -> void:
	var want: float = %TileLines.get_combined_minimum_size().y
	%TileScroll.custom_minimum_size.y = minf(want, PANE_LIST)
	var n: int = %TileLines.get_child_count()
	%EffectsTitle.text = "EFFECTS  %d" % n
	pane.reset_size()
	var view := pane.get_viewport_rect().size
	var lo := Vector2(($Root/Left as Control).get_global_rect().end.x + 3, 3)
	var hi := Vector2(($Root/Right as Control).get_global_rect().position.x - 3, view.y - 3)
	var map := battle.map
	var used := map.get_used_rect()
	var half := Vector2(map.tile_set.tile_size) / 2.0
	var xf := battle.get_viewport().get_canvas_transform() * map.get_global_transform()
	lo = lo.max(xf * (map.map_to_local(used.position) - half) + Vector2(3, 3))
	hi = hi.min(xf * (map.map_to_local(used.end - Vector2i.ONE) + half) - Vector2(3, 3))
	var mid := (lo + hi) / 2.0
	pane.position = Vector2(hi.x - pane.size.x if _mouse.x < mid.x else lo.x,
			hi.y - pane.size.y if _mouse.y < mid.y else lo.y)


func _tile_icon(c: Vector2i) -> Texture2D:
	var map := battle.map
	var key := [map.get_cell_source_id(c), map.get_cell_atlas_coords(c)]
	if key not in _icons:
		var src := map.tile_set.get_source(key[0]) as TileSetAtlasSource
		if not src:
			return null
		var tex := AtlasTexture.new()
		tex.atlas = src.texture
		tex.region = src.get_tile_texture_region(key[1])
		_icons[key] = tex
	return _icons[key]


func _open_skills() -> void:
	skills.open(selected, _name(selected), _can_spend(selected))


# Skill points are the player's to spend for the leader and the party.
func _can_spend(u: Unit) -> bool:
	return u != null and not busy and command.ours(u)


func _on_unlocked(s: Skill) -> void:
	var u := skills.unit
	if _can_spend(u) and u.unlock(s):
		_log("%s learns %s." % [_tag(u), s.name])
		_rebuild_bar()
	_mark()


func _on_raised(s: Skill) -> void:
	var u := skills.unit
	if _can_spend(u) and u.raise(s):
		_log("%s raises %s to rank %s." % [_tag(u), s.name, Skill.roman(u.rank(s))])
		_rebuild_bar()
	_mark()


func _on_leveled() -> void:
	var u := skills.unit
	if _can_spend(u):
		u.level_up()
		_log("%s reaches level %d." % [_tag(u), u.level])
	_mark()


func _open_book() -> void:
	var u := selected
	spellbook.open(u, _name(u), _editable(u), func(s: Skill) -> bool: return _orders(u) and command.may_use(u, s))


func _rebuild_bar() -> void:
	var n := _bar_slots(selected if selected and known(selected) else null)
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


# Hotbar slots shown for u: all of them, but its clover slot (the last) only while it's lucky or holds
# a skill.
func _bar_slots(u: Unit) -> int:
	if not u:
		return Unit.SLOTS
	var c := u.clover()
	if c >= 0 and u.luck <= 0 and (c >= u.hotbar.size() or u.hotbar[c] == null):
		return c
	return u.bar_size()


func _refresh_bar() -> void:
	_rebuild_bar()
	var u := selected if selected and known(selected) else null
	bar.visible = u != null or not selected  # other sides' skills aren't the player's to see
	%BarTitle.visible = bar.visible
	var orders := u != null and _orders(u)
	var edit := u != null and _editable(u)
	for slot: SkillSlot in bar.get_children():
		var i := slot.index
		var s: Skill = u.hotbar[i] if u and i < u.hotbar.size() else null
		var locked := u != null and known(u) and u != command.leader and not command.slot_open(u, i)
		var works := u == null or u.slot_works(i)
		var usable := orders and s != null and not locked and works and (s.passive or u.can_afford(s))
		slot.set_state(i, s, u.rank(s) if s else 0, s != null and s == armed, s != null and u.is_on(s), usable, edit, locked)
		slot.set_kind(u.slot_kind(i) if u else &"", works)
		if locked:
			slot.tooltip_text += "\n" + _why_locked()


func _on_dropped(i: int, s: Skill, _from: int) -> void:
	var u := selected
	if u and _editable(u):
		if not u.bar_place(s, i):
			var kind: String = Skill.CATEGORIES.get(u.slot_kind(i), "")
			if u.rank(s) == 0:
				_say("%s doesn't know %s" % [_name(u), s.name])
			elif not u.slot_works(i):
				_say(SkillSlot.NO_LUCK)
			elif kind:
				_say("%s slots hold only %s skills" % [kind, kind.to_lower()])
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
	hint.visible = hint.text != ""
	hint.add_theme_color_override(&"font_color", GOLD if _note else MUTED)
	end_button.disabled = not my_turn()


# What's going on that the screen doesn't already show; how to play is in the Guide (Settings).
func _hint() -> String:
	if battle.phase == Battle.Phase.OVER:
		return "The battle is over."
	if not command.leader.is_alive():
		return "Your leader has fallen; your allies fight on."
	if %Initiative.visible:
		return "Rolling for initiative... (any key skips)"
	if busy:
		return "%s acting..." % ("Your allies are" if battle.turn == command.faction() else battle.turn.name + " is")
	if battle.turn != command.faction():
		return "Waiting for %s." % battle.turn.name
	var u := selected
	if not u or not known(u) or _orders(u):
		return ""
	if u.asleep():
		return "Asleep. An ally ending the turn beside it wakes it for the next one."
	return "Too far to hear you. Bring %s within %s." % [_name(command.leader),
			_tiles(command.party_reach() if u in command.party else float(command.reach()))]


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
	party_title.text = "PARTY  %d/%d  (?)" % [command.party.size(), command.party_size()]
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
	var help := _party_help()
	party_title.tooltip_text = help
	for i in command.party_size() - command.party.size():
		var l := Label.new()
		l.theme_type_variation = &"Muted"
		l.text = "  open slot"
		l.add_theme_color_override(&"font_color", Color(MUTED, 0.5))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.tooltip_text = help
		roster.add_child(l)


# How the party and orders work, for the party header's tooltip.
func _party_help() -> String:
	var leader := _name(command.leader)
	var n := command.slots()
	return "\n".join([
		"Your party: up to %d %s (%s's charisma)." % [command.party_size(), "ally" if command.party_size() == 1 else "allies", leader],
		"Select an ally within %s of %s and press P to invite it; P again lets it go." % [_tiles(command.reach()), leader],
		"Orders reach allies within %s of %s; party members hear them from %s." % [_tiles(command.reach()), leader, _tiles(command.party_reach())],
		"Commanded allies use hotbar slot%s 1%s." % ["" if n == 1 else "s", "" if n == 1 else "-%d" % n] if n > 0
				else "Commanded allies only take move orders.",
	])


static func _sentence(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


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
		if command.ours(u) and u.skill_points > 0:
			chips.append(["%d skill point%s" % [u.skill_points, "" if u.skill_points == 1 else "s"], GOLD])
		if u.asleep():
			chips.append(["Asleep", SLEEP])
		elif battle.turn == command.faction() and battle.phase == Battle.Phase.TURNS and u != command.leader:
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
		rows.append(["DF", _defense_line(u), null, MOVE_COLOR])
		info.rows = rows
	else:
		var r := view(u)
		info.name = r.name if r.name else "Unknown"
		info.shape = r.faction == null
		var parts: PackedStringArray = []
		if r.level != null:
			parts.append("Lv %d" % r.level)
		if r.role:
			parts.append(r.role.name)
		elif not r.tags.is_empty():
			parts.append(" ".join(r.tags.map(func(t): return String(t).capitalize())))
		if not parts:
			parts.append(_sentence(r.hint) if r.hint else ("Kind unknown" if r.name else "Hard to make out"))
		info.sub = " ".join(parts)
		if r.faction == null:
			chips.append(["Unknown", MUTED])
		elif r.faction == command.faction():
			chips.append(["Friendly", FRIEND])
		else:
			chips.append(["Enemy", FOE])
		if sleeping(u):
			chips.append(["Asleep", SLEEP])
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
		if r.net >= 0:
			rows.append(["DF", _defense_line(u), null, MOVE_COLOR])
		info.rows = rows
	info.chips = chips
	return info


# "11 · Gambeson", "2 · unarmored", with tagged Defense after: "+2 vs magical".
func _defense_line(u: Unit) -> String:
	var text := "%d · %s" % [u.defense(), u.armor.name if u.armor else "unarmored"]
	var tagged := u.tagged_defense()
	for t in tagged:
		text += ", %+d vs %s" % [tagged[t], t]
	return text


func _update_tip() -> void:
	var text := "" if _panel_open() else _tip_text()
	tip.visible = text != ""
	if tip.visible:
		tip_label.text = text
		tip.reset_size()
	_show_pane()


func _tip_text() -> String:
	if hover == NOWHERE:
		return ""
	var u := unit_seen(hover)
	if armed and selected:
		if not u and not armed.on_tile():
			if not armed.for_foes():
				return "%s\nPick a unit" % armed.name
			var why_tile := why_not(selected, armed, hover)
			return "%s\n%s" % [armed.name, why_tile if why_tile else "Ctrl-click to strike at whatever may be here"]
		var target: Variant = hover if armed.on_tile() else u
		var why := why_not(selected, armed, target)
		var head := armed.name + (" on " + _name(u) if u and not armed.on_tile() else "")
		return "%s\n%s" % [head, why if why else "Click to use: " + _forecast(selected, armed, target if target is Unit else null)]
	if u:
		return _unit_line(u) + ("\n" + _charge_line(selected, hover) if charge == hover else "")
	var lines: PackedStringArray = []
	if not plan.is_empty():
		var path: Array = plan.path
		var cost := _cost_text(path, plan.costs.reduce(func(sum, x): return sum + x, 0.0))
		if path.is_empty():
			lines.append("Can't get closer")
		elif path[-1] == hover:
			lines.append("Walk here: %s of %s" % [cost, Skill.num(selected.move_left())])
		else:
			lines.append("Stops %d short (%s move)" % [plan.line.size() - path.size(), cost])
		if path.any(func(c): return tile_view(c).trap == true):
			lines.append("Steps onto a known trap")
		elif path.any(func(c): return ground(c) == &"bad"):
			lines.append("Crosses detrimental ground")
	if hover in dubious and _orders(selected) and _primary(selected):
		lines.append("Ctrl-click to strike at whatever may be here")
	return "\n".join(lines)


# A move cost as the player should read it: with a '?' when the walk crosses unsure ground.
func _cost_text(path: Array, cost: float) -> String:
	return Skill.num(cost) + ("?" if path.any(func(c): return ground(c) == &"unsure") else "")


func _unit_line(u: Unit) -> String:
	if known(u):
		return "%s\nHP %d/%d" % [_name(u), u.hp, u.max_hp]
	var r := view(u)
	var text: String = r.name if r.name else "Something"
	if r.faction == null and r.hint:
		text += "\n" + _sentence(r.hint)
	if r.hp != null:
		text += "\nHP %d/%d" % [r.hp, r.max_hp]
	elif r.healthy != null:
		text += "\n" + ("Healthy" if r.healthy else "Bloodied")
	if r.vibe:
		text += "\n" + r.vibe
	return text


# What clicking the foe at c would do: walk up and use the primary skill, or only close in.
func _charge_line(u: Unit, c: Vector2i) -> String:
	var s := _primary(u)
	var a := _approach(u, s, c)
	if not a.ready:
		if a.dest != u.cell:
			return "Click: walk closer (out of reach this turn)"
		return _short(u, s) if not u.can_afford(s) else "Out of reach of %s" % s.name
	var walk := "walk %s, then " % _cost_text(plan.get("path", []), reach[a.dest]) if a.dest != u.cell else ""
	return "Click: %s%s %s\n%s" % [walk, s.name, Skill.roman(u.rank(s)), _forecast(u, s, unit_seen(c))]


# What using s on target would cost and roughly do (before mitigation and luck): AP, cost, the
# chance to hit (when the target's Defense can be made out) and the damage of a hit - or, for a dual
# skill used on an ally, the effects it gets.
func _forecast(u: Unit, s: Skill, target: Unit = null) -> String:
	var fund: Variant = u.funding(s)
	var text := "%s AP" % Skill.num(u.ap_cost(s, fund))
	if u.cost_from(s, fund):
		text += ", %d %s" % [u.cost_from(s, fund), fund.name if fund is Reserve else "energy"]
	if s.dual and target and not foe(target):
		var n := s.lasts(u.rank(s))
		return text + " · %s, %d turn%s" % [", ".join(s.effects.map(func(e: Effect): return e.describe(u.rank(s)))), n, "" if n == 1 else "s"]
	if target and s.attacks():
		text += " · %s to hit" % ("%d%%" % roundi(Battle.hit_chance(u, s, target) * 100.0) if _defense_shows(target) else "?%")
	var t := s.tier(u.rank(s))
	if t:
		var hits := u.rank(s) if s.hits_per_rank else 1
		var bonus := u.mod(u.wielded(t.stat, s.tags), s.tags) if t.stat else 0
		var lo := maxi(t.power + t.dice.x + bonus, 1) * hits
		var hi := maxi(t.power + t.dice.x * t.dice.y + bonus, 1) * hits
		text += " · %s damage" % (str(lo) if lo == hi else "%d-%d" % [lo, hi])
	return text


# --- Rules of thumb for the player

func _orders(u: Unit) -> bool:
	return u != null and my_turn() and command.can_order(u)


# The leader's and party's hotbars are the player's to arrange; other allies keep their own.
func _editable(u: Unit) -> bool:
	return u != null and not busy and command.ours(u)


func _why_locked() -> String:
	var n := command.slots()
	if n == 0:
		return "Allies only take move orders from %s (charisma %+d)" % [_name(command.leader), command.leader.mod(&"charisma")]
	return "Allies use only slot%s 1%s on %s's orders" % ["" if n == 1 else "s", "" if n == 1 else "-%d" % n, _name(command.leader)]


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
	if u.asleep():
		return "Asleep: an ally ending the turn beside it wakes it"
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
	return view(t).faction == command.faction()


# Tiles the selected unit expects to reach this turn, with what each would cost (kept until the
# next change).
func _find_reach() -> void:
	var u := selected if not armed and _orders(selected) else null
	if u and u == _reach_of:
		return
	_reach_of = u
	reach.clear()
	if not u or u.move_left() <= 0.0001:
		return
	for c in battle.map.get_used_cells():
		if c != u.cell and not unit_seen(c):
			var w := battle.walk(u, c, true)
			if not w.path.is_empty() and w.path[-1] == c:
				reach[c] = w.costs.reduce(func(sum, x): return sum + x, 0.0)


# The hovered move, or the walk up to a hovered foe a click would attack.
func _replan() -> void:
	plan = {}
	charge = NOWHERE
	var u := selected
	if hover == NOWHERE or not u or armed or not _orders(u) or hover == u.cell:
		return
	var t := unit_seen(hover)
	if foe(t) and _primary(u):
		charge = hover
		var a := _approach(u, _primary(u), hover)
		if a.dest != u.cell:
			plan = battle.walk(u, a.dest, true)
	elif not t:
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
	var r := view(u)
	return r.name if r.name else "Something"


# A name for the log, in its side's colour as far as the player can tell.
func _tag(u: Unit) -> String:
	var f: Faction = u.faction if known(u) else view(u).faction
	var col := shade(f.primary) if f else MUTED
	return "[color=#%s]%s[/color]" % [col.to_html(false), _name(u).replace("[", "[lb]")]


func _log(text: String) -> void:
	log_box.append_text(text + "\n")


func _say(text: String) -> void:
	_note = text
	_mark()


# A turn changes hands (about a second): the screen dims as a band in the side's colour sweeps in
# to centre with its name, holds, and sweeps on.
func _transition(f: Faction, mine: bool) -> void:
	var band: Control = %Band
	var curtain: ColorRect = %Curtain
	%BandTitle.text = f.name
	%BandSub.text = "%s · Round %d" % ["Your turn" if mine else "Their turn", maxi(round_no, 1)]
	%BandFill.color = Color(f.primary.darkened(0.3), 0.92)
	if pace <= 0.0:
		return  # unwatched: no show
	if _turn_show:
		_turn_show.kill()
	var across := band.get_viewport_rect().size.x
	band.position.x = -across
	band.show()
	curtain.show()
	curtain.modulate.a = 0.0
	_turn_show = create_tween()
	_turn_show.tween_property(curtain, "modulate:a", 1.0, 0.22)
	_turn_show.parallel().tween_property(band, "position:x", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_turn_show.tween_interval(TRANSITION - 0.56)
	_turn_show.tween_property(band, "position:x", across, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_turn_show.parallel().tween_property(curtain, "modulate:a", 0.0, 0.28)
	_turn_show.tween_callback(band.hide)
	_turn_show.tween_callback(curtain.hide)


# The opening initiative roll, as the player sees it: by side in turn order, each unit's d20
# (units the player can't make out, or can't tell the side of - a persona's lie - roll as "?"),
# the side's best bonus and its total.
func initiative_rows() -> Array:
	var out := []
	for f in battle.order:
		var dice := []
		for u: Unit in battle.unit_rolls:
			if u.faction == f:
				var plain := known(u) or (unit_seen(u.cell) == u and view(u).faction == u.faction)
				dice.append([u if plain else null, battle.unit_rolls[u]])
		out.append([f, dice, battle.initiative_bonus(f), battle.total(f)])
	return out


# Every die spins, then lands on its number one after another; the totals follow and the side
# that goes first is called out. Any key or click skips it.
func _show_initiative() -> void:
	var rows := initiative_rows()
	_clear(%InitRows)
	_spinning.clear()
	var dice: Array[Label] = []
	var finals: Array[int] = []
	var totals: Array[Label] = []
	for row in rows:
		var f: Faction = row[0]
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 4)
		var side := Label.new()
		side.text = f.name
		side.custom_minimum_size.x = 36
		side.add_theme_color_override(&"font_color", shade(f.primary))
		line.add_child(side)
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override(&"separation", 2)
		chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(chips)
		for d in row[1]:
			var chip := VBoxContainer.new()
			chip.add_theme_constant_override(&"separation", 0)
			var u: Unit = d[0]
			var face := TextureRect.new()
			face.custom_minimum_size = Vector2(14, 14)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face.texture = u.sprite.sprite_frames.get_frame_texture(&"default", 0) if u else null
			face.tooltip_text = _name(u) if u else "Something unseen"
			chip.add_child(face)
			var die := Label.new()
			die.text = "?"
			die.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			die.add_theme_font_size_override(&"font_size", 8)
			chip.add_child(die)
			chips.add_child(chip)
			dice.append(die)
			finals.append(d[1])
		var total := Label.new()
		total.custom_minimum_size.x = 30
		total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		total.add_theme_color_override(&"font_color", GOLD)
		line.add_child(total)
		totals.append(total)
		%InitRows.add_child(line)
	%InitFoot.text = ""
	var panel: Control = %Initiative
	panel.modulate.a = 0.0
	panel.show()
	panel.reset_size()
	_spinning.assign(dice)
	_intro = create_tween()
	_intro.tween_property(panel, "modulate:a", 1.0, 0.15)
	_intro.tween_interval(0.35)
	for i in dice.size():
		_intro.tween_callback(_land.bind(dice[i], finals[i]))
		_intro.tween_interval(0.12)
	_intro.tween_interval(0.2)
	_intro.tween_callback(func():
		for r in rows.size():
			var bonus: int = rows[r][2]
			totals[r].text = "= %d%s" % [rows[r][3], " (+%d)" % bonus if bonus else ""]
		%InitFoot.text = "%s go%s first" % ["You" if rows[0][0] == command.faction() else rows[0][0].name,
				"" if rows[0][0] == command.faction() else "es"])
	_intro.tween_interval(0.9)
	_intro.tween_property(panel, "modulate:a", 0.0, 0.25)
	_intro.tween_callback(_end_intro)


func _land(die: Label, value: int) -> void:
	_spinning.erase(die)
	die.text = str(value)
	die.add_theme_color_override(&"font_color", GOLD if value == 20 else (FOE if value == 1 else Color.WHITE))


func _end_intro() -> void:
	if _intro:
		_intro.kill()
		_intro = null
	_spinning.clear()
	%Initiative.hide()
	intro_done.emit()


func _banner(text: String, col: Color) -> void:
	banner.text = text
	banner.add_theme_color_override(&"font_color", col)
	var tw := banner.create_tween()
	banner.modulate.a = 0.0
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.9)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
