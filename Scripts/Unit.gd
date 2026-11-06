class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal energy_changed(was: int, now: int)
signal reserve_changed(r: Reserve, was: int, now: int)
signal died(u: Unit)
signal downed(u: Unit)  # it took mortal damage with a heart left: it gets up again as the turn ends (Battle._on_downed())

# Stats with a base value on the unit; effects add to these and to any other named stat.
const CORE: Array[StringName] = [&"strength", &"dexterity", &"constitution", &"intelligence",
		&"wisdom", &"charisma", &"movement", &"reach", &"size"]
const BASE_AP := 10.0
const GENERAL_TREES: Array[SkillTab] = [preload("res://Trees/general.tres"), preload("res://Trees/general_martial.tres"),
		preload("res://Trees/general_specialist.tres"), preload("res://Trees/general_caster.tres")]  # the general trees, on the far right of the skills screen (general_trees())
const MENTAL: Array[StringName] = [&"intelligence", &"wisdom", &"charisma"]  # the stats of mental checks (bracing)
const SPECIALIST_EDGE := 2  # tiers sooner a class with the Specialist tree reaches the other trees through Martialist and Thaumaturgist (_general_need())
const SUFFICIENT := 2  # the con or str mod that lets armor that eases heavy armor's drag lift it (armor_drag())
const CLASS_HP := 5  # a class unit's max HP before what its levels bring (Battle.from_role(); level_hp()) - its level 1 total is 5 + con mod + vigor, a Fighter 10
const SLOTS := 4  # skill slots at level 1; one more every 4 levels (slot_count()), plus any skills grant
const ENERGY_COLOR := Color("#e8c547")
const POWER_COLOR := Color("#f2a93b")  # Energy that's Power (Powerful): yellow tinted orange, pulsing white above 75% and blue when full
const HP_COLOR := Color("#3fbf4f")
const SHAPE_EDGE := Color("#8a8f9c")  # glow of a shape whose side can't be told
const SHAPE := Color(0.03, 0.03, 0.03)  # what a shape is painted
const GLOW := 0.55  # how strongly a unit glows in its side's colour
const DESATURATE := preload("res://Scenes/UI/desaturate.gdshader")
const PROMINENCE := 1.6  # a commandable unit's glow, this much stronger; x2 in high contrast
# The gods units pray to (god; Pray: Battle.pray()), by domain.
const GODS := {&"ramut": "war, power", &"eros": "love, healing", &"sol": "light, fire", &"urlo": "magic, energy", &"luun": "dark, jovial",
		&"drael": "water, air", &"vetruvis": "earth, music"}
# The damage tag of each god's domain, carried by skills of their worshippers that take it (Smite: Skill.god_tag).
const GOD_TAGS := {&"ramut": &"physical", &"eros": &"love", &"sol": &"fire", &"urlo": &"energy", &"luun": &"dark",
		&"drael": &"water", &"vetruvis": &"earth"}
const TRIM_DARKEN := 0.45  # bar trim: the side's primary, this much darker
const BAR_WIDTH := 24.0


# A channel it holds (Metea): the skill, where it was cast, and its side's turns since.
class Channel:
	var skill: Skill
	var at: Vector2i
	var turns := 0

	func _init(s: Skill, c: Vector2i) -> void:
		skill = s
		at = c


# A timed effect on this unit: turns left, and the rank of the skill that applied it.
class Applied:
	var turns: int  # 0 with until_move: no limit
	var rank: int
	var fades := false  # when its turns run out, it loses a rank a turn instead of ending (Clever Disguise)
	var until_move := false  # ends once its holder moves, rather than standing still (Hide; still())
	var known_to: Array[Unit] = []  # units that saw through it (Battle.investigate()): it doesn't count against them
	var skill: Skill  # the skill that put it on, if one did
	var roll := 0  # what investigators must beat: its user's one roll as it was put on (Clever Disguise: d20 + cha mod + rank)
	var evaluated := false  # an ally's Self-evaluation saw that roll, so its side knows it
	var by: Unit  # the unit that put it on (a grapple's holder)
	var since := -1  # the side's turn it was put on (Battle.turns_begun): a bleed doesn't take that one
	var lasting := false  # no limit: it lasts until something ends it (a grapple: breaking free), or all battle (Ramut's Ire)
	var through: Array[Unit] = []  # allies its holder has seen straight through it (Haluca: their tags unscrambled; Battle.inspect())
	var total := 0  # the turns it was put on for: an arc's strength goes by how far through them it is (wauaw)
	var scale := 1.0  # its strength, set as it was put on

	func _init(t: int, r: int) -> void:
		turns = t
		rank = r

	# How strong it is now, for effect e: its scale, and for an arc (Effect.arc) the steps it has
	# climbed - one a turn to the middle of its turns, then back down (5 turns: 1, 2, 3, 2, 1).
	func strength(e: Effect) -> float:
		if not e.arc or total <= 0:
			return scale
		var i := clampi(total - turns, 0, total - 1)
		return scale * (mini(i, total - 1 - i) + 1)


@export var cell: Vector2i
@export var faction: Faction
@export var role: Role
@export var race: Race
@export var nick := ""  # the name the player gave it (node names get sanitised)
@export var title := ""  # "of Red"
@export var level := 1
@export var look: Texture2D  # sprite; falls back to the role's, then the scene's
@export var tags: Array[StringName] = []  # what it is, beyond race and role (monster, undead...)
@export var vibe := ""  # the impression it gives off ("Smouldering", "Reeking")
@export var aura := 0  # -2 ominous .. +2 benevolent
# How its AI acts beyond the usual: craven (won't advance without an ally it reads as higher-level
# near: AI.CRAVEN_REACH); lure (serene and still until unmasked, singing, drowning and raking what comes into reach: AI._ambush()).
@export var behaviour := &""
# Whom it heals first (AI._heal()): benevolent (the default: those most in need), pragmatic (its MVPs,
# by the level it reads, when a heal wouldn't go to waste) or loyal (its party first).
@export var tends := &""
@export var god := &""  # whom it prays to (Pray), one of GODS; empty: its class's (Role.god)
@export var uncontrolled := false  # on the player's side, but it takes no orders and joins no party: it acts on its own (the Astral Envoy's shades)
@export var with_player := false  # joins whichever side the player's starter is on (Battle._ready(): the Astral Envoy's villagers and shades)
@export var hearts := 0  # extra lives of its own, on top of its items' (lives())
@export var loot: Loot  # what it may drop as it falls (Battle._on_died())
@export var summons: PackedScene  # comes with each heart it spends, as it gets up (the Astral Princess: a Regeneration Probe)
@export_file("*.tscn") var reverts_to := ""  # what it falls back into as it dies, on its tile (a Starman: a Starmote; Battle._on_died()) - a path: the two scenes name each other
@export_file("*.tscn") var reforms_into := ""  # what it becomes once its Reforming stacks reach its level (a Starmote: a Starman; Battle._starkind())
@export var hunts: Array[Faction] = []  # sides its AI goes after first (Starmen: the Stellar Order; AI.HUNT)

@export_group("Persona")  # what it advertises; the Persona skill's rank says how much
# The side it presents as, to those it fools (Read.stance): Friendly (rank 2) passes for their ally;
# from rank 3 it can claim the wrong team - Enemy (hostile), Aggressive (to be avoided), Passive
# (mostly ignored), Traitor (against its real allies, for its real enemies).
@export var stance := ""  # "", Friendly, Enemy, Aggressive, Passive or Traitor
@export var shows_level := 0  # rank 2: the level it claims to those it fools (0: it advertises its own)
@export var shows_vibe: Array[String] = []  # rank 1
@export var shows_tags: Array[StringName] = []  # rank 3: identity
@export var shows_adjectives: Array[String] = []  # rank 3: the first word of the name it goes by, one picked per battle ("Radiant")
@export var shows_nouns: Dictionary[String, String] = {}  # rank 3: the second, each with text standing in for its sprite ("Lady": ";)")
@export var extra_dissonance := 0  # on top of what its persona puts forward (dissonance())
@export var intention := ""  # what it means to do, read by insight (the Astral Princess: "Purge evil")
@export var strategy: Array[StringName] = []  # how it picks its targets, read by insight, driving its AI (AI._best_target()): closest, strongest, weakest
@export_group("")
@export var innate: Array[Slot] = []  # from the unit's kind (villagers: Strike); the role adds its own
@export var learned: Array[Slot] = []  # per unit
# Skills on the hotbar by slot, null where empty (see Skill.fits_bar() and slot_kinds()). Left empty,
# it fills with the unit's actives, then its toggled passives.
@export var hotbar: Array[Skill] = []
@export var lore: Array[Skill] = []  # accrued knowledge: skills it has come to know of and can unlock
@export var skill_points := 0  # one per level gained, spent unlocking skills (unlock())
var waived: Dictionary[Skill, Skill] = {}  # general-tree skills learned through a waiver -> the skill that waived their needs (Generalist): they stop working without it (lapsed())
var element := &""  # the element its Strikes carry when imbued or with Elemental Mastery (Battle.imbue())
var imbued := 0  # Strike uses left carrying its element (Elemental Strike)
var purchases: Array = []  # [skill, points] for each unlock and raise, in order: a level curse takes the last back first (unranked())
@export var extra_slots := 0  # sure slots past 4 + level / 4, for NPCs and monsters that need them

@export var max_hp := 10:
	set(m):
		max_hp = m
		if hp > m:
			hp = m
		if is_node_ready():
			_show_bars()
@export var max_energy := 10:
	set(m):
		max_energy = m
		if energy > m:
			energy = m
		if is_node_ready():
			_show_bars()
@export var reserves: Dictionary[Reserve, int] = {}  # extra energy types -> max (Icor: mana 12)

@export_group("Equipment")
@export var armor: Item  # sets its Defense (none: dex mod + con mod; see armor_defense())
@export var weapon: Item  # can let its strength attacks use another stat (wielded())
@export var trinket: Item  # Heart Up

@export_group("Stats")
@export var strength := 5
@export var dexterity := 5
@export var constitution := 5
@export var intelligence := 5
@export var wisdom := 5
@export var charisma := 5
@export var movement := 5  # movement points per turn
@export var reach := 0.0  # added to skill ranges; weapons and passives raise it
@export var size := 3  # Medium, when the unit has no race

# Starts at 0 and fills in _ready, so bars get an initial hp_changed(0, max_hp).
var hp := 0:
	set(v):
		v = clampi(v, 0, max_hp + over_max)
		if v == hp:
			return
		var was := hp
		hp = v
		if v <= max_hp:
			over_max = 0
		hp_changed.emit(was, v)
		if v == 0 and not reviving and lives_left() > 0:  # local v, not hp: a listener may have changed hp re-entrantly
			hearts_used += 1
			reviving = true
			downed.emit(self)
		elif v == 0:
			died.emit(self)

# The default energy every unit has; reserves (mana...) are extra.
var energy := 0:
	set(v):
		v = clampi(v, 0, max_energy)
		if v == energy:
			return
		var was := energy
		energy = v
		energy_changed.emit(was, v)

var stores: Dictionary[Reserve, int] = {}  # current amount of each reserve
var ap: Array[AP] = []  # refilled at the start of each of this unit's faction turns
var moved := 0.0  # movement spent this turn
var steps := 0  # tiles walked this turn (still())
var ground: Array[StringName] = []  # tags of the tile it stands on (Battle keeps this current)
var footing: Terrain  # the tile it stands on, whose effects it has while there (Battle keeps this current)
var blind_on: Variant = null  # a cell it walked onto this turn without seeing under its leaves (Battle.obscured()): checks there come at disadvantage
var steadied: Variant = null  # the cell where it caught itself as glass gave way: spared that ground's effects until it moves off or a turn passes (Battle._teeter())
var steady_turn := -1  # turns_taken when it did
var stowed: Item  # the trinket shackles bound on it took the place of: back on as they come off (Battle._bind())
var timed: Dictionary[Effect, Applied] = {}  # effects others put on this unit
var exposed := 0  # concealment levels lost to attacking or being hit (Battle.cast); back as its side's turn starts
var shown: Read  # how the player's side sees it (see appear()); null: as it is
var rest := 0.0  # energy recovered towards the next whole point (recover())
var alias := ""  # the name its persona goes by (rank 3), picked from its pools as it's set up: "Radiant Lady"
var alias_face := ""  # the stand-in sprite of that name's noun: ";)"
var alias_noun := ""  # that name's noun: "Lady"
var follows: Unit  # the leader whose party it's in (Command.join())
var suspicion := {}  # stacks against the units (and tiles: Vector2i) it's grown suspicious of: each sees through a rank of their trickery and concealment (Battle.suspect())
var noticed := {}  # tiles where it has inspected something suspicious (Battle._first_look())
var rested_turns := 0  # its side's turns in a row it has rested through: it looks further and better (Battle.survey())
var unwatched := 0  # its turns since it last looked around (Battle._watch(): wis mod 0 or less looks only every few)
var heading := Vector2i.ZERO  # the way its last move this turn went, if moving was the last thing it did (Eyes Forward)
var _face: Label  # draws a persona's stand-in sprite in place of its own (_show_face())
var _role_slots: Array[Slot] = []  # this unit's copies of its role's innate skills
var _ap_start: Array[float] = []  # each AP pool as its turn started, to tell how hard it worked (activity())
var _walk_ap: Array[float] = []  # of each AP pool, what walking took this turn (activity(): standing still doesn't count)
var _kinds: Array[StringName] = []  # the slot kinds the hotbar was last arranged for (_arrange())
var hearts_used := 0  # hearts spent getting back up this battle
var reviving := false  # down at 0 HP with a heart spent: it gets up as the turn ends (Battle._on_downed())
var channel: Channel  # a channeled skill it's holding (Metea; Battle.cast_at())
var pulse_wait := 0  # its side's turns since it last pulsed (Regeneration Pulse; Battle._pulse())
var _hp_bonus := 0  # what its level, items and passives add to its max HP now (refit())
var respec: Dictionary[StringName, int] = {}  # how far each base stat has been shifted from what it was born with (respec_by())
var over_max := 0  # HP it may hold past its max for now (a Red Spinel Ring past rank 10), gone once it drops to its max
var slain_from := 0  # the HP it had as Death took it: what revival and die-hard effects go by (Battle._death())
var disabled: Dictionary[Skill, int] = {}  # skills switched off (Brainfog) -> its turns left: they can't be used, and passives stop working
var cursed: Dictionary[Skill, bool] = {}  # of those, the ones a curse switched off (Brainfog): their slots quiver
var chant_gains := 0  # Sweet Nothing gains a Chant will add one to (Battle._chant())
var chant_up := false  # a Chant primed: its next Warlock skill is used a rank higher (rank())
var turns_taken := 0  # its side's turns it has started this battle (refresh(): a Dagger's opening AP)

# Every skill entry, the role's first; a skill listed twice keeps its highest rank.
var slots: Array[Slot]:
	get:
		var best := {}
		for s in _role_slots + innate + learned:
			if s and s.skill and (s.skill not in best or s.rank > best[s.skill].rank):
				best[s.skill] = s
		var out: Array[Slot] = []
		out.assign(best.values())
		return out

var actives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		var lost := unranked()
		s.assign(slots.filter(func(x: Slot): return not x.skill.passive and x.skill not in disabled and lost.get(x.skill, 0) < x.rank and not lapsed(x.skill) and rank(x.skill) > 0).map(func(x: Slot): return x.skill))
		return s

# Passive entries that are on (and not disabled).
var on_passives: Array[Slot]:
	get:
		var s: Array[Slot] = []
		var lost := unranked()
		s.assign(slots.filter(func(x: Slot): return x.skill.passive and x.on and x.skill not in disabled and lost.get(x.skill, 0) < x.rank and not lapsed(x.skill)))
		return s

var passives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		s.assign(on_passives.map(func(x: Slot): return x.skill))
		return s

# What it can do, as others read it: its actives and passives that are on, and what's disabled.
var kit: Array[Skill]:
	get:
		var s: Array[Skill] = actives + passives
		for x in disabled:
			if x not in s:
				s.append(x)
		return s

var luck: int:
	get:
		return roundi(stat(&"luck"))

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var glow: Sprite2D = $Glow
@onready var trim: Panel = $BarTrim
@onready var hp_bar: ProgressBar = $HpBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var reserve_bar: ProgressBar = $ReserveBar


func _ready() -> void:
	# Skill entries hold per-unit state (rank, toggles), but scenes and roles share them: copy.
	_role_slots.assign((role.innate if role else []).map(func(s: Slot): return s.duplicate()))
	innate.assign(innate.map(func(s: Slot): return s.duplicate()))
	learned.assign(learned.map(func(s: Slot): return s.duplicate()))
	if role and not race:
		race = role.race
	if role and not look:
		look = role.look
	_take_looks()
	_pick_alias()
	_fill_bar()
	_show_look()
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = DESATURATE
	set_saturation(1.0)
	_layout_bars()
	_show_faction()
	refit()
	hp_changed.connect(_show_bars.unbind(2))
	energy_changed.connect(_show_bars.unbind(2))
	reserve_changed.connect(_show_bars.unbind(3))
	hp = max_hp
	energy = max_energy
	for r in pools():
		set_store(r, pools()[r])
	_show_bars()
	set_process(powered())


# Power (powered()) pulses its bar: white above 75%, blue when full.
func _process(_delta: float) -> void:
	var full := float(energy) / maxi(max_energy, 1)
	var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	var to := Color(0.7, 0.9, 1.8) if full >= 1.0 else Color(1.7, 1.7, 1.7)
	energy_bar.self_modulate = Color.WHITE.lerp(to, beat) if full > 0.75 else Color.WHITE


# Its rank in s as it uses it: what it has learned, plus what rank effects add or take (a Broadsword:
# Strike; Record Striker's curse) and a primed Chant (a Warlock skill, once); 0 if it doesn't have s,
# or it's cursed down to nothing.
func rank(s: Skill) -> int:
	var r: int = base_rank(s) - unranked().get(s, 0)
	return maxi(r + roundi(skill_stat(&"rank", s)) + int(chant_up and &"warlock" in s.tags), 0) if r > 0 else 0


# Levels a curse has taken off it (Level Down), from its timed level effects alone (its passives can't
# be read here: they depend on this).
func _cursed_levels() -> int:
	var n := 0.0
	for e in timed:
		if e.stat == "level":
			n += e.amount * (timed[e].rank if e.per_rank else 1) * timed[e].strength(e)
	return maxi(-roundi(n), 0)


# Ranks a level curse has taken back, by skill: each level lost costs a skill point, from its unspent
# ones first; past those, its last purchases are undone, newest first, until the total isn't negative.
# An unlock undone switches the skill off; a raise, a rank off. Back as the curse ends.
func unranked() -> Dictionary:
	var out := {}
	var owed := _cursed_levels() - skill_points
	var i := purchases.size() - 1
	while owed > 0 and i >= 0:
		out[purchases[i][0]] = out.get(purchases[i][0], 0) + 1
		owed -= purchases[i][1]
		i -= 1
	return out


# Its rank in s as learned: what skill points raise (raise_cost()).
func base_rank(s: Skill) -> int:
	for x in slots:
		if x.skill == s:
			return x.rank
	return 0


# An attribute of s for it (range, rank): what its effects add, asked with s's tags (Skill.query()),
# and only effects that list s when they list skills.
func skill_stat(attr: StringName, s: Skill) -> float:
	return stat(attr, s.query(), null, s)


func is_on(s: Skill) -> bool:
	for x in slots:
		if x.skill == s:
			return x.on
	return false


# Switches a passive that has a toggle on or off. False if the unit has no such skill.
func toggle(s: Skill) -> bool:
	for x in slots:
		if x.skill == s and s.passive and s.toggle:
			x.on = not x.on
			return true
	return false


# Its sure skill slots: 4 + level / 4, rounded down, + any extra (NPCs and monsters) - by the higher of
# its level and its level now (lv()): a level buff adds slots, and slots a curse takes stay on the bar,
# sealed (sealed()).
func slot_count() -> int:
	return _slots_at(maxi(level, lv()))


func _slots_at(l: int) -> int:
	return SLOTS + floori(l / 4.0) + extra_slots


# Its level now: its own, plus level effects (a buff or a curse), at least 1.
func lv() -> int:
	return maxi(level + roundi(stat(&"level")), 1)


# Whether sure slot i is one a level curse took (lv() below its level): it stays, sealed and quivering,
# until the curse ends.
func sealed(i: int) -> bool:
	return i >= _slots_at(lv()) and i < slot_count()


# Slots its passives grant (Basic Magic Skill Slot +1), in the order it learned them, then its items'
# (the Burning Bag): each one's type
# (magical, martial, specialist: it only holds skills carrying that tag), or &"" for an untyped one.
func granted_slots() -> Array[StringName]:
	var out: Array[StringName] = []
	var sources: Array = on_passives.map(func(x: Slot): return [x.skill.effects, x.rank]) + items().map(func(it: Item): return [it.effects, it.rank])
	for pair in sources:
		for e: Effect in pair[0]:
			if e.stat == "slots":
				for i in roundi(e.amount * (pair[1] if e.per_rank else 1)):
					out.append(e.tags[0] if not e.tags.is_empty() else &"")
	return out


# Hotbar slots that burn, by index -> [damage, whoever set them alight (null: an item)]: the slots a
# burning item grants (the Burning Bag: 10% x its rank of max HP), and its rightmost slots Cindering
# set alight (10% x its rank of max HP + its caster's wis mod). Using a skill from one burns it
# (Battle._burn()).
func burning_slots() -> Dictionary:
	var out := {}
	var end := slot_count() + granted_slots().size()
	for it in items():
		if it.burning:
			var n := 0
			for e in it.effects:
				if e.stat == "slots":
					n += roundi(e.amount * (it.rank if e.per_rank else 1))
			for i in range(end - n, end):
				out[i] = [maxi(rounded(0.1 * it.rank * max_hp), 1), null]
	for e in timed:
		if e.stat == "cinders":
			var a := timed[e]
			var dmg := rounded(0.1 * a.rank * max_hp) + (a.by.mod(&"wisdom") if a.by else 0)
			for i in range(maxi(bar_size() - a.rank, 0), bar_size()):
				out[i] = [maxi(dmg, 1), a.by]
	return out


# Every hotbar slot's kind, in order: its sure slots (&""), then the slots its skills grant (their
# type), then the clover slot (&"clover") while level / 4 has something to round.
func slot_kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	for i in slot_count():
		out.append(&"")
	out.append_array(granted_slots())
	if lv() % 4:
		out.append(&"clover")
	return out


func slot_kind(i: int) -> StringName:
	var kinds := slot_kinds()
	return kinds[i] if i >= 0 and i < kinds.size() else &""


# The clover slot: the one more a lucky unit gets from rounding level / 4 up instead - the last slot,
# while level isn't a multiple of 4 (-1 when it is: there's nothing to round). It only works while the
# unit is lucky; a level that makes the rounding exact turns it into a plain slot.
func clover() -> int:
	return slot_count() + granted_slots().size() if lv() % 4 else -1


# Hotbar slots, the clover slot included (whether it works now or not).
func bar_size() -> int:
	return slot_kinds().size()


# Whether hotbar slot i works now: every slot does but the clover slot, which needs the unit lucky,
# and slots a level curse sealed.
func slot_works(i: int) -> bool:
	return i >= 0 and i < bar_size() and (i != clover() or luck > 0) and not sealed(i)


# Whether s can go in hotbar slot i: a typed slot only holds skills carrying its type.
func fits(s: Skill, i: int) -> bool:
	var k := slot_kind(i)
	return k == &"" or k == &"clover" or k in s.tags


# x rounded down, or up while the unit is lucky (level / 2 for a Gambeson, level / 4 for slots).
func rounded(x: float) -> int:
	return Luck.settle(x, luck, true, false)


# Puts one of the unit's skills in hotbar slot i (one that works and that it fits). A skill already on
# the bar swaps places with whatever is in i - which comes off the bar if it doesn't fit there. Pillar
# skills keep the last sure slots: they can't be moved, and nothing takes their place.
func bar_place(s: Skill, i: int) -> bool:
	if i < 0 or i >= hotbar.size() or not slot_works(i) or not s or not s.fits_bar() or rank(s) == 0 or not fits(s, i):
		return false
	if s.pillar() or (hotbar[i] and hotbar[i].pillar()):
		return false
	var old := hotbar.find(s)
	if old >= 0:
		hotbar[old] = hotbar[i] if hotbar[i] and fits(hotbar[i], old) else null
	hotbar[i] = s
	return true


func bar_clear(i: int) -> void:
	if i >= 0 and i < hotbar.size() and not (hotbar[i] and hotbar[i].pillar()):
		hotbar[i] = null


func level_up() -> void:
	level += 1
	skill_points += 1
	_arrange()


# The first empty hotbar slot that works (and that s fits, given one), or -1.
func free_slot(s: Skill = null) -> int:
	for i in hotbar.size():
		if not hotbar[i] and slot_works(i) and (s == null or fits(s, i)):
			return i
	return -1


# The skills on offer to it, by where they come from: its class (its options, or its whole skill
# tree), its species, and what it's come to know.
func sources() -> Dictionary:
	return {
		&"class": (role.offered() if role else ([] as Array[Skill])) + general_skills().filter(func(s: Skill): return not role or s not in role.offered()),
		&"species": race.options if race else ([] as Array[Skill]),
		&"knowledge": lore,
	}


# sources(), less the skills it already has and those it can't learn yet: what a skill point could
# unlock.
func options() -> Dictionary:
	var out := {}
	var all := sources()
	for k in all:
		var fresh: Array[Skill] = []
		fresh.assign(all[k].filter(func(x: Skill): return x and rank(x) == 0 and missing(x) == ""))
		out[k] = fresh
	return out


# What stands between it and learning s, apart from skill points: "" if nothing. A stub waits on an
# open question; on a class tree, the skills a branch comes after, and the count of its root's
# skills a capstone needs.
# Its own default skill for a posture (Skill.serves): the first active on its hotbar it can use that
# way now. Null when it has none - the commander's intent order would be wasted (HUD.issue_intent).
func intent_skill(posture: StringName) -> Skill:
	for sk in hotbar:
		if sk and sk.serves(posture) and can_afford(sk):
			return sk
	return null


func missing(s: Skill) -> String:
	if s.stub:
		return s.waits()
	if s.exclusive:
		for x in slots:
			if x.skill != s and x.skill.exclusive == s.exclusive and x.rank > 0:
				return "Not with %s" % x.skill.name
	var gtier := -1
	for g in GENERAL_TREES:
		gtier = g.tier_of(s)
		if gtier >= 0:
			break
	if gtier > 0 and (not role or role.tier(s) < 0):
		return _general_need(s, gtier)[0]
	var learnt := learned.filter(func(x: Slot): return x.skill != s and x.rank > 0).size()
	if s.min_tier > 1 and learnt < s.min_tier - 1:
		return "Learn %d skill%s first (%d so far)" % [s.min_tier - 1, "" if s.min_tier == 2 else "s", learnt]
	var root := role.root_of(s) if role else null
	if not root:
		return ""
	var devoted := devotion()
	var tab := role.tab_of(s)
	if devoted and tab and tab.devotes and tab != devoted:
		return "Devoted to %s" % devoted.name
	var b := root.branch(s)
	var first := b.after.filter(func(x: Skill): return rank(x) == 0)
	if not first.is_empty():
		return "Learn %s first" % " and ".join(first.map(func(x: Skill): return x.name))
	if b.needs > 0:
		var have := root.skills().filter(func(x: Skill): return x != s and rank(x) > 0).size()
		if have < b.needs:
			return "Needs %d %s skills (%d so far)" % [b.needs, root.name, have]
	return ""


# The devoting tab (a Warlock's patron) it has learned a skill on beyond the shared row, or null:
# the other devoting tabs are closed to it.
func devotion() -> SkillTab:
	if not role:
		return null
	for t in role.tabs:
		if t and t.devotes and t.roots.any(func(r: SkillRoot): return r and r.skills().any(func(x: Skill): return base_rank(x) > 0)):
			return t
	return null


# Spends a skill point on one of options(), learning it at rank I: onto the hotbar's first free slot
# that fits it, if it goes there; slots it grants join the bar. False if it can't.
func unlock(s: Skill) -> bool:
	if skill_points <= 0 or not options().values().any(func(list: Array): return s in list):
		return false
	var gtier := tier(s)
	var via: Skill = _general_need(s, gtier)[1] if general_skills().has(s) and (not role or role.tier(s) < 0) else null
	if via:
		waived[s] = via
	var x := Slot.new()
	x.skill = s
	learned.append(x)
	skill_points -= 1
	purchases.append([s, 1])
	_arrange()
	refit()  # a passive may change what's derived (Hardy)
	var free := free_slot(s)
	if s.fits_bar() and free >= 0:
		hotbar[free] = s
	return true


# Skill points to raise s from its rank r to r + 1: 1 + r^2 (II costs 2, III 5, IV 10). Unlocking
# (r = 0) is the same rule: 1. A skill with its own rank_cost charges that for II, times its
# rank_growth each rank after (Clever Disguise: 4, 8, 16).
func raise_cost(s: Skill) -> int:
	var r := base_rank(s)
	if s.rank_cost > 0 and r > 0:
		return roundi(s.rank_cost * pow(s.rank_growth, r - 1))
	return 1 + r * r


# Whether s can go up a rank at all: it has it, and it's below the skill's cap.
func can_raise(s: Skill) -> bool:
	var r := base_rank(s)
	return r > 0 and not s.stub and (s.max_rank == 0 or r < s.max_rank)


# Spends raise_cost() to take s up a rank. False (nothing spent) if it can't, or lacks the points.
func raise(s: Skill) -> bool:
	if not can_raise(s) or skill_points < raise_cost(s):
		return false
	purchases.append([s, raise_cost(s)])
	skill_points -= raise_cost(s)
	for x in slots:
		if x.skill == s:
			x.rank += 1
	_arrange()  # a slot-granting skill may grant more per rank
	refit()  # and a passive more of what's derived (Hardy)
	return true


func _fill_bar() -> void:
	var fresh := hotbar.is_empty()
	hotbar.resize(bar_size())
	_kinds = slot_kinds()
	if not fresh:
		return
	var pinned := slot_count() - 1
	for x in slots:
		if x.skill.pillar() and x.skill.fits_bar() and pinned >= 0:  # pillar skills take the last sure slots
			hotbar[pinned] = x.skill
			pinned -= 1
	var picks := slots.filter(func(x: Slot): return not x.skill.passive and not x.skill.pillar())
	picks.append_array(slots.filter(func(x: Slot): return x.skill.passive and x.skill.fits_bar() and not x.skill.pillar()))
	for x in picks:
		var i := free_slot(x.skill)
		if i >= 0:
			hotbar[i] = x.skill


# Re-sorts the hotbar after its slots change (a level, a slot-granting skill): each skill keeps a slot
# of the kind it was in - sure slots in order, typed ones by type, and the clover slot's skill in the
# clover slot, or in a sure one when the clover slot turns plain. A skill left with no slot comes off
# the bar.
func _arrange() -> void:
	var now := slot_kinds()
	if now == _kinds and hotbar.size() == now.size():
		return
	var queues := {}
	for i in hotbar.size():
		queues.get_or_add(_kinds[i] if i < _kinds.size() else &"", []).append(hotbar[i])
	var out: Array[Skill] = []
	for k in now:
		var from: Array = queues.get(k, [])
		if from.is_empty() and k == &"" and &"clover" not in now:
			from = queues.get(&"clover", [])
		out.append(from.pop_front() if not from.is_empty() else null)
	hotbar = out
	_kinds = now


# Passives (on) that stop working on ground with these tags (Oceanic on water).
func paused_on(ground_tags: Array[StringName]) -> Array[Skill]:
	var out: Array[Skill] = []
	for s in passives:
		if s.effects.any(func(e: Effect): return e.unless_on.any(func(t): return t in ground_tags)):
			out.append(s)
	return out


# Base value (core stats only) plus every effect on that stat whose tags match the query;
# "mul" effects then multiply the total (Stoneskin halves dexterity). As `viewer` sees it: timed
# effects it saw through (Hide, against an investigator who passed) don't count.
func stat(s: StringName, tags: Array[StringName] = [], viewer: Unit = null, of: Skill = null) -> float:
	var t := Tags.expand(tags)
	var sum: float = 0.0
	if s == &"size" and race:
		sum = race.size
	elif s in CORE:
		sum = get(s)
	var factor := 1.0
	for pair in _effects(viewer):
		var e: Effect = pair[0]
		if e.stat != s or not (e.tags.is_empty() or e.tags.any(func(x): return x in t)):
			continue
		if not e.skills.is_empty() and of not in e.skills:
			continue
		if e.armored and not armored():
			continue
		if e.above_hp > 0 and hp <= e.above_hp * max_hp:
			continue
		if pair[1] < e.min_rank or e.unless_on.any(func(x): return x in ground):
			continue
		var amount: float = e.amount * (floori(stat(e.per_stat) / e.per) if e.per_stat else 1) * (pair[1] if e.per_rank else 1) * pair[2]
		if e.per_mod:
			amount *= mod(e.per_mod)
		if e.op == "mul":
			factor *= amount
		else:
			sum += amount
	return sum * factor


# The god it prays to: its own, else the one its devotion names (a Cleric's tab), else its class's.
func deity() -> StringName:
	if god:
		return god
	var d := devotion()
	if d and d.god:
		return d.god
	return role.god if role else &""


# Stacks of suspicion it has of t, a unit or a tile (Battle.suspect()).
func suspects(t: Variant) -> int:
	return suspicion.get(t, 0)


# How far what it shows is from the truth: what insightful units read of it (Perception.insight()),
# and a penalty to its own deceiving checks - a less believable lie. A point for each thing its
# persona puts forward at its rank - each vibe word (I), its stance and a level it claims (II), each
# identity tag and the name it goes by (III) - one each for fronting its stats (Embellish, Brood),
# plus extra_dissonance.
func dissonance() -> int:
	var p := roundi(stat(&"persona"))
	var n := extra_dissonance + int(stat(&"embellish") > 0) + int(stat(&"brood") > 0)
	if p >= 1:
		n += shows_vibe.size()
	if p >= 2:
		n += int(stance in Battle.stances(p) and stance != "") + int(shows_level > 0)
	if p >= 3:
		n += shows_tags.size() + int(alias != "")
	return n


# Dissonance as it counts against its own rolls: cut by the rank of a skill carrying the look it puts
# forward (Alluring: a practised lie), but no lower than 0.
func dissonance_penalty() -> int:
	var practised := 0
	for x in slots:
		if x.skill.has_look():
			practised = maxi(practised, x.rank)
	return maxi(dissonance() - practised, 0)


# Conspire's rank while it's switched on, else 0: allies near it let its persona fool them.
func conspiring() -> int:
	return roundi(stat(&"conspire"))


# Has Conspire, switched off: its allies see straight through its persona.
func candid() -> bool:
	return slots.any(func(x: Slot): return x.skill.passive and not x.on and x.skill.effects.any(func(e: Effect): return e.stat == "conspire"))


# Reads others well enough that only trickery fools it: a positive wis mod, or a bonus to reading
# others (insight).
func insightful() -> bool:
	return mod(&"wisdom") > 0 or stat(&"insight") > 0


# d20-style modifier: 10-11 -> 0, 12-13 -> +1, 8-9 -> -1. With a skill's tags, stand-in
# passives may swap the stat (see scaling()).
func mod(s: StringName, tags: Array[StringName] = []) -> int:
	return floori((scaling(s, tags) - 10) / 2.0)


# The stat value a skill with these tags scales on, after stand-in passives (Arcanist
# Perspective: int for wis/cha on magical skills). Below rank 5 the replaced stat must be at least
# (100% - 20% x rank) of the stand-in used, so the stand-in caps at replaced / (1 - 0.2 x rank).
# From rank 5 there's no cap, and each rank past 5 adds 20% of the replaced stat.
func scaling(s: StringName, tags: Array[StringName]) -> float:
	if role and s in role.swaps and &"magical" in tags:
		s = role.swaps[s]  # a Warlock's Hex: charisma for wisdom
	var base := stat(s)
	var best := base
	for x in on_passives:
		var p := x.skill
		if not (p.stand_in and s in p.replaces and p.tags.any(func(t): return t in tags)):
			continue
		var other := stat(p.stand_in)
		if x.rank < 5:
			best = maxf(best, minf(other, base / (1.0 - 0.2 * x.rank)))
		else:
			best = maxf(best, other + 0.2 * (x.rank - 5) * base)
	return best


func damage(d: int) -> void:
	hp -= maxi(d, 0)


# A tagged attack. Mitigation applies, then net luck (mine minus the attacker's) rounds what's
# left: up (against me) unless I'm luckier. Returns the damage taken.
func hit(raw: float, tags: Array[StringName], by: Unit = null) -> int:
	var charmed := roundi(stat(&"flamecharmed"))
	if by and by != self and charmed > 4 and &"fire" in tags and Faction.friends(by.faction, faction):
		heal(roundi(raw * 0.25 * (charmed - 4)))  # Flamecharmed: an ally's fire feeds it
	var net := luck - (by.luck if by else 0)
	var cut := mitigation(tags)
	if by and by.faction == faction:
		cut = minf(cut + stat(&"ally_mitigate"), 1.0)  # friendly fire (Conspire)
	var taken := Luck.settle(raw * (1.0 - cut), net, false)
	damage(taken)
	return taken


# Fraction of a hit with these tags that's blocked (additive, capped at 100%).
func mitigation(tags: Array[StringName]) -> float:
	return minf(stat(&"mitigate", tags), 1.0)


# What an attack with these tags must roll to hit it: what its armor sets, plus defense effects -
# untagged ones always, tagged ones against attacks carrying that tag or a child of it (physical
# Defense counts against a pierce).
func defense(tags: Array[StringName] = []) -> int:
	return armor_defense() + roundi(stat(&"defense", tags)) + armor_mind(tags) + (hearts_used if trinket and trinket.spent_defense else 0)


# Defence its armor's mind_stat adds against magical attacks alone (Robe: wis mod). Untagged queries
# (Defense shown at rest) count it too, so the sheet reflects it; a physical blow doesn't.
func armor_mind(tags: Array[StringName] = []) -> int:
	if not armor or not armor.mind_stat:
		return 0
	return mod(armor.mind_stat) if tags.is_empty() or &"magical" in Tags.expand(tags) else 0


# The Defense it has on top against attacks carrying a particular tag: tag -> how much more (Hydera:
# magical +1). Tags it has none extra for are left out.
func tagged_defense() -> Dictionary:
	var out := {}
	if armor and armor.mind_stat and mod(armor.mind_stat) != 0:
		out[&"magical"] = mod(armor.mind_stat)
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat == "defense":
			for t in e.tags:
				var extra := defense([t]) - defense()
				if extra:
					out[t] = extra
	return out


# Defense from armor alone. Unarmored, or in armor that sets none (Heart Up-Link): dex mod + con mod.
# Armor of a weight (light, medium, heavy) goes by its basic piece's scaling (Item.WEIGHTS).
# Armored: the higher of the armor's floor and its level now x its per_level (rounded down, or up
# while lucky), plus dex mod if the armor allows it.
func armor_defense() -> int:
	if not armor or not armor.sets_defense():
		return mod(&"dexterity") + mod(&"constitution") + (armor.enchant if armor else 0)
	var w := armor.weight_class()
	if w:
		var base: Array = Item.WEIGHTS[w]
		var share: float = 0.0 if armor.no_dex else (1.0 if armor.full_dex else base[2])
		var m := mod(&"dexterity")
		var dex := floori(m * share) if m < 0 else rounded(m * share)  # a negative share rounds down: a penalty always bites
		return maxi(base[0], rounded(lv() * base[1])) + dex + armor.enchant
	var floor_or_level := maxi(armor.defense, rounded(lv() * armor.per_level))
	return floor_or_level + (mod(&"dexterity") if armor.plus_dex else 0) + (rounded(stat(&"dexterity") * armor.dex_share) if armor.dex_share > 0.0 else 0) + armor.enchant


# Damage its weapon adds to attacks scaling on s: an enchanted weapon's +1 a rank, on strength attacks.
func weapon_bonus(s: StringName) -> int:
	return weapon.enchant if weapon and s == &"strength" else 0


# Pray, to Urlo: enchants up to n of its unenchanted items, weapon first, then armor: what an item
# becomes enchanted (Item.enchanted_as), else a copy of its own at +1. Items with nothing to scale
# would be skipped (none yet). How many it enchanted.
func enchant(n: int) -> int:
	var done := 0
	for slot in [&"weapon", &"armor"]:
		var item: Item = get(slot)
		if done < n and item and not item.enchanted():
			if item.enchanted_as:
				set(slot, item.enchanted_as)
			else:
				item = item.duplicate()
				item.enchant = 1
				set(slot, item)
			done += 1
	return done


# Haluca on it: it sees everyone's tags scrambled. The effect's Applied, or null.
func scrambled() -> Applied:
	for e in timed:
		if e.stat == "scrambled":
			return timed[e]
	return null


# Coordinate on it, linking it with others: the effect's Applied (by: whoever cast it), or null.
func linked() -> Applied:
	for e in timed:
		if e.stat == "coordinate":
			return timed[e]
	return null


# It sees t's tags scrambled: it's under Haluca and hasn't seen t straight since.
func scrambles(t: Unit) -> bool:
	var a := scrambled()
	return a != null and t != self and t not in a.through


# What it adds to s's attack roll: its mod in the skill's stat (Skill.stat()), or in a stat its
# weapon lets it use instead.
func attack_mod(s: Skill) -> int:
	return mod(wielded(s.stat(), s.tags), s.tags)


# The stat it really uses where one is asked for: for strength, a weapon may allow others, and it
# uses the best (a rapier: dexterity).
func wielded(s: StringName, tags: Array[StringName] = []) -> StringName:
	if s != &"strength" or not weapon:
		return s
	var best := s
	for x in weapon.attack_stats:
		if mod(x, tags) > mod(best, tags):
			best = x
	return best


# Its lives beyond the one it has: its own hearts, and its items' (Heart Up; Heart Up-Link: con mod;
# a Red Spinel Ring's once a battle, spent last: ring_lives()).
func lives() -> int:
	var n := hearts + ring_lives()
	for it in items():
		n += it.hearts + (maxi(mod(it.hearts_mod), 0) if it.hearts_mod else 0)
	return n


# The life its trinket gives once a battle (a Red Spinel Ring): 1, or 0.
func ring_lives() -> int:
	return 1 if trinket and trinket.revives > 0.0 else 0


# The average of its six core stats, as a mod: what a general check of the whole unit rolls with (its
# last stand: Battle.last_stand(); Level Down).
func average_mod() -> int:
	var sum := 0.0
	for s in CORE:
		sum += stat(s)
	return floori((sum / CORE.size() - 10) / 2.0)


# Starkind: its max HP is its max Power, and it wastes away off the star lattice (Battle._starkind()).
func starkind() -> int:
	return roundi(stat(&"starkind"))


func lives_left() -> int:
	return maxi(lives() - hearts_used, 0)


# What it has equipped: weapon, armor, trinket.
func items() -> Array[Item]:
	var out: Array[Item] = []
	for it in [weapon, armor, trinket]:
		if it:
			out.append(it)
	return out


# Whether it can wear it: the slot is one it equips, and it meets the item's requirement (Heart
# Up-Link: a positive con mod).
func can_wear(it: Item) -> bool:
	return it != null and it.slot in ["weapon", "armor", "trinket"] and (not it.requires or mod(it.requires) > 0)


# Puts it on in its slot, returning what was there (null if nothing, or if it can't wear it: then
# nothing changes). Its max HP follows (refit()).
func equip(it: Item) -> Item:
	if not can_wear(it):
		return null
	var old: Item = get(it.slot)
	set(it.slot, it)
	refit()
	return old


# Takes off what's in a slot, returning it.
func unequip(slot: String) -> Item:
	var old: Item = get(slot)
	set(slot, null)
	refit()
	return old


# The derived-stat pipeline's last step (docs/plan-composability.md, seam 5). Its stats are its base
# (respec_by() shifts it) under whatever effects are on it; from those, max HP: its authored base +
# what its level brings (level_hp()) + what items and passives add (max_hp effects: Burning Blade),
# less what Asphyxia takes (a share of base and level HP a stack) and Humble cuts, at least 1.
# Starkind, its base is its max Power and levels add nothing. Run whenever any of those change.
func refit() -> void:
	var authored := max_energy if starkind() > 0 else max_hp - _hp_bonus
	var grown := authored + (0 if starkind() > 0 else level_hp())
	var bonus := roundi(stat(&"max_hp")) - roundi(stat(&"asphyxia") * grown) - roundi(stat(&"humble"))
	max_hp = maxi(grown + bonus, 1)
	_hp_bonus = max_hp - authored
	if hp > max_hp + over_max:
		hp = max_hp + over_max
	_arrange()  # items can grant slots (the Burning Bag)


# Whether it carries tag t, from what it is (its tags), what it wears, or what it knows (Wildfire's
# bane: earth).
func has_tag(t: StringName) -> bool:
	return t in tags or items().any(func(it: Item): return t in it.tags) \
			or slots.any(func(x: Slot): return x.rank > 0 and t in x.skill.tags)


# Its shackles (a binding trinket) are locked: a Shackled effect is on it.
func shackled() -> bool:
	return timed.keys().any(func(e: Effect): return e.stat == "shackled")


# How heavy it is to move: its size, rounded up, + what its equipped items weigh (Item.heft(): armor
# by class, weapons medium unless light or heavy, anything with a weight of its own - Shackles).
func weight() -> int:
	var w := ceili(stat(&"size"))
	for it in items():
		w += it.heft()
	return w


# How hard it is to stop: how far it's moved this turn + its weight. Worked out when asked - glass's
# check is against it (Battle._teeter()): the further and heavier it came, the worse it screwed up.
func inertia() -> int:
	return steps + weight()


# Max HP its level brings on top of its base: (con mod x (1 + Hardy) + its class's vigor) a level. A
# unit without a class (hand-authored: a golem, a villager) has its usual scaling in its base already;
# only Hardy's extra con scaling adds to it.
func level_hp() -> int:
	var con := mod(&"constitution")
	var per := con * roundi(stat(&"hardy")) + (con + role.vigor_per_level() if role else 0)
	return per * lv()


# Shifts its base stats (Meditate): `changes` stat -> amount, each stat's total shift kept within
# `limit` either way of what it was born with. All or nothing: false (and no change) if any would go
# past it. Everything derived follows (refit()).
func respec_by(changes: Dictionary, limit: int) -> bool:
	for s in changes:
		assert(s in CORE, "%s isn't a core stat" % s)
		if absi(respec.get(s, 0) + changes[s]) > limit:
			return false
	for s in changes:
		respec[s] = respec.get(s, 0) + changes[s]
		set(s, get(s) + changes[s])
	refit()
	return true


# Its six core stats as they are, unchanged by effects, added up: Starblade's measure of a target.
func base_total() -> int:
	return strength + dexterity + constitution + intelligence + wisdom + charisma


# Its Energy is Power (Powerful): it never comes back on its own - only what gives it back does
# (Starblade).
func powered() -> bool:
	return stat(&"powered") > 0.0


# Energy damage (Smite): what gets through mitigation (and luck, as hit()) drains its Energy first;
# once that's gone, `carry` of the rest goes on to HP. Returns the HP taken.
func drain(raw: float, tags: Array[StringName], by: Unit, carry: float) -> int:
	var net := luck - (by.luck if by else 0)
	var taken := Luck.settle(raw * (1.0 - mitigation(tags)), net, false)
	var off := mini(energy, taken)
	energy -= off
	var over := Luck.settle((taken - off) * carry, net, false)
	damage(over)
	return over


# Dead units stay dead.
func heal(h: int) -> void:
	if is_alive():
		hp += maxi(h, 0)


# Every reserve it has, by max: its own (reserves), and those its passives give - each the holder's
# mod in the passive's reserve_mod x its rank, no less than 0 (Sweet Nothings: cha mod x rank). A
# passive switched off or disabled keeps its reserve, but nothing is spent from it (spends()).
func pools() -> Dictionary[Reserve, int]:
	var out: Dictionary[Reserve, int] = reserves.duplicate()
	for x in slots:
		var r := x.skill.reserve
		if r and x.skill.passive:
			out[r] = out.get(r, 0) + maxi(mod(x.skill.reserve_mod) if x.skill.reserve_mod else 1, 0) * x.rank
	return out


func store(r: Reserve) -> int:
	return stores.get(r, 0)


# Whether it spends from r now: unless the passive that gives it is switched off (Sweet Nothings'
# toggle) or disabled.
func spends(r: Reserve) -> bool:
	for x in slots:
		if x.skill.reserve == r and x.skill.passive and (not x.on or x.skill in disabled):
			return false
	return true


# Points back into its reserves that come back a certain way (Reserve.on_kill: a foe it slew;
# Reserve.patron: its patron satisfied), up to their max.
# A Chant primed (chant_gains) adds one to each of that many gains of a patron's reserve.
func gain(how: StringName, n: int) -> void:
	for r in pools():
		if n > 0 and ((how == &"kill" and r.on_kill > 0) or (how == &"patron" and r.patron)):
			var more := r.on_kill if how == &"kill" else n
			if r.patron and chant_gains > 0:
				more += 1
				chant_gains -= 1
			set_store(r, store(r) + more)


func set_store(r: Reserve, v: int) -> void:
	v = clampi(v, 0, pools().get(r, 0))
	var was := store(r)
	if v == was:
		return
	stores[r] = v
	reserve_changed.emit(r, was, v)


# What s costs it, at its rank (starter spells: cost x rank), before any savings (cost_from()).
func price(s: Skill) -> int:
	return s.price(rank(s))


# What s costs it paid from fund: a reserve that pays whole costs takes its few points for any cost
# (Sweet Nothings: 1); otherwise price(), times the best cost_with factor of any reserve that
# payment counts as, where its passives open that reserve up to s's tier (Mana I: the starter spells
# at half cost). Rounded up.
func cost_from(s: Skill, fund: Variant) -> int:
	if fund is Reserve and fund.whole > 0:
		return fund.whole if price(s) > 0 or s.needs == fund else 0
	var factor := 1.0
	for r in s.cost_with:
		if pays_as(s, fund, r) and opened(r) >= tier(s):
			factor = minf(factor, s.cost_with[r])
	return ceili(price(s) * factor - 0.0001)


# The highest tier its passives open r's savings for (Mana II: tier 2); 0 if none do.
func opened(r: Reserve) -> int:
	var best := 0
	for x in on_passives:
		if x.skill.opens == r:
			best = maxi(best, x.rank)
	return best


# s's tier for it: from its class's tree (what it started with: 0), else from a general tree, else 1
# (species and lore skills) - at least the skill's own floor (Smite: 3).
func tier(s: Skill) -> int:
	var t := role.tier(s) if role else -1
	if t < 0:
		for g in GENERAL_TREES:
			t = g.tier_of(s)
			if t >= 0:
				break
	return maxi(t if t >= 0 else 1, s.min_tier)


# The general trees it can learn from, on the far right of its skills screen: the base General tree,
# those its class gets (Role.general), and those a skill of its opens (Martialist, Thaumaturgist).
func general_trees() -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	for g in GENERAL_TREES:
		if g.category == &"" or (role and g.category in role.general) or _opener(g.category) != null:
			out.append(g)
	return out


func general_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for g in general_trees():
		for s in g.core + g.roots.reduce(func(all: Array, r: SkillRoot): return all + r.skills(), []):
			if s and s not in out:
				out.append(s)
	return out


# Its class's tree tabs, then its general trees (the skills screen).
func trees() -> Array[SkillTab]:
	var out: Array[SkillTab] = role.trees() if role else ([] as Array[SkillTab])
	out.append_array(general_trees())
	return out


# The skill it has learned that waives a general tree's needs (Skill.waives: general for the base
# tree, else the category), or null.
func _opener(category: StringName) -> Skill:
	var key := category if category else &"general"
	for x in slots:
		if x.skill.waives == key and x.rank > 0:
			return x.skill
	return null


# What stands between it and a general-tree skill s at tier t, "" if nothing, and the waiver that
# would carry it (null if its own needs are met). On the base tree: 3 skills learned of tier t or more.
# On a category tree (any it has that offers s): a class skill of that category (Role.category()) of
# tier t or more. A waiver (Generalist, Martialist, Thaumaturgist) opens its tree up to its rank in
# tier - one less where the class doesn't have the tree, but SPECIALIST_EDGE more for a class with the
# Specialist tree.
func _general_need(s: Skill, t: int) -> Array:
	var why := ""
	for g in general_trees():
		if not g.offers(s):
			continue
		var c := g.category
		if c == &"":
			var have := slots.filter(func(x: Slot): return x.skill != s and x.rank > 0 and tier(x.skill) >= t).size()
			if have >= 3:
				return ["", null]
			why = "Needs 3 T%d+ skills (%d so far)" % [t, have]
		else:
			var best := -1
			for x in slots:
				if x.rank > 0 and role and role.tier(x.skill) >= 0 and role.category(x.skill) == c:
					best = maxi(best, role.tier(x.skill))
			if best >= t:
				return ["", null]
			why = "Needs a T%d+ %s class skill" % [t, "caster" if c == &"magical" else String(c)]
		var by := _opener(c)
		if by:
			var native := c == &"" or (role and c in role.general)
			var reach := base_rank(by) - (0 if native else 1)
			if not native and role and &"specialist" in role.general:
				reach += SPECIALIST_EDGE  # specialists branch out more easily
			if t <= reach:
				return ["", by]
	return [why, null]


# A general-tree skill learned through a waiver whose waiver isn't working now: removed, disabled, or
# cursed down to nothing. It stops working too.
func lapsed(s: Skill) -> bool:
	var by: Skill = waived.get(s)
	return by != null and (base_rank(by) == 0 or by in disabled or unranked().get(by, 0) >= base_rank(by))


# The name a skill goes by for it: Strike takes the name of a low-tier upgrade it has learned
# (Decisive Strike), or its element's while imbued (Firestrike).
func skill_name(s: Skill) -> String:
	if not s.chain:
		return s.name
	if imbued > 0 and element:
		return String(element).capitalize() + "strike"
	for x in slots:
		if x.skill.renames and x.rank > 0:
			return x.skill.renames
	return s.name


# What pays for a skill: the reserve it needs, if it needs one (and nothing else will do); else a
# reserve that makes it cheaper (Hex: mana, for AP; the starter spells: mana, for cost; a Warlock's
# dearer skills: a Sweet Nothing), then one dedicated to its tags (mana for magical skills, so Energy
# is kept for generic skills), then Energy, then any other reserve. Returns the Reserve, &"energy", or null if
# nothing can.
func funding(s: Skill) -> Variant:
	var allowed := pools().keys().filter(func(r: Reserve): return spends(r) and (r.only.is_empty() or r.only.any(func(t): return t in s.tags)))
	if s.needs and s.needs in pools():  # a unit without that reserve at all (a Cleric's Level Down) pays as usual
		return s.needs if s.needs in allowed and store(s.needs) >= cost_from(s, s.needs) else null
	for r: Reserve in allowed:
		if (s.ap_with.has(r) or cost_from(s, r) < price(s)) and store(r) >= cost_from(s, r):
			return r
	for r: Reserve in allowed:
		if not r.only.is_empty() and r.whole == 0 and store(r) >= cost_from(s, r):
			return r
	if energy >= cost_from(s, &"energy"):
		return &"energy"
	for r: Reserve in allowed:
		if store(r) >= cost_from(s, r):
			return r
	return null


# Tags its Energy counts as, from its passives (Working Knowledge: magical).
func energy_tags() -> Array[StringName]:
	var out: Array[StringName] = []
	for p in passives:
		for t in p.energy_as:
			if t not in out:
				out.append(t)
	return out


# Whether paying for s with fund counts as paying with reserve r, for r's bonuses: r itself, or Energy
# its passives let count as r for skills like s (Working Knowledge: Energy counts as Mana for Hex).
func pays_as(s: Skill, fund: Variant, r: Reserve) -> bool:
	if fund is Reserve:
		return fund == r
	if fund != &"energy":
		return false
	return energy_tags().any(func(t): return t in s.tags and t in r.only)


# AP to use s paid from fund: its AP, times the best factor of any reserve that payment counts as.
func ap_cost(s: Skill, fund: Variant) -> float:
	var factor := 1.0
	for r in s.ap_with:
		if pays_as(s, fund, r):
			factor = minf(factor, s.ap_with[r])
	return s.ap * factor


func can_afford(s: Skill) -> bool:
	return can_afford_after(s, 0.0)


# Whether it could still pay for s after walking `steps` movement first (which takes move-only AP,
# then general AP the skill might have needed).
func can_afford_after(s: Skill, steps: float) -> bool:
	var fund: Variant = funding(s)
	if fund == null:
		return false
	var general := 0.0
	var move_only := 0.0
	for p in ap:
		if p.only == &"":
			general += p.amount
		elif p.only == &"move":
			move_only += p.amount
	var left := ap_for(&"skill") - maxf(steps - move_only, 0.0)
	return general >= maxf(steps - move_only, 0.0) - 0.0001 and left >= ap_cost(s, fund) - 0.0001


# Pays a skill's AP and cost from its funding. False (and nothing spent) if it can't.
func pay_for(s: Skill) -> bool:
	var fund: Variant = funding(s)
	if fund == null or not pay(ap_cost(s, fund), &"skill"):
		return false
	if fund is Reserve:
		set_store(fund, store(fund) - cost_from(s, fund))
	else:
		energy -= cost_from(s, fund)
	return true


# Whether it could pay a channeled skill's strike now.
func can_strike(s: Skill) -> bool:
	return energy >= s.strike_cost and ap_for(&"skill") >= s.strike_ap - 0.0001


# Pays a channeled skill's strike (Metea): its strike AP, and its strike cost in Energy. False (and
# nothing spent) if it can't.
func pay_strike(s: Skill) -> bool:
	if not can_strike(s):
		return false
	pay(s.strike_ap, &"skill")
	energy -= s.strike_cost
	return true


# Start of this unit's faction turn: fresh AP and movement, and it can slip back into hiding.
func refresh() -> void:
	turns_taken += 1
	ap = _pools()
	_ap_start.assign(ap.map(func(p: AP): return p.amount))
	_walk_ap.assign(ap.map(func(_p: AP): return 0.0))
	moved = 0.0
	steps = 0
	exposed = 0


# How hard it worked this turn: &"rest" (it didn't move or spend AP), &"light" (it only spent its
# dex move or wis skill AP, leaving the general pool whole) or &"busy". Walking while standing still
# (Meander) doesn't count.
func activity() -> StringName:
	var walking := still()
	var general := 0.0
	var spent := 0.0
	for i in mini(ap.size(), _ap_start.size()):
		var used := _ap_start[i] - ap[i].amount - (_walk_ap[i] if walking and i < _walk_ap.size() else 0.0)
		spent += used
		if ap[i].only == &"":
			general += used
	if spent < 0.0001 and (is_zero_approx(moved) or walking):
		return &"rest"
	return &"light" if general < 0.0001 else &"busy"


# Whether it's still technically standing still this turn, `extra` tiles on: no tiles walked, or no
# more than its Meander rank (switched on).
func still(extra := 0) -> bool:
	return steps + extra <= meander()


# How many tiles a turn it can walk while standing still (Meander, while on).
func meander() -> int:
	return roundi(stat(&"meander"))


# How many tiles off it sees an ally's rolls, its own among them (Self-evaluation; Battle.evaluators()).
func evaluates() -> int:
	return roundi(stat(&"evaluates"))


# Whether stepping onto ground t, `extra` tiles into a walk, leaves it untouched: standing still
# (Meander) there, at a rank no lower than the ground's level.
func passes_by(t: Terrain, extra: int) -> bool:
	return still(extra) and t.level <= meander()


# Pays for walking n tiles that took `cost` movement (and as much move AP), counting them towards
# still(). Once it's walked further than standing still allows, what lasts until it moves ends (Hide).
func walked(n: int, cost: float) -> void:
	var before := ap.map(func(p: AP): return p.amount)
	moved += cost  # a Relay boost can take it below what it's walked
	pay(maxf(cost, 0.0), &"move")
	for i in mini(ap.size(), _walk_ap.size()):
		_walk_ap[i] += before[i] - ap[i].amount
	steps += n
	if not still():
		for e in timed.keys():
			if timed[e].until_move:
				timed.erase(e)


# Energy back as its side's turn ends, by activity() - but never Power (powered()). Resting: (con mod + wis mod) / 2 a turn,
# rounded down (up while lucky), at least 1; below 0, a point every (1 - that) turns rested
# instead (-2: one every 3). Light activity: half as fast. Busy: none. Returns what it got back.
func recover() -> int:
	if powered():
		return 0
	var k := rounded((mod(&"constitution") + mod(&"wisdom")) / 2.0)
	var rate := float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)
	match activity():
		&"rest":
			rest += rate
		&"light":
			rest += rate / 2.0
		_:
			return 0
	if energy >= max_energy:
		rest = 0.0
		return 0
	var whole := floori(rest + 0.0001)
	rest -= whole
	var was := energy
	energy += whole
	return energy - was


# What refresh() hands out: every pool together.
func full_ap() -> float:
	return _pools().reduce(func(sum: float, p: AP): return sum + p.amount, 0.0)


# General, then dex (moving only), then wis (skills only); negative mods cut the general pool. Heavy
# armor drags the dex and wis pools (armor_drag()); move_ap and skill_ap add to them (Aethendine,
# Ignauldron, Invigorating Bracing).
# Haste: ap adds that fraction to the general and wis pools, dex_ap to the dex pool.
func _pools() -> Array[AP]:
	var dex := mod(&"dexterity")
	var wis := mod(&"wisdom")
	var more := 1.0 + stat(&"ap")
	var opening := stat(&"opening_ap") if turns_taken <= 1 else 0.0  # a Dagger, on its first turn
	var moving := maxf(maxi(dex, 0) * (1.0 + stat(&"dex_ap")) - armor_drag(&"move") + stat(&"move_ap"), 0.0)
	var casting := maxf(maxi(wis, 0) * more - armor_drag(&"skill") + stat(&"skill_ap"), 0.0)
	var out: Array[AP] = [AP.new((BASE_AP + mini(dex, 0) + mini(wis, 0)) * (more + opening)),
			AP.new(moving, &"move"), AP.new(casting, &"skill")]
	return out


# What armor takes off its dex (pool &"move") or wis (&"skill") AP each turn: heavy armor its rank less
# its con mod (dex) or str mod (wis) - a negative mod makes it worse - medium armor half that; never
# below 0. None from armor that eases that pool (Item.eases) on a wearer with that mod at SUFFICIENT
# or more. Light armor takes nothing.
func armor_drag(pool: StringName) -> float:
	if not armor or armor.weight_class() not in [&"heavy", &"medium"]:
		return 0.0
	var m := mod(&"constitution" if pool == &"move" else &"strength")
	if armor.eases == (&"dexterity" if pool == &"move" else &"wisdom") and m >= SUFFICIENT:
		return 0.0
	return maxf((armor.rank - m) / (2.0 if armor.weight_class() == &"medium" else 1.0), 0.0)


# Wearing armor to some effect: armor that sets Defense, whose requirement it meets. Bracing passives
# work only then (check_bonus(); Effect.armored).
func armored() -> bool:
	return armor != null and armor.sets_defense() and can_wear(armor)


# What it adds to a check in stat s, as `kind` (offensive or defensive): its mod (stand-ins by `tags`)
# plus what its bracing gives (check_bonus()). The usual bonus of one side of a Check.
func check_mod(s: StringName, kind: StringName, tags: Array[StringName] = []) -> int:
	return mod(s, tags) + check_bonus(s, kind)


# What its bracing passives add to a check in stat s (offensive or defensive; mental: int, wis, cha):
# each that matches its armor's weight, stat and kind adds its armor's rank (x the passive's share),
# up to the passive's rank (Agility, Balanced, Vanguard, Combat, Meditative, Invigorating Bracing).
func check_bonus(s: StringName, kind: StringName) -> int:
	if not armored():
		return 0
	var w := armor.weight_class()
	var total := 0
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat != "brace" or not (e.tags.is_empty() or w in e.tags):
			continue
		if not (s in e.checks or (&"mental" in e.checks and s in MENTAL)) or (e.kind and e.kind != kind):
			continue
		total += mini(floori(armor.rank * e.amount), pair[1])
	return total


# Gets n AP back into its general pool, up to what that pool started the turn with (Renew).
# Returns what it got.
func regain(n: float) -> float:
	if n <= 0.0 or ap.is_empty() or _ap_start.is_empty():
		return 0.0
	var got := clampf(_ap_start[0] - ap[0].amount, 0.0, n)
	ap[0].amount += got
	return got


func ap_left() -> float:
	return ap.reduce(func(sum: float, p: AP): return sum + p.amount, 0.0)


# Movement it can still make this turn: what's left of its movement, as far as its AP allows.
func move_left() -> float:
	return minf(stat(&"movement") - moved, ap_for(&"move"))


# AP available for a use (&"move" or &"skill").
func ap_for(use: StringName) -> float:
	var sum := 0.0
	for p in ap:
		if p.only == use or p.only == &"":
			sum += p.amount
	return sum


# Pays AP for a use, draining pools reserved for it before general ones.
func pay(n: float, use: StringName) -> bool:
	if n > ap_for(use) + 0.0001:
		return false
	for p in ap.filter(func(x: AP): return x.only == use) + ap.filter(func(x: AP): return x.only == &""):
		var take := minf(p.amount, n)
		p.amount -= take
		n -= take
	return true


# Puts an effect on this unit for some of its faction's turns. Re-applying refreshes the timer
# (keeping the higher rank) rather than stacking.
func afflict(e: Effect, turns: int, at_rank := 1) -> Applied:
	var r := maxi(at_rank, timed[e].rank) if e in timed else at_rank
	timed[e] = Applied.new(turns, r)
	if e.stat == "level":
		_arrange()  # its slots follow
	if e.stat in ["level", "constitution", "hardy"]:
		refit()  # and its max HP
	return timed[e]


# Switches s off for some of its turns (Brainfog); a pillar skill takes every pillar skill with it.
# A curse's (Brainfog) slots quiver; others only dim.
func disable(s: Skill, turns: int, curse := false) -> void:
	if s.inherent:
		return  # what it is can't be switched off (Starkind)
	for x in (pillars() if s.pillar() else [s] as Array[Skill]):
		disabled[x] = maxi(disabled.get(x, 0), turns)
		if curse:
			cursed[x] = true


# Its pillar skills: those its build stands on (Powerful), easiest to disable - one goes, all go.
func pillars() -> Array[Skill]:
	var out: Array[Skill] = []
	for x in slots:
		if x.skill.pillar():
			out.append(x.skill)
	return out


# Its skills in the slots a disabling skill reaches, right to left, a slot at a time (each an
# Array[Skill]): its pillar skills first, as one - they sit in its last sure slots; Foundations (a kind
# of pillar: Generalist) sit rank / 2 slots further in, unless plain pillars go first and take them along - then the passives
# that are always on (they fill the bar from the bottom), then what's on its hotbar from the last slot
# back, then any other actives it has. Skills already disabled are skipped.
func disable_order() -> Array[Array]:
	var out: Array[Array] = []
	var seen := {}
	var group := func(list: Array[Skill]) -> void:
		var fresh: Array[Skill] = []
		for s in list:
			if s and not s.inherent and s not in seen and s not in disabled and rank(s) > 0:
				seen[s] = true
				fresh.append(s)
		if not fresh.is_empty():
			out.append(fresh)
	var foundations_only := pillars().all(func(x: Skill): return x.foundation())
	if not foundations_only:
		group.call(pillars())  # Foundations go with plain pillars
	else:
		for x in pillars():
			seen[x] = true  # placed below, not among the passives
	var rest: Array[Skill] = []
	for x in slots:
		if x.skill.passive and not x.skill.fits_bar():
			rest.append(x.skill)
	rest.reverse()
	for i in range(hotbar.size() - 1, -1, -1):
		rest.append(hotbar[i])
	for x in slots:
		if not x.skill.passive:
			rest.append(x.skill)
	for s in rest:
		group.call([s] as Array[Skill])
	var deep: Array[Skill] = []
	if foundations_only:
		deep.assign(pillars().filter(func(x: Skill): return x not in disabled and rank(x) > 0))
	if not deep.is_empty():  # rank / 2 slots in from the right: harder to reach
		out.insert(mini(deep.map(func(x: Skill): return base_rank(x)).max() / 2, out.size()), deep)
	return out


# What a slot of disable_order() adds to the check against disabling it: its skill's rank, or for
# the pillar skills (one slot), their median rank.
func slot_weight(group: Array) -> int:
	var ranks := group.map(func(s: Skill): return rank(s))
	ranks.sort()
	var n := ranks.size()
	if n == 0:
		return 0
	return ranks[n / 2] if n % 2 else roundi((ranks[n / 2 - 1] + ranks[n / 2]) / 2.0)


# End of this unit's faction turn: timed effects count down, and so do disabled skills. One that fades loses a rank instead
# of ending, a turn at a time; one lasting until it moves (with no turns set), or until something
# ends it (lasting), doesn't count down.
func tick() -> void:
	for s in disabled.keys():
		disabled[s] -= 1
		if disabled[s] <= 0:
			disabled.erase(s)
			cursed.erase(s)
	for e in timed.keys():
		var a := timed[e]
		if a.lasting or (a.until_move and a.turns == 0):
			continue
		a.turns -= 1
		if a.turns > 0:
			continue
		if a.fades and a.rank > 1:
			a.rank -= 1
			a.turns = 1
		else:
			timed.erase(e)
	_arrange()  # a level effect may have ended
	refit()  # or Asphyxia fallen a stack


func is_alive() -> bool:
	return hp > 0


func asleep() -> bool:
	return stat(&"sleep") > 0.0


func wake() -> void:
	for e in timed.keys():
		if e.stat == "sleep":
			timed.erase(e)


# [effect, rank, strength] for every passive (that's on), timed effect, effect of the ground it stands
# on, and effect of its items. A timed effect the unit's own passives already give doesn't count twice (Stonegift on a
# Stoneskin golem), nor does one `viewer` saw through.
func _effects(viewer: Unit = null) -> Array:
	var out := []
	var own := {}
	for x in on_passives:
		for e in x.skill.effects:
			out.append([e, x.rank, 1.0])
			own[e] = true
	for e in timed:
		if e not in own and not (viewer and viewer in timed[e].known_to):
			out.append([e, timed[e].rank, timed[e].strength(e)])
	if footing and not (steadied != null and steadied == cell):
		for e in footing.effects:
			out.append([e, 1, 1.0])
	for it in items():
		for e in it.effects:
			out.append([e, it.rank, 1.0])
	return out


# The reserve with the largest pool: the one shown above Energy (Wizards: mana).
func main_reserve() -> Reserve:
	var main: Reserve = null
	var all := pools()
	for r in all:
		if main == null or all[r] > all[main]:
			main = r
	return main


# Puts forward the look its skills carry (Alluring), on top of its own: a stance if it has none, and
# their vibe words, tags and name pools.
func _take_looks() -> void:
	for x in slots:
		var s := x.skill
		if not s.has_look():
			continue
		if stance == "":
			stance = s.stance
		for w in s.shows_vibe:
			if w not in shows_vibe:
				shows_vibe.append(w)
		for t in s.shows_tags:
			if t not in shows_tags:
				shows_tags.append(t)
		for w in s.shows_adjectives:
			if w not in shows_adjectives:
				shows_adjectives.append(w)
		shows_nouns.merge(s.shows_nouns)


# The name its persona goes by: an adjective and a noun from its pools, at random ("Serene
# Songstress"), or the one word if a pool is empty. Nouns bring their stand-in sprite.
func _pick_alias() -> void:
	var adjective: String = shows_adjectives.pick_random() if not shows_adjectives.is_empty() else ""
	var noun: String = shows_nouns.keys().pick_random() if not shows_nouns.is_empty() else ""
	set_alias(adjective, noun)


# Goes by this name from its pools (Personify), its noun bringing its stand-in sprite.
func set_alias(adjective: String, noun: String) -> void:
	alias = (adjective + " " + noun).strip_edges()
	alias_face = shows_nouns.get(noun, "")
	alias_noun = noun


func _show_look() -> void:
	if look:
		var frames := SpriteFrames.new()
		frames.add_frame(&"default", look)
		sprite.sprite_frames = frames
		sprite.play(&"default")


# Bars sit just above the sprite's head as one block: HP on top and, peeking out 2px under it, each
# lesser pool - the main reserve (if any), then Energy (fading back when there's a reserve). Their
# side trims the block (_show_side()).
func _layout_bars() -> void:
	var main := main_reserve()
	energy_bar.add_theme_stylebox_override("fill", _flat(POWER_COLOR if powered() else ENERGY_COLOR))
	energy_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	energy_bar.modulate.a = 0.45 if main else 1.0
	if main:
		reserve_bar.add_theme_stylebox_override("fill", _flat(main.color))
		reserve_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	hp_bar.add_theme_stylebox_override("fill", _flat(HP_COLOR))
	hp_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_border_width_all(1)
	trim.add_theme_stylebox_override("panel", box)


# Stacks the visible bars from the bottom up, with the trim one pixel out around them.
func _stack() -> void:
	var bottom := -sprite.sprite_frames.get_frame_texture(&"default", 0).get_height() / 2.0 - 2.0
	var y := bottom
	for pair in [[energy_bar, 2.0], [reserve_bar, 2.0], [hp_bar, 4.0]]:
		var bar: ProgressBar = pair[0]
		if bar.visible:
			bar.size = Vector2(BAR_WIDTH, pair[1])
			bar.position = Vector2(-BAR_WIDTH / 2.0, y - pair[1])
			y -= pair[1]
	trim.visible = y < bottom
	trim.position = Vector2(-BAR_WIDTH / 2.0 - 1.0, y - 1.0)
	trim.size = Vector2(BAR_WIDTH + 2.0, bottom - y + 2.0)


# How the player's side sees it (the HUD calls this; until then it's drawn as it is). Not located:
# not drawn at all. Located with its side unknown: a black shape with no side colours and no bars.
# Otherwise it wears the side it shows as - its own, or one a persona claims - with bars for
# whatever of HP, energy and reserves can be made out. A persona posing as someone shows that
# name's stand-in sprite instead of its own. null: as it is.
# How saturated its sprite is (1 full colour .. 0 greyscale): the HUD drains it on units it has
# commanded this turn (HUD.command_state()).
func set_saturation(v: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter(&"saturation", v)


# Its look while taking orders: `sat` saturation, and a brighter, larger glow when `prominent` (a
# unit the player can command now), brighter still in high `contrast`. Allies keep a lifted glow in
# high contrast even when not prominent.
func command_look(sat: float, prominent: bool, contrast := false) -> void:
	set_saturation(sat)
	if glow.visible:
		var mult := 1.0
		if prominent:
			mult = PROMINENCE * (2.0 if contrast else 1.0)
		elif contrast:
			mult = 1.6
		glow.modulate.a = clampf(GLOW * mult, 0.0, 1.0)
		glow.scale = Vector2.ONE * (1.3 if prominent else 1.0)


func appear(r: Read) -> void:
	shown = r
	visible = r == null or r.located()
	_show_side(faction if r == null else r.faction, r != null and r.faction == null)
	_show_face(r.face if r else "")
	_show_bars()


# Text in place of its sprite (";)"), until the nouns personas claim have sprites; "": its own.
func _show_face(text: String) -> void:
	sprite.visible = text == ""
	if text and not _face:
		_face = Label.new()
		var tex := sprite.sprite_frames.get_frame_texture(&"default", 0)
		_face.size = tex.get_size() if tex else Vector2(16, 16)
		_face.position = -_face.size / 2.0
		_face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_face.add_theme_font_size_override(&"font_size", 10)
		_face.add_theme_constant_override(&"outline_size", 3)
		_face.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.add_sibling(_face)
	if _face:
		_face.visible = text != ""
		_face.text = text


func _show_bars() -> void:
	var r := shown
	var main := main_reserve()
	hp_bar.visible = r == null or r.hp != null
	energy_bar.visible = r == null or r.energy != null
	reserve_bar.visible = main != null and energy_bar.visible
	hp_bar.max_value = r.max_hp if r and r.hp != null else max_hp
	hp_bar.value = r.hp if r and r.hp != null else hp
	energy_bar.max_value = maxi(max_energy, 1)
	energy_bar.value = r.energy if r and r.energy != null else energy
	if main:
		reserve_bar.max_value = maxi(pools()[main], 1)
		reserve_bar.value = r.stores.get(main, 0) if r else store(main)
	_stack()


func _show_faction() -> void:
	_show_side(faction, false)


# Stand-in art: a faint glow of the side's primary behind the sprite; the bars get its primary,
# darkened, as trim and its secondary behind HP. A shape is painted black over a neutral glow.
func _show_side(f: Faction, shape: bool) -> void:
	sprite.modulate = SHAPE if shape else Color.WHITE
	glow.visible = shape or f != null
	if glow.visible:
		glow.modulate = Color(SHAPE_EDGE if shape else f.primary, GLOW)
	if f:
		hp_bar.add_theme_stylebox_override("background", _flat(f.secondary))
		(trim.get_theme_stylebox("panel") as StyleBoxFlat).border_color = f.primary.darkened(TRIM_DARKEN)


func _flat(c: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	return box
