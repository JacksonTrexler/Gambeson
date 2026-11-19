class_name Unit
extends Node2D

signal hp_changed(was: int, now: int)
signal energy_changed(was: int, now: int)
signal overcharge_changed(was: int, now: int)  # its Overcharge buffer (overcharge) changed
signal reserve_changed(r: Reserve, was: int, now: int)
signal died(u: Unit)
signal taking_hit(u: Unit, blow: Dictionary)  # hit(): about to take blow.damage (from blow.by, tagged blow.tags); listeners may change it (Battle: Molothrus)
signal being_healed(u: Unit, heal: Dictionary)  # heal(): about to get heal.hp back; listeners may take a cut (Battle: Molothrus)
signal recovered(u: Unit, pool: Variant, n: int)  # n came back to pool (&"hp", &"energy" or a Reserve) by heal(), grant_energy() or note_recovery() - never regen (Battle: RecoveryEndurance)
signal downed(u: Unit)  # it took mortal damage with a heart left: it gets up again as the turn ends (Battle._on_downed())
signal falling(u: Unit, hold: Dictionary)  # _landed(): it reached 0 HP; a listener may set hold.stay to hold it up there (Battle: Final Act)
signal lost_skills(u: Unit, skills: Array[Skill])  # skills stopped being equipped (an item taken off, a slot lost, unequipped: _sync_granted(), _arrange(), bar_clear()): Battle ends a channel on one
signal paid(u: Unit, s: Skill, wear: Exhaustion.Wear)  # pay_for(): one use of s, now counted in its exhaustion (Battle holds it open until its cast is over: Behaviour.wearing())
signal disabling(u: Unit, d: Dictionary)  # disable(): d.skills are about to be switched off for d.turns by d.by (null: nobody); d.curse a curse's - listeners may change d.turns (Battle: Behaviour.disabling(): Coyote Charm, Coyote Scepter)
signal slaying(u: Unit, d: Dictionary)  # slay(): an instant death, with HP left; a listener may set d.defer to put it on borrowed time for that many rounds instead (Battle: Behaviour.slain(): an enchanted Coyote Charm)
signal dbno_changed(u: Unit, how: StringName)  # Downed (Scripts/Downed.gd), not the hearts' going down: &"down", &"saved", or what it died of (Downed.succumb())

# Stats with a base value on the unit; effects add to these and to any other named stat.
const CORE: Array[StringName] = [&"strength", &"dexterity", &"constitution", &"intelligence",
		&"wisdom", &"charisma", &"movement", &"reach", &"size"]
const BASE_AP := 10.0
const REAR_EDGE := 1  # Defense an attack from behind takes off its target: +1 to hit (defense(), side_of())
const GENERAL_TREES: Array[SkillTab] = [preload("res://Trees/general.tres"), preload("res://Trees/general_martial.tres"),
		preload("res://Trees/general_specialist.tres"), preload("res://Trees/general_caster.tres")]  # the general trees, on the far right of the skills screen (general_trees())
const POSTURES: Array[StringName] = [&"offensive", &"supportive", &"defensive"]  # how a skill can be used (Skill.serves())
const FURY_MOD := -5  # the mod of a stat of 1: a mental stat under Mindless Fury (mod())
const MENTAL: Array[StringName] = [&"intelligence", &"wisdom", &"charisma"]  # the stats of mental checks (bracing)
const SPECIALIST_EDGE := 2  # tiers sooner a class with the Specialist tree reaches the other trees through Martialist and Thaumaturgist (_general_need())
const PLATE := "plate_"  # a slot a skill gives it beyond armor's own is named for the skill: plate_power_armor (u.get(slot) and u.set(slot, item) reach it, so the sheet and the outfit treat it as any slot)
const SUFFICIENT := 2  # the con or str mod that lets armor that eases heavy armor's drag lift it (armor_drag())
const CLASS_HP := 5  # a class unit's max HP before what its levels bring (Battle.from_role(); level_hp()) - its level 1 total is 5 + con mod + vigor, a Fighter 10
const SLOTS := 4  # skill slots at level 1; one more every 4 levels (slot_count()), plus any skills grant
const ENERGY_COLOR := Color("#e8c547")
const POWER_SIPHON := 1.5  # a siphon takes this much more from a powered unit (siphon()): Power is easier to siphon
const OVERCHARGE: Effect = preload("res://Effects/overcharge.tres")
const OVERCHARGE_COLOR := Color("#6fd8e4")  # the unit card's Overcharge row: energy's own colour
const POWER_COLOR := Color("#f2a93b")  # Energy that's Power (Powerful): yellow tinted orange, pulsing white above 75% and blue when full
const HP_COLOR := Color("#3fbf4f")
const SHAPE_EDGE := Color("#8a8f9c")  # glow of a unit whose side can't be told
const SHAPE := Color(0.03, 0.03, 0.03)  # what a silhouette is painted: one that might be a monster in the brush (Read.silhouette())
const GLOW := 0.55  # how strongly a unit glows in its side's colour
const MARK_TIME := 1.0  # seconds a mark (pop_mark(): ? suspected, ! seen through) takes to pop and fade
const DESATURATE := preload("res://Scenes/UI/desaturate.gdshader")
const PROMINENCE := 1.6  # a commandable unit's glow, this much stronger; x2 in high contrast
# The four strengths a unit's glow takes when the HUD has something to say with it (set_glow();
# HUD.glow_of()): barely for one out of reach this turn, somewhat for one only a walk that can't be
# counted on reaches, mostly for one a sure walk reaches, fully for one ready now.
enum Intensity { BARELY, SOMEWHAT, MOSTLY, FULLY }
const INTENSITY: Array[float] = [0.3, 0.65, 1.25, PROMINENCE]  # each strength's glow, times GLOW: the plain glow (1) sits between somewhat and mostly
const INTENSITY_SIZE: Array[float] = [0.8, 0.9, 1.15, 1.3]  # ...and how large it spreads
const DOWN_TILT := 1.35  # radians: a Downed unit lies over on its side (_lie())
const DOWN_SAT := 0.55  # ...and keeps this share of its colour, however the HUD sets it
const CONTRAST_GLOW := 1.6  # high contrast: glows this much stronger again
const TRIM_DARKEN := 0.45  # bar trim: the side's primary, this much darker
const BAR_WIDTH := 24.0


# A channel it holds (Metea): the skill, where it was cast, and its side's turns since.
class Channel:
	var skill: Skill
	var at: Vector2i
	var turns := 0
	var rank := 0  # Clairvoyance: its rank for this channel, rising each turn end it holds
	var pings: Dictionary[Unit, Vector2i] = {}  # Clairvoyance: the foes it sensed -> where (Battle.clairvoy())
	var switch: Variant  # a switch between what it runs on (Unit.toggle()): what it switches to, a Reserve or &"energy"; null: not a switch
	var from: Variant  # ...and what it leaves
	var held := 0  # ...and its side's turn ends it has held through idle (Unit.channel_held()): what it carries over

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
@export var xp := 0  # experience toward its next level (gain_xp(): xp_to_next())
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
@export var god := &""  # whom it prays to (Pray), one of God.pantheon(); empty: its class's (Role.god)
@export var uncontrolled := false  # on the player's side, but it takes no orders and joins no party: it acts on its own (the Astral Envoy's shades)
@export var with_player := false  # joins whichever side the player's starter is on (Battle._ready(): the Astral Envoy's villagers and shades)
@export var hearts := 0  # extra lives of its own, on top of its items' (lives())
@export var loot: Loot  # what it may drop as it falls (Battle._on_died())
@export var summons: PackedScene  # comes with each heart it spends, as it gets up (the Astral Princess: a Regeneration Probe)
@export_file("*.tscn") var reverts_to := ""  # what it falls back into as it dies, on its tile (a Starman: a Starmote; Battle._on_died()) - a path: the two scenes name each other
@export_file("*.tscn") var reforms_into := ""  # what it becomes once its Reforming stacks reach its level (a Starmote: a Starman; Battle._starkind())
@export var hunts: Array[Faction] = []  # sides its AI goes after first (Starmen: the Stellar Order; AI.HUNT)
@export var bio: Bio  # how it behaves (its AI), looks, what it's made of and whom it has standing with (Scripts/Bio.gd)

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
# Skills on the hotbar by slot, null where empty (see Skill.fits_bar() and slot_kinds()): its equipped
# skills (equipped()), the only ones that work. Left empty, it fills at setup: pillars in the last sure
# slots, actives and toggles from the left, always-on passives from the right (the bottom).
@export var hotbar: Array[Skill] = []
@export var lore: Array[Skill] = []  # accrued knowledge: skills it has come to know of and can unlock
@export var skill_points := 0  # one per level gained, spent unlocking skills (unlock())
var last_hit_by: Unit  # who last struck it (hit()): whoever's blow kills it gets two shares of its XP (Battle._award())
var paid_fall := false  # it has paid out its XP for falling (Battle._award()): a unit pays once...
var paid_rise := false  # ...and once more for being brought back (Battle.rescued())
var waived: Dictionary[Skill, Skill] = {}  # general-tree skills learned through a waiver -> the skill that waived their needs (Generalist): they stop working without it (lapsed())
var element := &""  # the element its Strikes carry when imbued or with Elemental Mastery (Behaviours/imbue.gd)
var imbued := 0  # Strike uses left carrying its element (Elemental Strike)
var form := &""  # the beast it's shaped into (Beastshape: rabbit, squirrel, mole, wisp, mote, pike; Battle.FORMS), body and mind; "" itself
var form_turns := 0  # its turns left as one
var form_rank := 0  # the rank it was shaped at
static var HASTE: Effect = _haste()
var disciplined := 0  # AP burned into the attack it's making (Discipline: Battle._discipline()); 0 between them
var leaned: Array[Skill] = []  # skills learned while an item's lent skill carried a prerequisite (unlock()): they stop working once their prerequisites aren't met without it (lapsed(), counts())
var _judging := false  # lapsed() is working out whether a leaned skill's prerequisites hold: nothing it reads may touch effects (they read lapsed()): _skippable() stands down
var _bare := false  # counts() is reading prerequisites as if nothing were lent (unlock(): was a lent skill needed?)
var purchases: Array = []  # [skill, points] for each unlock and raise, in order: a level curse takes the last back first (unranked())
var picked: Array[String] = []  # the trees it has picked on its class's own tab, as "TreeChoice/Tab" (Role.choices: pick())
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
@export var trinket: Item:  # Heart Up
	set(v):
		trinket = v
		if banner:
			banner.queue_redraw()  # its trim shows as a banner

var plating: Dictionary[StringName, Item] = {}  # the armor worn in the slots its skills give beyond the first, by slot name (plate_slot(); plate_skills())

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
		v = clampi(v, Downed.floor_hp(self), max_hp + over_max)  # below 0 only while Downed
		if v == hp:
			return
		var was := hp
		hp = v
		if v <= max_hp:
			over_max = 0
		hp_changed.emit(was, v)
		_landed(was, v)


# What comes of its HP going from was to v (the hp setter; fall()): nothing while its death is put off
# (Borrowed Time); on its last life a defer stat puts its death off before Downed has its say; Downed
# lingers, is saved or dies past its limit; else a heart goes, or it dies.
func _landed(was: int, v: int) -> void:
	if deferred > 0 or staying:
		pass  # it can't die meanwhile
	elif v <= 0 and was > 0 and dbno == null and not reviving and _held_up():
		pass  # held up at 0 HP for now (Final Act); Battle has it fall() after
	elif v == 0 and was > 0 and dbno == null and not reviving and lives_left() <= 0 and defer():
		pass
	elif Downed.takes(self, was, v):  # Downed: on its last life it lingers at 0 or below, is saved, or dies past its limit
		pass
	elif v == 0 and not reviving and lives_left() > 0:  # local v, not hp: a listener may have changed hp re-entrantly
		hearts_used += 1
		reviving = true
		downed.emit(self)
	elif v == 0:
		died.emit(self)


var staying := false  # held up at 0 HP by a reaction to its fall, until it has acted (Battle.grant_interrupt(): Final Act); alive meanwhile


# Asks its listeners whether it's held up at 0 HP for now (falling): true if it is.
func _held_up() -> bool:
	var hold := {stay = false}
	falling.emit(self, hold)
	staying = hold.stay
	return staying


# --- Deferred death (the defer stat: Borrowed Time)
# On its last life, taken to 0 HP with a defer stat, it doesn't die - once a battle. For that many of its
# side's rounds (deferred) it can't: its HP stops at 0, it acts as ever. It keeps a log of what harmed it
# (harms: HP lost, debuffs put on) over the last `defer` rounds; as each of its rounds ends while its death
# is put off, the log is replayed in order through the usual paths (damage(), afflict()) - unless
# something intervenes, that takes it back to 0. The last round over, a check against an execute at
# that rank (Battle._borrowed()): failing, it falls as it would have (fall(): Downed, if it can).
signal deferring(u: Unit, how: StringName)  # &"begin", &"replay", &"survived", &"executed" (Battle._borrowed())
var deferred := 0  # rounds its death is still put off
var defer_rank := 0  # the defer it went on borrowed time at: the replay window and the execute's rank
var deferred_once := false
var defer_fresh := false  # it went on borrowed time in its own side's turn: that turn's end doesn't count (Battle sets it)
var harms: Array[Dictionary] = []  # {at: rounds, hp: n} or {at, effect, turns, rank}, oldest first, while it has a defer stat
var rounds := 0  # its side's turns ended since the battle began (Battle._borrowed())
var replaying := false  # what it suffers now is the log replayed: not logged again


# Its defer, rounded: how many rounds its death would be put off, and how far back it keeps its log.
func defers() -> int:
	return roundi(stat(&"defer"))


# Puts its death off, if it can (the hp setter, at 0 HP on its last life): true if it did. `n`: for that
# many rounds rather than its defer stat's (slay(): a behaviour lending it borrowed time).
func defer(n := -1) -> bool:
	if n < 0:
		n = defers()
	if deferred_once or n < 1:
		return false
	deferred_once = true
	defer_rank = n
	deferred = defer_rank
	deferring.emit(self, &"begin")
	return true


# Logs a harm while it has a defer stat (damage(), afflict()), unless it's the log replayed.
func _log_harm(h: Dictionary) -> void:
	if replaying or (deferred <= 0 and defers() < 1):
		return
	h.at = rounds
	harms.append(h)


# Its side's round is over (Battle._borrowed()): what's older than its window drops out of its log.
func age_harms() -> void:
	rounds += 1
	var keep := maxi(defer_rank if deferred > 0 else defers(), 1)
	harms.assign(harms.filter(func(h: Dictionary): return h.at > rounds - keep))


# The log replayed in order, through the usual paths, none of it logged again.
func replay_harms() -> void:
	replaying = true
	for h in harms.duplicate():
		if h.has(&"hp"):
			damage(h.hp)
		else:
			afflict(h.effect, h.turns, h.rank)
	replaying = false


# Instant death (Death, Luun's Smite): it dies with HP left - the one place that happens. Its listeners
# may put it on borrowed time instead (slaying, d.defer: an enchanted Coyote Charm), else its HP goes to 0
# and it falls as it would (a heart, Downed, Borrowed Time's defer stat). With no HP left it's no instant
# death: it just falls.
func slay() -> void:
	if hp > 0:
		var d := {defer = 0}
		slaying.emit(self, d)
		defer(int(d.defer))
	hp = 0


# Its borrowed time is up and the execute took it: it falls as its death would have had it - a Downed
# skill puts it down, else it dies.
func fall() -> void:
	deferred = 0
	slain_from = hp
	if hp > 0:
		hp = 0
	else:
		_landed(1, 0)

# The default energy every unit has; reserves (mana...) are extra.
var energy := 0:
	set(v):
		v = clampi(v, 0, max_energy)
		if v == energy:
			return
		var was := energy
		energy = v
		energy_changed.emit(was, v)

# Overcharge: an extra buffer spent before its own Energy or reserve on a cost (pay_for()), while the
# Overcharge status lasts (add_overcharge(); it decays in tick()). Spent to 0, the status ends.
var overcharge := 0:
	set(v):
		v = maxi(v, 0)
		if v == overcharge:
			return
		var was := overcharge
		overcharge = v
		if v == 0:
			timed.erase(OVERCHARGE)
		overcharge_changed.emit(was, v)

var stores: Dictionary[Reserve, int] = {}  # current amount of each reserve
var ap: Array[AP] = []  # refilled at the start of each of this unit's faction turns
var moved := 0.0  # movement spent this turn
var steps := 0  # tiles walked this turn (still())
var ground: Array[StringName] = []  # tags of the tile it stands on (Battle keeps this current)
var footing: Terrain  # the tile it stands on, whose effects it has while there (Battle keeps this current)
var blind_on: Variant = null  # a cell it walked onto this turn without seeing under its leaves (Battle.obscured()): checks there come at disadvantage
var steadied: Variant = null  # the cell where it caught itself as glass gave way: spared that ground's effects until it moves off or a turn passes (Battle._teeter())
var steady_turn := -1  # turns_taken when it did
var respec_room := 0  # how far each stat may shift now, a Meditation just done (Battle.respec())
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
var assumed := {}  # units that vanished before its eyes -> the side they seemed to be of: it goes on taking them for that (Battle._vanish(), Perception)
var rested_turns := 0  # its side's turns in a row it has rested through: it looks further and better (Battle.survey())
var unwatched := 0  # its turns since it last looked around (Battle._watch(): wis mod 0 or less looks only every few)
var facing := Vector2.ZERO:  # the way it faces (a direction; zero: none yet): set by its steps, by what it aims at (face()), by Shields Up!; side_of() reads it
	set(v):
		facing = v
		if heading_tick:
			heading_tick.queue_redraw()
var guard := false  # its shield is up (Shields Up!: Battle._guard(); hit()): it blocks what comes from its front
var striding := false  # moving was the last thing it did this turn (Eyes Forward looks the way it faces)
var mark: Label  # the mark that last popped over it (pop_mark()), while it fades
var _face: Label  # draws a persona's stand-in sprite in place of its own (_show_face())
var _role_slots: Array[Slot] = []  # this unit's copies of its role's innate skills
var _ap_start: Array[float] = []  # each AP pool as its turn started, to tell how hard it worked (activity())
var _walk_ap: Array[float] = []  # of each AP pool, what walking took this turn (activity(): standing still doesn't count)
var _keys: Array = []  # the slot keys the hotbar was last arranged for (_slot_keys(), _arrange())
var _bonus: Array = [0, {}]  # bonus_slots() as last worked out, with the hotbar's hash it was for; _arrange() drops it
var _bonus_busy := false  # bonus_slots() is being worked out: equipped() (asked by the modifiers it reads) doesn't ask it again
var _seen: Dictionary[Skill, bool] = {}  # skills it has had since it was set up: one not among them is new, and auto-equips (_sync_new())
var _seen_sig := -1  # _skill_sig() when _seen was last brought up to date (_sync_new(): cheap to check)
static var auto_equip := true  # Settings: new skills, and skills for new slots, go on the bar by themselves (HUD sets it from Prefs)
var hearts_used := 0  # hearts spent getting back up this battle
var reviving := false  # down at 0 HP with a heart spent: it gets up as the turn ends (Battle._on_downed())
var dbno: Downed.State  # Downed, down but not out (a Downed skill on its last life: Tenacity, Grudge): its rounds left and what it has done since; null while it isn't
var endurance := 0  # Recovery Endurance (RE): recoveries it takes before it bites (Scripts/RecoveryEndurance.gd); may run below 0
var burnt := {}  # pool (&"hp", &"energy" or a Reserve) -> max it has lost to Recovery Endurance's rule, for good (refit(), pools())
var fury_acts := 0  # skill uses this turn while helpless, under a permit (Mindless Fury: its rank a turn; stopped())
var overdriven := false  # ordered past its leader's command caps this turn, under a permit (Drone; Command.order())
var healed_by: Unit  # who last healed it since it went Downed (Battle sets it): whoever saves it gets two shares of its XP (Battle.rescued())
var channel: Channel:  # a channeled skill it's holding (Metea; Battle.cast_at()), or a switch of what it runs on (toggle())
	set(v):
		var was := channel
		channel = v
		if was and was.switch != null and was != v:
			_switched(was)  # however the channel ends (stopped, broken, interrupted, replaced), the switch completes
var paid_for: Skill  # the skill it last paid for (pay_for()), and what with: a Reserve or &"energy" (paid_as())
var paid_with: Variant
var paid_ap := 0.0  # and the AP it took (refund())
var paid_cut := 0.0  # and the share a behaviour took off its price first (Battle.rebate())
var emptied := false  # that payment spent the last of the reserve it came from (focus_bonus())
var reserve_rest: Dictionary[Reserve, float] = {}  # a with_energy reserve's recovery towards its next whole point (recover())
var exhaustion := Exhaustion.new()  # its uses of each skill lately, and what they add to its costs (price(), ap_cost())
var pulse_wait := 0  # its side's turns since it last pulsed (Regeneration Pulse; Battle._pulse())
var _hp_bonus := 0  # what its level, items and passives add to its max HP now (refit())
var respec: Dictionary[StringName, int] = {}  # how far each base stat has been shifted from what it was born with (respec_by())
var over_max := 0  # HP it may hold past its max for now (a Red Spinel Ring past rank 10), gone once it drops to its max
var slain_from := 0  # the HP it had as Death took it: what revival and die-hard effects go by (Battle._death())
var disabled: Dictionary[Skill, int] = {}  # skills switched off (Brainfog) -> its turns left: they can't be used, and passives stop working
var cursed: Dictionary[Skill, bool] = {}  # of those, the ones a curse switched off (Brainfog): their slots quiver
var postponed: Dictionary[Skill, Array] = {}  # disablings held while it postpones them (the postpone stat: Coyote Charm) -> [turns, curse]: they land as it stops (release())
var chant_gains := 0  # Sweet Nothing gains a Chant will add one to (Battle._chant())
var chant_up := false  # a Chant primed: its next Warlock skill is used a rank higher (rank())
var unspent := 0.0  # AP it had left as its side's last turn ended (Battle.end_turn(): Spike)
var tally: Dictionary[StringName, int] = {}  # counts behaviours keep over its turn, across walks (Peel's assisted steps: Battle.travel()); cleared by refresh()
var turns_taken := 0  # its side's turns it has started this battle (refresh(): a Dagger's opening AP)
var rolls_made := 0  # attack rolls it has made in its skill use under way (Battle.roll_attack(), zeroed as a use opens: opening_rolls, Glancing Strike)
var friction := 0  # steps of friction on its next attack roll (Battle.loops(), friction tag): above 0, at disadvantage and - this (Battle.attack_check()); set by Battle per use
var allowed: Dictionary = {}  # Skill -> highest rank: while not empty, its only actives, each at no more than that rank (an interrupt that allows only some: Chaser; Battle.grant_interrupt())

# Every skill entry, its own (_own()) and what its items lend (granted()): a skill listed twice keeps its
# highest rank, its own first on a tie.
var slots: Array[Slot]:
	get:
		var best := {}
		for s in _own() + granted():
			if s and s.skill and (s.skill not in best or s.rank > best[s.skill].rank):
				best[s.skill] = s
		var out: Array[Slot] = []
		out.assign(best.values())
		return out

var _held: Array[Skill] = []  # the skills its items lent at the last refit() (_sync_granted())
var _granted: Dictionary[Skill, Slot] = {}  # the slots its items lend, kept while they're worn (granted()): a toggle's state lasts as long

# Its own skill entries, the role's first: what it has learned, one per skill at its highest rank. What its
# items lend (granted()) is not among them: it can't be raised, and doesn't count toward learning anything.
func _own() -> Array[Slot]:
	var best := {}
	for s in _role_slots + innate + learned:
		if s and s.skill and (s.skill not in best or s.rank > best[s.skill].rank):
			best[s.skill] = s
	var out: Array[Slot] = []
	out.assign(best.values())
	return out


# The slots its worn items lend (Item.skills), at the item's rank (Item.skill_rank()): flagged with the item
# (Slot.from). A skill two items lend comes from the higher; one an item stops lending, or that comes off
# with it, drops out (its toggle state with it).
func granted() -> Array[Slot]:
	var out: Array[Slot] = []
	var live := {}
	for it in items():
		for s in it.skills:
			if not s:
				continue
			var r := it.skill_rank(s)
			if s in live and live[s].rank >= r:
				continue
			var x: Slot = _granted.get(s)
			if not x:
				x = Slot.new()
				x.skill = s
				_granted[s] = x
			x.rank = r
			x.from = it
			live[s] = x
	for s in _granted.keys():
		if s not in live:
			_granted.erase(s)
	out.assign(live.values())
	return out


var actives: Array[Skill]:
	get:
		var s: Array[Skill] = []
		var lost := unranked()
		s.assign(slots.filter(func(x: Slot): return not x.skill.passive and (allowed.is_empty() or allowed.has(x.skill)) and equipped(x.skill) and x.skill not in disabled and lost.get(x.skill, 0) < x.rank and not lapsed(x.skill) and rank(x.skill) > 0).map(func(x: Slot): return x.skill))
		return s

# Passive entries that work: equipped (equipped()), on, and not disabled. Every reader of what a passive
# does goes through here, or through equipped() itself.
var on_passives: Array[Slot]:
	get:
		var s: Array[Slot] = []
		var lost := unranked()
		s.assign(slots.filter(func(x: Slot): return x.skill.passive and x.on and equipped(x.skill) and x.skill not in disabled and lost.get(x.skill, 0) < x.rank and not lapsed(x.skill)))
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
var second_bar: ProgressBar  # a second reserve's bar, made when it holds two (_layout_bars())
var more_bars: Array[ProgressBar] = []  # a third reserve's, and any further: 1px slivers (the map's bars, as few pixels as they need)
var heading_tick: Node2D  # a faint tick at the edge of its tile toward the way it faces (facing); on the sprite, so a silhouette hides it
var banner: Node2D  # its trinket's trim (Item.trim()) as a little banner over its shoulder; on the sprite, so a silhouette hides it


func _init() -> void:
	exhaustion.ease = func() -> float: return 1.0 + maxf(stat(&"stamina"), 0.0)  # Stamina: its counts / (rank + 1)
	exhaustion.penalty = func(s: Skill) -> float: return Burnout.penalty(self, s)  # Burnout: int skills wear harder


func _ready() -> void:
	# Skill entries hold per-unit state (rank, toggles), but scenes and roles share them: copy.
	_role_slots.assign((role.innate if role else []).map(func(s: Slot): return s.duplicate()))
	innate.assign(innate.map(func(s: Slot): return s.duplicate()))
	learned.assign(learned.map(func(s: Slot): return s.duplicate()))
	if role and not race:
		race = role.race
	if role and not look:
		look = role.look
	if bio:
		for p in bio.properties:
			for x in p.tags:
				if x not in tags:
					tags.append(x)  # an Aquatic unit counts as water to skills that ask
	_fill_bar()  # first: its looks come from what it has equipped
	_take_looks()
	_pick_alias()
	_show_look()
	banner = Node2D.new()
	banner.name = &"Banner"
	banner.position = Vector2(6, -13)
	banner.draw.connect(_draw_banner)
	sprite.add_child(banner)
	heading_tick = Node2D.new()
	heading_tick.name = &"Facing"
	heading_tick.draw.connect(_draw_tick)
	sprite.add_child(heading_tick)
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = DESATURATE
	set_saturation(1.0)
	_layout_bars()
	_show_faction()
	refit()
	hp_changed.connect(_show_bars.unbind(2))
	dbno_changed.connect(_lie.unbind(2))
	energy_changed.connect(_show_bars.unbind(2))
	reserve_changed.connect(_show_bars.unbind(3))
	hp = max_hp
	endurance = endurance_max()
	_one_replacer()
	energy = 0 if runs_on() is Reserve else max_energy  # running on Mana or Stamina: no Energy of its own
	for r in pools():
		set_store(r, 0 if r.empty else pools()[r])  # Focus starts empty
	_show_bars()
	set_process(powered())


# A unit runs on one thing at a time: of the passives standing in for Energy it has on (replacer()), the
# first on its bar stays on, the rest go off.
func _one_replacer() -> void:
	var found := false
	for x in slots:
		if replacer(x.skill) and x.on:
			x.on = not found
			found = true


# Power (powered()) pulses its bar: white above 75%, blue when full.
func _process(_delta: float) -> void:
	var full := float(energy) / maxi(max_energy, 1)
	var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	var to := Color(0.7, 0.9, 1.8) if full >= 1.0 else Color(1.7, 1.7, 1.7)
	energy_bar.self_modulate = Color.WHITE.lerp(to, beat) if full > 0.75 else Color.WHITE


# Its rank in s as it uses it: what it has learned, plus what rank effects add or take (a Broadsword:
# Strike; Record Striker's curse), a primed Chant (a Warlock skill, once) and +1 if the skill is enchanted
# or honed (Tags.quality_rank(): a capstone's weight); 0 if it doesn't have s, or it's cursed down to nothing.
func rank(s: Skill) -> int:
	var r: int = base_rank(s) - unranked().get(s, 0)
	if r <= 0:
		return 0
	r = maxi(r + roundi(skill_stat(&"rank", s)) + int(chant_up and &"warlock" in s.tags) + Tags.quality_rank(s.tags), 0)
	return mini(r, allowed[s]) if allowed.has(s) else r


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


# Its rank in s as it has it: what it learned (own_rank()), or what an item lends (granted()), the higher.
func base_rank(s: Skill) -> int:
	var best := own_rank(s)
	for x in granted():
		if x.skill == s:
			best = maxi(best, x.rank)
	return best


# Its rank in s as learned: what skill points raise (raise_cost()). Items lend ranks that can't be raised.
func own_rank(s: Skill) -> int:
	for x in _own():
		if x.skill == s:
			if x.rank > 0 and s.rank_cost == 0:
				var a := affinity(s)
				if a != 0:  # its points, read on its Affinity's curve: it may rank up or down at once
					return maxi(Unit.rank_for(points_in(s), a, s.max_rank), 1)
			return x.rank
	return 0


# Its Affinity for s: affinity effects tagged with the postures s serves (Skill.serves: Berserker's
# Offender +1 offensive, Unsupportive and Indefensible -1), added up - a skill pulled both ways nets out.
func affinity(s: Skill) -> int:
	var ps: Array[StringName] = []
	for p in POSTURES:
		if s.serves(p, self):
			ps.append(p)
	return (roundi(stat(&"affinity", ps)) if not ps.is_empty() else 0) + guest_affinity(s)


# The Affinity its class and a picked tree bring a skill: +1 for its class's knack (a Ranger's
# Discipline), and what the tree's choice says (a Wizard's guest trees: -1; Mage schools by Mastery:
# 0) - a penalty lifted by enough magic learned (invest: a Ranger's Nature) or, sparing kin, for an
# elemental skill or a tree kin to one it picked (a Druid's guests), and +1 by its talent up to the
# tier it reads (Natural Talent); then its efficiency stacks on the tree (efficiency()).
func guest_affinity(s: Skill) -> int:
	if not role:
		return 0
	var out := 1 if s in role.knack else 0
	for t in role.tabs_of(s):
		for c in role.choices_of(t):
			if not picks(c).any(func(x: SkillTab): return x.name == t.name and x.kind == t.kind):
				continue
			var a := c.affinity
			if a < 0 and ((c.invest > 0 and magic_learned() >= c.invest) or (c.spares_kin and _kin(s, t))):
				a = 0
			if c.talent and role.tier(s) <= roundi(stat(c.talent)):
				a += 1
			return out + efficiency(s, t, a)
	return out


# An efficiency stack is +1 Affinity on a tree's skills - cheaper rank-ups - up to a tier: one for
# each flex slot burned into tree t (burned(): a Warlock's patron, every tier), and whatever its equipped
# passives' behaviours say, given the choice's own `a` (Behaviour.affinity(): Efficiency, a stack up to
# its rank's tier - Bargaining, Acceptance, a Ranger's capstones; Illusionist).
func efficiency(s: Skill, t: SkillTab, a := 0) -> int:
	a += burned(t)
	for x in slots:
		if x.rank > 0 and x.skill.passive and equipped(x.skill):
			for h in x.skill.behaviours:
				a = h.affinity(self, x.rank, s, t, a)
	return a


# The biomes it has picked (a Druid's: astral, sylvan, montane, xeric, nival, thalassic), by name.
func biomes() -> Array[StringName]:
	var out: Array[StringName] = []
	for c in role.choices if role else []:
		for t in picks(c):
			if t.kind == "Biome":
				out.append(StringName(t.name.to_lower()))
	return out


# Takes form f at rank r for `turns` of its turns (Behaviours/beastshape.gd): a rabbit's haste is +rank
# movement; a mote's element goes into its Strikes, rank uses.
func shape(f: StringName, el: StringName, r: int, turns: int) -> void:
	form = f
	form_rank = r
	form_turns = turns
	if &"haste" in Battle.FORMS[f][2]:
		afflict(HASTE, turns, r)
	if el:
		element = el
		imbued = r


# Back to itself.
func unshape() -> void:
	timed.erase(HASTE)
	form = &""
	form_turns = 0
	form_rank = 0


# Whether it can use s as it is now: shaped, only Strike, beast skills (tagged beast) and Beastshape (to turn back).
func shaped_allows(s: Skill) -> bool:
	return not form or s.chain or &"beast" in s.tags or s.behaviour(&"beastshape") != null


static func _haste() -> Effect:
	var e := Effect.new()
	e.stat = "movement"
	e.per_rank = true
	e.name = "Haste"
	return e


# How many magical skills it has learned (TreeChoice.invest).
func magic_learned() -> int:
	return slots.filter(func(x: Slot): return x.rank > 0 and &"magical" in x.skill.tags).size()


# Whether s on tree t is kin to it (TreeChoice.spares_kin): s carries an element, or a tree it has
# picked names t its kin (a Druid's Thalassic: Currents).
func _kin(s: Skill, t: SkillTab) -> bool:
	if s.tags.any(func(x: StringName): return x in TreeChoice.ELEMENTS):
		return true
	for c in role.choices:
		if c and picks(c).any(func(p: SkillTab): return t.name in p.kin):
			return true
	return false


# Skill points put into s: what was spent on it, or what its rank is worth on the even curve.
func points_in(s: Skill) -> int:
	for x in _own():
		if x.skill == s:
			return x.points if x.points >= 0 else Unit.worth(x.rank, 0)
	return 0


# Skill points rank n is worth on an Affinity's curve, all told. Even (0): 1 to unlock, then 1 + r^2 a
# rank (1, 3, 8, 18: about n^2); +1: n log2 n, no less than n (1, 2, 5, 8, 12); +2 and up: n; -1 and
# down: n^(2 - affinity) (-1: 1, 8, 27).
static func worth(n: int, a: int) -> int:
	if n <= 0:
		return 0
	if a == 0:
		var t := 1
		for r in range(1, n):
			t += 1 + r * r
		return t
	if a >= 2:
		return n
	if a == 1:
		return nlogn(n)
	return roundi(pow(n, 2 - a))


# n log2 n, rounded up, no less than n (1, 2, 5, 8, 12): the +1 Affinity curve, and the XP each level
# takes (xp_to_next()).
static func nlogn(n: int) -> int:
	return maxi(n, ceili(n * log(n) / log(2.0))) if n > 0 else 0


# The rank `points` buy on an Affinity's curve, up to `cap` (0: no cap).
static func rank_for(points: int, a: int, cap := 0) -> int:
	var n := 0
	while worth(n + 1, a) <= points and (cap == 0 or n < cap):
		n += 1
	return n


# An attribute of s for it (range, rank): what its effects add, asked with s's tags (Skill.query()),
# and only effects that list s when they list skills.
func skill_stat(attr: StringName, s: Skill) -> float:
	return stat(attr, s.query() + (mods(s).tags if emblems() else ([] as Array[StringName])), null, s)


# Whether it wears anything putting modifiers on its skills (Item.emblem): the fast way past mods().
func emblems() -> bool:
	return items().any(func(it: Item): return it.emblem != &"")


# The modifiers on its use of s (Modifiers.of(): its emblems'): s as it uses it is s plus these.
# Everything that reads a per-rank or per-stat value of s for it goes through them.
func mods(s: Skill) -> Modifiers:
	return Modifiers.of(self, s) if s and emblems() else Modifiers.NONE


# s's tags as it uses s: its own, plus the tags its modifiers add (a Fire Insignia: fire).
func skill_tags(s: Skill) -> Array[StringName]:
	var m := mods(s)
	if m.tags.is_empty():
		return s.tags
	var out: Array[StringName] = s.tags.duplicate()
	for t in m.tags:
		if t not in out:
			out.append(t)
	return out


func is_on(s: Skill) -> bool:
	for x in slots:
		if x.skill == s:
			return x.on
	return false


# Switches a passive that has a toggle on or off. False if the unit has no such skill.
# One that stands in for Energy (Mana, Stamina: replacer()) doesn't switch at once: it begins a channel
# (Channel.switch) from what it runs on now to what it would run on after, completing as the channel
# ends (_switched()); toggled again while switching, it completes now. False while it holds another
# channel.
func toggle(s: Skill) -> bool:
	for x in slots:
		if x.skill == s and s.passive and s.toggle:
			if replacer(s) == null:
				x.on = not x.on
				return true
			if channel and channel.switch != null and channel.skill == s:
				channel = null
				return true
			if channel:
				return false
			var ch := Channel.new(s, cell)
			ch.from = runs_on()
			ch.switch = &"energy" if x.on else replacer(s)
			channel = ch
			return true
	return false


# The reserve a toggle passive stands in for Energy with (Reserve.replaces): the one it gives (Stamina)
# or opens (Mana); null for any other skill.
static func replacer(s: Skill) -> Reserve:
	if not (s.passive and s.toggle):
		return null
	for r: Reserve in [s.reserve, s.opens]:
		if r and r.replaces:
			return r
	return null


# What it runs on: the reserve of its replacer() passive that's on (and not disabled) - Mana, Stamina -
# or &"energy". Running on a reserve, its own Energy is emptied and doesn't come back (recover()): what
# Energy it holds came some other way, and pays as Energy does.
func runs_on() -> Variant:
	for x in on_passives:
		var r := replacer(x.skill)
		if r:
			return r
	return &"energy"


# Whether it's switching what it runs on (toggle()): the channel's target, or null.
func switching() -> Variant:
	return channel.switch if channel else null


# How much a switch held `held` turns carries over: 10% of the max of what it leaves, x the rank of
# the passive switched, x the turns held, rounded down - no more than it has of it.
func carry(from: Variant, s: Skill, held: int) -> int:
	var most: int = max_energy if from is StringName else pools().get(from, 0)
	var have: int = energy if from is StringName else store(from)
	return mini(floori(most * 0.1 * maxi(mods(s).irank(rank(s), &"rank_impact"), 1) * held + 0.0001), have)


# A switch's channel ends: what it leaves goes, all but carry() of it, which comes into what it
# switches to (up to its max); the passive switches, any other replacer it had on going off.
func _switched(ch: Channel) -> void:
	var kept := carry(ch.from, ch.skill, ch.held)
	if ch.from is Reserve:
		set_store(ch.from, 0)
	else:
		energy = 0
	for x in slots:
		var r := replacer(x.skill)
		if r:
			x.on = ch.switch is Reserve and r == ch.switch
	if ch.switch is Reserve:
		set_store(ch.switch, store(ch.switch) + kept)
	else:
		energy += kept
	if is_node_ready():
		_show_bars()


# Its side's turn ends with its channel held (Battle.end_turn()): a switch held through an idle turn
# counts one more turn of carry-over, and completes once it would carry all it has.
func channel_held(was_idle: bool) -> void:
	if not channel or channel.switch == null or not was_idle:
		return
	channel.held += 1
	var have: int = energy if channel.from is StringName else store(channel.from)
	if carry(channel.from, channel.skill, channel.held) >= have:
		channel = null


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
	out.assign(_grants().map(func(g: Array): return g[0]))
	return out


# granted_slots(), each with where it comes from: [type, source], the source the granting skill, or
# &"item" for its items' (an enchantment swaps an item for a copy: theirs pool by type). A skill
# unequipped takes its own slots with it, and the skills in them (_arrange()).
func _grants() -> Array:
	var out := []
	var modded := emblems()
	var sources: Array = on_passives.map(func(x: Slot): return [x.skill.effects, mods(x.skill).irank(x.rank, &"rank_impact") if modded else x.rank, x.skill]) + items().map(func(it: Item): return [it.effects, it.ranked(), &"item"])
	for t in sources:
		for e: Effect in t[0]:
			if e.stat == "slots":
				for i in roundi(e.amount * (t[1] if e.per_rank else 1)):
					out.append([e.tags[0] if not e.tags.is_empty() else &"", t[2]])
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
					n += roundi(e.amount * (it.ranked() if e.per_rank else 1))
			for i in range(end - n, end):
				out[i] = [maxi(rounded(0.1 * it.ranked() * max_hp), 1), null]
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
	for k in _slot_keys():
		out.append(k if k is StringName else k[0])
	return out


# Each hotbar slot's key, what _arrange() sorts skills by: &"" a sure slot, &"clover", or a granted
# slot's [type, source] (_grants()), so a granting skill's slots are told from another's.
func _slot_keys() -> Array:
	var out := []
	for i in slot_count():
		out.append(&"")
	out.append_array(_grants())
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


# Its bonus slots (Cram's caster bonus slots), by hotbar index -> [type, rank]: sure slots a skill on its bar
# converts (an Effect "bonus_slots", tagged with the type; amount per rank): the sure slots to its left, past
# pillar skills and slots already converted, right to left. Rank as its modifiers read it (rank_impact: a Density emblem doubles them). A
# bonus slot holds anything (fits()), but its skill works only while it carries the type and no pillar skill
# on the bar is disabled (bonus_off()); wear on a skill there is x rank (slot_penalty(): Burnout.penalty()).
# Read from the hotbar itself, not on_passives: equipped() reads this.
func bonus_slots() -> Dictionary:
	if _bonus_busy or hotbar.is_empty():
		return {}
	var h := hotbar.hash()
	if _bonus[0] == h:
		return _bonus[1]
	_bonus_busy = true
	var out := {}
	var bar := hotbar.duplicate()
	for i in range(bar.size() - 1, -1, -1):
		var s: Skill = bar[i]
		var at := mini(i, slot_count()) - 1
		for e: Effect in s.effects if s else []:
			if e.stat != "bonus_slots" or base_rank(s) <= 0:
				continue
			var r := mods(s).irank(base_rank(s), &"rank_impact")
			for n in roundi(e.amount * (r if e.per_rank else 1)):
				while at >= 0 and ((bar[at] and bar[at].pillar()) or out.has(at)):
					at -= 1
				if at < 0:
					break
				out[at] = [e.tags[0] if not e.tags.is_empty() else &"", r]
				at -= 1
	_bonus_busy = false
	_bonus = [h, out]
	return out


# Why the skill in bonus slot i doesn't work now, or "" if it does (or i is no bonus slot): a pillar skill on
# the bar is disabled (any: Cram's, or another's), or the skill lacks the slot's type.
func bonus_why(i: int) -> String:
	var b: Variant = bonus_slots().get(i)
	if b == null or i >= hotbar.size():
		return ""
	if hotbar.any(func(x: Skill): return x and x.pillar() and x in disabled):
		return "a pillar skill is disabled"
	if hotbar[i] and b[0] != &"" and not hotbar[i].tagged(b[0]):
		return "not a %s skill" % Skill.CATEGORIES.get(b[0], String(b[0])).to_lower()
	return ""


func bonus_off(i: int) -> bool:
	return bonus_why(i) != ""


# What wear on s is multiplied by for the slot it sits in: a bonus slot's rank (Cram's caster bonus slots),
# else 1. Burnout.penalty() reads it.
func slot_penalty(s: Skill) -> float:
	var b: Variant = bonus_slots().get(hotbar.find(s)) if s else null
	return float(b[1]) if b != null else 1.0


# Whether s goes in slot i when slotted by itself (auto-equip, a unit setting up): it fits, and a bonus slot
# only takes a skill it would work in there.
func _suits(s: Skill, i: int) -> bool:
	if s == null:
		return true
	var b: Variant = bonus_slots().get(i)
	return fits(s, i) and (b == null or b[0] == &"" or s.tagged(b[0]))


# Whether s can go in hotbar slot i: a typed slot only holds skills carrying its type, and the clover
# slot, filled on its unit's own turn and only working while it's lucky, holds no always-on passive.
func fits(s: Skill, i: int) -> bool:
	var k := slot_kind(i)
	if k == &"clover":
		return s.fits_bar() and (not s.passive or s.toggle)
	return k == &"" or k in s.tags


# --- Equipping
# A unit's learned skills (slots) and what it has equipped: its hotbar. Only equipped skills work, actives
# and passives alike: every reader asks equipped() (on_passives and actives do). Traits (Starkind)
# take no slot and are always equipped (unless suppressed). A skill it gets that it hasn't had before goes on the bar by
# itself (auto-equip, the Settings toggle: Unit.auto_equip) - actives and toggles from the left,
# always-on passives from the right (the bottom), pillars in the last sure slots.

# Whether s is equipped, so working: a trait (Skill.is_trait(): always, unless traits_suppressed()), or on its
# hotbar in a slot a level curse hasn't sealed.
# Asking brings in any skill it has newly got first (_sync_new()).
func equipped(s: Skill) -> bool:
	if s == null:
		return false
	if s.is_trait():
		return not traits_suppressed()
	_sync_new()
	var i := hotbar.find(s)
	return i >= 0 and not _sealed_now(i) and not bonus_off(i)


# The traits it has (learned, lent or innate), in the order it holds them: what the HUD shows apart from the
# hotbar, at its far end. They take no hotbar slot, so nothing that walks the hotbar reaches them.
func traits() -> Array[Skill]:
	var out: Array[Skill] = []
	for x in slots:
		if x.rank > 0 and x.skill.is_trait() and not x.skill.is_equipment():  # equipment (Armor) isn't listed: it is what an item does
			out.append(x.skill)
	return out


# Whether its traits are suppressed now: a no_traits status is on it (Effects/traits_suppressed.tres). Read from
# its timed statuses alone, as shackled() is: equipped() asks it, so it can't ask the passives.
func traits_suppressed() -> bool:
	return timed.keys().any(func(e: Effect): return e.stat == "no_traits")


# sealed(), read without its passives (they depend on this): a sure slot past what its level, less what
# a level curse takes, gives.
func _sealed_now(i: int) -> bool:
	return i < _slots_at(level) and i >= _slots_at(maxi(level - _cursed_levels(), 1))


# Its equipped skills, slot by slot (null where empty), brought up to date (_sync_new()): what a save keeps
# and the HUD's bar shows. set_equipped() puts them back.
func get_equipped() -> Array[Skill]:
	_sync_new()
	return hotbar.duplicate()


# Equips these skills, slot by slot, as far as it can (bar_place(): what it knows, where it fits);
# anything else comes off the bar.
func set_equipped(bar: Array) -> void:
	var was := hotbar.duplicate()
	for i in hotbar.size():
		if hotbar[i] and not hotbar[i].pillar():
			hotbar[i] = null
	for i in mini(bar.size(), hotbar.size()):
		if bar[i] is Skill and bar[i] not in hotbar:
			bar_place(bar[i], i)
	_settle(was)


# Notes skills it has got since it last looked (learned, lent, its role's), cheaply: only when what its
# skill entries hold changed (_skill_sig()). New ones auto-equip (auto_equip); ones it no longer has come
# off the bar. A unit still being set up waits for _fill_bar().
func _sync_new() -> void:
	if hotbar.is_empty():
		return
	var sig := _skill_sig()
	if sig == _seen_sig:
		return
	_seen_sig = sig
	var have := {}
	var fresh: Array[Skill] = []
	for x in slots:
		have[x.skill] = true
		if x.skill not in _seen:
			_seen[x.skill] = true
			fresh.append(x.skill)
	var gone: Array[Skill] = []
	for sk in _seen.keys():
		if sk not in have:
			_seen.erase(sk)
			gone.append(sk)
	var was := hotbar.duplicate()
	for sk in gone:
		var i := hotbar.find(sk)
		if i >= 0:
			hotbar[i] = null
	if auto_equip:
		for sk in fresh:
			equip_skill(sk)
	if not gone.is_empty():
		_settle(was)


# What its skill entries hold, as one number: changes as a skill is learned, lent or dropped.
func _skill_sig() -> int:
	var h := 17
	for list: Array[Slot] in [_role_slots, innate, learned]:
		for x in list:
			h = (h * 31 + (x.skill.get_instance_id() if x and x.skill else 0)) & 0x7fffffffffff
	for sk in _granted:
		h = (h * 31 + sk.get_instance_id()) & 0x7fffffffffff
	return h


# Puts s on the bar where it goes by itself (_auto_slot()), if it isn't there. False if it has nowhere.
func equip_skill(s: Skill) -> bool:
	if s == null or s.is_trait() or s in hotbar or not s.fits_bar() or base_rank(s) == 0:
		return s != null and (s.is_trait() or s in hotbar)
	var i := _auto_slot(s)
	if i < 0:
		return false
	hotbar[i] = s
	_arrange()  # it may grant slots
	return true


# Where s goes by itself: a pillar in the last free sure slot; an always-on passive in the last free sure
# slot (the bottom of the bar), else the last granted slot it fits - never the clover slot (fits()), and
# a granted slot only past the sure ones, so one granting skill rarely sits in another's slot; anything
# else the first free slot it fits. -1: full.
func _auto_slot(s: Skill) -> int:
	if s.passive and not s.toggle or s.pillar():
		var sure := mini(slot_count(), hotbar.size())
		var order := range(sure - 1, -1, -1)
		if not s.pillar():
			order += range(hotbar.size() - 1, sure - 1, -1)
		for i in order:
			if not hotbar[i] and slot_works(i) and _suits(s, i):
				return i
		return -1
	return free_slot(s)


# Fills its free slots, as auto_equip does when slots appear: its learned skills that aren't equipped,
# actives and toggles first, in the order it has them.
func auto_fill() -> void:
	var picks := slots.filter(func(x: Slot): return x.skill.fits_bar() and not x.skill.passive)
	picks.append_array(slots.filter(func(x: Slot): return x.skill.fits_bar() and x.skill.passive))
	for x in picks:
		if x.skill not in hotbar and base_rank(x.skill) > 0:
			var i := _auto_slot(x.skill)
			if i >= 0:
				hotbar[i] = x.skill


# x rounded down, or up while the unit is lucky (level / 2 for a Gambeson, level / 4 for slots).
func rounded(x: float) -> int:
	return Luck.settle(x, luck, true, false)


# Puts one of the unit's skills in hotbar slot i (one that works and that it fits). A skill already on
# the bar swaps places with whatever is in i - which comes off the bar if it doesn't fit there. Pillar
# skills keep the last sure slots: they can't be moved, and nothing takes their place.
# Pillar skills keep the last sure slots: they can't be moved, and nothing takes their place - one off the
# bar goes only into an empty sure slot. Whatever drops off the bar by it, or with the slots it took
# (a slot-granting skill moved out), is announced (lost_skills).
func bar_place(s: Skill, i: int) -> bool:
	if i < 0 or i >= hotbar.size() or not slot_works(i) or not s or not s.fits_bar() or base_rank(s) == 0 or not fits(s, i):
		return false
	if (hotbar[i] and hotbar[i].pillar()) or (s.pillar() and (s in hotbar or hotbar[i] or i >= slot_count())):
		return false
	var was := hotbar.duplicate()
	var old := hotbar.find(s)
	if old >= 0:
		hotbar[old] = hotbar[i] if hotbar[i] and fits(hotbar[i], old) else null
	hotbar[i] = s
	_settle(was)
	return true


# Unequips the skill in slot i (not a pillar). One that granted slots takes them with it, and their skills.
func bar_clear(i: int) -> void:
	if i >= 0 and i < hotbar.size() and not (hotbar[i] and hotbar[i].pillar()):
		var was := hotbar.duplicate()
		hotbar[i] = null
		_settle(was)


# After a change to the bar: its slots follow what's equipped (_arrange(), till nothing more drops), and
# the skills no longer on it are announced.
func _settle(was: Array) -> void:
	_arrange()
	var lost: Array[Skill] = []
	for sk in was:
		if sk and sk not in hotbar and sk not in lost:
			lost.append(sk)
	if not lost.is_empty():
		lost_skills.emit(self, lost)


func level_up() -> void:
	level += 1
	skill_points += 1
	var was := max_hp
	refit()
	if is_alive():
		hp += maxi(max_hp - was, 0)  # what the level brings, it gets at once
	_arrange()


# --- Experience
# Levels are bought with XP, each one's cost growing n log n: from level n to the next takes
# XP_PER_LEVEL x n log2 n (at least x n: 20, 40, 100, 160, 240... ), up to MAX_LEVEL. A unit is worth
# the mean of its six core stats and its level (xp_worth()), shared by those near it as it falls, or
# as it's brought back (Battle._award(), Battle.rescued()).

const XP_PER_LEVEL := 20
const MAX_LEVEL := 20


# XP it takes to go from level n to the next.
static func xp_to_next(n: int) -> int:
	return XP_PER_LEVEL * nlogn(maxi(n, 1))


# Its base stat total: its six core stats as they stand without effects (what Meditate shifts counts).
func bst() -> int:
	var t := 0
	for s in CORE.slice(0, 6):
		t += roundi(get(s))
	return t


# What felling it (or bringing it back) is worth: its BST and its level, over the seven of them -
# level counts as one more stat - rounded, at least 1 (a level 1 villager 65 / 7: 9; a level 4 Siren
# 82 / 7: 12).
func xp_worth() -> int:
	return maxi(roundi((bst() + level) / 7.0), 1)


# Takes n XP, levelling up as often as it covers the next level's cost. The levels gained. At
# MAX_LEVEL it takes no more.
func gain_xp(n: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	xp += maxi(n, 0)
	var gained := 0
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level_up()
		gained += 1
	if level >= MAX_LEVEL:
		xp = 0
	return gained


# The first empty hotbar slot that works (and that s fits, given one), or -1.
func free_slot(s: Skill = null) -> int:
	for i in hotbar.size():
		if not hotbar[i] and slot_works(i) and _suits(s, i):
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
		if sk and sk.serves(posture, self) and can_afford(sk):
			return sk
	return null


func missing(s: Skill) -> String:
	if s.stub:
		return s.waits()
	if not s.classes.is_empty() and not (role and StringName(role.name.to_lower()) in s.classes):
		return "%s only" % " and ".join(s.classes.map(func(c): return String(c).capitalize()))
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
	var learnt := learned.filter(func(x: Slot): return x.skill != s and x.rank > 0).size() + _lent_count(s)
	if s.min_tier > 1 and learnt < s.min_tier - 1:
		return "Learn %d skill%s first (%d so far)" % [s.min_tier - 1, "" if s.min_tier == 2 else "s", learnt]
	var homes := role.tabs_of(s) if role else ([] as Array[SkillTab])
	if not homes.is_empty() and not homes.any(func(t: SkillTab): return open_tab(t)):
		return "Pick %s first" % homes[0].title()
	var root := role.root_of(s) if role else null
	if not root:
		return ""
	var why := ""
	for r in _homes(s, root):  # on several trees (a Druid's borrowed skills), the way on any one will do
		var w := _root_missing(r, s)
		if w == "":
			return ""
		if why == "":
			why = w
	return why


# The roots of its class s is on that are open to it (its own, and picked trees'), else just `fallback`.
func _homes(s: Skill, fallback: SkillRoot) -> Array[SkillRoot]:
	var out: Array[SkillRoot] = []
	for r in role.roots:
		if r and r.branch(s):
			out.append(r)
	for t in role.all_tabs():
		if t and open_tab(t):
			for r in t.roots:
				if r and r.branch(s) and r not in out:
					out.append(r)
	if out.is_empty():
		out.append(fallback)
	return out


# What stands between it and s on root r: the skills its branch comes after, reached on r, and the
# count of r's skills a capstone needs.
func _root_missing(r: SkillRoot, s: Skill) -> String:
	var b := r.branch(s)
	var first := b.after.filter(func(x: Skill): return not reached(r, x) and not _skippable(x))
	if not first.is_empty():
		return "Learn %s first" % " and ".join(first.map(func(x: Skill): return x.name))
	if b.needs > 0:
		var have := r.skills().filter(func(x: Skill): return x != s and counts(x)).size()
		if have < b.needs:
			return "Needs %d %s skills (%d so far)" % [b.needs, r.name, have]
	return ""


# Whether it has reached x on root r: learned it, and - for a skill on more than one tree, learned
# on another - what comes before it on r too. A shared skill is one skill, learned and ranked once;
# having it doesn't skip the way to it on another tree.
func reached(r: SkillRoot, x: Skill) -> bool:
	if not counts(x):
		return false
	if not role or role.all_roots().filter(func(o: SkillRoot): return o.branch(x)).size() < 2:
		return true
	return r.branch(x).after.all(func(y: Skill): return reached(r, y) or _skippable(y))


# A step on its trees it may pass over (Reckless Abandon: defensive and supportive skills that don't
# also attack).
func _skippable(x: Skill) -> bool:
	return not _judging and stat(&"abandon") > 0 and (x.serves(&"supportive", self) or x.serves(&"defensive", self)) and not x.serves(&"offensive", self)


# The devoting tabs it has picked (a Warlock's patron, a Cleric's god; a Wizard may have a pact and a
# god), or learned a skill on beyond the shared row: whom it serves (deity(); Hogel's rest).
func devotions() -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	if role:
		for c in role.choices:
			if c and not c.slot():  # a god slot's trees come from whom it serves: they don't decide it
				for t in picks(c):
					if t.devotes and t not in out:
						out.append(t)
		for t in role.tabs:
			if t and t.devotes and _learned_on(t):
				out.append(t)
	return out


# The first of devotions(), or null.
func devotion() -> SkillTab:
	var all := devotions()
	return all[0] if not all.is_empty() else null


# Whether it has learned a skill on t's roots beyond the shared row (its slots' own ranks: base_rank()
# reads Affinity, which reads this).
func _learned_on(t: SkillTab) -> bool:
	var held := _own().filter(func(x: Slot): return x.rank > 0 and role.tab_of(x.skill) == t).map(func(x: Slot): return x.skill)
	return t.roots.any(func(r: SkillRoot): return r and r.skills().any(func(x: Skill): return x in held))


# The trees of choice c it has picked (Unit.pick()), and those a god slot opens without a pick (grants,
# or no more on offer than it may pick: "if there's choice at all"); with none, those it has learned a
# skill on (units authored with their skills, no picks).
func picks(c: TreeChoice) -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	var offer := offered(c)
	for t in offer:
		if t and c.key(t) in picked:
			out.append(t)
	if c.slot() and not offer.is_empty() and (c.grants or (not c.by and offer.size() <= c.picks)):
		for t in offer:
			if t not in out:
				out.append(t)
	if out.is_empty():
		for t in offer:
			if t and _learned_on(t):
				out.append(t)
	return out


# The trees of choice c open to it to pick: a god slot's, what its god offers of the slot's kinds
# (God.pool); a burning choice's, the tree it took up in a choice of god as well (to burn a slot into).
func offered(c: TreeChoice) -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	if not c.slot():
		out.assign(c.all().filter(func(t: SkillTab): return t != null and suits(t)))
		return out
	var g := God.of(deity())
	if g:
		for t in c.all():
			if t and g.has(t, c.kinds):
				out.append(t)
	return out


# Whether tab t of its class is open to it: a tab beside its own, or a tree of a choice it has picked.
func open_tab(t: SkillTab) -> bool:
	var cs := role.choices_of(t)
	return cs.is_empty() or cs.any(func(c: TreeChoice): return picks(c).any(func(x: SkillTab): return x.name == t.name and x.kind == t.kind))


# How many trees of c it may pick: the choice's count, or the rank of the skill that opens it.
func pick_cap(c: TreeChoice) -> int:
	return base_rank(c.by) if c.by else c.picks


# The tree it took up in another choice of god of c's kinds, if c burns (a Warlock's patron, for its
# Flex), else null.
func burnable(c: TreeChoice) -> SkillTab:
	if not c.burns or not role:
		return null
	for o in role.choices:
		if o and o != c and o.gods:
			for t in picks(o):
				if c.kinds.is_empty() or t.kind in c.kinds:
					return t
	return null


# Flex slots burned into tree t (TreeChoice.burns): each an efficiency stack on it (efficiency()).
func burned(t: SkillTab) -> int:
	var n := 0
	if role and t:
		for c in role.choices:
			var b := burnable(c) if c and c.burns else null
			if b and b.name == t.name and b.kind == t.kind:
				n += picked.count(c.key(b))
	return n


# What stands between it and picking tree t of choice c: "" if nothing. Picking is free.
func pick_missing(c: TreeChoice, t: SkillTab) -> String:
	if c.after and rank(c.after) == 0:
		return "Learn %s first" % c.after.name
	var mine := picks(c)
	var b := burnable(c)
	var burning := b != null and b.name == t.name and b.kind == t.kind
	var used := picked.filter(func(k: String): return k.begins_with(c.name + "/")).size()
	if not burning and (mine.any(func(x: SkillTab): return x.name == t.name) or (c.slot() and open_tab(t))):
		return "Picked"
	if c.by and rank(c.by) == 0:
		return "Learn %s first" % c.by.name
	if not offered(c).any(func(x: SkillTab): return x.name == t.name and x.kind == t.kind) and not burning:
		return "Not %s's way" % deity().capitalize() if deity() else "Needs a god"
	var cap := pick_cap(c)
	if maxi(used, mine.size()) >= cap:
		return "Took up %s" % mine[0].title() if cap == 1 and not mine.is_empty() else "Picked %d of %d" % [maxi(used, mine.size()), cap]
	return ""


# Picks tree t of choice c, opening its tab (or burning a slot into it: burned()). False if it can't
# (pick_missing()).
func pick(c: TreeChoice, t: SkillTab) -> bool:
	if pick_missing(c, t) != "":
		return false
	picked.append(c.key(t))
	refit()
	for r in t.reserves:  # a reserve it brings comes full (a Druid's Astral: mana)
		set_store(r, 0 if r.empty else pools()[r])
	return true


# Spends a skill point on one of options(), learning it at rank I: onto the hotbar's first free slot
# that fits it, if it goes there; slots it grants join the bar. False if it can't.
func unlock(s: Skill) -> bool:
	if skill_points <= 0 or not options().values().any(func(list: Array): return s in list):
		return false
	var gtier := tier(s)
	var via: Skill = _general_need(s, gtier)[1] if general_skills().has(s) and (not role or role.tier(s) < 0) else null
	if via:
		waived[s] = via
	_bare = true
	var needed := missing(s) != ""  # with nothing lent, still short of a prerequisite: a lent skill is what let it through
	_bare = false
	if needed:
		leaned.append(s)
	var x := Slot.new()
	x.skill = s
	learned.append(x)
	skill_points -= 1
	purchases.append([s, 1])
	_sync_new()  # onto the bar where it goes (auto_equip)
	_arrange()
	refit()  # a passive may change what's derived (Hardy)
	return true


# Skill points to raise s from its rank r to r + 1: 1 + r^2 (II costs 2, III 5, IV 10). Unlocking
# (r = 0) is the same rule: 1. A skill with its own rank_cost charges that for II, times its
# rank_growth each rank after (Clever Disguise: 4, 8, 16).
func raise_cost(s: Skill) -> int:
	var r := own_rank(s)
	if s.rank_cost > 0 and r > 0:
		return roundi(s.rank_cost * pow(s.rank_growth, r - 1))
	var a := affinity(s) if r > 0 else 0
	if a != 0:  # the points to its next rank on its Affinity's curve
		return Unit.worth(r + 1, a) - points_in(s)
	return 1 + r * r


# Whether s can go up a rank at all: it has it, and it's below the skill's cap.
func can_raise(s: Skill) -> bool:
	var r := own_rank(s)
	return r > 0 and not s.stub and (s.max_rank == 0 or r < s.max_rank)


# Spends raise_cost() to take s up a rank. False (nothing spent) if it can't, or lacks the points.
func raise(s: Skill) -> bool:
	if not can_raise(s) or skill_points < raise_cost(s):
		return false
	var cost := raise_cost(s)
	var into := points_in(s) + cost
	var curved := affinity(s) != 0 and s.rank_cost == 0
	purchases.append([s, cost])
	skill_points -= cost
	for x in _own():
		if x.skill == s:
			x.points = into
			x.rank = maxi(Unit.rank_for(into, 0, s.max_rank), 1) if curved else x.rank + 1  # its even-curve rank, for when the Affinity's gone
	_arrange()  # a slot-granting skill may grant more per rank
	refit()  # and a passive more of what's derived (Hardy)
	return true


# Sets the hotbar up as the unit is: one left empty (as scenes leave it) is filled - pillar skills in the
# last sure slots, then actives and toggles from the left, then always-on passives from the right, as
# far as its slots go (actives first: NPCs and monsters carry extra_slots for the rest). Not a setting:
# a unit comes ready, auto-equip or not.
func _fill_bar() -> void:
	var fresh := hotbar.is_empty()
	hotbar.resize(bar_size())
	_keys = _slot_keys()
	for x in slots:
		_seen[x.skill] = true
	_seen_sig = _skill_sig()
	if not fresh:
		return
	var pinned := slot_count() - 1
	for x in slots:
		if x.skill.pillar() and x.skill.fits_bar() and pinned >= 0:  # pillar skills take the last sure slots
			hotbar[pinned] = x.skill
			pinned -= 1
	for pass_ in 2:  # the slots its passives grant join as they go on
		for x in slots.filter(func(y: Slot): return not y.skill.pillar() and (not y.skill.passive or y.skill.toggle)):
			if x.skill not in hotbar:
				var i := free_slot(x.skill)
				if i >= 0:
					hotbar[i] = x.skill
		for x in slots.filter(func(y: Slot): return not y.skill.pillar() and y.skill.passive and not y.skill.toggle and y.skill.fits_bar()):
			if x.skill not in hotbar:
				var i := _auto_slot(x.skill)
				if i >= 0:
					hotbar[i] = x.skill
					_arrange()


# Re-sorts the hotbar after its slots change (a level, a slot-granting skill equipped or not): each skill
# keeps a slot of the kind it was in - sure slots in order, a granted one by its type and the skill (or
# items) granting it, and the clover slot's skill in the clover slot, or in a sure one when the clover
# slot turns plain. A skill left with no slot comes off the bar - a granting skill's slots go with it,
# skills and all, and so on till nothing more drops. Slots that appear auto-fill (auto_equip).
func _arrange() -> void:
	_bonus = [0, {}]  # ranks or items may have changed what bonus_slots() reads
	if hotbar.is_empty():
		return  # not set up yet: _fill_bar()
	var grew := false
	for guard in 8:
		var now := _slot_keys()
		if now == _keys and hotbar.size() == now.size():
			break
		grew = grew or now.size() > _keys.size()
		var queues := {}
		for i in hotbar.size():
			queues.get_or_add(_key_name(_keys[i] if i < _keys.size() else &""), []).append(hotbar[i])
		var sure: Array = queues.get_or_add("", [])
		var more: int = now.count(&"") - sure.size() - (queues.get("clover", []).size() if &"clover" not in now else 0)
		if more > 0:  # new sure slots go in above the passives and pillars at the bottom, which stay there
			var at := sure.size()
			while at > 0 and (sure[at - 1] == null or (sure[at - 1].passive and not sure[at - 1].toggle) or sure[at - 1].pillar()):
				at -= 1
			for n in more:
				sure.insert(at, null)
		var out: Array[Skill] = []
		for k in now:
			var from: Array = queues.get(_key_name(k), [])
			if from.is_empty() and k is StringName and k == &"" and &"clover" not in now:
				from = queues.get("clover", [])
			out.append(from.pop_front() if not from.is_empty() else null)
		hotbar = out
		_keys = now
	if grew and auto_equip:
		auto_fill()
		_arrange()


static func _key_name(k: Variant) -> String:
	if k is StringName:
		return String(k)
	return "%s@%s" % [k[0], k[1].get_instance_id() if k[1] is Object else k[1]]


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
	var t: Array[StringName] = []
	var expanded := false  # the query's tags, expanded when the first effect that asks for tags turns up
	var sum: float = 0.0
	if s == &"size" and race:
		sum = race.size
	elif s in CORE:
		sum = get(s)
	var factor := 1.0
	for pair in _stat_fx(s, viewer) if reading > 0 else _effects(viewer):
		var e: Effect = pair[0]
		if e.stat != s:
			continue
		if not e.tags.is_empty():
			if not expanded:
				t = Tags.expand(tags)
				expanded = true
			if not e.tags.any(func(x): return x in t):
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


# The first tree it has picked of its class's choice named so (Prowess, School), or null.
func taken(choice: String) -> SkillTab:
	for c in role.choices if role else []:
		if c.name == choice:
			var mine := picks(c)
			return mine[0] if not mine.is_empty() else null
	return null


# Whether a tab of its class suits its god: no god slot holds it (TreeChoice.kinds), or its god offers
# it (God.pool: a Paladin's Prowess).
func suits(t: SkillTab) -> bool:
	var cs := role.choices_of(t) if role else ([] as Array[TreeChoice])
	if not cs.any(func(c: TreeChoice): return c.slot()) or cs.any(func(c: TreeChoice): return not c.slot()):
		return true
	var g := God.of(deity())
	return g != null and g.has(t)


# Its class's tabs (Role.trees()), less the trees of its choices it hasn't picked.
func class_trees() -> Array[SkillTab]:
	var out: Array[SkillTab] = []
	if not role:
		return out
	for t in role.trees():
		if not t.kind or open_tab(t):
			out.append(t)
	return out


# The god it prays to: its own, else the one its devotion names (a Cleric's tab), else its class's.
func deity() -> StringName:
	if god:
		return god
	for d in devotions():
		if d.god:
			return d.god
	return role.god if role else &""


# Stacks of suspicion it has of t, a unit or a tile (Battle.suspect()).
func suspects(t: Variant) -> int:
	return suspicion.get(t, 0)


# How far what it shows is from the truth: what insightful units read of it (Perception.insight()),
# and a penalty to its own deceiving checks - a less believable lie. Each thing its persona puts
# forward at its rank costs by how far it is from what the unit is (Perception.lie(): nothing if
# true, half if near, 1 if the table can't say, 1.5 if far - a wolf in sheep's clothing): each vibe
# word (I); its stance (1) and a level it claims (II: within 1 of its own near, 4+ off far); each
# identity tag and the name it goes by (III: the worse of its two words). Plus 1 each for fronting
# its stats (Embellish, Brood) and extra_dissonance; the sum rounded up.
func dissonance() -> int:
	var p := roundi(stat(&"persona"))
	var n := float(int(stat(&"embellish") > 0) + int(stat(&"brood") > 0))
	var truths := true_words()
	if p >= 1:
		for w in shows_vibe:
			n += Perception.lie(w, truths)
	if p >= 2:
		n += float(stance in Battle.stances(p) and stance != "")
		if shows_level > 0:
			var off := absi(shows_level - level)
			n += Perception.LIE_TRUE if off == 0 else (Perception.LIE_NEAR if off <= 1 else (Perception.LIE_FAR if off >= 4 else Perception.LIE_DEFAULT))
	if p >= 3:
		for t in shows_tags:
			n += Perception.lie(t, truths)
		if alias != "":
			n += Array(alias.split(" ", false)).map(func(w: String): return Perception.lie(w, truths)).max()
	return extra_dissonance + ceili(n)


# What it truly is, as words a persona's claims are measured against (Perception.lie()), lowercase:
# its vibe, its bio's adjectives, what it looks like (Perception.kind_noun()), its tags and race,
# and its aura (ominous below 0, benevolent above).
func true_words() -> PackedStringArray:
	var out := PackedStringArray()
	for w in vibe.split(",", false):
		out.append(w.strip_edges().to_lower())
	if bio:
		for w in bio.adjectives:
			out.append(w.to_lower())
	out.append(Perception.kind_noun(self).to_lower())
	for t in tags:
		out.append(String(t).to_lower())
	if race:
		out.append(race.name.to_lower())
	if aura != 0:
		out.append(Perception.OMINOUS_WORD if aura < 0 else Perception.BENEVOLENT_WORD)
	return out


# Dissonance as it counts against its own rolls: cut by the rank of a skill carrying the look it puts
# forward (Alluring: a practised lie), but no lower than 0.
func dissonance_penalty() -> int:
	var practised := 0
	for x in slots:
		if x.skill.has_look() and equipped(x.skill):
			practised = maxi(practised, mods(x.skill).irank(x.rank, &"rank_impact"))
	return maxi(dissonance() - practised, 0)


# Conspire's rank while it's switched on, else 0: allies near it let its persona fool them.
func conspiring() -> int:
	return roundi(stat(&"conspire"))


# How its AI behaves (Bio.BEHAVIOURS): its bio's behaviour; a craven unit's timid.
func temper() -> StringName:
	if bio and bio.behaviour:
		return bio.behaviour
	return &"timid" if behaviour == &"craven" else &""


# Its standing with side f (Bio.clout): to f's units its persona goes this much further, or its
# trickery, and doubting it is this much harder (Battle.doubt()).
func clout(f: Faction) -> int:
	return bio.clout.get(f, 0) if bio and f else 0


# Has Conspire, switched off: its allies see straight through its persona.
func candid() -> bool:
	return slots.any(func(x: Slot): return x.skill.passive and not x.on and equipped(x.skill) and x.skill.effects.any(func(e: Effect): return e.stat == "conspire"))


# Reads others well enough that only trickery fools it: a positive wis mod, or a bonus to reading
# others (insight).
func insightful() -> bool:
	return mod(&"wisdom") > 0 or stat(&"insight") > 0


# d20-style modifier: 10-11 -> 0, 12-13 -> +1, 8-9 -> -1. With a skill's tags, stand-in
# passives may swap the stat (see scaling()).
func mod(s: StringName, tags: Array[StringName] = []) -> int:
	var m := floori((scaling(s, tags) - 10) / 2.0)
	if s in MENTAL and reduced():
		if helpless():
			return FURY_MOD  # Mindless Fury: its mental stats count as 1
		return mini(m, roundi(stat(&"drone")))  # Drone: capped at + its rank
	return m


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
	if d > 0:
		_log_harm({hp = d})
	hp -= maxi(d, 0)


# A tagged attack. Mitigation applies, then net luck (mine minus the attacker's) rounds what's
# left: up (against me) unless I'm luckier. Returns the damage taken.
func hit(raw: float, tags: Array[StringName], by: Unit = null) -> int:
	var charmed := roundi(stat(&"flamecharmed"))
	if by and by != self and charmed > 4 and &"fire" in tags and Faction.friends(by.faction, faction):
		heal(roundi(raw * 0.25 * (charmed - 4)))  # Flamecharmed: an ally's fire feeds it
	var net := luck - (by.luck if by else 0)
	var cut := mitigation(tags)
	if by and by != self and guarding(by.cell):
		cut = minf(cut + stat(&"guard"), 1.0)  # Shields Up!
	if by and by.faction == faction:
		cut = minf(cut + stat(&"ally_mitigate"), 1.0)  # friendly fire (Conspire)
	var taken := Luck.settle(raw * (1.0 - cut), net, false)
	if by and by != self:
		last_hit_by = by
	var blow := {damage = taken, by = by, tags = tags}
	taking_hit.emit(self, blow)  # its battle lets its passives have their say (Molothrus passes some on)
	taken = blow.damage
	damage(taken)
	return taken


# Its switched-on passives' behaviours, each with the passive's rank: [Behaviour, rank] (Behaviour's hooks).
func hooks() -> Array:
	var out := []
	for x in on_passives:
		for h in x.skill.behaviours:
			out.append([h, x.rank])
	return out


# The one place facing is recorded (docs/plans/w2-facing.md): it faces along v, the vector of its last move
# (start to finish, forced ones too) or of its last aim (from its tile to the target's), whichever came
# latest. A zero vector changes nothing.
func turn(v: Vector2i) -> void:
	if v != Vector2i.ZERO:
		facing = Vector2(v).normalized()


# Turns to face tile c (its own changes nothing).
func face(c: Vector2i) -> void:
	turn(c - cell)


# Which side of it tile c is on, by the cone test: &"front" (within 45 degrees of the way it faces),
# &"rear" (within 45 of the opposite) or &"flank" (the 90 degrees to either side). Front when it faces
# no way yet, or c is its own tile. Battle.hit_tags() tags an attack from the rear or flank with it.
func side_of(c: Vector2i) -> StringName:
	if facing == Vector2.ZERO or c == cell:
		return &"front"
	var a := absf(angle_difference(facing.angle(), Vector2(c - cell).angle()))
	if a <= PI / 4.0 + 0.0001:
		return &"front"
	return &"rear" if a >= 3.0 * PI / 4.0 - 0.0001 else &"flank"


# Shields Up! is on it and c's centre lies in its front cone - not while Jammed.
func guarding(c: Vector2i) -> bool:
	return guard and reacts() and stat(&"guard") > 0.0 and c != cell and side_of(c) == &"front"


# Fraction of a hit with these tags that's blocked (additive, capped at 100%).
func mitigation(tags: Array[StringName]) -> float:
	return minf(stat(&"mitigate", tags), 1.0)


# What an attack with these tags must roll to hit it: what its armor sets, plus defense effects -
# untagged ones always, tagged ones against attacks carrying that tag or a child of it (physical
# Defense counts against a pierce).
func defense(tags: Array[StringName] = []) -> int:
	return armor_defense() + roundi(stat(&"defense", tags)) + armor_mind(tags) + (hearts_used if trinket and trinket.spent_defense else 0) - (REAR_EDGE if &"rear" in tags else 0)


# Defence its armor's mind_stat adds against magical attacks alone (Robe: wis mod). Untagged queries
# (Defense shown at rest) count it too, so the sheet reflects it; a physical blow doesn't.
func armor_mind(tags: Array[StringName] = []) -> int:
	if not armor or not armor.mind_stat or armor_skills().is_empty():
		return 0
	return mod(armor.mind_stat) if tags.is_empty() or &"magical" in Tags.expand(tags) else 0


# The Defense it has on top against attacks carrying a particular tag: tag -> how much more (Hydera:
# magical +1). Tags it has none extra for are left out.
func tagged_defense() -> Dictionary:
	var out := {}
	if armor and armor.mind_stat and mod(armor.mind_stat) != 0 and not armor_skills().is_empty():
		out[&"magical"] = mod(armor.mind_stat)
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat == "defense":
			for t in e.tags:
				var extra := defense([t]) - defense()
				if extra:
					out[t] = extra
	return out


# Defense from armor alone: what the equipment skills its armor lends set (armor_skills(): Armor, by the armor's own
# fields - Behaviours/armor.gd), added up; with none working (no armor, or its skills suppressed) it is unarmored: dex mod + con mod.
func armor_defense() -> int:
	var sum := _set_by(armor)
	var set := sum != Behaviour.NO_ARMOR
	if not set:
		sum = 0
	for pair in plated_defense():  # the armor in its other slots adds its own, by each slot's rules
		sum += pair[1]
		set = true
	return sum if set else mod(&"dexterity") + mod(&"constitution")


# What the equipment skills item lends set its wearer's Defense to, added up (NO_ARMOR: none do).
func _set_by(item: Item) -> int:
	var sum := 0
	var set := false
	for s in armor_skills(item):
		for b in s.behaviours:
			var n: int = b.armor(self, item.skill_rank(s), item) if b else Behaviour.NO_ARMOR
			if n != Behaviour.NO_ARMOR:
				sum += n
				set = true
	return sum if set else Behaviour.NO_ARMOR


# The equipment skills (Skill.is_equipment()) its worn armor (or `item`) lends that work now: equipped() says (traits suppressed:
# none).
func armor_skills(item: Item = armor) -> Array[Skill]:
	var out: Array[Skill] = []
	if item:
		for s in item.skills:
			if s and s.is_equipment() and equipped(s):
				out.append(s)
	return out


# Damage its weapon adds to attacks scaling on s: an enchanted weapon's +1 a rank, on strength attacks.
func weapon_bonus(s: StringName) -> int:
	return weapon.enchant if weapon and s == &"strength" else 0


# Pray, to Urlo: enchants up to n of its unenchanted, unhoned items, weapon first, then armor, then trinket: what
# an item becomes enchanted (Item.enchanted_as), else a copy of its own at +1 (Defense, damage; a trinket's, and
# any item's skills, a rank). Items with nothing to scale (Item.scales(): Heart Up) are skipped, and cost none of
# n. How many it enchanted.
func enchant(n: int) -> int:
	var done := 0
	for slot in [&"weapon", &"armor", &"trinket"]:
		var item: Item = get(slot)
		if done < n and item and not item.enchanted() and not item.honed() and item.scales():  # honed: already as good as it gets
			if item.enchanted_as:
				set(slot, item.enchanted_as)
			else:
				item = item.duplicate()
				item.enchant = 1
				set(slot, item)
			done += 1
	if done > 0:
		refit()  # a trinket's rank, a skill's
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
	return mod(attack_stat(s), s.tags)


# The stat s's attack roll reads: its own, or a weapon's (wielded()), or the best of those and any an
# attack_stat effect offers (checks: the stats; skills / tags: which attacks; Striking Features: cha,
# Striking Intellect: int, on Strikes) - whichever mod is highest.
func attack_stat(s: Skill) -> StringName:
	var best := wielded(s.stat(), s.tags)
	var t: Array[StringName] = []
	for pair in _stat_fx(&"attack_stat", null) if reading > 0 else _effects(null):
		var e: Effect = pair[0]
		if e.stat != "attack_stat" or pair[2] <= 0.0 or pair[1] < e.min_rank or (not e.skills.is_empty() and s not in e.skills):
			continue
		if not e.tags.is_empty():
			if t.is_empty():
				t = Tags.expand(s.tags)
			if not e.tags.any(func(x): return x in t):
				continue
		for x in e.checks:
			if mod(x, s.tags) > mod(best, s.tags):
				best = x
	return best


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


# Puts it on in its slot - or in `to`, one of the armor slots its skills give (plate_slots()) - returning what was there
# (null if nothing, or if it can't wear it: then nothing changes). Its max HP follows (refit()).
func equip(it: Item, to := "") -> Item:
	if not can_wear(it) or (to and to != it.slot and not (it.slot == "armor" and to in plate_slots())):
		return null
	var old: Item = get(to if to else it.slot)
	set(to if to else it.slot, it)
	refit()
	return old


# Its trinket's banner: its trim on dark cloth (not its side's colours: a banner mustn't give away a
# disguise); nothing for an untrimmed one.
func _draw_banner() -> void:
	var c := trinket.trim() if trinket else Color(0, 0, 0, 0)
	if c.a > 0.0:
		Item.draw_banner(banner, Vector2.ZERO, c, Color("#1d1a12"))


# The tick for the way it faces: a small pale chevron at the rim of its tile, faint (no side's colour: a
# disguise gives nothing away).
func _draw_tick() -> void:
	if facing == Vector2.ZERO:
		return
	var d := facing.normalized()
	var at := d * 9.0  # out past the sprite's arms
	var side := d.orthogonal()
	var pts := PackedVector2Array([at + d * 2.5, at - d * 1.0 + side * 3.0, at - d * 1.0 - side * 3.0])
	heading_tick.draw_colored_polygon(pts, Color(1, 1, 1, 0.8))
	heading_tick.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0, 0, 0, 0.7), 1.0)


# Takes off what's in a slot, returning it.
func unequip(slot: String) -> Item:
	var old: Item = get(slot)
	set(slot, null)
	refit()
	return old


# The armor slots its skills give beyond the first (Behaviour.armor_slot()): a slot for each such skill it has learned,
# whether it works now or not (the armor in it stays worn).
func plate_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for x in _own():
		if x.rank > 0 and x.skill.behaviours.any(func(b: Behaviour): return b and b.armor_slot()):
			out.append(x.skill)
	return out


# Their slot names, as u.get() and u.set() take them (plate_slot()).
func plate_slots() -> Array[StringName]:
	var out: Array[StringName] = []
	for s in plate_skills():
		out.append(plate_slot(s))
	return out


# The slot the skill gives: PLATE + its file's name.
static func plate_slot(s: Skill) -> StringName:
	return StringName(PLATE + s.resource_path.get_file().get_basename())


# What a slot is called: an item slot's name, or the skill giving it (its slot's: "Power Armor").
func slot_label(slot: String) -> String:
	for s in plate_skills():
		if plate_slot(s) == slot:
			return s.name
	return slot.capitalize()


func _get(property: StringName) -> Variant:
	return plating.get(property) if String(property).begins_with(PLATE) else null


func _set(property: StringName, value: Variant) -> bool:
	if not String(property).begins_with(PLATE):
		return false
	if value == null:
		plating.erase(property)
	else:
		plating[property] = value
	return true


# The armor it wears in the slots its skills give that work now (Behaviour.slot_works()), with the skill giving each:
# [skill, item] pairs, in the order it learned them. None while nothing is worn in one (the usual: it reads nothing).
func plates() -> Array:
	var out := []
	if plating.is_empty():
		return out
	for s in plate_skills():
		var it: Item = plating.get(plate_slot(s))
		if it and can_wear(it) and s in passives and s.behaviours.all(func(b: Behaviour): return not b or b.slot_works(self, own_rank(s))):
			out.append([s, it])
	return out


# The Defense each worn armor in those slots confers: [skill, Defense] pairs, for the armor that sets any (the slot's
# own rules - Behaviour.slot_defense() - applied). What Battle asks of a missed attack: which of them blocked it.
func plated_defense() -> Array:
	var out := []
	for pair in plates():
		var s: Skill = pair[0]
		var d := _set_by(pair[1])
		if d == Behaviour.NO_ARMOR:
			continue
		for b in s.behaviours:
			if b:
				d = b.slot_defense(self, own_rank(s), d)
		out.append([s, d])
	return out


# How much of its Power it has, 0 to 1: its Energy, or the reserve it runs on in place of it (runs_on()).
func power_share() -> float:
	var on: Variant = runs_on()
	if on is Reserve:
		return float(store(on)) / maxi(pools().get(on, 0), 1)
	return float(energy) / maxi(max_energy, 1)


# Takes n off its Power (power_share()): what an attack Power Armor blocks does.
func sap_power(n: int) -> void:
	var on: Variant = runs_on()
	if on is Reserve:
		set_store(on, store(on) - n)
	else:
		energy -= n


# The derived-stat pipeline's last step (docs/plan-composability.md, seam 5). Its stats are its base
# (respec_by() shifts it) under whatever effects are on it; from those, max HP: its authored base +
# what its level brings (level_hp()) + what items and passives add (max_hp effects: Burning Blade),
# less what Asphyxia takes (a share of base and level HP a stack) and Humble cuts, at least 1.
# Starkind, its base is its max Power and levels add nothing. Run whenever any of those change.
func refit() -> void:
	var authored := max_energy if starkind() > 0 else max_hp - _hp_bonus
	var grown := authored + (0 if starkind() > 0 else level_hp())
	var bonus := roundi(stat(&"max_hp")) - roundi(stat(&"asphyxia") * grown) - roundi(stat(&"humble")) - int(burnt.get(&"hp", 0))
	max_hp = maxi(grown + bonus, 1)
	_hp_bonus = max_hp - authored
	if hp > max_hp + over_max:
		hp = max_hp + over_max
	_arrange()  # items can grant slots (the Burning Bag)
	_sync_granted()  # and skills


# The name of the item lending it s - "" if it has none, or learned s at a rank the item doesn't beat.
func lent_by(s: Skill) -> String:
	for x in slots:
		if x.skill == s:
			return x.from.name if x.from else ""
	return ""


# Its hotbar follows what its items lend (refit(), on every equip, unequip and enchantment): a skill newly lent
# is new (_sync_new(): it auto-equips), one no longer lent comes off the bar and is announced (lost_skills: Battle
# ends a channel on it) - lent again later, it's new again. Only the hotbar of a unit in the tree: one still
# being set up fills itself (_fill_bar()).
func _sync_granted() -> void:
	var now: Array[Skill] = []
	now.assign(granted().map(func(x: Slot): return x.skill))
	var lost: Array[Skill] = []
	lost.assign(_held.filter(func(s: Skill): return s not in now and own_rank(s) == 0))  # one it learned as well isn't lost
	for s in lost:
		_seen.erase(s)
		var i := hotbar.find(s)
		if i >= 0:
			hotbar[i] = null
	if not lost.is_empty():
		_arrange()
	if now != _held:
		_seen_sig = -1
	_held = now
	_sync_new()
	if not lost.is_empty():
		lost_skills.emit(self, lost)


# Whether it carries tag t, from what it is (its tags), what it wears, what it knows (Wildfire's
# bane: earth; a passive only while equipped), or the beast it's shaped into (Battle.FORMS' traits: a pike is aquatic).
func has_tag(t: StringName) -> bool:
	return t in tags or items().any(func(it: Item): return t in it.tags) \
			or slots.any(func(x: Slot): return x.rank > 0 and (not x.skill.passive or equipped(x.skill)) and (t in x.skill.tags or (emblems() and t in mods(x.skill).tags))) \
			or (form != &"" and t in Battle.FORMS[form][2])


# The statuses on it that bear `tag` (Effect.bears: cc for those that impair its ability to act). Nothing reads
# cc yet: a rule, a skill or a piece of gear that deals with a kind of status asks here.
func afflicted(tag: StringName) -> Array[Effect]:
	var out: Array[Effect] = []
	for e: Effect in timed.keys():
		if tag in e.bears:
			out.append(e)
	return out


# Its shackles (a binding trinket) are locked: a Shackled effect is on it.
func shackled() -> bool:
	return timed.keys().any(func(e: Effect): return e.stat == "shackled")


# How heavy it is to move: its size, rounded up, + what its equipped items weigh (Item.heft(): armor
# by class, weapons medium unless light or heavy, anything with a weight of its own - Shackles).
func weight() -> int:
	var w := ceili(stat(&"size"))
	for it in items():
		w += it.heft()
	for pair in plates():  # and the armor in its other slots
		w += pair[1].heft()
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


# Shifts its base stats (Meditate): `changes` stat -> amount, points moved out of some core stats and
# into others - the decreases pay for the increases exactly (the amounts sum to 0), at most `limit`
# points moved (a point a rank a use), and no stat below 1. All or nothing: false (and no change)
# otherwise. `respec` keeps the running shift from birth. Everything derived follows (refit()).
func respec_by(changes: Dictionary, limit: int) -> bool:
	var total := 0
	var moved := 0
	for s in changes:
		assert(s in CORE, "%s isn't a core stat" % s)
		total += changes[s]
		moved += maxi(changes[s], 0)
		if get(s) + changes[s] < 1:
			return false
	if total != 0 or moved > limit or moved == 0:
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


# Siphon damage (Energy Transfer): what gets through mitigation (and luck, as drain()) comes off its
# resources and never its HP - its Overcharge first, then what it currently spends (siphon_order()),
# spilling from one to the next. A powered unit loses POWER_SIPHON times as much. Returns what it lost.
func siphon(raw: float, tags: Array[StringName], by: Unit) -> int:
	var net := luck - (by.luck if by else 0)
	var left := Luck.settle(raw * (1.0 - mitigation(tags)) * (POWER_SIPHON if powered() else 1.0), net, false)
	var got := 0
	var off := mini(overcharge, left)
	overcharge -= off
	got += off
	left -= off
	for fund in siphon_order():
		if left <= 0:
			break
		if fund is Reserve:
			off = mini(store(fund), left)
			set_store(fund, store(fund) - off)
		else:
			off = mini(energy, left)
			energy -= off
		got += off
		left -= off
	return got


# What a siphon takes from, after Overcharge: the fund it last paid from (Energy, or a reserve it still
# spends) if that holds any, then Energy, then its other reserves it spends, fullest first.
func siphon_order() -> Array:
	var all := pools()
	var rest := all.keys().filter(func(r: Reserve): return spends(r))
	rest.sort_custom(func(a: Reserve, b: Reserve): return store(a) > store(b))
	var out: Array = [&"energy"]
	out.append_array(rest)
	if paid_with != null and paid_with in out:
		out.erase(paid_with)
		out.push_front(paid_with)
	return out


# Energy an effect gives it (Starblade, an Energy Potion, starlight, Starsap, Energy Transfer) - every
# grant comes through here, not regen (recover()). A powered unit's Energy is its Power, so the grant
# arrives as Power (Powerful). Up to its max; returns what it got.
# heard: reported as a recovery (recovered: RecoveryEndurance); a caller that adds Overcharge too reports the two at once.
func grant_energy(n: int, heard := true) -> int:
	var was := energy
	energy += maxi(n, 0)
	if heard:
		note_recovery(&"energy", energy - was)
	return energy - was


# Something gave back n of pool (&"hp", &"energy" - Overcharge counts - or a Reserve) by means other than
# regen: told to whoever listens (recovered: Battle's RecoveryEndurance). heal() and grant_energy() call it; a new
# way to restore something calls it too, and burnout reaches it without knowing.
func note_recovery(pool: Variant, n: int) -> void:
	if n > 0:
		recovered.emit(self, pool, n)


# Its Recovery Endurance as a battle starts, and as a resting turn at full refills it: con mod, not below 0.
func endurance_max() -> int:
	return maxi(mod(&"constitution"), 0)


# RecoveryEndurance takes n off the max of pool for good (burnt): HP through refit(), Energy off max_energy, a
# reserve through pools().
func burn(pool: Variant, n: int) -> void:
	if n <= 0:
		return
	burnt[pool] = burnt.get(pool, 0) + n
	if pool is StringName and pool == &"hp":
		refit()
	elif pool is StringName and pool == &"energy":
		max_energy = maxi(max_energy - n, 0)
		if starkind() > 0:
			refit()
	elif pool is Reserve:
		set_store(pool, store(pool))
		reserve_changed.emit(pool, store(pool), store(pool))


# Puts n points of Overcharge on it for `turns` of its turns, + `spare` that don't count (1 on its own
# side's turn, as Behaviour.Cast.put() gives). More while it lasts adds up, and the timer starts again.
# It decays to nothing over the turns that count (tick()).
func add_overcharge(n: int, turns: int, spare := 0) -> void:
	if n <= 0 or turns <= 0:
		return
	var a := Applied.new(turns + spare, 1)
	a.total = turns
	timed[OVERCHARGE] = a
	overcharge += n


# Dead units stay dead. heard: told first (being_healed), so others' passives may take a cut (Molothrus).
func heal(h: int, heard := true) -> void:
	if not is_alive():
		return
	if heard:
		var got := {hp = h}
		being_healed.emit(self, got)
		h = got.hp
	var was := hp
	hp += maxi(h, 0)
	if heard:
		note_recovery(&"hp", hp - was)


# Every reserve it has, by max: its own (reserves), those the trees it picked bring (SkillTab.reserves:
# a Druid's Astral), and those its passives give - each the holder's
# mod in the passive's reserve_mod, plus the reserve's base, x its rank, no less than 0 (Sweet Nothings:
# cha mod x rank; Stamina: (con mod + 2) x rank). A
# passive switched off or disabled keeps its reserve, but nothing is spent from it (spends()).
func pools() -> Dictionary[Reserve, int]:
	var out: Dictionary[Reserve, int] = reserves.duplicate()
	for c in role.choices if role else []:
		for t in picks(c):
			for r in t.reserves:
				out[r] = out.get(r, 0) + t.reserves[r]
	for x in slots:
		var r := x.skill.reserve
		if r and x.skill.passive and equipped(x.skill):
			var m := mods(x.skill)  # its modifiers: the mod is stat impact, the rank rank impact
			out[r] = out.get(r, 0) + maxi((m.stat(mod(x.skill.reserve_mod), &"stat_impact") if x.skill.reserve_mod else 1) + r.base, 0) * m.irank(x.rank, &"rank_impact")
	for r in out:
		out[r] = maxi(out[r] - int(burnt.get(r, 0)), 0)  # Recovery Endurance's loss
	return out


func store(r: Reserve) -> int:
	return stores.get(r, 0)


# Whether it spends from r now: unless the passive that gives it, or stands in for Energy with it
# (replacer(): Mana), is switched off (Sweet Nothings' toggle), disabled or not equipped.
func spends(r: Reserve) -> bool:
	for x in slots:
		if x.skill.reserve == r and x.skill.passive and (not x.on or x.skill in disabled or not equipped(x.skill)):
			return false
		if replacer(x.skill) == r and (not x.on or x.skill in disabled or not equipped(x.skill)):
			return false  # Mana switched off: mana it holds pays for nothing
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


# What s costs it, at its rank (starter spells: cost x rank; Pricing.cost_for()), before any savings (cost_from()): more
# the more it has used it lately (Exhaustion.rate(); Exhaustion.raise() rounds it), and more again paid from a fund
# that burns (Burnout.on_cost(): an int skill paid in Mana).
func price(s: Skill, fund: Variant = null) -> int:
	return Exhaustion.raise(Pricing.cost_for(self, s), exhaustion.rate(s, Burnout.on_cost(s, fund)))  # priced, or hand-set under its modifiers


# What s costs it paid from fund: a reserve that pays whole costs takes its few points for any cost
# (Sweet Nothings: 1); otherwise price(), times the best cost_with factor of any reserve that
# payment counts as, where its passives open that reserve up to s's tier (Mana I: the starter spells
# at half cost). Rounded up.
func cost_from(s: Skill, fund: Variant, cut := 0.0) -> int:
	if fund is Reserve and fund.whole > 0:
		return fund.whole if price(s) > 0 or s.needs == fund else 0
	var factor := 1.0
	for r in s.cost_with:
		if pays_as(s, fund, r) and opened(r) >= tier(s):
			factor = minf(factor, s.cost_with[r])
	return ceili(price(s, fund) * factor * (1.0 - cut) - 0.0001)


# The highest tier its passives open r's savings for (Mana II: tier 2); 0 if none do.
func opened(r: Reserve) -> int:
	var best := 0
	for x in on_passives:
		if x.skill.opens == r:
			best = maxi(best, mods(x.skill).irank(x.rank, &"rank_impact"))  # through its modifiers
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
	var out := class_trees()
	out.append_array(general_trees())
	return out


# The skill it has learned that waives a general tree's needs (Skill.waives: general for the base
# tree, else the category), or null.
func _opener(category: StringName) -> Skill:
	var key := category if category else &"general"
	for x in slots:
		if x.skill.waives == key and x.rank > 0 and equipped(x.skill):
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
			var have := _counted().filter(func(x: Skill): return x != s and tier(x) >= t).size()
			if have >= 3:
				return ["", null]
			why = "Needs 3 T%d+ skills (%d so far)" % [t, have]
		else:
			var best := -1
			for x in _counted():
				if role and role.tier(x) >= 0 and role.category(x) == c:
					best = maxi(best, role.tier(x))
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


# A skill that stopped working: learned through a waiver whose waiver isn't working now (removed, disabled, or
# cursed down to nothing, or unequipped), or learned on a lent skill (leaned) whose prerequisites are no longer met
# now it is gone (missing(): counts() reads a lent skill only while it is lent and works). Dependents of a lapsed
# skill lapse too, the way down the tree.
func lapsed(s: Skill) -> bool:
	var by: Skill = waived.get(s)
	if by != null and (base_rank(by) == 0 or by in disabled or not equipped(by) or unranked().get(by, 0) >= base_rank(by)):
		return true
	if s not in leaned or _bare:
		return false
	var was := _judging
	_judging = true
	var gone := missing(s) != ""
	_judging = was
	return gone


# Whether x counts as a prerequisite: it has x (rank), and - if only an item lends it - it still works: lent, not
# disabled, and not a trait while traits are suppressed. A skill learned on a lent one (leaned) counts while it hasn't
# lapsed. With _bare (unlock() asking what it needed): nothing lent counts, nor anything learned on it.
func counts(x: Skill) -> bool:
	var own := 0  # (the slots' own ranks, not rank() or own_rank(): those read effects, which read lapsed())
	var lent := 0
	for list: Array[Slot] in [_role_slots, innate, learned]:
		for sl in list:
			if sl and sl.skill == x:
				own = maxi(own, sl.rank)
	for it in items():
		if x in it.skills:
			lent = maxi(lent, it.skill_rank(x))
	if maxi(own, lent) - unranked().get(x, 0) <= 0:
		return false
	if x in leaned:
		return not _bare and not lapsed(x)
	if own > 0:
		return true
	return not _bare and x not in disabled and not (x.is_trait() and traits_suppressed())


# The skills that count as prerequisites (counts()): what it has learned, and what is lent and works.
func _counted() -> Array[Skill]:
	var out: Array[Skill] = []
	for x in slots:
		if x.skill not in out and counts(x.skill):
			out.append(x.skill)
	return out


# How many lent skills count toward s's tier (min_tier: skills learned first), beyond the `learned` ones.
func _lent_count(s: Skill) -> int:
	return granted().filter(func(x: Slot): return x.skill != s and own_rank(x.skill) == 0 and counts(x.skill)).size()


# The name a skill goes by for it: Strike takes the name of a low-tier upgrade it has learned
# (Decisive Strike; only while equipped, as it only works then), or its element's while imbued (Firestrike).
func skill_name(s: Skill) -> String:
	if not s.chain:
		return s.name
	if imbued > 0 and element:
		return String(element).capitalize() + "strike"
	for x in slots:
		if x.skill.renames and x.rank > 0 and equipped(x.skill):
			return x.skill.renames
	return s.name


# Whether it holds n points in fund (a Reserve or &"energy"); `buffered`, counting its Overcharge -
# which tops up Energy or a point-for-point reserve, not one that pays whole costs (Sweet Nothings) or
# one built to be spent to its last point (Focus: aims).
func covers(fund: Variant, n: int, buffered := false) -> bool:
	var have := store(fund) if fund is Reserve else energy
	return have + (overcharge if buffered and not (fund is Reserve and (fund.whole > 0 or fund.aims)) else 0) >= n


# Spends what it can of a cost of n from fund out of its Overcharge first (pay_for(), pay_strike());
# returns that much. Not on the reserves covers() leaves out: Focus still pays its own, to its last point.
func _spend_overcharge(fund: Variant, n: int) -> int:
	if fund is Reserve and (fund.whole > 0 or fund.aims):
		return 0
	var off := clampi(n, 0, overcharge)
	overcharge -= off
	return off


# What pays for a skill: the reserve it needs, if it needs one (and nothing else will do); else the
# reserve its cost profile prefers (Pricing.reserve_of(): "high mana"), if it can; else a
# reserve that makes it cheaper (Hex: mana, for AP; the starter spells: mana, for cost; a Warlock's
# dearer skills: a Sweet Nothing), then one dedicated to its tags or kinds (Skill.tagged(): mana for
# magical skills, stamina for martial, specialist, general and physical ones, so Energy is kept for the
# rest), then Energy, then any other reserve. Returns the Reserve, &"energy", or null if
# nothing can. Running on a reserve (runs_on()), its own Energy is empty, so a skill no reserve of its
# pays for needs Energy that came some other way (Energy Transfer, Overcharge); running on Stamina
# (Reserve.bars), no spell that costs anything can be paid at all. Overcharge doesn't change that order:
# only when nothing can pay without it does it look again counting Overcharge (covers()); whatever pays,
# Overcharge is spent first (pay_for()).
func funding(s: Skill, cut := 0.0) -> Variant:
	var on: Variant = runs_on()
	if on is Reserve and on.bars.any(func(t): return s.tagged(t)) and (price(s) > 0 or s.needs):
		return null  # running on Stamina: nothing pays for a spell
	var fund: Variant = _funding(s, false, cut)
	return fund if fund != null or overcharge <= 0 else _funding(s, true, cut)


func _funding(s: Skill, buffered: bool, cut: float) -> Variant:
	var allowed := pools().keys().filter(func(r: Reserve): return spends(r) and (r.only.is_empty() or r.only.any(func(t): return s.tagged(t))))
	if s.needs and s.needs in pools():  # a unit without that reserve at all (a Cleric's Level Down) pays as usual
		return s.needs if s.needs in allowed and covers(s.needs, cost_from(s, s.needs, cut), buffered) else null
	var pref := Pricing.reserve_of(s)  # its cost profile prefers a reserve ("high mana"): that first
	if pref:
		for r: Reserve in allowed:
			if r.resource_path.get_file().get_basename() == pref and covers(r, cost_from(s, r, cut), buffered):
				return r
	if ranged(s):
		for r: Reserve in allowed:
			if r.aims and covers(r, cost_from(s, r, cut), buffered):
				return r  # Focus: first for a ranged attack, what it's built for
	for r: Reserve in allowed:
		if (s.ap_with.has(r) or cost_from(s, r) < price(s)) and covers(r, cost_from(s, r, cut), buffered):
			return r
	for r: Reserve in allowed:
		if not r.only.is_empty() and r.whole == 0 and covers(r, cost_from(s, r, cut), buffered):
			return r
	if covers(&"energy", cost_from(s, &"energy", cut), buffered):
		return &"energy"
	for r: Reserve in allowed:
		if covers(r, cost_from(s, r, cut), buffered):
			return r  # Focus, for anything but a ranged attack: only once Energy can't
	return null


# A ranged attack: one that rolls to hit a foe, reaching past the tiles beside it (Focus pays first for
# these, and sharpens one that spends the last of it).
func ranged(s: Skill) -> bool:
	return s.attacks() and s.span(self) > 1.5


# What its last payment adds to s's attack roll: its focus stat (Focus: its rank) when it paid for a
# ranged attack with an aims reserve and spent the last of it (Battle.cast()).
func focus_bonus(s: Skill) -> int:
	return roundi(stat(&"focus")) if paid_for == s and emptied and paid_with is Reserve and paid_with.aims and ranged(s) else 0


# What focus_bonus() would be if it used s now (Battle.hit_chance()'s forecast).
func focus_forecast(s: Skill) -> int:
	var fund: Variant = funding(s)
	return roundi(stat(&"focus")) if fund is Reserve and fund.aims and ranged(s) and store(fund) == cost_from(s, fund) else 0


# Tags its Energy counts as, from its passives (Working Knowledge: magical).
func energy_tags() -> Array[StringName]:
	var out: Array[StringName] = []
	for p in passives:
		for t in p.energy_as:
			if t not in out:
				out.append(t)
	return out


# Whether paying for s with fund counts as paying with reserve r, for r's bonuses: r itself, or Energy
# its passives let count as r for skills like s (Working Knowledge: Energy counts as Mana for Hex; Field
# Experience as Stamina for martial skills) - a general skill (Move) counting as any kind they name.
func pays_as(s: Skill, fund: Variant, r: Reserve) -> bool:
	if fund is Reserve:
		return fund == r
	if fund != &"energy":
		return false
	return energy_tags().any(func(t): return (s.tagged(t) or s.general()) and t in r.only)


# Whether its last payment for s counted as paying with r (pays_as()): a stamina skill paid with Stamina,
# or by an Adventurer's Energy standing in for it, does more (Behaviours/move.gd).
func paid_as(r: Reserve, s: Skill) -> bool:
	return paid_for == s and pays_as(s, paid_with, r)


# AP to use s paid from fund: its AP, times the best factor of any reserve that payment counts as,
# and more the more it has used it lately (Exhaustion.rate()).
func ap_cost(s: Skill, fund: Variant, cut := 0.0) -> float:
	var factor := 1.0
	for r in s.ap_with:
		if pays_as(s, fund, r):
			factor = minf(factor, s.ap_with[r])
	return Pricing.ap_for(self, s) * factor * exhaustion.rate(s) * (1.0 - cut)  # priced, or hand-set under its modifiers


# Its actives it would aim at a foe itself (not a tile, nor used at once on whoever's nearest), those it
# can pay for now only if `affordable` - what the AI weighs to strike with.
func foe_actives(affordable := false) -> Array[Skill]:
	var out: Array[Skill] = []
	out.assign(actives.filter(func(x: Skill): return x.for_foes() and not x.on_tile() and not x.auto and (not affordable or can_afford(x))))
	return out


# `cut`: the share of its price a behaviour takes off before it's paid (Battle.rebate(), Poach's bloodied foe).
func can_afford(s: Skill, cut := 0.0) -> bool:
	return can_afford_after(s, 0.0, cut)


# Whether it could still pay for s after walking `steps` movement first (which takes move-only AP,
# then general AP the skill might have needed).
func can_afford_after(s: Skill, steps: float, cut := 0.0) -> bool:
	var fund: Variant = funding(s, cut)
	if fund == null:
		return false
	var general := 0.0
	var move_only := 0.0
	for p in ap:
		if p.only == &"":
			general += p.amount
		elif p.only == &"move":
			move_only += p.amount
	var use := s.pays_with if s.pays_with else &"skill"  # Meditate: movement first
	var left := ap_for(use) - (steps if use == &"move" else maxf(steps - move_only, 0.0))
	return general >= maxf(steps - move_only, 0.0) - 0.0001 and left >= ap_cost(s, fund, cut) - 0.0001


# Pays a skill's AP and cost from its funding: one use of it (Exhaustion.used()). False (and nothing
# spent) if it can't.
func pay_for(s: Skill, cut := 0.0) -> bool:
	var fund: Variant = funding(s, cut)
	if fund == null or not pay(ap_cost(s, fund, cut), s.pays_with if s.pays_with else &"skill"):
		return false
	paid_ap = ap_cost(s, fund, cut)
	paid_cut = cut
	var cost := cost_from(s, fund, cut) - _spend_overcharge(fund, cost_from(s, fund, cut))
	if fund is Reserve:
		set_store(fund, store(fund) - cost)
	else:
		energy -= cost
	emptied = fund is Reserve and store(fund) == 0
	var gain := exhaustion.used(s)
	paid_for = s
	paid_with = fund
	if dbno:
		dbno.acted += 1  # Downed: a skill use against its allowance (Grudge)
	_count_fury()
	var wear := Exhaustion.Wear.new()
	wear.skill = s
	wear.caster = self
	wear.gain = gain
	wear.uses = gain
	paid.emit(self, s, wear)
	return true


# A channeled skill's strike AP and cost for it: the skill's, at the rate its channel was paid at
# (Exhaustion.strike_rate(): channel and strike are one use), the cost rounded up.
func strike_ap(s: Skill) -> float:
	return s.strike_ap * exhaustion.strike_rate(s)


func strike_cost(s: Skill) -> int:
	return Exhaustion.raise(s.strike_cost, exhaustion.strike_rate(s))


# Whether it could pay a channeled skill's strike now.
func can_strike(s: Skill) -> bool:
	return covers(&"energy", strike_cost(s), true) and ap_for(&"skill") >= strike_ap(s) - 0.0001


# Pays a channeled skill's strike (Metea): its strike AP, and its strike cost in Energy. False (and
# nothing spent) if it can't.
func pay_strike(s: Skill) -> bool:
	if not can_strike(s):
		return false
	pay(strike_ap(s), &"skill")
	energy -= strike_cost(s) - _spend_overcharge(&"energy", strike_cost(s))
	if dbno:
		dbno.acted += 1
	_count_fury()
	return true


# Start of this unit's faction turn: fresh AP and movement, and it can slip back into hiding.
func refresh() -> void:
	turns_taken += 1
	disciplined = 0
	if form:
		form_turns -= 1
		if form_turns <= 0:
			unshape()
	ap = _pools()
	_ap_start.assign(ap.map(func(p: AP): return p.amount))
	_walk_ap.assign(ap.map(func(_p: AP): return 0.0))
	moved = 0.0
	steps = 0
	exposed = 0
	fury_acts = 0
	overdriven = false
	tally.clear()
	winded()


# Winded (the winded stat: Bludgeon): it loses that much AP - at once, if it has AP to lose, as its turn
# opens otherwise.
func winded() -> void:
	var n := stat(&"winded")
	if n > 0.0:
		pay(minf(n, ap_for(&"")), &"")


# How hard it worked this turn: &"rest" (idle(), holding no channel), &"light" (it only spent its
# dex move or wis skill AP, leaving the general pool whole - or it was idle holding a channel: keeping
# the channel is what it gets instead of rest's benefits) or &"busy". Walking while standing still
# (Meander) doesn't count.
func activity() -> StringName:
	if idle():
		return &"light" if channel else &"rest"
	var spent := _spent()
	var general := 0.0
	for i in spent.size():
		if ap[i].only == &"":
			general += spent[i]
	return &"light" if general < 0.0001 else &"busy"


# Whether this turn met rest's requirements: no AP spent and no tiles walked beyond standing still
# (Meander). A channel holds through a turn only if it did (Battle.end_turn()).
func idle() -> bool:
	var spent := 0.0
	for x in _spent():
		spent += x
	return spent < 0.0001 and (is_zero_approx(moved) or still())


# AP spent from each pool this turn, less what walking took while standing still (Meander).
func _spent() -> PackedFloat64Array:
	var walking := still()
	var out := PackedFloat64Array()
	for i in mini(ap.size(), _ap_start.size()):
		out.append(_ap_start[i] - ap[i].amount - (_walk_ap[i] if walking and i < _walk_ap.size() else 0.0))
	return out


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
	return wards(t.level, extra)


# Whether standing still (Meander), `extra` tiles into a walk, wards off a tile effect of this level: the
# ground's (passes_by()) or what a tile makes it pay for moving (per_tile; Battle.travel()). `began`: the
# tiles it had walked before this walk, when it's already been paid for (steps).
func wards(level: int, extra: int, began := -1) -> bool:
	return (steps if began < 0 else began) + extra <= meander() and level <= meander()


# Pays for walking n tiles that took `cost` movement (and as much move AP), counting them towards
# still(). Once it's walked further than standing still allows, what lasts until it moves ends (Hide).
func walked(n: int, cost: float, compelled := false) -> void:
	var before := ap.map(func(p: AP): return p.amount)
	moved += cost  # a Relay boost can take it below what it's walked
	pay(minf(maxf(cost, 0.0), ap_for(&"move")) if compelled else maxf(cost, 0.0), &"move")  # compelled (fear): pays what it has, and goes anyway
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
# Its reserves come back too (_recover_reserves()).
func recover() -> int:
	var k := rounded((mod(&"constitution") + mod(&"wisdom")) / 2.0)
	var rate := float(maxi(k, 1)) if k >= 0 else 1.0 / (1 - k)
	var how := activity()
	if how == &"rest" and full_resource():
		endurance = maxi(endurance, endurance_max())  # RE comes back only resting at full
	_recover_reserves(how, rate)
	if powered() or runs_on() is Reserve:
		return 0  # running on Mana or Stamina: its own Energy doesn't come back
	match how:
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


# Whether what it runs on is full: its Energy (Power), or the reserve standing in for it (runs_on()).
func full_resource() -> bool:
	var on: Variant = runs_on()
	if on is Reserve:
		return store(on) >= pools().get(on, 0)
	return energy >= max_energy


# Reserves that come back at turn's end, by activity `how`: one with_energy (Stamina, Mana) at Energy's
# rate (light activity half), plus its rest_rank x the rank of the passive giving or opening it on a
# resting turn (Stamina 2 x rank), and its steady share of that on any other turn (Mana: half) - while
# it spends from it (switched off, nothing) - whether or not
# Energy is full or Power; one that builds (Focus) its share of its max, rounded up, only on a resting
# turn (a channeler isn't resting: activity()).
func _recover_reserves(how: StringName, rate: float) -> void:
	var all := pools()
	for r in all:
		if r.with_energy:
			var bonus := r.rest_rank * giver_rank(r) * (1.0 if how == &"rest" else r.steady)
			if not spends(r) or store(r) >= all[r] or (how == &"busy" and bonus <= 0.0):
				reserve_rest[r] = 0.0
				continue
			var got: float = reserve_rest.get(r, 0.0) + {&"rest": rate, &"light": rate / 2.0}.get(how, 0.0) + bonus
			var whole := floori(got + 0.0001)
			reserve_rest[r] = got - whole
			set_store(r, store(r) + whole)
		if r.builds > 0.0 and how == &"rest":
			set_store(r, store(r) + ceili(r.builds * all[r] - 0.0001))


# The highest rank of its passives giving or opening reserve r (Stamina's rank, Mana's), 0 if none.
func giver_rank(r: Reserve) -> int:
	var best := 0
	for x in slots:
		if (x.skill.reserve == r or x.skill.opens == r) and x.skill.passive and equipped(x.skill):
			best = maxi(best, mods(x.skill).irank(x.rank, &"rank_impact"))  # as its modifiers read it, as pools() does
	return best


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
	var out: Array[AP] = [AP.new(maxf((BASE_AP + mini(dex, 0) + mini(wis, 0)) * (more + opening) + stat(&"base_ap"), 0.0)),
			AP.new(moving, &"move"), AP.new(casting, &"skill")]
	return out


# What armor takes off its dex (pool &"move") or wis (&"skill") AP each turn: heavy armor its rank less
# its con mod (dex) or str mod (wis) - a negative mod makes it worse - medium armor half that; never
# below 0. None from armor that eases that pool (Item.eases) on a wearer with that mod at SUFFICIENT
# or more. Light armor takes nothing. What it wears in the slots its skills give (plates()) drags the same, each
# worked out alone and all added up.
func armor_drag(pool: StringName) -> float:
	var sum := _drag_of(armor, pool)
	for pair in plates():  # armor in its other slots drags in full, on top: harder to overcome
		sum += _drag_of(pair[1], pool)
	return sum


func _drag_of(item: Item, pool: StringName) -> float:
	if not item or item.weight_class() not in [&"heavy", &"medium"]:
		return 0.0
	var m := mod(&"constitution" if pool == &"move" else &"strength")
	if item.eases == (&"dexterity" if pool == &"move" else &"wisdom") and m >= SUFFICIENT:
		return 0.0
	return maxf((item.ranked() - m) / (2.0 if item.weight_class() == &"medium" else 1.0), 0.0)


# Wearing armor to some effect: armor that sets Defense, whose requirement it meets. Bracing passives
# work only then (check_bonus(); Effect.armored).
func armored() -> bool:
	return armor != null and armor.sets_defense() and can_wear(armor)


# What it adds to a check in stat s, as `kind` (offensive or defensive): its mod (stand-ins by `tags`)
# plus what its bracing gives (check_bonus()). The usual bonus of one side of a Check.
func check_mod(s: StringName, kind: StringName, tags: Array[StringName] = []) -> int:
	return mod(s, tags) + check_bonus(s, kind, tags)


# What its bracing passives add to a check in stat s (offensive or defensive; mental: int, wis, cha):
# each that matches its armor's weight, stat and kind adds its armor's rank (x the passive's share),
# up to the passive's rank (Agility, Balanced, Vanguard, Combat, Meditative, Invigorating Bracing).
# Plain check effects (Turtle Tactics) add theirs, armor or not.
# A `check` effect with tags counts only for checks carrying one (the check tag seam: a check that
# taps carries `taps`, an execute's carries `execute`, so one effect can help with every such check).
func check_bonus(s: StringName, kind: StringName, tags: Array[StringName] = []) -> int:
	var w := armor.weight_class() if armored() else &""
	var total := 0
	var t := Tags.expand(tags) if not tags.is_empty() else ([] as Array[StringName])
	for pair in _effects():
		var e: Effect = pair[0]
		if e.stat not in ["brace", "check"] or (e.kind and e.kind != kind):
			continue
		if e.stat == "check" and not e.tags.is_empty() and not e.tags.any(func(x): return x in t):
			continue
		if not (s in e.checks or (&"mental" in e.checks and s in MENTAL) or (e.stat == "check" and e.checks.is_empty())):
			continue
		if e.stat == "check":
			total += roundi(e.amount * (pair[1] if e.per_rank else 1) * pair[2])
		elif armored() and (e.tags.is_empty() or w in e.tags):
			total += mini(floori(armor.ranked() * e.amount), pair[1])
	return total


# Its best defensive bracing over its stats: what a last stand, which goes by every stat at once, takes.
func best_defensive_bonus() -> int:
	var best := 0
	for s in [&"strength", &"dexterity", &"constitution", &"intelligence", &"wisdom", &"charisma"]:
		best = maxi(best, check_bonus(s, &"defensive"))
	return best


# Gives back `share` of its last payment for s (pay_for()): the AP to its general pool, the cost to what
# paid it. A refund, not a recovery: no RE spent (Poach's and Slam Jam's discounts). Returns the cost back.
func refund(s: Skill, share: float) -> int:
	if share <= 0.0 or paid_for != s:
		return 0
	var fund: Variant = paid_with
	if not ap.is_empty():
		ap[0].amount += paid_ap * share
	var n := floori(cost_from(s, fund, paid_cut) * share + 0.0001)
	if fund is Reserve:
		set_store(fund, store(fund) + n)
	else:
		energy += n
	return n


# Bloodied: half its HP or less, as an execute measures it (execute_share(): whole while hale). Poach.
func bloodied() -> bool:
	return execute_share() <= 0.5


# Gets n AP back into its general pool, up to what that pool started the turn with (Renew).
# Returns what it got.
# `pool` names another (&"move": its dex AP, &"skill": its wis AP; the regain stat's dex or wis tag; Charge!).
func regain(n: float, pool := &"") -> float:
	var i := ap.find_custom(func(p: AP): return p.only == pool)
	if n <= 0.0 or i < 0 or i >= _ap_start.size():
		return 0.0
	var got := clampf(_ap_start[i] - ap[i].amount, 0.0, n)
	ap[i].amount += got
	return got


func ap_left() -> float:
	return ap.reduce(func(sum: float, p: AP): return sum + p.amount, 0.0)


# The share of its turn's AP it has left: 1 as its turn starts (or with none to spend), 0 spent.
func ap_share() -> float:
	var start: float = _ap_start.reduce(func(sum: float, a: float): return sum + a, 0.0)
	return clampf(ap_left() / start, 0.0, 1.0) if start > 0.0001 else 1.0


# Gains n tiles of movement this turn: n move AP, and n further than its movement allows (Move).
func stride(n: float) -> void:
	ap.append(AP.new(n, &"move"))
	moved -= n


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
	if e.stat == "regain":  # instant: AP back to the pool it's tagged with, and nothing stays on
		regain(e.amount * (at_rank if e.per_rank else 1), {&"dex": &"move", &"wis": &"skill"}.get(e.tags[0] if not e.tags.is_empty() else &"", &""))
		return Applied.new(0, at_rank)
	if e.helps() < 0:
		_log_harm({effect = e, turns = turns, rank = at_rank})
	var r := maxi(at_rank, timed[e].rank) if e in timed else at_rank
	timed[e] = Applied.new(turns, r)
	if e.stat == "level":
		_arrange()  # its slots follow
	if e.stat in ["level", "constitution", "hardy"]:
		refit()  # and its max HP
	return timed[e]


# Switches s off for some of its turns (Brainfog); a pillar skill takes every pillar skill with it.
# A curse's (Brainfog) slots quiver; others only dim. `by`: who disables it, if anyone. Its listeners
# have their say first (disabling: Coyote Scepter lengthens it); while it postpones (the postpone stat:
# Coyote Charm) the disabling is held, not counting down, and lands as that ends (release()).
func disable(s: Skill, turns: int, curse := false, by: Unit = null) -> void:
	if s.is_trait():
		return  # what it is can't be switched off (Starkind); only traits_suppressed() does
	var d := {skills = pillars() if s.pillar() else [s] as Array[Skill], turns = turns, curse = curse, by = by}
	disabling.emit(self, d)
	for x: Skill in d.skills:
		if postponing():
			var was: Array = postponed.get(x, [0, false])
			postponed[x] = [maxi(was[0], d.turns), was[1] or d.curse]
			continue
		disabled[x] = maxi(disabled.get(x, 0), d.turns)
		if d.curse:
			cursed[x] = true


# It holds disablings off for now (the postpone stat: Coyote Charm): they and its curse debuffs wait.
func postponing() -> bool:
	return timed.keys().any(func(e: Effect): return e.stat == "postpone")


# What it postponed lands, once nothing postpones it any longer (tick(), Battle._strip()): each disabling for
# its full turns.
func release() -> void:
	if postponing():
		return
	for x in postponed:
		disabled[x] = maxi(disabled.get(x, 0), postponed[x][0])
		if postponed[x][1]:
			cursed[x] = true
	postponed.clear()


# Its pillar skills: those its build stands on (Powerful), easiest to disable - one goes, all go.
func pillars() -> Array[Skill]:
	var out: Array[Skill] = []
	for x in slots:
		if x.skill.pillar():
			out.append(x.skill)
	return out


# Its skills in the slots a disabling skill reaches, right to left, a slot at a time (each an
# Array[Skill]): its pillar skills first, as one - they sit in its last sure slots; Foundations (a kind
# of pillar: Generalist) sit rank / 2 slots further in, unless plain pillars go first and take them along - then
# what's on its hotbar from the last slot back (always-on passives fill it from the bottom). Skills it hasn't
# equipped don't work, so aren't reached; skills already disabled are skipped.
func disable_order() -> Array[Array]:
	var out: Array[Array] = []
	var seen := {}
	var group := func(list: Array[Skill]) -> void:
		var fresh: Array[Skill] = []
		for s in list:
			if s and not s.is_trait() and s not in seen and s not in disabled and s not in postponed and rank(s) > 0:
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
	for i in range(hotbar.size() - 1, -1, -1):
		rest.append(hotbar[i])
	for s in rest:
		group.call([s] as Array[Skill])
	var deep: Array[Skill] = []
	if foundations_only:
		deep.assign(pillars().filter(func(x: Skill): return x not in disabled and rank(x) > 0))
	if not deep.is_empty():  # rank / 2 slots in from the right: harder to reach
		out.insert(mini(deep.map(func(x: Skill): return base_rank(x)).max() / 2, out.size()), deep)
	return out


# What a slot of disable_order() adds to the check against disabling it: its skill's rank, or for
# the pillar skills (one slot), their median rank; each with its modifiers' check shift (Density's
# makes a dense skill easier to overcome, Diluted's harder: Modifiers.check).
func slot_weight(group: Array) -> int:
	var ranks := group.map(func(s: Skill): return rank(s) + mods(s).check)
	ranks.sort()
	var n := ranks.size()
	if n == 0:
		return 0
	return ranks[n / 2] if n % 2 else roundi((ranks[n / 2 - 1] + ranks[n / 2]) / 2.0)


# End of this unit's faction turn: timed effects count down, and so do disabled skills. One that fades loses a rank instead
# of ending, a turn at a time; one lasting until it moves (with no turns set), or until something
# ends it (lasting), doesn't count down; nor, while it postpones (Coyote Charm), its curse debuffs. The
# postponing over, what it held lands (release()).
func tick() -> void:
	var holding := postponing()
	for s in disabled.keys():
		disabled[s] -= 1
		if disabled[s] <= 0:
			disabled.erase(s)
			cursed.erase(s)
	var oc: Applied = timed.get(OVERCHARGE)
	if oc and oc.turns <= oc.total:  # Overcharge: what's left / turns left, rounded up - none on a turn that doesn't count
		overcharge -= ceili(overcharge / float(maxi(oc.turns, 1)))
	for e in timed.keys():
		var a := timed[e]
		if a.lasting or (a.until_move and a.turns == 0) or (holding and &"curse" in e.bears and e.helps() < 0):
			continue
		a.turns -= 1
		if a.turns > 0:
			continue
		if a.fades and a.rank > 1:
			a.rank -= 1
			a.turns = 1
		else:
			timed.erase(e)
	if OVERCHARGE not in timed:
		overcharge = 0
	release()
	_arrange()  # a level effect may have ended
	refit()  # or Asphyxia fallen a stack


# On the field: standing, or Downed (down but not out, at 0 HP or below).
func is_alive() -> bool:
	return hp > 0 or dbno != null or deferred > 0 or staying


# How whole an execute takes it to be: HP left / max HP - or 1, full, while something makes it hale
# (Intervention's Bless). Every execute reads this (Battle.executed(), Battle.last_stand(), Luun's Smite).
func execute_share() -> float:
	return 1.0 if stat(&"hale") > 0.0 else float(hp) / maxi(max_hp, 1)


# The tags a moment of its own state lends what's asked of it: downed while Downed - an effect tagged
# downed counts only then (Bless's regen; Unit.stat()'s tag filter).
func state_tags() -> Array[StringName]:
	var out: Array[StringName] = []
	if dbno:
		out.append(&"downed")
	return out


# Under something that takes away all its actions: a helpless effect (Stunned), sleep, or Downed
# without the will to fight on (Tenacity; Downed.acts). The source; whether it stops it is stopped().
func helpless() -> bool:
	return stat(&"helpless") > 0.0 or asleep() or (dbno != null and not dbno.rule.acts)


# Helpless with nothing letting it act: a permit (the mindless stat: Mindless Fury) lets it take that
# many skill uses a turn anyway; spent, it's stopped too. It can't act, move or take orders.
func stopped() -> bool:
	return helpless() and fury_acts >= roundi(stat(&"mindless"))


# Whether it still has its reactions: it can dodge (Battle.evade()), guard behind a shield (guarding())
# and obstruct (Battle.obstruction()). Lost to Jam (the jammed stat) and to being stopped(): helpless,
# it does none of these. Watching isn't one of them: a helpless unit still sees (Battle._watch()).
func reacts() -> bool:
	return stat(&"jammed") <= 0.0 and not stopped()


# Tapped, as far as the unit itself can tell: out of AP, or stopped(). Never stored or cleansed: it
# lifts the moment its cause does (Stunned healed or cleansed, AP back). Command.tapped() adds the
# leader's caps; that's the one the HUD and orders read.
func tapped() -> bool:
	return ap_left() <= 0.001 or stopped()


# Acting in a reduced capacity: where it would be tapped, a permit lets it act - helpless under
# Mindless Fury (its mental stats count as 1), or ordered past the caps as a Drone (its mental mods
# capped at + its Drone rank). mod() applies the cost; the HUD drains it to half colour.
func reduced() -> bool:
	return overdriven or (helpless() and not stopped())


func _count_fury() -> void:
	if helpless():
		fury_acts += 1  # a skill use under Mindless Fury


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
	if reading > 0:
		return _held_fx(viewer).all
	return _gather_effects(viewer)


# While a read is under way, or any other stretch that changes no one's effects (begin_read()/end_read(): reading > 0),
# what _effects() found for each viewer (null: none), kept for the stretch's length with its effects listed by stat
# (_stat_fx()): a read changes no one's effects, and asks for the same few units' stats dozens of times. It holds only
# while the unit stands where it was (a planning step on another tile, Battle.standing(), has other ground's effects),
# and it is dropped as the outermost stretch begins (_epoch), so nothing carries from one to the next.
var _fx := {}  # viewer -> {all: [effect, rank, strength]..., by: {stat: the same, of that stat}}
var _fx_epoch := -1
var _fx_at: Variant
var _fx_ground: Terrain
var _fx_steady: Variant
static var reading := 0
static var _epoch := 0


func _held_fx(viewer: Unit) -> Dictionary:
	if _fx_epoch != _epoch or _fx_at != cell or _fx_ground != footing or _fx_steady != steadied:
		_fx.clear()
		_fx_epoch = _epoch
		_fx_at = cell
		_fx_ground = footing
		_fx_steady = steadied
	var held: Variant = _fx.get(viewer)
	if held == null:
		held = {all = _gather_effects(viewer), by = {}}
		_fx[viewer] = held
	return held


# What _effects() holds for s alone, in the order it holds them (the same sum comes out); in a stretch only.
func _stat_fx(s: StringName, viewer: Unit) -> Array:
	var held := _held_fx(viewer)
	var by: Dictionary = held.by
	if s not in by:
		var some := []
		for pair in held.all:
			if StringName(pair[0].stat) == s:
				some.append(pair)
		by[s] = some
	return by[s]


# Begins a stretch in which nothing's effects change (a read, or a planning loop of reads: suspicious(), the AI's
# weighing of its options before it acts). Nest freely; end each with end_read(). Anything that changes a unit's
# passives, timed effects or items must not happen inside one.
static func begin_read() -> void:
	if reading == 0:
		_epoch += 1
	reading += 1


static func end_read() -> void:
	reading = maxi(reading - 1, 0)


func _gather_effects(viewer: Unit) -> Array:
	var out := []
	var own := {}
	var modded := emblems()
	for x in on_passives:
		var m := mods(x.skill) if modded else Modifiers.NONE
		for e in x.skill.effects:
			out.append([e, x.rank, 1.0] if m.empty() else m.effect(e, x.rank))  # its modifiers (Modifiers.effect())
			own[e] = true
	for e in timed:
		if e not in own and not (viewer and viewer in timed[e].known_to):
			out.append([e, timed[e].rank, timed[e].strength(e)])
	if footing and not (steadied != null and steadied == cell):
		for e in footing.effects:
			out.append([e, 1, 1.0])
	for it in items():
		for e in it.effects:
			out.append([e, it.ranked(), 1.0])
	if bio:
		for p in bio.properties:
			for e in p.effects:
				out.append([e, 1, 1.0])
	return out


# The reserve shown first above Energy: the one it runs on (runs_on(): Mana, Stamina), else the one it
# spends from with the largest pool (Icor: mana); null if none.
func main_reserve() -> Reserve:
	var all := held_reserves()
	return all[0] if not all.is_empty() else null


# The reserves it holds to pay with, as its bars show them: the one it runs on first, then every other
# it spends from (spends(): Mana switched off holds none), largest pool first (a Ranger on Stamina: then
# Focus).
func held_reserves() -> Array[Reserve]:
	var all := pools()
	var out: Array[Reserve] = []
	out.assign(all.keys().filter(spends))
	var on: Reserve = runs_on() if runs_on() is Reserve else null
	out.sort_custom(func(a: Reserve, b: Reserve): return a == on or (b != on and all[a] > all[b]))
	return out


# Whether it holds Energy to pay with, as its bars show it: always, unless it runs on a reserve - then
# only Energy that came some other way (`now`: how much it has, or seems to).
func holds_energy(now: int) -> bool:
	return runs_on() is StringName or now > 0


# Puts forward the look its skills carry (Alluring), on top of its own: a stance if it has none, and
# their vibe words, tags and name pools.
func _take_looks() -> void:
	for x in slots:
		var s := x.skill
		if not s.has_look() or not equipped(s):
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
	_colour_pools()
	hp_bar.add_theme_stylebox_override("fill", _flat(HP_COLOR))
	hp_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_border_width_all(1)
	trim.add_theme_stylebox_override("panel", box)


# Colours the Energy and reserve bars for what it holds now (held_reserves()): it can change mid-battle
# (a switch of what it runs on).
func _colour_pools() -> void:
	var held := held_reserves()
	var main: Reserve = held[0] if held.size() > 0 else null
	energy_bar.add_theme_stylebox_override("fill", _flat(POWER_COLOR if powered() else ENERGY_COLOR))
	energy_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	energy_bar.modulate.a = 0.45 if main else 1.0
	if main:
		reserve_bar.add_theme_stylebox_override("fill", _flat(main.color))
		reserve_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	if held.size() > 1:  # a second reserve it holds (a Ranger's Focus beside its Stamina): a bar of its own
		if not second_bar:
			second_bar = reserve_bar.duplicate()
			second_bar.name = &"SecondReserveBar"
			reserve_bar.add_sibling(second_bar)
		second_bar.add_theme_stylebox_override("fill", _flat(held[1].color))
		second_bar.add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))
	for i in range(2, held.size()):  # and one more sliver for each further reserve
		if more_bars.size() < i - 1:
			var bar: ProgressBar = reserve_bar.duplicate()
			bar.name = "ReserveBar%d" % (i + 1)
			reserve_bar.add_sibling(bar)
			more_bars.append(bar)
		more_bars[i - 2].add_theme_stylebox_override("fill", _flat(held[i].color))
		more_bars[i - 2].add_theme_stylebox_override("background", _flat(Color(0, 0, 0, 0.5)))


# High contrast: the faction trim around the bars is two pixels thick, not one.
func _heavy_trim(on: bool) -> void:
	var box := trim.get_theme_stylebox("panel") as StyleBoxFlat if trim else null
	var w := 2 if on else 1
	if box and box.border_width_left != w:
		box.set_border_width_all(w)
		_stack()


# Stacks the visible bars from the bottom up, with the trim one pixel (two, in high contrast) out around them.
func _stack() -> void:
	var bottom := -sprite.sprite_frames.get_frame_texture(&"default", 0).get_height() / 2.0 - 2.0
	var y := bottom
	var stack := [[energy_bar, 2.0]]
	for bar in more_bars:
		stack.append([bar, 1.0])
	stack.append_array([[second_bar, 2.0], [reserve_bar, 2.0], [hp_bar, 4.0]])
	for pair in stack:
		var bar: ProgressBar = pair[0]
		if bar and bar.visible:
			bar.size = Vector2(BAR_WIDTH, pair[1])
			bar.position = Vector2(-BAR_WIDTH / 2.0, y - pair[1])
			y -= pair[1]
	trim.visible = y < bottom
	var out := float((trim.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left) if trim.has_theme_stylebox_override("panel") else 1.0
	trim.position = Vector2(-BAR_WIDTH / 2.0 - out, y - out)
	trim.size = Vector2(BAR_WIDTH + 2.0 * out, bottom - y + 2.0 * out)


# How the player's side sees it (the HUD calls this; until then it's drawn as it is). Not located:
# not drawn at all. Located with its side unknown: in its own colours, but with no side colours and no bars -
# or, when it hides or stands in concealment, a black shape (Read.silhouette()). A trick it suspects in
# plain view shows as if unaffiliated - its own colours, a neutral glow - until seen through (Read.mark()).
# Otherwise it wears the side it shows as - its own, or one a persona claims - with bars for
# whatever of HP, energy and reserves can be made out. A persona posing as someone shows that
# name's stand-in sprite instead of its own. null: as it is.
# How saturated its sprite is (1 full colour .. 0 greyscale): the HUD drains it on the player's units
# as their AP runs low, and all the way once they can't be commanded this turn (HUD.command_sat()).
func set_saturation(v: float) -> void:
	_sat = v
	if sprite and sprite.material:
		sprite.material.set_shader_parameter(&"saturation", v * (DOWN_SAT if dbno else 1.0))


var _sat := 1.0  # the saturation the HUD last asked for (set_saturation())


# Downed (down but not out): the sprite lies over on its side, lowered a little, and drains of colour;
# standing again, upright. Every observer sees it: it's what the unit looks like, not what's known of it.
func _lie() -> void:
	var down := dbno != null
	sprite.rotation = DOWN_TILT * (1.0 if (cell.x + cell.y) % 2 == 0 else -1.0) if down else 0.0  # which way, by its cell
	sprite.position.y = 3.0 if down else 0.0
	set_saturation(_sat)


# How strongly it glows: at one of the four strengths (`level`, an Intensity: brighter and larger
# the stronger), or its plain glow (-1: the HUD has nothing to say of it). Stronger again in high
# `contrast`.
func set_glow(level: int, contrast := false) -> void:
	_heavy_trim(contrast)
	if glow.visible:
		var mult := INTENSITY[level] if level >= 0 else 1.0
		glow.modulate.a = clampf(GLOW * mult * (CONTRAST_GLOW if contrast else 1.0), 0.0, 1.0)
		glow.scale = Vector2.ONE * (INTENSITY_SIZE[level] if level >= 0 else 1.0)


func appear(r: Read) -> void:
	shown = r
	visible = r == null or r.located()
	var doubt := r != null and r.mark() == Read.Mark.DOUBT  # a trick it suspects: as if unaffiliated
	if r == null:
		_show_side(faction, false, false)
	else:
		_show_side(null if doubt else r.faction, r.faction == null or doubt, r.silhouette())
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
	var held := held_reserves()
	var main: Reserve = held[0] if held.size() > 0 else null
	var seen := r == null or r.energy != null  # what can be made out of its energy and reserves
	_colour_pools()
	hp_bar.visible = r == null or r.hp != null
	energy_bar.visible = seen and holds_energy(r.energy if r and r.energy != null else energy)
	reserve_bar.visible = main != null and seen
	if second_bar:
		second_bar.visible = held.size() > 1 and seen
		if second_bar.visible:
			second_bar.max_value = maxi(pools()[held[1]], 1)
			second_bar.value = r.stores.get(held[1], 0) if r else store(held[1])
	for i in more_bars.size():
		var more := more_bars[i]
		more.visible = held.size() > i + 2 and seen
		if more.visible:
			more.max_value = maxi(pools()[held[i + 2]], 1)
			more.value = r.stores.get(held[i + 2], 0) if r else store(held[i + 2])
	hp_bar.max_value = r.max_hp if r and r.hp != null else max_hp
	hp_bar.value = r.hp if r and r.hp != null else hp
	energy_bar.max_value = maxi(max_energy, 1)
	energy_bar.value = r.energy if r and r.energy != null else energy
	if main:
		reserve_bar.max_value = maxi(pools()[main], 1)
		reserve_bar.value = r.stores.get(main, 0) if r else store(main)
	_stack()


func _show_faction() -> void:
	_show_side(faction, false, false)


# Stand-in art: a faint glow of the side's primary behind the sprite; the bars get its primary,
# darkened, as trim and its secondary behind HP. One whose side can't be told (shape) glows neutral grey;
# `dark`, it's painted black as well: a silhouette, what might be a monster in the brush.
func _show_side(f: Faction, shape: bool, dark: bool) -> void:
	sprite.modulate = SHAPE if dark else Color.WHITE
	glow.visible = shape or f != null
	if glow.visible:
		glow.modulate = Color(SHAPE_EDGE if shape else f.primary, GLOW)
		glow.scale = Vector2.ONE
	var edge := f.primary if f else SHAPE_EDGE  # no side to tell: neutral trim, so a lie's colours don't linger
	hp_bar.add_theme_stylebox_override("background", _flat(f.secondary if f else SHAPE_EDGE.darkened(0.5)))
	(trim.get_theme_stylebox("panel") as StyleBoxFlat).border_color = edge.darkened(TRIM_DARKEN)


# A mark that pops over it and fades within about a second (MARK_TIME): what the player's side has
# just come to think of it ("?" suspected, "!" seen through: HUD._show_units()). The latest is mark.
func pop_mark(text: String, colour: Color) -> void:
	if mark and is_instance_valid(mark):
		mark.queue_free()
	mark = Label.new()
	mark.text = text
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override(&"font_size", 16)
	mark.add_theme_color_override(&"font_color", colour)
	mark.add_theme_constant_override(&"outline_size", 4)
	mark.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.z_index = 10
	mark.size = Vector2(16, 18)
	mark.pivot_offset = mark.size / 2.0
	mark.position = Vector2(-8, -39)  # above its bars
	add_child(mark)
	mark.scale = Vector2.ONE * 0.4
	var tw := mark.create_tween()
	tw.tween_property(mark, ^"scale", Vector2.ONE * 1.25, MARK_TIME * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mark, ^"scale", Vector2.ONE, MARK_TIME * 0.1)
	tw.tween_interval(MARK_TIME * 0.35)
	tw.tween_property(mark, ^"modulate:a", 0.0, MARK_TIME * 0.4)
	tw.tween_callback(mark.queue_free)


func _flat(c: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = c
	return box
