class_name HUD
extends CanvasLayer

# The player's side of a battle. Click a unit to select it. With a unit that takes orders selected,
# hover a tile to plan a move and click to walk there; click a foe to walk into reach and use the
# primary skill (slot 1) on it; or press a hotbar number (or click the slot) to arm a skill, then
# click its target. A toggled passive switches instead. Ctrl-click strikes at a tile whatever seems
# to be there - empty, or only suspected - Shift-click selects a foe instead of attacking it, and
# Alt-click casts a Rift unchanneled.
# B opens the spellbook, S the skills (spending skill points), H holds an ally where it is, P invites
# it to the party (or lets it go), Tab steps through units taking orders, Space ends the turn, Esc or
# right-click backs out. The cog opens Settings, with a Guide to all this; nothing on screen
# explains it otherwise. Command decides who takes orders and which of their slots. Allies left
# without orders act on their own as the turn ends, and other sides play themselves, paced so they
# can be followed.
# Other sides are shown only as the player's units make them out (Perception, shared across the
# side): unlocated units aren't drawn, ones whose side can't be told glow grey with no bars (black
# shapes when they hide or stand in concealment: Read.silhouette(); a trick it suspects in plain view
# pops a "?" and shows as if unaffiliated, a "!" once seen through: _pop()), and areas
# where something is only suspected are marked. A unit's glow says how ready it is for what the
# player is about, in four strengths (glow_of()). Ground is judged the same way - safe, unsure (not
# made out, or something may lurk there) or bad (a known trap, or known detrimental) - which colours where a
# unit can walk, puts a '?' on move costs through unsure ground, and heads the tile pane, a corner
# panel with what's known of the hovered tile.

const STARPOWER_TINT := Color("#ffe48a")  # tile-pane lines about the star lattice
const NOWHERE := Vector2i(-9999, -9999)
const GOLD := Color("#e8c547")
const MUTED := Color("#9aa0ae")
const FOE := Color("#ff6b5e")
const FRIEND := Color("#6fdc8c")
const AP_COLOR := Color("#7cc4ff")
const MOVE_COLOR := Color("#b8c0cc")
const SLEEP := Color("#9db4ff")
const SUSPICION := Color("#b07ae8")  # the suspicion eye (suspicion_icons())
const SUSPICION_ICON := preload("res://Icons/Effects/suspicion.png")
# What a Downed unit died of (Downed.succumb()), for the log.
const DBNO_DEATHS := {&"limit": "its HP past its limit", &"rounds": "its rounds are up", &"actions": "one skill too many", &"melee": "a round without a melee attack", &"slain": "finished off"}
const GROUND := {&"safe": Color("#7cc4ff"), &"unsure": Color("#f2c94c"), &"bad": Color("#a32424")}
const PANE_LIST := 34.0  # tallest the tile pane's effect list gets before it scrolls
# The effect list's auto-scroll, when it's too long to show: fade in, hold at the top, scroll down
# (slowest in the middle), hold at the bottom, fade out, and round again from the top.
const TRANSITION := 1.0  # seconds a turn change takes on screen (other sides wait it out)
const HURRY := 4.0  # how much faster turn changes and units acting on their own go while the hurry key is held
const SCROLL_HOLD := 2.0  # seconds
const SCROLL_FADE := 0.35
const SCROLL_SPEED := 10.0  # average px a second while scrolling
const SCROLL_EASE := 0.7  # how much faster than average the ends go, and slower the middle

@export var battle: Battle
@export var auto := true  # sides the player doesn't run play themselves
@export var pace := 0.45  # seconds between units acting on their own
@export var together := true  # units acting on their own all move at once, their walks shown side by side, then the turn ends
@export var turn_clock := true  # the player has turn_seconds() to act each turn (on screen, top middle), then the turn ends
var hand_over := true  # Settings: a unit that's spent (can't take another order this turn) hands the focus to the next that can
var log_open := false  # the whole log shows; collapsed (the default), only its last entry
@export_file("*.tscn") var menu_scene := "res://Scenes/entry.tscn"

var command: Command
var selected: Unit
var slot := 0  # the selected hotbar slot of the selected unit: always set (the first, or with keep_slot the last used)
var aim := false  # an area or trap skill in the slot is aimed: tile clicks cast it (its key again, or a right click, steps back)
var keep_slot := false  # Settings: a unit keeps the slot it last used, rather than starting on the first
var _last_slot: Dictionary[Unit, int] = {}  # keep_slot: each unit's last used slot
var armed: Skill:  # the selected slot's skill (null: an empty slot, or nothing selected)
	get:
		var u := selected
		return u.hotbar[slot] if u and hand(u) and slot >= 0 and slot < u.hotbar.size() else null
var hover := NOWHERE
var busy := false  # units are acting on their own; the player waits
var plan := {}  # the hovered move, as the selected unit expects it (Battle.walk)
var reach: Dictionary[Vector2i, float] = {}  # tiles the selected unit expects to reach, and the cost
var charge := NOWHERE  # the hovered foe a click would walk up to and use a skill on
var hovered := {}  # what a click on the hovered tile means (intent())
var spend := {}  # what the hovered plan would consume (drain()): drawn on the unit's own bars and card
var hurt := {}  # what the hovered attack would take off its target, when its HP is known: {unit, lo, hi}
var foresight_used: Dictionary[Unit, int] = {}  # hazard estimates each unit has acted on this turn (foresight())
var show_odds := false  # Alt held: the exact chance to hit, in the tip (only when the target's Defense is known)
var marked: Array[Unit] = []  # what the armed skill could be used on
var dubious: Dictionary[Vector2i, String] = {}  # tiles where something is only suspected, and the hint
var sleepers: Array[Unit] = []  # units the player can see are asleep, as of the last refresh
var traps: Dictionary[Vector2i, bool] = {}  # traps the player's side knows of: true for ones it laid
var grounds: Dictionary[Vector2i, StringName] = {}  # ground() for every tile, as of the last refresh
var marks: Dictionary[Unit, Dictionary] = {}  # per viewer (eyes()), what it last made of each trick in plain view (Read.mark()): a change pops a mark (_pop())
var _viewer: Unit  # whose eyes the last _show_units() drew through
var suspect: Dictionary[Vector2i, String] = {}  # concealed tiles the player has a hint about (a disguised trap) -> the hint
var _icons := {}  # [source id, atlas coords] -> AtlasTexture, for the tile pane
var _pane_list := ""  # what the pane's effect list last showed (a new one scrolls from the start)
var _scroll_t := 0.0  # seconds into the effect list's auto-scroll
var _spinning: Array[Label] = []  # initiative dice still rolling
var _intro: Tween  # the initiative roll on screen
var _turn_show: Tween  # the turn change on screen
var clock := 0.0  # seconds the player has left this turn (turn_clock)
var clock_on := false  # the clock was set for this turn of the player's (_on_turn()); off once it ends
var clock_label: Label  # the clock, top middle

signal intro_done
signal refused(u: Unit, word: String)  # a click refused: the unit shook, saying one word (_refuse())
signal prepared  # preparation's over: the battle begins (begin_battle())
var _opening := false  # preparation and the opening roll under way: the first turn waits for _begin()
var round_no := 0
var overlay: Overlay
var _last_turn := 999  # order index of the previous turn, for counting rounds
var _dirty := true
var _reach_of: Unit  # whose reach `reach` holds, until something changes
var _ways: Dictionary[Vector2i, Array] = {}  # the tiles its walk to each tile in `reach` crosses
var _unsure: Dictionary[Vector2i, bool] = {}  # tiles a walk can't be counted on to cross (_sure_walk()), as looked up since `reach` was found
var _note := ""  # a passing message for the hint line ("Out of reach")
var _mouse := Vector2.ZERO  # last pointer position, in screen (HUD) space
var _roll := {}  # the attack roll the next used signal is for (_on_attacked())
var _looks: Array = []  # [by, total, against, whether the player knows `against`]: investigations of the skill being used, logged after it
var _falls: Array[String] = []  # "X falls" lines, held until the hit that did it is logged (_flush_falls())
var _earned: Array = []  # [what it's for, "Brick +6"]: XP its side earned, logged after the falls (_flush_falls())

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
var guide_page := &"play"  # the Guide page shown (Guide.PAGES)
const ALLY_GLOW := Color("#b4ffd2")  # default glow of allies of another faction: a pale mint, to read on grass
const ALLY_GLOWS := {"Mint": ALLY_GLOW, "White": Color("#ffffff"), "Sky": Color("#8fe8ff"), "Gold": Color("#ffe27a")}  # Settings: the picker's choices
const ALLY_BOOST := 1.7  # an ally's glow is this much stronger than plain: pale on green ground it was hard to find
var ally_glow := ALLY_GLOW  # the glow of allies of another faction (look_of())
var high_contrast := false  # accessibility: brighter allied glow, heavier borders, whiter text
var suspicious_marks := false  # accessibility: every suspicious tile shows a plain ?
var persona := PersonaPanel.new()  # Personify's active half
var sheet := CharacterSheet.new()  # the character icon: equipment, hearts and the stash
var _personifying: Array = []  # [unit, skill] the persona panel is open for


static func shade(c: Color) -> Color:
	return c.lerp(Color.WHITE, 0.35)  # faction colours, lifted to read on dark panels


func _ready() -> void:
	add_to_group(&"hud")  # the battle camera finds it (BattleCamera)
	command = Command.new(battle, battle.player if battle.player else _stand_in())
	clock_label = Label.new()
	clock_label.name = &"Clock"
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	clock_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.position.y = 2
	clock_label.add_theme_font_size_override(&"font_size", 10)
	clock_label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	clock_label.add_theme_constant_override(&"outline_size", 3)
	clock_label.tooltip_text = "Time left this turn: your wisdom plus half your intelligence, in seconds"
	clock_label.mouse_filter = Control.MOUSE_FILTER_PASS
	clock_label.hide()
	$Root.add_child(clock_label)
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
	battle.contested.connect(_on_contested)
	battle.used.connect(_on_used)
	battle.sprung.connect(_on_sprung)
	battle.investigated.connect(func(by: Unit, of: Unit, s: Skill, total: int, against: int, _close: bool):
		_looks.append([by, total, against, roll_known(of, s)]))
	battle.evaluated.connect(_on_evaluated)
	battle.downed.connect(_on_downed)
	battle.dbno_changed.connect(_on_dbno)
	battle.held_fire.connect(func(u: Unit, ally: Unit):
		_log("%s holds its fire: that's %s" % [_tag(u), _tag(ally)])
		overlay.float_text(u, "Holds fire", FRIEND)
		_mark())
	battle.borrowed.connect(func(u: Unit, how: StringName):
		_log({&"begin": "%s is on borrowed time: its death put off %d round%s" % [_tag(u), u.deferred, "" if u.deferred == 1 else "s"],
				&"replay": "%s relives what harmed it" % _tag(u), &"survived": "%s's borrowed time runs out, and it lives" % _tag(u),
				&"executed": "%s's borrowed time runs out" % _tag(u)}.get(how, ""))
		if how == &"begin":
			overlay.float_text(u, "Borrowed Time", FRIEND)
		_mark())
	battle.revived.connect(_on_revived)
	battle.dropped.connect(_on_dropped_item)
	battle.pulsed.connect(_on_pulsed)
	battle.exploded.connect(_on_exploded)
	battle.shattered.connect(func(_u: Unit, _c: Vector2i): _mark())  # the layer that broke logs itself
	battle.layer_broke.connect(func(c: Vector2i, what: Terrain, by: Unit):
		_log("%s breaks the %s at %s" % [_tag(by), what.name.to_lower(), c] if by else "The %s at %s gives way" % [what.name.to_lower(), c])
		_mark())
	battle.teetered.connect(func(u: Unit, total: int, dc: int, kept: bool):
		_log("%s %s (%d vs %d)" % [_tag(u), "catches itself" if kept else "falls through", total, dc]))
	battle.shaped.connect(func(u: Unit, form: StringName, element: StringName):
		_log("%s %s" % [_tag(u), ("takes the shape of a %s%s" % [form, " of %s" % element if element else ""]) if form else "takes its own shape back"]))
	battle.bound.connect(func(_by: Unit, u: Unit, it: Item):
		_log("%s is in %s (weight %d)" % [_tag(u), it.name.to_lower(), it.heft()])
		_mark())
	battle.freed.connect(func(u: Unit, how: StringName, total: int, dc: int, done: bool):
		var verb: String = {&"unlock": "takes its shackles off", &"pick": "picks the lock", &"pry": "pries its shackles apart"}[how]
		_log("%s %s%s" % [_tag(u), verb if done else "fails: " + verb.trim_prefix("takes ").trim_prefix("picks ").trim_prefix("pries "), " (%d vs %d)" % [total, dc] if how != &"unlock" else ""])
		_mark())
	battle.sapped.connect(_on_sapped)
	battle.meditated.connect(func(u: Unit, room: int):
		if known(u) and room > 0 and not autopilot():
			_respec_window(u, room))
	battle.respecced.connect(func(u: Unit, changes: Dictionary):
		_log("%s shifts: %s" % [_tag(u), ", ".join(changes.keys().map(func(s): return "%s %+d" % [String(s).left(3), changes[s]]))])
		_mark())
	battle.perfect.connect(func(u: Unit):
		_log("[color=#e8c547]Perfect![/color] %s heals %d" % [_tag(u), Battle.PERFECT_HEAL])
		_mark())
	battle.reverted.connect(func(was: Unit, now: Unit):
		_watch_unit(now)
		_falls.append("%s falls back into %s" % [_tag(was), _tag(now)])
		_flush_falls.call_deferred())
	battle.reformed.connect(func(was: Unit, now: Unit):
		_watch_unit(now)
		_log("%s reforms into %s" % [_tag(was), _tag(now)])
		_mark())
	battle.leveled.connect(func(caster: Unit, t: Unit, n: int):
		_log("%s Level Down %s %s%s" % [_tag(caster), "-->" if n else "-x>", _tag(t), " (-%d level%s)" % [n, "" if n == 1 else "s"] if n else ""]))
	battle.gained_xp.connect(func(u: Unit, n: int, levels: int, from: Unit, saved: bool):
		if known(u):  # its own side's progress only
			_earned.append(["XP for %s %s" % ["saving" if saved else "felling", _tag(from)],
					"%s +%d%s" % [_tag(u), n, " (level %d)" % u.level if levels else ""]])
			_flush_falls.call_deferred()
			_mark())
	for u: Unit in battle.get_node("Units").get_children():
		_watch_unit(u)
	book_button.pressed.connect(toggle_spellbook)
	hold_button.pressed.connect(hold)
	party_button.pressed.connect(toggle_party)
	end_button.pressed.connect(_end_pressed)
	spellbook.switched.connect(func(s: Skill): switch(spellbook.unit, s))
	skills.unlocked.connect(_on_unlocked)
	skills.raised.connect(_on_raised)
	skills.leveled.connect(_on_leveled)
	%SkillsIcon.pressed.connect(toggle_skills)
	%BookIcon.pressed.connect(toggle_spellbook)
	%CogIcon.pressed.connect(toggle_settings)
	%SettingsClose.pressed.connect(_close_panels)
	%HighContrast.toggled.connect(func(on: bool) -> void:
		high_contrast = on
		_apply_contrast()
		_mark())
	var picker := OptionButton.new()  # Settings: the allied glow's colour
	picker.name = "AllyGlow"
	picker.focus_mode = Control.FOCUS_NONE
	picker.tooltip_text = "The glow of allies on another side"
	for n: String in ALLY_GLOWS:
		picker.add_item("Allied glow: " + n)
	picker.item_selected.connect(func(i: int) -> void:
		ally_glow = ALLY_GLOWS.values()[i]
		_mark())
	%HighContrast.get_parent().add_child(picker)
	KeyBinds.load_saved()
	var keys := KeyBinds.new()  # Settings: key rebinds
	keys.name = "KeyBinds"
	%Settings.get_node("Column").add_child(keys)
	%Settings.get_node("Column").move_child(keys, %Settings.get_node("Column/Options").get_index() + 1)
	%SuspiciousMarks.toggled.connect(func(on: bool) -> void:
		suspicious_marks = on
		_mark())
	%KeepSlot.toggled.connect(func(on: bool) -> void: keep_slot = on)
	%HandOver.button_pressed = hand_over
	%HandOver.toggled.connect(func(on: bool) -> void: hand_over = on)
	%LogTitle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			show_log(not log_open))
	%LogLine.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			show_log(true))
	show_log(log_open)
	add_to_group(&"guide")
	show_guide(guide_page)
	settings.get_parent().add_child(persona)
	settings.get_parent().add_child(sheet)
	sheet.hide()
	sheet.ap_of = battle.item_ap
	sheet.equipped.connect(_on_equipped)
	sheet.unequipped.connect(_on_unequipped)
	sheet.used_up.connect(_on_used_up)
	sheet.unshackled.connect(func(u: Unit, how: StringName) -> void:
		if _outfits(u) and not battle.unshackle(u, how):
			_say("%s needs %d AP for that" % [_name(u), u.trinket.ranked()] if u.trinket else "Nothing to take off")
		sheet.open(u, _outfits(u))
		_mark())
	persona.done.connect(_on_personified)
	battle.stalled.connect(_on_stalled)
	battle.struggled.connect(_on_struggled)
	battle.gripped.connect(_on_gripped)
	battle.discovered.connect(_on_discovered)
	battle.unmasked.connect(_on_unmasked)
	battle.vanished.connect(_on_vanished)
	battle.bumped.connect(_on_bumped)
	battle.untangled.connect(_on_untangled)
	battle.refused.connect(_on_refused)
	%CharacterIcon.pressed.connect(toggle_sheet)
	%MenuButton.pressed.connect(func(): get_tree().change_scene_to_file(menu_scene))
	banner.modulate.a = 0.0
	for c: Control in [tip, spellbook, skills, settings, over]:
		c.hide()
	if not battle.rolls.is_empty():
		_log("[color=#6b7180]Initiative: %s[/color]" % ", ".join(battle.order.map(
				func(f: Faction): return "%s %d" % [f.name, battle.total(f)])))
	_log("You lead %s" % _tag(command.leader))
	_rebuild_bar()
	_begin.call_deferred()


# The battle opens: the initiative roll plays out (when the HUD is paced to be watched), then the
# first turn starts.
func _begin() -> void:
	if battle.phase == Battle.Phase.PREP:
		_opening = true
		_log("[color=#6b7180]Preparation: look the field over. Click to study up to %d all%s (your cha mod) and %d foe%s or tile%s (your wis mod), a recon level better each; Begin when ready[/color]" % [
				battle.studies_left(command.leader, true), "y" if battle.studies_left(command.leader, true) == 1 else "ies",
				battle.studies_left(command.leader, false), "" if battle.studies_left(command.leader, false) == 1 else "s", "" if battle.studies_left(command.leader, false) == 1 else "s"])
		_mark()
		await prepared
		if not is_inside_tree():
			return
		for i in 2:  # the turn the roll set lands (deferred) while _opening, ignored: it starts below
			await get_tree().process_frame
		_log("[color=#6b7180]Initiative: %s[/color]" % ", ".join(battle.order.map(
				func(f: Faction): return "%s %d" % [f.name, battle.total(f)])))
	if pace > 0.0 and battle.phase == Battle.Phase.TURNS and not battle.unit_rolls.is_empty():
		busy = true
		_mark()
		_show_initiative()
		await intro_done
		if not is_inside_tree():
			return
		busy = false
	_opening = false
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
	_tick_clock(delta)
	_hurry()
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
	if e is InputEventKey and e.keycode == KEY_ALT and e.pressed != show_odds:
		show_odds = e.pressed
		_update_tip()


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
			click(_cell_at(e.position), e.ctrl_pressed or e.meta_pressed, e.shift_pressed, e.alt_pressed)
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
		_end_pressed()
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

# Focus: u, or with none given the player's own unit (its leader, while it stands and the battle's on).
# A new unit starts on its first slot, or with keep_slot the one it last used.
func select(u: Unit) -> void:
	if u == null and command and command.leader.is_alive() and battle.phase == Battle.Phase.TURNS:
		u = command.leader
	var was := selected
	selected = u if u and u.is_alive() else null
	if selected != was or not keep_slot:
		slot = _last_slot.get(selected, 0) if keep_slot else 0
	aim = false
	_note = ""
	_rebuild_bar()
	_replan()
	_mark()


# A click on the map: does what intent() says it means. force (Ctrl): strike at the tile, whatever
# seems to be there. inspect (Shift): select a foe rather than attack it. alt: a Rift cast unchanneled.
func click(c: Vector2i, force := false, inspect := false, alt := false) -> void:
	_run(intent(c, force, inspect, alt))


func hover_cell(c: Vector2i) -> void:
	if c == hover:
		return
	hover = c
	_replan()
	_update_tip()


# A hotbar slot's key or click: selects it. An area or trap skill aims as well (again: steps back); a
# self or automatic skill is used on the second press (or a click on the unit itself); a toggled
# passive switches; Personify opens its panel; a skill with elements asks which.
func use_slot(i: int) -> void:
	var u := selected
	if not u or not hand(u) or i < 0 or i >= u.hotbar.size() or not u.hotbar[i]:
		return
	var s: Skill = u.hotbar[i]
	var again := i == slot
	if not _orders(u):
		_refuse(u, _why_no_orders(u))
	elif skill_sense(u, s, view(u) if u != command.leader else null) == 0:
		_say("Your side can't make out what %s could do there" % _name(u))
	elif not command.slot_open(u, i):
		_refuse(u, _why_locked(u))
	elif not u.slot_works(i):
		_say(SkillSlot.NO_LUCK)
	elif s in u.disabled:
		_say("%s's %s is disabled for %d more turn%s" % [_name(u), s.name, u.disabled[s], "" if u.disabled[s] == 1 else "s"])
	elif s.passive and s.hybrid:
		if not command.may_use(u, s):
			return
		if not u.can_afford(s):
			_refuse(u, _short(u, s))
		else:
			_close_panels()
			_personifying = [u, s]
			persona.open(u, s, Battle.persona_rank(u, s))
	elif s.passive:
		switch(u, s)
	elif not s.elements.is_empty():
		if not u.can_afford(s):
			_refuse(u, _short(u, s))
		else:
			_pick_element(u, s)
	else:
		_pick_slot(u, i)
		if not u.can_afford(s):
			_refuse(u, _short(u, s))
		elif self_skill(u, s) and again:
			_run(intent(u.cell))  # the second press: used
		elif s.on_tile():
			aim = not (again and aim)
		_replan()
		_mark()


# Selects slot i of u's hotbar (remembered for keep_slot).
func _pick_slot(u: Unit, i: int) -> void:
	if i != slot:
		aim = false
	slot = i
	_last_slot[u] = i
	_note = ""


# A skill used on oneself, or at once (automatic: Sing): its slot selected, it's previewed on the unit;
# a second press or a click on the unit uses it.
func self_skill(u: Unit, s: Skill) -> bool:
	return s != null and not s.passive and (s.on_self(u) or s.auto)


# Whether an area or trap skill is aimed: tile clicks cast it.
func aiming() -> bool:
	return aim and armed != null and armed.on_tile()


# Steps back from aiming (the selected slot stays).
func disarm() -> void:
	aim = false
	_replan()
	_mark()


func switch(u: Unit, s: Skill) -> void:
	if not _orders(u) or not command.may_use(u, s) or not u.toggle(s):
		return
	var to: Variant = u.switching()
	if to != null and u.channel.skill == s:  # Mana, Stamina: a channel switching what it runs on
		_log("%s: switching to %s, channeled" % [_tag(u), "Energy" if to is StringName else to.name])
	else:
		_log("%s: %s %s" % [_tag(u), s.name, "on" if u.is_on(s) else "off"])
	_mark()


# Right click / Esc steps back once: a panel, then an aimed skill, then back to the player's own unit.
func cancel() -> void:
	if _panel_open():
		_close_panels()
	elif aiming():
		disarm()
	else:
		select(null)


func hold() -> void:
	var u := selected
	if not u or u == command.leader or not _orders(u) or u in command.ordered:
		return
	command.lock(u)  # held: done for the turn, and no autopilot once it ends (Command.idle())
	_log("%s holds" % _tag(u))
	_mark()
	_hand_over(u)


func toggle_party() -> void:
	var u := selected
	if not u or u == command.leader or not my_turn():
		return
	if u in command.party:
		command.leave(u)
		_log("%s leaves your party" % _tag(u))
	elif command.join(u):
		_log("%s joins your party" % _tag(u))
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
	return spellbook.visible or skills.visible or settings.visible or persona.visible or sheet.visible


# The character icon: the selected unit's sheet (else the leader's), its items changeable on its side's
# turn - or once the battle's over - if it's the player's own.
func toggle_sheet() -> void:
	var open := not sheet.visible
	_close_panels()
	if open:
		var u := selected if selected and hand(selected) else command.leader
		sheet.open(u, _outfits(u))


func _outfits(u: Unit) -> bool:
	return command.ours(u) and not busy and (battle.phase == Battle.Phase.OVER or (my_turn() and battle.outfitting(u)))


# The player's starter keeps what it has on, and its hearts, for the next battle.
func _keep_outfit(u: Unit) -> void:
	if u == battle.player:
		Game.outfit = {}
		for slot in CharacterSheet.SLOTS:
			if u.get(slot):
				Game.outfit[slot] = u.get(slot)
		Game.hearts = u.hearts


func _on_equipped(u: Unit, it: Item) -> void:
	if not _outfits(u) or it not in Game.stash or not u.can_wear(it):
		return
	var old: Item = u.get(it.slot)
	if not battle.equip(u, it):
		_say("%s needs %s AP to put on %s" % [_name(u), Skill.num(battle.equip_ap(u, it)), it.name])
		return
	Game.stash.erase(it)
	if old:
		Game.stash.append(old)
	_log("%s puts on %s" % [_tag(u), it.name])
	_keep_outfit(u)
	sheet.open(u, true)
	_mark()


func _on_unequipped(u: Unit, slot: String) -> void:
	if _outfits(u) and u.get(slot):
		var it := battle.unequip(u, slot)
		if not it:
			return
		Game.stash.append(it)
		_keep_outfit(u)
		sheet.open(u, true)
		_mark()


func _on_used_up(u: Unit, it: Item) -> void:
	if _outfits(u) and (it in Game.stash or it == u.trinket) and battle.use_item(u, it):
		Game.stash.erase(it)
		_log("%s uses %s" % [_tag(u), it.name])
		_keep_outfit(u)
		sheet.open(u, true)
		_mark()


# The Guide (Settings) at a page - with a term, scrolled to it. Panels' "i"s (GuideLink) and terms
# clicked in descriptions come here, through the "guide" group.
func open_guide(page: StringName, term := &"") -> void:
	_close_panels()
	settings.show()
	show_guide(page if page in Guide.PAGES else &"play")
	_update_tip()
	var at := Guide.terms(guide_page).find(term)
	if at >= 0:
		await get_tree().process_frame
		%Guide.scroll_to_paragraph(at * 2)  # a blank line between terms


func show_guide(page: StringName) -> void:
	guide_page = page
	%Guide.text = Guide.text(page)
	%Guide.scroll_to_line(0)
	var box: HBoxContainer = %GuidePages
	if box.get_child_count() == 0:
		var group := ButtonGroup.new()
		for id in Guide.ids():
			var b := Button.new()
			b.text = Guide.title(id)
			b.toggle_mode = true
			b.button_group = group
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override(&"font_size", 6)
			b.pressed.connect(show_guide.bind(id))
			box.add_child(b)
	for i in box.get_child_count():
		(box.get_child(i) as Button).set_pressed_no_signal(Guide.ids()[i] == page)


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
	persona.hide()
	sheet.hide()
	_mark()
	_update_tip()


# The end turn button (and Space): in preparation, Begin.
func _end_pressed() -> void:
	if battle.phase == Battle.Phase.PREP:
		begin_battle()
	else:
		end_turn()


# Preparation's over: the initiative roll, then the first turn (_begin()).
func begin_battle() -> void:
	if battle.phase != Battle.Phase.PREP:
		return
	battle.begin()
	prepared.emit()
	_mark()


# In preparation, a click studies what's there for the battle (Battle.study()): an ally by cha, a foe
# or the tile by wis.
func _study(c: Vector2i) -> void:
	var u := unit_seen(c)
	var k: Variant = u if u else c
	if u:
		select(u)
	if u == command.leader:
		return
	var ally := battle._studies_ally(command.leader, k)
	if battle.study(command.leader, k):
		_log("%s studies %s" % [_tag(command.leader), _tag(u) if u else _seen_as(command.leader, c)])
	elif battle.studied.get(command.faction(), {}).has(k):
		_say("Already studied")
	else:
		_say("No %s studies left (your %s mod)" % ["ally" if ally else "foe or tile", "cha" if ally else "wis"])
	_mark()


func end_turn() -> void:
	if not my_turn():
		return
	clock_on = false
	spellbook.hide()
	_act_alone(command.faction(), command.idle())


# The player's time to act a turn, in seconds: its wisdom plus half its intelligence.
func turn_seconds() -> float:
	return command.leader.stat(&"wisdom") + floorf(command.leader.stat(&"intelligence") / 2.0)


# The turn clock ticks while it's the player's turn - but not while Settings is open, nor unwatched
# (pace 0: tests) - and ends the turn when it runs out. Shown top middle, red in its last 5 seconds.
func _tick_clock(delta: float) -> void:
	var on := turn_clock and pace > 0.0 and clock_on and my_turn()  # not before _on_turn() sets it: turns change deferred
	clock_label.visible = on
	if not on:
		return
	if not settings.visible:
		clock = maxf(clock - delta, 0.0)
	var shown := minf(clock, turn_seconds())
	clock_label.text = "%d" % ceilf(shown)
	clock_label.add_theme_color_override(&"font_color", FOE if shown <= 5.0 else Color.WHITE)
	if clock <= 0.0:
		_log("[color=#6b7180]Out of time[/color]")
		end_turn()


func my_turn() -> bool:
	return not busy and battle.phase == Battle.Phase.TURNS and command.leader.is_alive() \
			and battle.turn == command.faction() and not autopilot()


# Units on the player's side: everything about them is known.
func known(u: Unit) -> bool:
	return u.faction == command.faction()


# Units the player gives orders to as its own: its side's, and a traitor posing in its party (whose
# insides the player still only knows as it reads them).
func hand(u: Unit) -> bool:
	return known(u) or command.ours(u)


# Elemental Strike: a choice of its elements; the pick imbues u's Strikes (Battle.imbue()).
func _pick_element(u: Unit, s: Skill) -> void:
	var picks := []
	for el in s.elements:
		picks.append([String(el).capitalize(), func() -> void:
			u.element = el
			if battle.cast(u, s, u):
				_done(u)
			else:
				_say("%s doesn't take" % s.name)
			_mark()])
	_choose(s.name, picks)


# A small themed choice panel in the HUD (a popup window would miss its theme and scale): a title, a
# button per [label, callable] - picking runs it and closes the panel - and Cancel.
func _choose(title: String, picks: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Choice"
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	var head := Label.new()
	head.theme_type_variation = &"Title"
	head.text = title
	col.add_child(head)
	for pick in picks:
		var b := Button.new()
		b.text = pick[0]
		b.focus_mode = Control.FOCUS_NONE
		var act: Callable = pick[1]
		b.pressed.connect(func() -> void:
			panel.queue_free()
			act.call())
		col.add_child(b)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(panel.queue_free)
	col.add_child(cancel)
	panel.add_child(col)
	settings.get_parent().add_child(panel)
	panel.reset_size()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	return panel


# The player's own unit is down (or gone): its side plays itself until the battle ends or the
# player gets back up (a heart, a Red Spinel Ring).
func autopilot() -> bool:
	return battle.player != null and (not is_instance_valid(battle.player) or not battle.player.is_alive())


# Someone on the player's side still standing: the leader if it can be.
func observer() -> Unit:
	if command.leader.is_alive():
		return command.leader
	var allies := battle.members(command.faction())
	return allies[0] if allies else null


# The player is commanding a unit: one of its side, selected, on its side's turn (taking an order
# right now or not, so the view holds steady as orders are spent).
func commanding() -> bool:
	return selected != null and is_instance_valid(selected) and selected.is_alive() and known(selected) \
			and battle.phase == Battle.Phase.TURNS and battle.turn == command.faction() and not autopilot()


# Whose eyes the player sees through: the unit it commands, else observer() (the leader if it can be).
func eyes() -> Unit:
	return selected if commanding() else observer()


# What the player's side makes out about a unit: what the player sees - through the unit it commands,
# else its leader, else whoever of its side is still standing (eyes()). The viewer's own card reads as
# the leader sees it. Others' sight reaches it only through skills that share what they make out
# (Coordinate: Battle.read()). The observer itself, and with no one left to look, nothing.
func view(u: Unit) -> Read:
	var o := eyes()
	if o == u:
		o = observer()
	if o == null or o == u:
		var none := Read.new()
		none.net = -4
		return none if o == null else battle.read(o, u)
	var r := battle.read(o, u)
	var pings := battle.pinged(o.faction)
	if not r.located() and pings.has(u):
		r.cell = pings[u]  # sensed there, though it's since moved on (Clairvoyance): drawn where it was
		r.concealed = true
	return r


func tile_view(c: Vector2i) -> Read:
	var o := eyes()
	return battle.read(o, c) if o else Read.new()


# How the player's side judges a tile: &"bad" (a known trap, or known to be detrimental), &"unsure"
# (not made out, or something may be lurking there), or &"safe" (most ground: neutral, or beneficial).
# `r`: its tile_view(), if already read.
func ground(c: Vector2i, r: Read = null) -> StringName:
	if r == null:
		r = tile_view(c)
	if r.trap == true or (r.worth != null and r.worth < 0):
		return &"bad"
	if r.net < 0 or r.hint or c in dubious:
		return &"unsure"
	return &"safe"


# The unit at c, if the player's side can make out that something's there.
func unit_seen(c: Vector2i) -> Unit:
	var u := battle.unit_at(c)
	return u if u and (known(u) or view(u).cell == c) else null


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
		if (s.on_self(u) or s.auto) and target != u:
			return "%s is used on oneself" % s.name if s.on_self(u) else "%s is used at once, on whoever is nearest" % s.name
		var ally: bool = target.faction == u.faction if known(target) else _reads_as_ally(target)
		if ally and not s.for_allies():
			return "%s is for foes" % s.name
		if not ally and not s.for_foes():
			return "%s is for allies" % s.name
		for b: Behaviour in s.behaviours:  # the same filter Battle.cast() makes (Resuscitate: only the Downed)
			if not b.fits(battle, u, target):
				return b.unfit()
		if not battle.in_reach(u, s, target):
			return "Out of reach"
	elif target is Vector2i and s.channel and u.channel and u.channel.skill == s:
		if target not in battle.strike_tiles(u):
			return "Out of the channel's reach: %d tile%s from where it was cast" % [u.channel.turns, "" if u.channel.turns == 1 else "s"]
		return "" if u.can_strike(s) else "Not enough to strike: %s AP, %d Energy" % [Skill.num(u.strike_ap(s)), u.strike_cost(s)]
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

# What a click on c means, worked out once: the overlay draws it (hovered, plan, charge), the tooltip
# words it, click() runs it (_run()). {kind, cell, unit (who acts), skill, target (a Unit, or the cell
# for an area skill), dest (where it walks first: its own cell if nowhere), walk (Battle.walk() there,
# expected, or {}), ready (the skill should be usable from dest), why (a refusal's reason), alt}.
# Kinds: none, study (preparation), walk, use (walk to dest, then use skill on target: on itself for a
# self skill), strike_at (walk, then strike at the tile whatever's there), command_walk (the leader walks
# into order range of an ally), rest / continue (a channel) / done (it already acted): itself, ending
# only its own turn; select, let_go, refuse.
func intent(c: Vector2i, force := false, inspect := false, alt := false) -> Dictionary:
	var me := selected
	var it := {kind = &"none", cell = c, unit = me, skill = null, target = null, dest = me.cell if me else NOWHERE, walk = {}, ready = false, why = "", alt = alt}
	if c == NOWHERE:
		return it
	if battle.phase == Battle.Phase.PREP:
		it.kind = &"study"
		return it
	var t := unit_seen(c)
	var s := armed
	var mine := _orders(me)
	if mine and aiming() and _slot_usable(me, slot):  # an area or trap skill: the tile
		it.skill = s
		it.target = c
		var why_tile := why_not(me, s, c)
		if why_tile == "Out of reach":
			return _refusal(it, why_tile)
		it.kind = &"use"
		it.ready = true
		it.why = why_tile
		return it
	if mine and t == me and self_skill(me, s) and _slot_usable(me, slot):  # a self skill selected: used on itself
		it.kind = &"use"
		it.skill = s
		it.target = me
		it.why = why_not(me, s, me)
		it.ready = it.why == ""
		return it
	if mine and force and not (t and known(t)):  # Ctrl: strike at the tile, whatever seems to be there
		var p := s if s and s.for_foes() and not s.on_tile() and not self_skill(me, s) else _primary(me)
		if p:
			it.skill = p
			it.target = c
			return _walk_to(it, &"strike_at", _approach(me, p, c).dest, true)
	if mine and t and s and _slot_usable(me, slot) and not s.on_tile() and not self_skill(me, s) and t != me and not (inspect and foe(t)):
		var why := why_not(me, s, t)
		if why == "" or why == "Out of reach":  # the selected skill is for it
			return _use_intent(it, s, t)
	if mine and t and not inspect and foe(t):
		var p := _primary(me)
		if p:
			return _use_intent(it, p, t)
	if mine and t == me:  # itself: rest, keep a channel going, or (having acted) stand down for the turn
		it.target = me
		it.kind = (&"continue" if me.channel else &"rest") if me.idle() else &"done"
		return it
	if mine and t and me == command.leader and known(t) and command.could_order(t) and not command.in_range(t):
		var w := _into_command(t)  # an ally out of reach of orders: the leader's walk into range of it
		if w.dest != me.cell and w.sure:
			it.target = t
			return _walk_to(it, &"command_walk", w.dest, true)
	if t:
		it.kind = &"select"
		it.target = t
		return it
	if me and hand(me) and battle.turn == command.faction():
		if not mine:
			return _refusal(it, _why_no_orders(me))
		if c == me.cell:
			return it
		it.kind = &"walk"
		it.dest = c
		it.walk = battle.walk(me, c, true)
		return it
	it.kind = &"let_go"
	return it


# Using s on t: from here; after a walk it can count on into reach; refused when only a walk it can't
# count on gets there (unsure); or, out of reach this turn, a walk as close as it gets (not ready).
func _use_intent(it: Dictionary, s: Skill, t: Unit) -> Dictionary:
	var me: Unit = it.unit
	it.skill = s
	it.target = t
	var why := why_not(me, s, t)
	if why != "Out of reach":
		it.kind = &"use"
		it.ready = why == ""
		it.why = why
		return it
	var a := _approach(me, s, t.cell, true)
	if a.ready:
		return _walk_to(it, &"use", a.dest, true)
	a = _approach(me, s, t.cell)
	if a.ready:
		it.unsure = true  # only a walk it can't count on gets there: a click doesn't walk
		return _refusal(it, why)
	it.why = why
	return _walk_to(it, &"use", a.dest, false)


# How many hazard estimates u has left this turn: its int mod, less those it acted on (foresight_used).
# Below 0 it doesn't even know what it doesn't know (drain(): no "?").
func foresight(u: Unit) -> int:
	return u.mod(&"intelligence") - foresight_used.get(u, 0)


# What carrying out an intent would consume, as the unit expects it - the "will consume" signal, drawn
# as a draining segment on its own bars and card rows: {move, ap, hp, energy, <Reserve>: amount;
# unsure: [keys whose cost it can't foresee: a flashing "?" after the number]; estimated: true when a
# hazard estimate went into it (acting on it spends foresight())}. The walk's movement and the skill's
# AP and cost (after exhaustion) always show; what known traps on the way would do is an estimate:
# with foresight left, their average damage on HP; with none (or at int mod +0), only "?"; below 0,
# nothing - the walk looks safe.
func drain(it: Dictionary) -> Dictionary:
	var d := {}
	var u: Unit = it.get("unit")
	if not u or not _orders(u) or it.get("kind") not in [&"walk", &"use", &"strike_at", &"command_walk"]:
		return d
	var w: Dictionary = it.get("walk", {})
	if not w.is_empty() and not w.path.is_empty():
		d[&"move"] = w.costs.reduce(func(sum, x): return sum + x, 0.0)
		for c: Vector2i in w.path:
			if tile_view(c).trap != true:
				continue
			var mind := u.mod(&"intelligence")
			if mind < 0:
				continue  # it plans as if the way were safe
			if foresight(u) > 0:
				var t := battle.terrain(c)
				d[&"hp"] = d.get(&"hp", 0.0) + t.times * t.dice.x * (t.dice.y + 1) / 2.0 + t.bonus
				d.estimated = true
			elif &"hp" not in d.get("unsure", []):
				d.get_or_add("unsure", []).append(&"hp")
	var s: Skill = it.get("skill")
	if s and (it.ready or it.kind == &"strike_at"):
		var fund: Variant = u.funding(s)
		d[&"ap"] = d.get(&"ap", 0.0) + u.ap_cost(s, fund)
		var cost := u.cost_from(s, fund)
		if cost:
			var key: Variant = fund if fund is Reserve else &"energy"
			d[key] = d.get(key, 0.0) + cost
	return d


# The span of HP the hovered attack would take off its target when a hit lands, if the player's side
# can make out its HP: {unit, lo, hi}; {} otherwise (an unknown HP keeps its read; no number is made up).
func _hurt(it: Dictionary) -> Dictionary:
	var t: Variant = it.get("target")
	var s: Skill = it.get("skill")
	var u: Unit = it.get("unit")
	if it.get("kind") != &"use" or not it.ready or not (t is Unit) or t == u or not s or not s.for_foes() or not foe(t):
		return {}
	if not known(t) and view(t).hp == null:
		return {}
	var m := u.mods(s)  # its modifiers (Battle.cast() reads the same)
	var tier := s.tier(m.irank(u.rank(s), &"rank_impact"))
	if not tier:
		return {}
	var hits := u.rank(s) if s.hits_per_rank else 1
	var bonus := m.stat(u.mod(u.wielded(tier.stat, s.tags), s.tags), &"stat_impact") + u.weapon_bonus(tier.stat) if tier.stat else 0
	return {unit = t, lo = maxi(tier.power + tier.dice.x + bonus, 1) * hits, hi = maxi(tier.power + tier.dice.x * tier.dice.y + bonus, 1) * hits}


# How likely the hovered attack is to land, as the target's brackets show it: &"likely" (solid),
# &"even" (broken), &"unlikely" (faint), &"unknown" (its Defense can't be made out: wavering), or &""
# (not an attack roll).
func odds(it: Dictionary) -> StringName:
	var t: Variant = it.get("target")
	var s: Skill = it.get("skill")
	if it.get("kind") != &"use" or not (t is Unit) or not s or not s.attacks() or not foe(t):
		return &""
	if not _defense_shows(t):
		return &"unknown"
	var p := Battle.hit_chance(it.unit, s, t, battle)
	return &"likely" if p >= 0.65 else (&"even" if p >= 0.35 else &"unlikely")


# A refused order: the unit shakes and one word floats off it ("Too far", "Spent"); the full reason
# stays on the hint line.
func _refuse(u: Unit, why: String) -> void:
	_nag(why)
	if not why or not u:
		return
	var word := "No"
	for pair in [["reach", "Too far"], ["within", "Too far"], ["closer", "Too far"], ["Not enough", "Short"], ["movement", "Spent"], ["Asleep", "Asleep"],
			["Wait", "Wait"], ["Downed", "Down"], ["Held", "Held"], ["commands", "Spent"], ["order", "Spent"], ["Pick", "Pick"]]:
		if pair[0] in why:
			word = pair[1]
			break
	refused.emit(u, word)
	if overlay:
		overlay.float_text(u, word, FOE)
	var tw := u.create_tween()
	var at := u.position
	for dx in [2.0, -2.0, 1.5, -1.0, 0.0]:
		tw.tween_property(u, "position:x", at.x + dx, 0.04)


func _refusal(it: Dictionary, why: String) -> Dictionary:
	it.kind = &"refuse"
	it.why = why
	return it


# The intent walks to dest first (none if it's already there), then does `kind`.
func _walk_to(it: Dictionary, kind: StringName, dest: Vector2i, ready: bool) -> Dictionary:
	it.kind = kind
	it.dest = dest
	it.ready = ready
	if dest != it.unit.cell:
		it.walk = battle.walk(it.unit, dest, true)
	return it


# Does what an intent says (click()).
func _run(it: Dictionary) -> void:
	var u: Unit = it.unit
	var s: Skill = it.skill
	if it.kind in [&"walk", &"use", &"strike_at", &"command_walk"] and drain(it).get("estimated", false):
		foresight_used[u] = foresight_used.get(u, 0) + 1  # it acted on a hazard estimate: one of its turn's spent
	match it.kind:
		&"study":
			_study(it.cell)
		&"disarm":
			disarm()
		&"refuse":
			_refuse(u, it.why)
		&"select":
			var t: Unit = it.target
			select(t)
			if uses_intents(t) and not intent_options(t).is_empty():
				_show_intents(t)  # a commander who can only direct it by intent: ATTACK / DEFEND / HELP
		&"let_go":
			select(null)
		&"walk":
			_move(u, it.cell)
		&"command_walk":
			_move(u, it.dest)
		&"rest", &"continue", &"done":
			command.lock(u)  # only this unit's turn ends
			_log("%s %s" % [_tag(u), {&"rest": "rests", &"continue": "keeps channeling", &"done": "stands down"}[it.kind]])
			_done(u, true)
		&"use", &"strike_at":
			var walked: bool = it.dest != u.cell
			if walked:
				battle.travel(u, it.dest)
				command.order(u)
			if it.kind == &"strike_at":
				_strike_at(u, s, it.cell, walked)
				return
			var target: Variant = it.cell if s.on_tile() else unit_seen(it.cell)
			var why := why_not(u, s, target)
			var took := false
			if why == "" or not walked:
				took = battle.cast_at(u, s, it.cell, not it.alt) if s.on_tile() else (target != null and battle.cast(u, s, target))
			if took:
				_done(u, walked)
				return
			_refuse(u, why if why else "%s doesn't take" % s.name)
			_replan()
			_mark()


# Strikes at a tile, whatever seems to be there (Battle.attempt).
func _strike_at(u: Unit, s: Skill, c: Vector2i, counted := false) -> void:
	match battle.attempt(u, s, c):
		&"hit":
			_done(u, counted)
		&"miss":
			_done(u, counted)
			_say("Nothing there")
		&"shattered":
			_done(u, counted)
		_:
			var why := why_not(u, s, c)
			_say(why if why else "Can't strike there")


# The persona panel's Done: Personify pays its AP and puts the picks forward.
func _on_personified(changes: Dictionary) -> void:
	var u: Unit = _personifying[0]
	if battle.personify(u, _personifying[1], changes):
		_done(u)
	else:
		_say("%s doesn't take" % _personifying[1].name)
	_update_tip()


# Ramut's Ire builds on a unit stalling the fight. Who it is shows only where the player can place it.
func _on_stalled(u: Unit, rank: int) -> void:
	var who := _tag(u) if known(u) or view(u).located() else "something"
	_log("%s %s --> %s" % [Battle.IRE.name, Skill.roman(rank), who])
	_mark()


# A held unit tries to break free of its holder's grip (Drown), where the player can make out either.
func _on_struggled(u: Unit, by: Unit, total: int, against: int) -> void:
	if not (known(u) or known(by) or view(u).located()):
		return
	_log("%s breaks free%s%s%s" % [_tag(u), _arrow(total > against), _tag(by), _rolls(total, against if known(by) else null)])
	_mark()


# Still held as its turn ends, it takes the grip.
func _on_gripped(u: Unit, by: Unit, dealt: int) -> void:
	if not (known(u) or known(by) or view(u).located()):
		return
	var a := battle.held_by(u)
	var grip := "%s %s" % [a.skill.name, Skill.roman(by.rank(a.skill))] if a and a.skill else "grip"
	_log("%s %s%s%s%s" % [_tag(by), grip, _arrow(true), _tag(u), " [color=#ff6b5e]-%d[/color]" % dealt if _hp_shows(u) else ""])
	_mark()


# Suspicion is logged at its turns, not stack by stack: one of the player's units finds something odd
# about a unit or tile ("?": its first suspicion of it), sees through it ("!": what it took it for,
# then what it is), or watches a unit vanish before its eyes ("!?": it goes on taking it for its side).
func _on_discovered(by: Unit, of: Variant) -> void:
	if known(by):
		_log("%s [color=#%s]?[/color] %s" % [_tag(by), GOLD.to_html(false), _seen_as(by, of)])
		_mark()


func _on_unmasked(by: Unit, of: Variant, was: Read) -> void:
	if known(by):
		var then := (was.name if was.name else ("a %s" % was.looks if was.looks else "Something")) if of is Unit else \
				"%s at %d, %d" % [was.name if was.name else "The ground", of.x, of.y]
		var now := battle.read(by, of)
		var is_now := (now.name if now.name else "Something") if of is Unit else (("a " + now.name) if now.name else "something")
		_log("%s [color=#%s]![/color] %s is %s" % [_tag(by), FOE.to_html(false), then.replace("[", "[lb]"), is_now.replace("[", "[lb]")])
		_mark()


func _on_vanished(by: Unit, of: Unit, was: Read) -> void:
	if known(by):
		_log("%s [color=#%s]!?[/color] %s vanishes" % [_tag(by), SUSPICION.to_html(false), (was.name if was.name else "Something").replace("[", "[lb]")])
		_mark()


# One of the player's units walked into something it couldn't see (Battle.bumped): a recon level on it.
func _on_bumped(u: Unit, into: Unit) -> void:
	if known(u):
		_log("%s bumps into %s" % [_tag(u), _seen_as(u, into).to_lower() if battle.read(u, into).name else "something unseen"])
		_mark()


# A unit or tile as `by` knows it, for the log: "Precious Friend", "Grass at 3, 4".
func _seen_as(by: Unit, of: Variant) -> String:
	if of is Unit:
		return known_name(by, of).replace("[", "[lb]")
	var r := battle.read(by, of)
	return "%s at %d, %d" % [(r.name if r.name else "The ground").replace("[", "[lb]"), of.x, of.y]


# One of the player's units, under Haluca, sees an ally's tags straight again.
func _on_untangled(by: Unit, of: Unit, total: int, against: int) -> void:
	if known(by) and total >= against:
		_log("%s sees through Haluca%s%s%s" % [_tag(by), _arrow(true), _tag(of), _rolls(total, against)])
		_mark()


# A traitor posing in the player's party won't do as it's told (or acted on its own side's turn).
func _on_refused(u: Unit, leader: Unit) -> void:
	if leader == command.leader:
		_log("%s refuses %s" % [_tag(u), _tag(leader)])
		_mark()


# The order went through: the unit has acted, and whatever was armed is spent. counted: the order
# was already counted (a charge's walk, then its strike: one order).
func _done(u: Unit, counted := false) -> void:
	if not counted:
		command.order(u)
	aim = false
	if not keep_slot:
		slot = 0
	_note = ""
	_replan()
	_mark()
	_hand_over(u)


# Pace (hand_over): a spent unit - one that can't take another order this turn - hands the focus to
# the next that can (next_able()). Only the selected one, on the player's turn; none left, it stays.
func _hand_over(u: Unit) -> void:
	if not hand_over or u != selected or not my_turn() or _orders(u):
		return
	var to := next_able(u)
	if to:
		select(to)


# The next unit after u (the side's order, as Tab walks it, wrapping) that can take an order: the
# first that hasn't had one this turn, else the first that can still act.
func next_able(u: Unit) -> Unit:
	var side := battle.members(command.faction())
	var at := side.find(u)
	var any: Unit = null
	for k in range(1, side.size() + 1):
		var v := side[(at + k) % side.size()]
		if v == u or not _orders(v):
			continue
		if v not in command.ordered:
			return v
		if not any:
			any = v
	return any


# The skill a click on a foe uses: the first attack from the selected slot rightward, wrapping around,
# that the unit may be told to use and can make out.
func _primary(u: Unit) -> Skill:
	var n := u.hotbar.size()
	var from := slot if u == selected else 0
	for k in n:
		var i := (from + k) % n
		var s: Skill = u.hotbar[i]
		if s and s.for_foes() and not s.on_tile() and not self_skill(u, s) and _slot_usable(u, i):
			return s
	return null


# Whether u may use the active skill in slot i now, as far as the bar goes: the slot's open to it (on
# the leader's orders), works (clover), and the skill isn't disabled and can be made out.
func _slot_usable(u: Unit, i: int) -> bool:
	var s: Skill = u.hotbar[i] if i >= 0 and i < u.hotbar.size() else null
	return s != null and not s.passive and command.slot_open(u, i) and u.slot_works(i) and s not in u.disabled \
			and skill_sense(u, s, view(u) if u != command.leader else null) > 0


# Where u would walk to use s on whatever is at c: the cheapest tile it expects to reach that has c
# in reach and leaves the AP to use s; failing that, the reachable tile nearest c. Its own tile if
# it's already in reach. {dest, ready}: ready says s should be usable from dest. sure: only by a walk
# it can count on (_sure_walk()).
func _approach(u: Unit, s: Skill, c: Vector2i, sure := false) -> Dictionary:
	var span := battle.skill_range(u, s, unit_seen(c))
	var near := func(at: Vector2i) -> bool: return Vector2(at).distance_to(Vector2(c)) <= span + 0.0001
	if near.call(u.cell):
		return {dest = u.cell, ready = u.can_afford(s)}
	_find_reach()
	var best := u.cell
	var best_cost := INF
	var closest := u.cell
	for at in reach:
		if near.call(at) and u.can_afford_after(s, reach[at]) and reach[at] < best_cost and (not sure or _sure_walk(u, _ways[at])):
			best = at
			best_cost = reach[at]
		var d := Vector2(at).distance_to(Vector2(c))
		if d < Vector2(closest).distance_to(Vector2(c)) - 0.0001:
			closest = at
	return {dest = best, ready = true} if best_cost < INF else {dest = closest, ready = false}


func _move(u: Unit, c: Vector2i) -> void:
	if c == u.cell:
		return
	if battle.travel(u, c).is_empty():
		if battle.held_by(u):
			_refuse(u, "Held fast: breaking free takes %s movement and a %s contest" % [Skill.num(battle.escape_cost(u)), String(battle.held_by(u).skill.stat()).left(3)])
		else:
			_refuse(u, "Can't get any closer" if u.move_left() > 0.0001 else "No movement left this turn")
		return
	command.order(u)
	_note = ""
	_replan()
	_mark()
	_hand_over(u)


# Units acting on their own (AI), one at a time so it can be followed; then f's turn ends.
func _act_alone(f: Faction, units: Array[Unit], wait := 0.0) -> void:
	busy = true
	aim = false
	plan = {}
	_mark()
	if pace > 0.0 and wait > 0.0:
		await _wait(wait)
		if not is_inside_tree():
			return
	for u in units:
		if battle.phase != Battle.Phase.TURNS or battle.turn != f:
			break
		if not u.is_alive():
			continue
		if pace > 0.0 and not together:
			await _wait(pace)
			if not is_inside_tree():
				return
		if not together:
			select(u if unit_seen(u.cell) == u else null)
		AI.act(battle, u)
		_mark()
	if pace > 0.0 and battle.phase == Battle.Phase.TURNS:
		await _wait(pace)
		while is_inside_tree() and overlay.walking_left() > 0.0:  # together: till the last walk is done
			await get_tree().process_frame
		if not is_inside_tree():
			return
	busy = false
	_mark()
	if battle.phase == Battle.Phase.TURNS and battle.turn == f:
		battle.end_turn()


# Pace: how fast paced shows run - HURRY times while the hurry key is held, else 1.
func speed() -> float:
	return HURRY if Input.is_action_pressed(&"hurry") else 1.0


# Waits `seconds` of paced time: hurried (speed()) for as long as the key is held, frame by frame.
func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds and is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time() * speed()


# The turn change and the walks under way run at speed() (read every frame: letting go slows them back).
func _hurry() -> void:
	var s := speed()
	if _turn_show and _turn_show.is_valid():
		_turn_show.set_speed_scale(s)
	if is_instance_valid(overlay):
		overlay.hurry(s)


# --- Battle events

func _on_turn(_was: Faction, now: Faction) -> void:
	if battle.phase != Battle.Phase.TURNS or now != battle.turn or _opening:
		return  # stale: the turn moved on before this ran (or the opening's still showing: _begin() starts it)
	var i := battle.order.find(now)
	if i <= _last_turn:
		round_no += 1
	_last_turn = i
	var mine := now == command.faction() and command.leader.is_alive() and not autopilot()
	_log("[color=#6b7180]Round %d · %s[/color]" % [round_no, now.name])
	_transition(now, mine)
	if mine:
		command.new_turn()
		foresight_used.clear()
		select(command.leader)
		clock = turn_seconds() + (TRANSITION if pace > 0.0 else 0.0)  # its clock starts once the turn change has shown
		clock_on = true
	elif auto or now == command.faction():  # the player's down: its side fights on (autopilot())
		if now == command.faction() and autopilot():
			_log("[color=#6b7180]You're down: your side fights on without you[/color]")
		_act_alone(now, battle.members(now), TRANSITION)
	_mark()


func _on_phase(_was: Battle.Phase, now: Battle.Phase) -> void:
	if now != Battle.Phase.OVER:
		return
	var winner := battle.victor()
	var ours := battle.won(command.faction())
	%OverTitle.text = "Victory" if ours else "Defeat"
	%OverText.text = ("%s holds the field." % (command.faction().name if ours else winner.name)) if winner else "No one is left standing."
	var won: Array[Item] = battle.winnings(command.faction()) if ours else ([] as Array[Item])
	if not won.is_empty():
		Game.stash.append_array(won)
		%OverText.text += "\nSpoils: %s" % ", ".join(won.map(func(it: Item): return it.name))
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


# A contest in place of an attack roll (Drown), likewise.
func _on_contested(caster: Unit, target: Unit, total: int, against: int) -> void:
	_roll = {caster = caster, target = target, total = total, against = against, hit = total >= against, crit = false}


func _on_used(caster: Unit, skill: Skill, at: Variant, dealt: int) -> void:
	_mark()
	var looks := _looks
	_looks = []
	var roll := _roll if _roll.get("caster") == caster and _roll.get("target") == at else {}
	_roll = {}
	if skill.lays and not known(caster):
		if unit_seen(caster.cell) == caster:
			_log("%s is setting something up" % _tag(caster))
		return  # where, and what, is theirs to know
	var hit: bool = roll.is_empty() or roll.hit
	var text := "%s %s %s" % [_tag(caster), caster.skill_name(skill), Skill.roman(caster.rank(skill))]
	if at is Unit and at != caster:
		text += _arrow(hit) + _tag(at)
	elif at is Vector2i and skill.lays:
		var told: int = battle.snares[at].known.size() - 1 if at in battle.snares else 0
		text += "%s%d, %d%s" % [_arrow(true), at.x, at.y, ", %d %s told" % [told, "ally" if told == 1 else "allies"] if told > 0 else ""]
	elif at is Vector2i and not skill.on_tile():
		text += _arrow(false) + "air"
	elif at is Vector2i:
		text += "%s%d, %d" % [_arrow(true), at.x, at.y]
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
		elif known(caster):
			overlay.float_text(at, "Hit!", FOE)
	_log(text)
	for l in looks:
		_log("%s investigates%s%s%s" % [_tag(l[0]), _arrow(l[1] >= l[2]), _tag(at) if at is Unit else _tag(caster),
				_rolls(l[1], l[2] if l[3] else null)])
	_flush_falls()


# Logs the units that fell, after whatever felled them: a skill's line (_on_used()), else - a grip,
# a bleed, a trap - once the moment's lines are in.
func _flush_falls() -> void:
	for line in _falls:
		_log(line)
	_falls.clear()
	var lines: Array = []  # [what for, its parts]: "XP for felling Siren: Brick +6, Ash +3 (level 2)"
	for e in _earned:
		if lines and lines[-1][0] == e[0]:
			lines[-1][1].append(e[1])
		else:
			lines.append([e[0], [e[1]]])
	_earned.clear()
	for l in lines:
		_log("%s: %s" % [l[0], ", ".join(l[1])])


# Whether the player knows the roll u's skill was put on it with (Clever Disguise): u is on its
# side, and an ally's Self-evaluation saw it.
func roll_known(u: Unit, s: Skill) -> bool:
	return u.faction == command.faction() and s.effects.any(func(e: Effect): return e in u.timed and u.timed[e].evaluated)


# An ally's Self-evaluation saw a roll u made: on the player's side, it tallies up above u.
func _on_evaluated(u: Unit, _s: Skill, d20: int, total: int) -> void:
	if u.faction == command.faction():
		overlay.float_roll(u, d20, total)
	_mark()


# An attack roll or contest, the log's way: " (14 - 11)" against Defense (or the other side's roll),
# " (14)" where the player can't make Defense out, " (nat 20)".
func _roll_text(roll: Dictionary, target: Unit) -> String:
	if roll.has("against"):
		return _rolls(roll.total, roll.against)
	if roll.crit:
		return " [color=#6b7180](nat 20)[/color]"
	return _rolls(roll.total, roll.defense if _defense_shows(target) else null)


# The log's rolls: " (ours - theirs)", or " (ours)" where theirs is unknown to the player.
func _rolls(total: int, against: Variant) -> String:
	return " [color=#6b7180](%d%s)[/color]" % [total, " - %d" % against if against != null else ""]


# The log's arrow from actor to target: " --> " when it lands, " -x> " when it misses or fails.
func _arrow(landed: bool) -> String:
	return " --> " if landed else " -x> "


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
	_log("Trap --> %s" % _tag(by))


# The blow a unit is taking (Unit.taking_hit), for its damage number's colour: kept until the frame ends.
var _blows := {}


func _on_taking_hit(u: Unit, blow: Dictionary) -> void:
	_blows[u] = blow.tags
	(func() -> void: _blows.erase(u)).call_deferred()


# A damage number in the colour of what the blow was made of (Tags.mark() past the broad words: a
# fireball's in fire's), else red.
func _hurt_colour(u: Unit) -> Color:
	var t := Tags.mark(_blows.get(u, []), Tags.BROAD)
	return Tags.color(t) if t else FOE


func _on_hp(was: int, now: int, u: Unit) -> void:
	_mark()
	if not _hp_shows(u):
		return
	if now < was:
		overlay.float_text(u, "-%d" % (was - now), _hurt_colour(u))
	elif now > was:
		overlay.float_text(u, "+%d" % (now - was), FRIEND)


func _watch_unit(u: Unit) -> void:
	u.hp_changed.connect(_on_hp.bind(u))
	u.taking_hit.connect(_on_taking_hit)
	u.energy_changed.connect(_on_energy.bind(u))
	u.reserve_changed.connect(_mark.unbind(3))
	u.overcharge_changed.connect(_mark.unbind(2))
	u.died.connect(_on_died)


# Down with a heart spent: it lies faded where it fell until the turn ends.
func _on_downed(u: Unit) -> void:
	u.modulate.a = 0.45
	_falls.append("%s is down, a heart spent (%d left)" % [_tag(u), u.lives_left()])
	_flush_falls.call_deferred()
	_mark()


# Downed (down but not out, on its last life - not the hearts' going down): it goes down, is saved, or
# dies of it - told just before it falls (_on_died()).
func _on_dbno(u: Unit, how: StringName) -> void:
	match how:
		&"down":
			var n := u.dbno.left
			_falls.append("%s is Downed%s: %d round%s to get it above 0 HP" % [_tag(u), ", and fights on" if u.dbno.rule.acts else "", n, "" if n == 1 else "s"])
			overlay.float_text(u, "Downed", FOE)
		&"saved":
			_falls.append("%s is saved: no longer Downed" % _tag(u))
			overlay.float_text(u, "Saved", FRIEND)
		_:
			_falls.append("%s, Downed, dies of it: %s" % [_tag(u), DBNO_DEATHS.get(how, String(how))])
	_flush_falls.call_deferred()
	_mark()


# Back up as the turn ends - with whatever it brings (a Regeneration Probe), which the HUD now follows.
func _on_revived(u: Unit, came: Unit) -> void:
	u.modulate.a = 1.0
	_log("%s gets back up" % _tag(u))
	if came:
		_watch_unit(came)
		_log("%s appears beside it" % _tag(came))
	_mark()


func _on_dropped_item(u: Unit, it: Item) -> void:
	_falls.append("%s drops %s" % [_tag(u), it.name])
	_flush_falls.call_deferred()


# Starsap the player's side can see: who lost what to whom.
func _on_sapped(u: Unit, drained: Dictionary) -> void:
	if unit_seen(u.cell) != u:
		return
	_log("%s saps %s" % [_tag(u), ", ".join(drained.keys().map(func(o: Unit): return "%s %d" % [_tag(o), drained[o]]))])
	_mark()


# A Regeneration Pulse the player's side can see: who it healed, and by how much.
func _on_pulsed(u: Unit, healed: Dictionary) -> void:
	if unit_seen(u.cell) != u:
		return
	var parts := healed.keys().filter(func(o: Unit): return healed[o] > 0).map(func(o: Unit): return "%s [color=#3fbf4f]+%d[/color]" % [_tag(o), healed[o]])
	_log("%s pulses%s" % [_tag(u), ": " + ", ".join(parts) if parts else ", healing no one"])


# A channeled skill's blast: what it did to each unit caught in it.
func _on_exploded(_u: Unit, s: Skill, _at: Vector2i, hit: Dictionary) -> void:
	var parts := hit.keys().map(func(o: Unit): return "%s [color=#ff6b5e]-%d[/color]" % [_tag(o), hit[o]] if _hp_shows(o) else _tag(o))
	_log("%s's blast%s" % [s.name, " catches " + ", ".join(parts) if parts else " catches no one"])
	_mark()


func _hp_shows(u: Unit) -> bool:
	return known(u) or view(u).hp != null


func _on_died(u: Unit) -> void:
	command.leave(u)
	overlay.fade(u)
	_falls.append("%s falls" % _tag(u))
	_flush_falls.call_deferred()
	if u == selected:
		select(null)
	if u == command.leader:
		_banner("%s has fallen" % _name(u), FOE)
		_falls.append("Your allies fight on alone")
		if auto and battle.phase == Battle.Phase.TURNS and battle.turn == command.faction() and not busy:
			_act_alone.call_deferred(command.faction(), command.idle())
	_mark()


# --- Showing it

# The tiles whose look the map shows (grounds, traps, suspect): those the selected unit can move to,
# and those that could hide something from the player's side (Battle.maybe_suspicious(), what it finds
# dubious) - the rest read as plain ground. Reading every tile of a plane as big as the Meadows' grows,
# on every refresh, was what slowed it.
func _shown_cells() -> Array[Vector2i]:
	var out: Dictionary[Vector2i, bool] = {}
	for c in reach:
		out[c] = true
	for c in dubious:
		out[c] = true
	var o := eyes()
	if o:
		for c in battle.maybe_suspicious(o):
			out[c] = true
	return out.keys()


func _mark() -> void:
	_dirty = true
	_reach_of = null


func _refresh() -> void:
	_find_reach()
	_show_units()
	grounds.clear()
	traps.clear()
	suspect.clear()
	for c in _shown_cells():
		var tv := tile_view(c)
		grounds[c] = ground(c, tv)
		if tv.trap == true:
			traps[c] = c in battle.snares and battle.snares[c].faction == command.faction()
		if tv.hint != "" and c not in dubious:  # concealed ground it suspects is more than it looks
			suspect[c] = tv.hint
	marked = targets()
	sleepers.assign(battle.units.values().filter(func(u: Unit): return unit_seen(u.cell) == u and sleeping(u)))
	card.set_info(_card_info())
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
# Then every unit glows by how ready it is for what the player is about (glow_of()).
func _show_units() -> void:
	dubious.clear()
	if battle.phase == Battle.Phase.OVER:
		return
	var o := eyes()
	var quiet := o != _viewer and _viewer != null and not marks.has(o)  # a first look through new eyes: noted, not popped
	_viewer = o
	if o and not marks.has(o):
		marks[o] = {}
	for u: Unit in battle.get_node("Units").get_children():
		if not u.is_alive():
			continue
		if known(u):
			u.appear(null)
			continue
		var r := view(u)
		u.appear(r)
		if o:
			_pop(u, r, marks[o], quiet)
		u.position = battle.map.map_to_local(r.cell if r.located() else u.cell)  # a stale ping: where it was sensed
		if r.located() and r.silhouette() and battle.pinged(command.faction()).has(u):
			dubious[r.cell] = "sensed"  # Clairvoyance marks the tile
		for c in r.area:
			if battle.on_map(c):
				dubious[c] = r.hint
	for u: Unit in battle.get_node("Units").get_children():  # once every suspicion is noted: whether a walk is sure reads them
		if u.is_alive() and u.visible:
			_apply_look(u, look_of(u))


# Once per change in what one viewer makes of a trick in plain view (Read.mark()), a mark pops over
# it and fades: "?" (neutral) when suspicion first lands on it, "!" in its true side's colour when
# that suspicion sees through it. seen: that viewer's last marks (marks[eyes()]), so switching eyes
# pops nothing by itself; quiet: only note them (a viewer's first look).
func _pop(u: Unit, r: Read, seen: Dictionary, quiet := false) -> void:
	var m := r.mark()
	if m == seen.get(u, Read.Mark.NONE):
		return
	seen[u] = m
	if quiet:
		return
	if m == Read.Mark.DOUBT:
		u.pop_mark("?", Color.WHITE)
	elif m == Read.Mark.CAUGHT:
		u.pop_mark("!", r.faction.primary.lightened(0.15))


# The move cost line in the tile pane: nothing for plain ground (1) or free ground, "Mv -N" for a
# real cost (a walker pictogram would read better; follow-up), a trailing "?" when the tile is
# suspicious and the cost is known.
func _move_label(cost: Variant, suspicious: bool) -> String:
	if cost == null or cost <= 1:
		return ""
	return "Mv -%s%s" % [Skill.num(cost), " ?" if suspicious else ""]


# The tile is known to be something more than it shows, its effects concealed: a hint read off it,
# or a spot where something may lurk.
func _suspicious(c: Vector2i, r: Read) -> bool:
	return r.hint != "" or c in dubious or r.obscured


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
	var suspicious := _suspicious(c, r)
	%TileCost.text = _move_label(r.cost, suspicious)
	%TileCost.visible = %TileCost.text != ""
	var effects := _tile_effects(c, r)
	var notes := _tile_notes(c, r)
	if suspicious:
		effects.append(["?", GROUND[&"unsure"]])  # something more, its effects concealed
	elif effects.is_empty() and notes.is_empty():
		notes.append(["Nothing of note" if kind == &"safe" else "Hard to make out", MUTED])
	var listed := "%s %s" % [c, effects]
	if listed != _pane_list:
		_pane_list = listed
		_scroll_t = 0.0
	_fill_lines(%TileLines, effects)
	_fill_lines(%TileNotes, notes)
	%TileScroll.visible = not effects.is_empty()
	_place_pane()


# [Glossary markup, colour] for each thing the tile is known to do: beneficial or detrimental, a trap,
# conditions on whoever stands there, steps in or ends a turn there (Effect.conditions: Haste's two
# effects are one line), sticky ground, and what whoever stands there is (Moist, Wet) - each kind
# named by its term.
func _tile_effects(c: Vector2i, r: Read) -> Array:
	var out := _layer_lines(c, r)
	if r.worth != null and r.worth != 0:
		out.append(["Beneficial" if r.worth > 0 else "Detrimental", FRIEND if r.worth > 0 else FOE])
	if r.trap == true:
		var t := battle.terrain(c)
		var dmg := "%dd%d" % [t.dice.x, t.dice.y] + (" x%d" % t.times if t.times != 1 else "") + (" %+d" % t.bonus if t.bonus else "")
		out.append(["%s: %s %s" % [Glossary.term(&"trap"), dmg, " ".join(t.damage_tags.filter(func(x): return x != &"trap").map(func(x): return "{x:%s}" % x))], FOE])
	for group in Effect.conditions(r.effects):
		out.append([Effect.summarize(group, true), _tone(group)])
	for when in [[r.afflicts, &"on_enter", "on entering"], [r.at_end, &"turn_end", "at turn end"]]:
		for group in Effect.conditions(when[0]):
			var n: int = group[0].turns if group[0].turns else battle.terrain(c).turns
			out.append(["%s · {t:%d turn%s} · %s" % [Effect.summarize(group, true), n, "" if n == 1 else "s", Glossary.term(when[1], when[2])], _tone(group)])
	if r.exit:
		out.append(["%s: +%d to leave" % [Glossary.term(&"sticky"), r.exit], MUTED])
	for t in r.tags.filter(func(t): return t not in [&"trap", &"sticky"] and String(t) not in r.name.to_lower() and not Battle.material(t)):
		out.append(["{x:%s|%s}" % [t, String(t).capitalize()], MUTED])
	return out


# [markup, colour] for the layers the player can make out on c, top down: each one's name and traits
# by term (Brittle, Unstable...), and a mending startile's progress. Under obscuring leaves, only the
# leaves themselves.
func _layer_lines(c: Vector2i, r: Read) -> Array:
	var out := []
	var shown: Array = [battle.top_layer(c)] if r.obscured else battle.reached(c)
	for l: Battle.Layer in shown:
		if l == null:
			continue
		var t := l.terrain
		var traits: PackedStringArray = []
		for pair in [[l.passes, &"lets_through"], [t.obscures, &"obscuring"], [t.cover, &"cover"], [t.brittle, &"brittle"],
				[t.unstable, &"unstable"], [t.flammable, &"flammable"], [t.windswept, &"windswept"]]:
			if pair[0]:
				traits.append(Glossary.term(pair[1]))
		out.append(["%s: %s" % [t.name, ", ".join(traits)] if not traits.is_empty() else t.name, MUTED])
		if l.repair_goal > 0:
			out.append(["%s: %d/%d" % [Glossary.term(&"repairing"), l.repairing, l.repair_goal], STARPOWER_TINT])
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
			out.append(["Your %s cover %d%s, %d turns left" % [z.kind, z.levels[c], " (hides only your side)" if z.allied else "", z.turns], MUTED])
	if c in battle.debris and r.net >= 0:
		var d: Battle.Debris = battle.debris[c]
		out.append([d.kind + (": left by %s hiding" % _name(d.by) if d.faction == command.faction() else ": someone hid nearby?"),
				MUTED if d.faction == command.faction() else GROUND[&"unsure"]])
	if battle.on_lattice(c):
		var what := "Starpower source, %d%% full" % roundi(100.0 * battle.charge[c] / Battle.STAR_CAPACITY) if c in battle.starpower \
				else Glossary.term(&"starpane")
		var rate := "Power back x%s" % Skill.num(snappedf(battle.star_rate(c), 0.1)) if battle.star_source(c) != null else "linked to no source"
		out.append(["%s: %s" % [what, rate], STARPOWER_TINT])
	if c in battle.earthworks:
		var ours := battle.earthworks[c].faction == command.faction()
		var who := " (yours): your enemies pay" if ours else ": you pay"
		out.append(["%s%s 50%% more to enter, {t:%d turns} left" % [Glossary.term(&"disturbed_earth"), who, battle.earthworks[c].turns], FRIEND if ours else FOE])
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
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.text = Glossary.rich(line[0])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = pane.custom_minimum_size.x - 14  # wrap at the pane's width from the start
		l.add_theme_color_override(&"default_color", line[1])
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
		_log("%s learns %s" % [_tag(u), s.name])
		_rebuild_bar()
	_mark()


func _on_raised(s: Skill) -> void:
	var u := skills.unit
	if _can_spend(u) and u.raise(s):
		_log("%s raises %s to rank %s" % [_tag(u), s.name, Skill.roman(u.rank(s))])
		_rebuild_bar()
	_mark()


func _on_leveled() -> void:
	var u := skills.unit
	if _can_spend(u) and u.level < Unit.MAX_LEVEL:
		u.level_up()
		_log("%s reaches level %d" % [_tag(u), u.level])
	_mark()


func _open_book() -> void:
	var u := selected
	spellbook.open(u, _name(u), _editable(u), func(s: Skill) -> bool: return _orders(u) and command.may_use(u, s))


func _rebuild_bar() -> void:
	var n := _bar_slots(selected if selected and hand(selected) else null)
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


# Hotbar slots shown for u: all of them, but its clover slot (the last) only while it's lucky - unlucky,
# it's gone, though it remembers what was in it for when the luck comes back.
func _bar_slots(u: Unit) -> int:
	if not u:
		return Unit.SLOTS
	var c := u.clover()
	if c >= 0 and u.luck <= 0:
		return c
	return u.bar_size()


func _refresh_bar() -> void:
	_rebuild_bar()
	var u := selected if selected and hand(selected) else null
	bar.visible = u != null or not selected  # other sides' skills aren't the player's to see
	%BarTitle.visible = bar.visible
	var orders := u != null and _orders(u)
	var edit := u != null and _editable(u)
	var r := view(u) if u and u != command.leader else null
	for slot: SkillSlot in bar.get_children():
		var i := slot.index
		var s: Skill = u.hotbar[i] if u and i < u.hotbar.size() else null
		var locked := u != null and hand(u) and u != command.leader and not command.slot_open(u, i)
		var works := u == null or u.slot_works(i)
		var sense := skill_sense(u, s, r)
		var off: int = u.disabled.get(s, 0) if u and s else 0
		var usable := orders and s != null and sense > 0 and not locked and works and off == 0 and (s.passive or u.can_afford(s))
		slot.set_state(i, s, u.rank(s) if s else 0, s != null and s == armed, s != null and u.is_on(s), usable, edit and not (s and s.pillar()), locked, sense, u.mods(s).label() if s else "")
		slot.set_kind(u.slot_kind(i) if u else &"", works)
		slot.label = u.skill_name(s) if u and s else ""
		var taken := u != null and s != null and u.base_rank(s) > 0 and u.rank(s) == 0  # a level curse took it back (Unit.unranked())
		slot.set_off(maxi(off, 1) if taken else off, u != null and s != null and (u.cursed.has(s) or taken), u != null and u.sealed(i))
		var to: Variant = u.switching() if u and s and u.channel and u.channel.skill == s else null
		slot.set_switching("" if to == null else "Energy" if to is StringName else to.name)
		if locked:
			slot.tooltip_text += "\n" + _why_locked(u)
		slot.set_exhausted(u.exhaustion.of(s) if u and s and sense == 2 and not s.passive else 0.0)


# How much of u's skill s the player's side makes out (r: its read of u): 2 all of it (the leader's
# own, or net 3), 1 its name (an ally's kit), 0 nothing - an unperceptive side can't use it.
func skill_sense(u: Unit, s: Skill, r: Read) -> int:
	if u == null or s == null or u == command.leader or s in r.skills:
		return 2
	return 1 if s in r.kit else 0


func _on_dropped(i: int, s: Skill, _from: int) -> void:
	var u := selected
	if u and _editable(u):
		if i == u.clover() and battle.phase == Battle.Phase.TURNS and battle.turn != u.faction:
			_say("A clover slot is filled on its unit's own turn")
		elif not u.bar_place(s, i):
			var kind: String = Skill.CATEGORIES.get(u.slot_kind(i), "")
			if u.rank(s) == 0:
				_say("%s doesn't know %s" % [_name(u), s.name])
			elif s.pillar() or (u.hotbar[i] and u.hotbar[i].pillar()):
				_say("Pillar skills keep the last slots")
			elif u.sealed(i):
				_say("A curse has sealed this slot")
			elif not u.slot_works(i):
				_say(SkillSlot.NO_LUCK)
			elif kind:
				_say("%s slots hold only %s skills" % [kind, kind.to_lower()])
		_mark()


func _on_cleared(i: int) -> void:
	if selected and _editable(selected):
		if i == slot:
			aim = false
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
	var prepping := battle.phase == Battle.Phase.PREP
	end_button.disabled = not (my_turn() or prepping)
	end_button.text = "Begin  (Space)" if prepping else "End turn  (Space)"


# What's going on that the screen doesn't already show; how to play is in the Guide (Settings).
func _hint() -> String:
	if battle.phase == Battle.Phase.OVER:
		return "The battle is over."
	if battle.phase == Battle.Phase.PREP:
		var allies := battle.studies_left(command.leader, true)
		var others := battle.studies_left(command.leader, false)
		return "Preparing. Studies left: %d all%s, %d foe%s or tile%s. Begin when ready." % [
				allies, "y" if allies == 1 else "ies", others, "" if others == 1 else "s", "" if others == 1 else "s"]
	if not command.leader.is_alive():
		return "Your leader has fallen; your allies fight on."
	if %Initiative.visible:
		return "Rolling for initiative... (any key skips)"
	if busy:
		return "%s acting..." % ("Your allies are" if battle.turn == command.faction() else battle.turn.name + " is")
	if battle.turn != command.faction():
		return "Waiting for %s." % battle.turn.name
	var u := selected
	if not u or not hand(u) or _orders(u):
		return ""
	if u.asleep():
		return "Asleep."
	if u.stopped():
		return _why_tapped(u) + "."
	return ""  # not commandable (too far): the grayed hotbar and the lit commandable units say so


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


# What Burnout has taken off its maxes for good (Unit.burnt): "Burnt -3 HP", one chip a pool.
func _burnt_chips(u: Unit, chips: Array) -> void:
	for pool in u.burnt:
		var what: String = pool.name.left(2).to_upper() if pool is Reserve else ("HP" if pool == &"hp" else ("PW" if u.powered() else "EN"))
		chips.append(["Burnt -%d %s" % [u.burnt[pool], what], FOE])


func _info(u: Unit) -> Dictionary:
	var info := {look = u.sprite.sprite_frames.get_frame_texture(&"default", 0)}
	var chips := []
	if u == command.leader:  # it knows itself; everyone else, the side sees as it reads them
		info.name = _name(u)
		var kind := " ".join([u.race.name if u.race else "", u.role.name if u.role else ""]).strip_edges()
		info.sub = "Lv %d %s" % [u.lv(), kind if kind else ", ".join(u.tags)]
		chips.append(["Leader", GOLD])
		if u.skill_points > 0:
			chips.append(["%d skill point%s" % [u.skill_points, "" if u.skill_points == 1 else "s"], GOLD])
		if u.asleep():
			chips.append(["Asleep", SLEEP])
		if u.bio:  # its own side knows its bio
			for p in u.bio.properties:
				chips.append([p.name, MUTED])
			if u.bio.behaviour:
				chips.append([String(u.bio.behaviour).capitalize(), MUTED])
		_heart_chips(u, chips)
		_burnt_chips(u, chips)
		var rows := [["HP", u.hp, u.max_hp, Unit.HP_COLOR]]
		for r in u.held_reserves():  # what it runs on first, then a second it holds (Focus)
			rows.append([r.name.left(2).to_upper(), u.store(r), u.pools()[r], r.color])
		if u.holds_energy(u.energy):
			rows.append(["PW" if u.powered() else "EN", u.energy, u.max_energy, Unit.POWER_COLOR if u.powered() else Unit.ENERGY_COLOR])
		if u.overcharge > 0:  # Overcharge: the buffer spent before them, while it lasts
			rows.append(["OC", "+%d" % u.overcharge, null, Unit.OVERCHARGE_COLOR])
		rows.append(["RE", "%d/%d" % [u.endurance, u.endurance_max()], null, FOE if u.endurance <= 0 else MUTED])  # Recovery Endurance (Burnout)
		rows.append(["AP", u.ap_left(), u.full_ap(), AP_COLOR])
		rows.append(["MV", maxf(u.move_left(), 0.0), u.stat(&"movement"), MOVE_COLOR])
		rows.append(["DF", _defense_line(u), null, MOVE_COLOR])
		rows.append(["ST", _bst_line(Unit.CORE.slice(0, 6).map(func(x): return u.stat(x))), null, MUTED])
		info.rows = rows
		info.effects = effect_icons(u) + suspicion_icons(u, u.suspicion)
		info.trims = trims(u)
		info.chips = chips
		return info
	var r := view(u)
	info.name = r.name if r.name else ("Looks like a %s" % r.looks if r.looks else "Unknown")
	info.face = r.face
	var doubt := r.mark() == Read.Mark.DOUBT  # a trick it suspects: as if unaffiliated
	info.shape = r.faction == null or doubt
	info.silhouette = r.silhouette()
	var parts: PackedStringArray = []
	if r.level != null:
		parts.append("Lv %d" % r.level)
	if r.role:
		parts.append(r.role.name)
	elif r.looks and r.name:  # its class lost on the observer: how it looks (Bio)
		parts.append(r.looks)
	elif not r.tags.is_empty():
		parts.append(" ".join(r.tags.map(func(t): return String(t).capitalize())))
	if not parts:
		parts.append(_sentence(r.hint) if r.hint else ("Kind unknown" if r.name else "Hard to make out"))
	info.sub = " ".join(parts)
	if r.faction == null:
		chips.append(["Unknown", MUTED])
	elif doubt:
		chips.append(["?", MUTED])
	elif r.stance in [&"aggressive", &"passive", &"traitor"]:
		chips.append([String(r.stance).capitalize(), FOE if r.attitude(eyes()) == &"avoid" else MUTED])
	elif known(u) and r.faction == command.faction():
		chips.append(["Party", GOLD] if u in command.party else ["Ally", shade(u.faction.primary)])
	elif r.faction == command.faction():
		chips.append(["Friendly", FRIEND])
	else:
		chips.append(["Enemy", FOE])
	if command.ours(u) and u.skill_points > 0:
		chips.append(["%d skill point%s" % [u.skill_points, "" if u.skill_points == 1 else "s"], GOLD])
	if command.ours(u):
		_burnt_chips(u, chips)
	for word in r.traits:
		chips.append([word, MUTED])
	if sleeping(u):
		chips.append(["Asleep", SLEEP])
	elif known(u) and battle.turn == command.faction() and battle.phase == Battle.Phase.TURNS:
		var given: int = command.ordered.get(u, 0)
		if command.can_order(u):
			chips.append(["Takes orders" if given == 0 or u == command.leader else "Ordered %d/%d" % [given, command.order_cap(u)], FRIEND])
		elif given > 0:
			chips.append(["Ordered", MUTED])
		elif not command.under_caps(u):
			chips.append(["Command spent", MUTED])
		else:
			chips.append(["Out of range", MUTED])
	if r.vibe:
		chips.append([r.vibe, MUTED])
	for p in r.properties:
		chips.append([p.name, MUTED])
	if r.hp != null:
		_heart_chips(u, chips)
	var rows := []
	if r.hp != null:
		rows.append(["HP", r.hp, r.max_hp, Unit.HP_COLOR])
	elif r.healthy != null:
		rows.append(["HP", "Healthy" if r.healthy else "Bloodied", null, Unit.HP_COLOR if r.healthy else FOE])
	else:
		rows.append(["HP", "?", null, MUTED])
	if r.energy != null:
		rows.append(["PW" if u.powered() else "EN", r.energy, null, Unit.POWER_COLOR if u.powered() else Unit.ENERGY_COLOR])
	if known(u) and command.can_order(u):  # what it has left to follow orders with
		rows.append(["AP", u.ap_left(), u.full_ap(), AP_COLOR])
		rows.append(["MV", maxf(u.move_left(), 0.0), u.stat(&"movement"), MOVE_COLOR])
	if r.net >= 0:
		rows.append(["DF", _defense_line(u), null, MOVE_COLOR])
	if not r.stats.is_empty():
		rows.append(["ST", _bst_line(Unit.CORE.slice(0, 6).map(func(x): return r.stats[x])), null, MUTED])
	info.rows = rows
	if not info.silhouette and not info.face and _defense_shows(u):  # its gear can be made out
		info.trims = trims(u)
	if known(u):
		info.effects = effect_icons(u, r.effects) + suspicion_icons(u, r.suspects)
		if info.effects.is_empty() and r.affected == true:  # it can tell something's on it, not what
			info.effects = [["?", MUTED, "Something's affecting %s; your side can't make out what" % _name(u), ""]]
	info.note = "" if known(u) and r.insight.ends_with("appear otherwise.") else r.insight  # an honest ally goes without saying
	if r.temper:
		info.note = (info.note + "\n" if info.note else "") + "Seems %s." % r.temper
	if r.intention or not r.strategy.is_empty():
		info.note = (info.note + "\n" if info.note else "") + "Intends to %s%s." % [r.intention.to_lower() if r.intention else "fight",
				"; goes for the %s" % " and ".join(r.strategy) if not r.strategy.is_empty() else ""]
	info.chips = chips
	return info


# [colour, item name] for each item u wears with a trim (Item.trim()): the card's banners.
static func trims(u: Unit) -> Array:
	var out := []
	for it: Item in [u.weapon, u.armor, u.trinket]:
		if it and it.trim().a > 0.0:
			out.append([it.trim(), it.name])
	return out


# The selected unit's card, with what the hovered plan would consume (spend) on its rows: a number
# drains a segment off the row's bar; "?" (an effect it can't foresee) mutes the row and flashes a ?.
func _card_info() -> Dictionary:
	if not selected:
		return {}
	var info := _info(selected)
	if spend.is_empty():
		return info
	var keys := {"HP": &"hp", "AP": &"ap", "MV": &"move", "EN": &"energy", "PW": &"energy"}
	for r: Array in info.get("rows", []):
		var key: Variant = keys.get(r[0])
		if key == null:
			for res in selected.held_reserves():
				if res.name.left(2).to_upper() == r[0]:
					key = res
		if key == null or r[2] == null:
			continue
		if key in spend.get("unsure", []):
			r.append("?")
		elif spend.get(key, 0.0) > 0.0:
			r.append(spend[key])
	return info


# Its hearts, if it has any: how many lives it has left, and whether it's down. And whether it's Downed
# (down but not out): the rounds it has left, and for one that fights on (Grudge) the skill uses left
# to it and the melee attack it owes this round.
func _heart_chips(u: Unit, chips: Array) -> void:
	if u.reviving:
		chips.append(["Down", FOE])
	if u.dbno:
		chips.append(["Downed: %d round%s left" % [u.dbno.left, "" if u.dbno.left == 1 else "s"], FOE])
		if u.dbno.spare() >= 0:
			chips.append(["%d skill use%s left" % [u.dbno.spare(), "" if u.dbno.spare() == 1 else "s"], FOE if u.dbno.spare() == 0 else GOLD])
		if u.dbno.rule.melee and not u.dbno.meleed and not u.dbno.fresh:
			chips.append(["Owes a melee attack", GOLD])
	if u.deferred > 0:  # Borrowed Time: death put off, the harms taken in the window waiting to be replayed
		chips.append(["Borrowed time: %d round%s left" % [u.deferred, "" if u.deferred == 1 else "s"], FOE if u.deferred == 1 else GOLD])
		if not u.harms.is_empty():
			chips.append(["%d harm%s to replay" % [u.harms.size(), "" if u.harms.size() == 1 else "s"], FOE])
	if u.lives() > 0:
		chips.append(["%d heart%s left" % [u.lives_left(), "" if u.lives_left() == 1 else "s"], FOE if u.lives_left() == 0 else GOLD])


# [mark, colour, tooltip, roll] for what's timed on u, an icon per skill that put it on (its mark:
# Clever Disguise's "CD") or per condition (its first letters: "Po"), green if it helps. roll: the
# roll it was put on with, where the player knows it (roll_known()), else "". only: just these
# effects (what the side can make out), unless null.
func effect_icons(u: Unit, only: Variant = null) -> Array:
	var out := []
	var at := {}
	for e: Effect in u.timed:
		if only != null and e not in only:
			continue
		var a: Unit.Applied = u.timed[e]
		var key: Variant = a.skill if a.skill else e.label()
		var line := e.describe(a.rank) + _time_left(a)
		if key in at:
			out[at[key]][2] += "\n" + line
			continue
		at[key] = out.size()
		var known_roll := a.evaluated and a.roll != 0 and u.faction == command.faction()
		out.append([a.skill.mark() if a.skill else e.label().left(2), FRIEND if e.helps() > 0 else FOE,
				(a.skill.name + "\n" if a.skill else "") + line + ("\nRolled %d" % a.roll if known_roll else ""),
				str(a.roll) if known_roll else ""])
	return out


# Suspicion (Battle.suspect()) as one utility status, a purple eye, whatever u has grown suspicious of:
# its tooltip names each unit and tile as u knows it - the name it goes by to u, or how it looks; the
# ground it seems to be - with the ranks of trickery and concealment u sees through there, and the
# eye's corner counts them. [] when it suspects nothing (still standing).
func suspicion_icons(u: Unit, of: Dictionary) -> Array:
	var lines: PackedStringArray = []
	for t: Variant in of:
		var ranks := "%d rank%s" % [of[t], "" if of[t] == 1 else "s"]
		if t is Vector2i:
			var seen := battle.read(u, t)
			lines.append("%s at %d, %d: sees through %s of what hides there" % [seen.name if seen.name else "The ground", t.x, t.y, ranks])
		elif t.is_alive():
			lines.append("%s: sees through %s of its trickery and concealment" % [known_name(u, t), ranks])
	if lines.is_empty():
		return []
	return [[SUSPICION_ICON, SUSPICION, "Suspicious\n" + "\n".join(lines), str(lines.size()) if lines.size() > 1 else ""]]


# What o calls t: the name it goes by to o, else how it looks ("a Beautiful Minstrel"), else "Something".
func known_name(o: Unit, t: Unit) -> String:
	var r := battle.read(o, t)
	return r.name if r.name else ("A %s" % r.looks if r.looks else "Something")


# " · 2 turns left", " · until it moves", " · until it breaks free", " · 1 turn left, then fading".
func _time_left(a: Unit.Applied) -> String:
	if a.lasting:
		return " · until it breaks free" if a.skill and a.skill.holds() else " · for the rest of the battle"
	if a.until_move and a.turns == 0:
		return " · until it moves"
	return " · %d turn%s left%s" % [a.turns, "" if a.turns == 1 else "s", ", then fading" if a.fades and a.rank > 1 else ""]


# "76 BST": its six core stats added up (what Embellish inflates).
func _bst_line(stats: Array) -> String:
	return "%d BST" % roundi(stats.reduce(func(sum, x): return sum + x, 0.0))


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


# The tooltip: a unit's name and read, no more - what a click does is drawn (the plan, glow, brackets,
# the drain on the bars), and the instructions are in the Guide. Alt held: the exact chance to hit,
# once the target's Defense is known. An aimed area skill: its name.
func _tip_text() -> String:
	if hover == NOWHERE:
		return ""
	var it := hovered if not hovered.is_empty() else intent(hover)
	var u := unit_seen(hover)
	if aiming() and selected:
		return armed.name
	if not u:
		return ""
	var line := _unit_line(u)
	if show_odds and odds(it) not in [&"", &"unknown"]:
		line += "\n%d%% to hit" % roundi(Battle.hit_chance(it.unit, it.skill, u, battle) * 100.0)
	return line


func _unit_line(u: Unit) -> String:
	if u == command.leader:
		return "%s\nHP %d/%d" % [_name(u), u.hp, u.max_hp]
	var r := view(u)
	var text: String = r.name if r.name else "Something"
	if r.faction == null and r.hint:
		text += "\n" + _sentence(r.hint)
	if r.hp != null:
		text += "\nHP %d/%d" % [r.hp, r.max_hp]
	elif r.healthy != null:
		text += "\n" + ("Healthy" if r.healthy else "Bloodied")
	if not r.traits.is_empty():
		text += "\n" + ", ".join(r.traits)
	if r.vibe:
		text += "\n" + r.vibe
	return text


# --- Rules of thumb for the player

func _orders(u: Unit) -> bool:
	return u != null and my_turn() and command.can_order(u)


# The leader's and party's hotbars are the player's to arrange; other allies keep their own.
func _editable(u: Unit) -> bool:
	return u != null and not busy and command.ours(u)


func _why_locked(u: Unit = null) -> String:
	var n := command.slots(u)
	if n == 0:
		return "Allies only take move orders from %s (%s)" % [_name(command.leader), command.basis(0, u)]
	return "Allies use only slot%s 1%s on %s's orders" % ["" if n == 1 else "s", "" if n == 1 else "-%d" % n, _name(command.leader)]


# Says `why` only when there's something to say: a too-far unit no longer nags (its grayed hotbar
# and the lit commandable units carry that), but asleep / fallen / wrong-turn still speak.
func _nag(why: String) -> void:
	if why:
		_say(why)


const INTENTS := {&"attack": &"offensive", &"defend": &"defensive", &"help": &"supportive"}


# The commander can't give u a specific skill order - either it can't convey complex strategy (cha mod
# <= 0: no hotbar slot is open to orders) or it can't read what u can do (low wisdom). It commands by
# intent instead (ATTACK / DEFEND / HELP) and u uses its own default skill (Unit.intent_skill()).
func uses_intents(u: Unit) -> bool:
	return _orders(u) and u != command.leader and (command.slots(u) <= 0 or command.leader.mod(&"wisdom") < 0)


# How well an order lands: the commander's clarity (wis mod) + how well u takes direction (cha mod). At
# -5 or lower the commander is guessing: every intent shows with a "?", even ones u can't carry out.
func _command_read(u: Unit) -> int:
	return command.leader.mod(&"wisdom") + u.mod(&"charisma")


# The intents to offer for u: [intent, eligible (u has a skill for it), uncertain (shown with ?)].
# Normally only intents u can carry out show; while guessing (read <= -5) all three show, with a "?".
func intent_options(u: Unit) -> Array:
	var guessing := _command_read(u) <= -5
	var out := []
	for intent in [&"attack", &"defend", &"help"]:
		var has := u.intent_skill(INTENTS[intent]) != null
		if has or guessing:
			out.append([intent, has, guessing])
	return out


# Issues an intent to u: eligible, u uses its default skill for it; ineligible (only reachable while
# guessing), the order is wasted and u takes no more commands this faction turn.
func issue_intent(u: Unit, intent: StringName) -> bool:
	if not uses_intents(u):
		return false
	if u.intent_skill(INTENTS[intent]) == null:  # ineligible: it has no skill for this posture
		_say("%s can't %s that way - a wasted order" % [_name(u), String(intent)])
		command.lock(u)
		_mark()
		return false
	# It takes the rest of its turn on its own, restricted to the ordered posture (AI.act).
	select(u if unit_seen(u.cell) == u else null)
	AI.act(battle, u, INTENTS[intent])
	command.order(u)
	_mark()
	return true


# After a Meditation: a small panel to move up to `room` points between u's six ability scores, one
# down for each one up. Shift (open once they balance) commits them (Battle.respec()); Keep closes it -
# either way the room is spent.
func _respec_window(u: Unit, room: int) -> void:
	var panel := PanelContainer.new()
	panel.name = "Respec"
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	var title := Label.new()
	title.theme_type_variation = &"Title"
	title.text = "Meditate"
	col.add_child(title)
	var note := Label.new()
	note.theme_type_variation = &"Muted"
	note.text = "Move up to %d point%s: one down for each up" % [room, "" if room == 1 else "s"]
	col.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 4
	var picked := {}
	var shift := Button.new()
	var balance := func() -> void:  # Shift opens once the points down pay for the points up, within room
		var total := 0
		var moved := 0
		for t in picked:
			total += picked[t] - int(u.get(t))
			moved += maxi(picked[t] - int(u.get(t)), 0)
		shift.disabled = total != 0 or moved == 0 or moved > room
	for s: StringName in Skill.STAT_TAGS.values():
		var now := int(u.get(s))
		picked[s] = now
		var name := Label.new()
		name.text = String(s).left(3).capitalize()
		name.custom_minimum_size.x = 22
		var value := Label.new()
		value.text = str(picked[s])
		value.custom_minimum_size.x = 14
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var less := Button.new()
		less.text = "-"
		var more := Button.new()
		more.text = "+"
		for pair in [[less, -1], [more, 1]]:
			var btn: Button = pair[0]
			var step: int = pair[1]
			btn.focus_mode = Control.FOCUS_NONE
			btn.custom_minimum_size = Vector2(11, 0)
			btn.pressed.connect(func() -> void:
				picked[s] = clampi(picked[s] + step, maxi(now - room, 1), now + room)
				value.text = str(picked[s])
				value.add_theme_color_override(&"font_color", GOLD if picked[s] != now else Color.WHITE)
				balance.call())
		grid.add_child(name)
		grid.add_child(less)
		grid.add_child(value)
		grid.add_child(more)
	col.add_child(grid)
	var row := HBoxContainer.new()
	var keep := Button.new()
	keep.text = "Keep"
	shift.text = "Shift"
	balance.call()
	row.add_child(keep)
	row.add_child(shift)
	col.add_child(row)
	panel.add_child(col)
	var close := func() -> void:
		u.respec_room = 0
		panel.queue_free()
		_mark()
	keep.pressed.connect(close)
	shift.pressed.connect(func() -> void:
		var changes := {}
		for s in picked:
			if picked[s] != int(u.get(s)):
				changes[s] = picked[s] - int(u.get(s))
		battle.respec(u, changes)
		close.call())
	settings.get_parent().add_child(panel)
	panel.reset_size()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


# A small ATTACK / DEFEND / HELP choice for an ally the commander can only direct by intent ("?" while
# guessing: an impossible pick wastes the order).
func _show_intents(u: Unit) -> void:
	var picks := []
	for opt in intent_options(u):
		var intent: StringName = opt[0]
		picks.append([String(intent).to_upper() + (" ?" if opt[2] else ""), func() -> void: issue_intent(u, intent)])
	_choose("Order %s" % _name(u), picks)


# How a unit of the player's own stands this turn, for the map: &"ready"


# High contrast (accessibility): whiter body text and a heavier faction trim; the brighter allied
# glow comes through Unit.set_glow() (passed high_contrast in _show_units), the bolder suspicious marks
# through the Overlay. A plain, easy win on legibility.
func _apply_contrast() -> void:
	%Guide.add_theme_color_override(&"default_color", Color.WHITE if high_contrast else Color(0.78, 0.8, 0.85))
	%TileLines.modulate = Color.WHITE
	_mark()


# How a unit is drawn for what the player is about - the one place glow, colour and tint are decided:
# {glow: a strength (glow_of(), -1 plain), sat: how much colour it keeps (command_sat(): only the player's
# own side drains), tint: its glow's colour, or null for its side's own}. An ally of another faction
# glows ally_glow (green by default) rather than its own primary: plainly on the player's side, not its.
func look_of(u: Unit) -> Dictionary:
	var look := {glow = glow_of(u), sat = command_sat(u) if known(u) else 1.0, tint = null}
	var f: Faction = u.faction if known(u) else view(u).faction
	var doubt := not known(u) and view(u).mark() == Read.Mark.DOUBT
	if f and f != command.faction() and Faction.friends(f, command.faction()) and not doubt and not (not known(u) and view(u).silhouette()):
		look.tint = ally_glow
	return look


# Puts look_of() on the unit.
func _apply_look(u: Unit, look: Dictionary) -> void:
	u.set_saturation(look.sat)
	u.set_glow(look.glow, high_contrast and (known(u) or look.glow >= 0))
	if look.tint != null and u.glow.visible:
		u.glow.modulate = Color(look.tint, clampf(u.glow.modulate.a * ALLY_BOOST, 0.0, 1.0))


# How a unit of the player's own side stands for orders, for the map: &"ready" (it can take an order
# now, with AP to act on it: lit), &"far" (it would, but for standing out of reach of the leader's
# orders: in colour, its glow weaker), &"reduced" (it takes orders, but only in a reduced capacity -
# Mindless Fury, Drone: Unit.reduced()), &"spent" (on the player's turn it's tapped - Command.tapped():
# out of AP, helpless, past the turn's command caps: grey) or &"idle" (not the player's turn, or not
# its side: allies of another side and foes are drawn as they are).
func command_state(u: Unit) -> StringName:
	if not my_turn() or not known(u):
		return &"idle"
	if not command.could_order(u):
		return &"spent"
	if u.reduced():
		return &"reduced"
	return &"ready" if command.in_range(u) else &"far"


# How strongly a unit glows (Unit.set_glow()): one of the four strengths, by how ready it is for what
# the player is about - or -1, its plain glow, when that says nothing of it. With a skill armed, the
# units it's for glow by how reachable they are (skill_glow()); with none, on the player's turn, its
# own side glows by how ready each is for an order (command_glow()).
func glow_of(u: Unit) -> int:
	var me := selected if _orders(selected) else null
	var s := armed
	if me and aiming():
		return command_glow(u)
	if me and s and support_view():  # the support view: the units it's for glow by reach, foes fall back
		if unit_seen(u.cell) != u:
			return -1
		var g := skill_glow(me, s, u)
		return g if g >= 0 else (Unit.Intensity.BARELY if foe(u) else command_glow(u))
	if me and foe(u) and unit_seen(u.cell) == u:
		var p := _primary(me)
		return skill_glow(me, p, u) if p else -1
	return command_glow(u)


# The selected slot holds a skill for allies, not foes (support or defence), used on a unit: the map
# turns to it - allies glow by how reachable they are, foes fall back, hovering an ally plans the walk.
func support_view() -> bool:
	var s := armed
	return s != null and not s.on_tile() and not self_skill(selected, s) and s.for_allies() and not s.for_foes()


# How reachable t is for u's s, as far as the player can tell: fully, in reach now; mostly, a walk it
# can count on brings u into reach with the AP left to use it (a click walks there and uses it:
# _use_on()); somewhat, only a walk it can't count on does (_sure_walk()); barely, not this turn.
# -1: s isn't for t at all.
func skill_glow(u: Unit, s: Skill, t: Unit) -> int:
	var why := why_not(u, s, t)
	if why == "":
		return Unit.Intensity.FULLY
	if why != "Out of reach":
		return -1
	if _approach(u, s, t.cell, true).ready:
		return Unit.Intensity.MOSTLY
	return Unit.Intensity.SOMEWHAT if _approach(u, s, t.cell).ready else Unit.Intensity.BARELY


# How ready one of the player's own side is for an order, on the player's turn: fully, it takes one
# now. Out of reach of the leader's orders with nothing else against it (far): mostly when a walk
# the leader can count on, straight toward it, brings it into reach; somewhat when only one it can't
# count on does; barely when none does this turn. One that can't take another at all (spent: grey)
# glows barely too. -1: not the player's turn, or not its side.
func command_glow(u: Unit) -> int:
	match command_state(u):
		&"ready", &"reduced":
			return Unit.Intensity.FULLY
		&"spent":
			return Unit.Intensity.BARELY
		&"far":
			var w := _into_command(u)
			if w.dest == command.leader.cell:
				return Unit.Intensity.BARELY
			return Unit.Intensity.MOSTLY if w.sure else Unit.Intensity.SOMEWHAT
	return -1


# Where the leader's walk straight toward u first brings u into reach of its orders, and whether that
# walk is one it can count on (_sure_walk()); {dest = the leader's own cell} if none does this turn.
func _into_command(u: Unit) -> Dictionary:
	var lead := command.leader
	var span := command.party_reach() if u in command.party else float(command.reach())
	var path: Array[Vector2i] = []
	for c in battle.walk(lead, u.cell, true).path:
		path.append(c)
		if Command.tiles(c, u.cell) <= span and not unit_seen(c):
			return {dest = c, sure = _sure_walk(lead, path)}
	return {dest = lead.cell, sure = false}


# Whether u's walk across `path` is one the player can count on: nothing holds u (breaking free is a
# contest), and none of the ground it crosses is unsure - not made out, hinting at more, or where
# something may lurk (ground(): the '?' on a move cost) - or a known trap (it springs: dice).
func _sure_walk(u: Unit, path: Array) -> bool:
	if battle.held_by(u):
		return false
	for c: Vector2i in path:
		if c not in _unsure:
			var r := tile_view(c)
			_unsure[c] = r.trap == true or ground(c, r) == &"unsure"
		if _unsure[c]:
			return false
	return true


const SAT_LOW := 0.75  # the colour a unit that can still be commanded keeps on its last AP, or its last order
const SAT_REDUCED := 0.5  # acting in a reduced capacity (Unit.reduced(): Mindless Fury, Drone)


# How much colour it draws with (Unit.set_saturation()): full, but for the player's own side on its
# turn. One that can still be commanded - or could, were it in reach - drains only a little, as its
# AP runs out or its orders toward the caps are used (SAT_LOW at the last); one acting in a reduced
# capacity is half grey; one that's tapped this turn (Command.tapped()) is grey.
func command_sat(u: Unit, state := command_state(u)) -> float:
	match state:
		&"ready", &"far":
			var used := float(command.ordered.get(u, 0)) / command.order_cap(u) if u != command.leader else 0.0
			return 1.0 - (1.0 - SAT_LOW) * maxf(pow(1.0 - u.ap_share(), 2.0), minf(used, 1.0))
		&"reduced":
			return SAT_REDUCED
		&"spent":
			return 0.0
	return 1.0


func _why_no_orders(u: Unit) -> String:
	if battle.phase != Battle.Phase.TURNS:
		return "The battle is over"
	if not hand(u):
		return "Not yours to command"
	if not command.leader.is_alive():
		return "Your leader has fallen"
	if busy or battle.turn != command.faction():
		return "Wait for your turn"
	if not u.is_alive():
		return "Fallen"
	if u.stopped() or u.ap_left() <= 0.001:
		return _why_tapped(u)
	if not command.under_caps(u):
		if u in command.ordered:  # what skills and items add to a cap is named beside the charisma (Command.basis())
			return "%s gives an ally %d order%s a turn (%s)" % [_name(command.leader), command.order_cap(u), "" if command.order_cap(u) == 1 else "s", command.basis(command.order_bonus(), u)]
		return "%s commands %d all%s a turn (%s)" % [_name(command.leader), command.ally_cap(), "y" if command.ally_cap() == 1 else "ies", command.basis(command.ally_bonus())]
	return ""  # too far: no nag - its hotbar is grayed, and the units you can command are lit


# What taps it, of its own sources (Unit.tapped()): each can be lifted, and the tap with it.
func _why_tapped(u: Unit) -> String:
	if u.helpless() and u.fury_acts > 0:
		return "Tapped: its Mindless Fury is spent this turn"
	if u.asleep():
		return "Asleep: an ally ending the turn beside it wakes it"
	if u.dbno != null and not u.dbno.rule.acts:
		return "Downed: helpless until it's healed above 0 HP"
	if u.stat(&"helpless") > 0.0:
		var names := u.timed.keys().filter(func(e: Effect): return e.stat == "helpless").map(func(e: Effect): return e.label())
		return "%s: helpless%s" % [", ".join(names), " till healed or cleansed" if u.timed.keys().any(func(e: Effect): return e.stat == "helpless" and e.wound) else ""]
	return "Tapped: out of AP"


func _why_no_join(u: Unit) -> String:
	if not (known(u) or command.can_join(u)) or u == command.leader:
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
# next change) and the tiles its walk there crosses. With a skill armed they aren't drawn (Overlay),
# but say which of its targets a walk reaches (skill_glow()).
func _find_reach() -> void:
	var u := selected if _orders(selected) else null
	if u and u == _reach_of:
		return
	_reach_of = u
	reach.clear()
	_ways.clear()
	_unsure.clear()
	if not u or u.move_left() <= 0.0001:
		return
	var far := u.move_left() + 2.0  # every step costs at least 1, and luck squeezes in one more: nothing farther is reached
	var r := ceili(far)
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var c := u.cell + Vector2i(dx, dy)
			if Vector2(dx, dy).length() > far or not battle.on_map(c) or c == u.cell or unit_seen(c):
				continue
			var w := battle.walk(u, c, true)
			if not w.path.is_empty() and w.path[-1] == c:
				reach[c] = w.costs.reduce(func(sum, x): return sum + x, 0.0)
				_ways[c] = w.path


# What hovering shows: the intent of a click on the hovered tile (intent()), its walk as `plan` and the
# unit it would be used on as `charge`.
func _replan() -> void:
	hovered = intent(hover) if hover != NOWHERE else {}
	plan = hovered.get("walk", {})
	var it := hovered
	if (it.is_empty() or it.kind not in [&"walk", &"use", &"strike_at", &"command_walk"]) and selected and self_skill(selected, armed) and _orders(selected):
		it = intent(selected.cell)  # a self skill selected: its use, previewed
	spend = drain(it)
	hurt = _hurt(it)
	if card:
		card.set_info(_card_info())
	charge = hovered.cell if hovered.get("kind") == &"use" and hovered.target is Unit and hovered.target != selected else NOWHERE


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
	%LogLine.text = text


# The log: open, every line; collapsed, only the last entry, at the foot of the column (floating
# numbers on the units carry the moment). A click on the line or the LOG title opens it; the title closes it.
func show_log(open: bool) -> void:
	log_open = open
	log_box.visible = open
	%LogLine.visible = not open
	%LogGap.visible = not open
	%LogTitle.text = "LOG ▾" if open else "LOG ▸"


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
