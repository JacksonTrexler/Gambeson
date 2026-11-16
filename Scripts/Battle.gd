class_name Battle
extends Node2D

signal phase_changed(was: Phase, now: Phase)
signal turn_changed(was: Faction, now: Faction)
signal initiative_rolled(rolls: Dictionary[Faction, Array])
signal traveled(u: Unit, from: Vector2i, path: Array[Vector2i])
signal used(caster: Unit, skill: Skill, at: Variant, dealt: int)  # at: the target Unit, or a cell
signal sprung(c: Vector2i, by: Unit)
signal marked(c: Vector2i, u: Unit, mark: Mark)  # u triggered a mark on c (_trigger()): its effects went on
signal toll_paid(u: Unit, hp: int)  # u lost hp walking (a per_tile effect, travel())
signal attacked(caster: Unit, target: Unit, d20: int, total: int, defense: int)  # an attack roll (cast())
signal layer_broke(c: Vector2i, what: Terrain, by: Unit)  # a brittle layer broke (expose(), _teeter())
signal layer_lifted(c: Vector2i, what: Terrain, why: StringName)  # a layer burned (fire) or blew (wind) away
signal teetered(u: Unit, total: int, dc: int, kept: bool)  # glass gave way under u; kept: it caught itself
signal evaded(u: Unit, total: int, dc: int, share: float)  # u tried to dodge: share is how much still landed (evade())
signal meditated(u: Unit, room: int)  # a Meditation done: u may shift each stat up to room (respec())
signal respecced(u: Unit, changes: Dictionary)
signal bound(by: Unit, u: Unit, it: Item)  # a binding item (Shackles) put on u in place of its trinket (_bind())
signal freed(u: Unit, how: StringName, total: int, dc: int, done: bool)  # u worked at its shackles: unlock, pick or pry (unshackle())
signal mended(c: Vector2i, into: Terrain)  # a cracked startile finished repairing
signal contested(caster: Unit, target: Unit, total: int, against: int)  # a contest in place of one (Drown): won when total >= against
signal investigated(by: Unit, of: Unit, skill: Skill, total: int, against: int, close: bool)  # investigate(): seen through when total >= against
signal stalled(u: Unit, rank: int)  # u stalls the fight: Ramut's Ire builds on it, to this rank (_check_stall())
signal struggled(u: Unit, by: Unit, total: int, against: int)  # u, held, tries to move away from by's grip (_break_free()): free when total > against
signal driven(u: Unit, by: Unit, tags: Array[StringName], went: int, hit: bool)  # u was forced to move (displace()): went tiles, its tags (shove, fear, entrance) riding on it; hit: it was stopped short by a unit or the edge and took the blow
signal gripped(u: Unit, by: Unit, dealt: int)  # u, still held as its turn ends, takes by's grip (_grip())
signal inspected(by: Unit, at: Vector2i, total: int, against: int)  # inspect(): by grows suspicious of the tile when total >= against
signal prayed(u: Unit, god: StringName, rank: int)  # pray(): u prays to its god (Pray)
signal untangled(by: Unit, of: Unit, total: int, against: int)  # inspect(): by, under Haluca, sees of's tags straight when total >= against
signal refused(u: Unit, leader: Unit)  # a traitor in leader's party won't do as it's told, or acted on its own side's turn (_refuse())
signal doubted(by: Unit, of: Unit, total: int, against: int)  # doubt(): by grows suspicious of `of` when total >= against
signal told(by: Unit, to: Unit, of: Unit, heard: bool)  # spread(): by told an ally it suspects `of`; heard: the word got through
signal discovered(by: Unit, of: Variant)  # suspect(): by's first stack of suspicion of a unit or tile: something odd about it ("?")
signal unmasked(by: Unit, of: Variant, was: Read)  # suspect(): by now sees through what fooled or hid it; was: by's read before ("!")
signal vanished(by: Unit, of: Unit, was: Read)  # of slipped from by's sight before its very eyes (_vanish()); was: by's read before ("!?")
signal bumped(u: Unit, into: Unit)  # u's walk was stopped short by `into`, a unit it couldn't place: a recon level on it (travel(), note())
signal evaluated(u: Unit, skill: Skill, d20: int, total: int)  # an ally's Self-evaluation saw a roll u made using skill (evaluators())
signal downed(u: Unit)  # u took mortal damage with a heart left: it gets up as the turn ends (_on_downed())
signal dbno_changed(u: Unit, how: StringName)  # u is Downed (&"down": down but not out, Scripts/Downed.gd), was &"saved", or died of it (why: Downed.succumb())
signal held_fire(u: Unit, ally: Unit)  # u was about to attack an ally it couldn't tell for one, and caught itself (_holds_fire())
signal borrowed(u: Unit, how: StringName)  # a deferred death (the defer stat: Borrowed Time): &"begin", &"replay", &"survived", &"executed" (_borrowed())
signal revived(u: Unit, summoned: Unit)  # u got up, a heart spent; summoned: what came with it (a Regeneration Probe), or null
signal dropped(u: Unit, item: Item)  # u fell, leaving an item (its loot)
signal pulsed(u: Unit, healed: Dictionary)  # a Regeneration Pulse: unit -> HP it got back
signal channeled(u: Unit, skill: Skill, at: Vector2i)  # u began channeling a skill on a tile (Metea)
signal interrupted(u: Unit, ended: Array[StringName])  # what needed u's constant attention was broken off (interrupt(): Jam)
signal exploded(u: Unit, skill: Skill, at: Vector2i, hit: Dictionary)  # a channeled skill struck: unit -> damage taken
signal shattered(u: Unit, at: Vector2i)  # u broke a starpane, bludgeoning it
signal sapped(u: Unit, drained: Dictionary)  # Starsap: unit -> Energy (or HP) u drained from it
signal reverted(was: Unit, now: Unit)  # a Starman fell back into a Starmote
signal reformed(was: Unit, now: Unit)  # a Starmote reformed into a Starman
signal burned(u: Unit, hp: int, why: String)  # u took fire from a flame, a burning slot or a burning item
signal perfect(u: Unit)  # 36 Strike hits in a row: u healed PERFECT_HEAL
signal chanted(u: Unit, rank: int)  # u waited its turn out and chanted (Chant)
signal leveled(caster: Unit, target: Unit, levels: int)  # Level Down took levels off target (0: none)
signal shaped(u: Unit, form: StringName, element: StringName)  # u took a beast's form (Beastshape), or its own back (form "")
signal disciplined(u: Unit, burned: int)  # u burned AP into an attack (Discipline)
signal neutralized(u: Unit, by: Unit, how: StringName)  # taken out of the fight (neutralize()): &"downed", &"down" (Downed), &"killed"; by: who last hit it
signal gained_xp(u: Unit, n: int, levels: int, from: Unit, saved: bool)  # u earned n XP from `from` falling, or being brought back (saved), and levels (Unit.gain_xp())
signal reacted(u: Unit, skill: Skill, r: Behaviour.Reaction)  # u's passive reacted to a moment (react()): r.trigger, r.subject, r.by
signal interrupt_began(u: Unit)  # u acts out of turn (grant_interrupt(): Final Act); the turn under way waits
signal interrupt_ended(u: Unit)  # ...and the interrupted turn resumes

enum Phase { INITIATIVE, TURNS, OVER, PREP }  # PREP: before the initiative roll, the player looks the field over (study()), then begin()s

# Terrain loaded when the class first runs, not preloaded: a Terrain's effects reach back to Battle
# (Effect's text), so a compile-time preload here can catch Terrain.gd mid-compile.
static var PLAIN: Terrain = load("res://Terrain/grass.tres")  # tiles with no terrain set
const UNIT := preload("res://Scenes/unit.tscn")
const MEDIUM := 3  # size assumed for a target not yet chosen
const PASS_SHARE := 0.1  # of the size penalty for moving through a unit, taken off per point of dex mod
const DISCIPLINE_HIT := 2  # to hit, a point of Discipline (discipline_points())
const DISCIPLINE_DAMAGE := 0.1  # more damage, a point of Discipline per point of the attack's stat mod (at least 1)
const PERFECT_HITS := 36  # Strike hits in a row (Strike!'s three) for a Perfect...
const PERFECT_HEAL := 300  # ...healing this much at once, true (_chain())
const SLAM := 2  # blunt HP for each tile of a push stopped short by a unit or the map's edge (displace())
const DRIVES := {&"shove": 1, &"fear": 1, &"entrance": -1}  # the Effect stats that move their holder: away (1) or toward (-1) whoever put them on (drive())
const PULSE_REACH := 3  # tiles a Regeneration Pulse reaches (_pulse())
const WORD := 4  # tiles (+ its cha mod) within which a unit tells its allies what it's grown suspicious of (spread())
const XP_NEAR := 3.0  # tiles from a unit falling or brought back within which others get a share of its XP (_share())
const RECAST_LIMIT := 20  # recasts on a natural 20 in a row (Jugular: "without limit for now"), a guard on a rigged rng
var _recasts := 0
var _resolving: Array[Behaviour.Cast] = []  # casts under way, innermost last: told when their target is neutralized (felled())
var _aimed: Dictionary[Unit, Dictionary] = {}  # caster -> {target: times it used a skill on it} this battle (aimed())
var _reacted: Dictionary[Unit, Dictionary] = {}  # holder -> {passive: times it reacted this battle} (times_reacted())
var interrupter: Unit  # acting out of turn (grant_interrupt()): while set, only it acts (_acting())
var directed := Callable()  # (unit) -> bool: a person picks that unit's interrupt (the HUD sets it for the player's side); unset, every unit's is the AI's
var _interrupts: Array = []  # [unit, actions] waiting their turn to interrupt, first first
var _interrupt_left := 0  # actions the interrupter has left
var _interrupt_ap: AP  # the free AP its skill uses are paid from, taken back as it ends
var _picked: Array[Unit] = []  # the units the outermost cast()'s caster picked by hand
var _wears: Array[Exhaustion.Wear] = []  # uses paid for in the cast under way, settled as the outermost is done (_settle_wear(): Behaviour.wearing())
var _aims: Array[Unit] = []  # whom each cast() under way is aimed at, innermost last
var _casting := 0  # cast() / cast_at() calls under way: an interrupt opens once the outermost is done
var _reacting := 0  # react() calls under way: an interrupt granted in one opens after it
var _settling: Unit  # falling after its interrupt (_settle())
const INTERRUPT_AP := 99.0  # a free action: AP enough for any skill, for skill uses only
const STAR_SLOW := 2.0  # Power back on the star lattice, x its usual resting rate: linked to a source with any Power in it...
const STAR_FAST := 5.0  # ...up to a full one (an empty source gives nothing)
const STAR_ENERGY := 0.3  # regular Energy gets this share of what the boost adds (+10 for Power: +3)
const STAR_CAPACITY := 20  # Power a starpower source holds full
static var STARPANE: Terrain = load("res://Terrain/starpane.tres")
static var STARTILE: Terrain = load("res://Terrain/startile.tres")
static var FLOOD: Terrain = load("res://Terrain/flood.tres")  # laid by Battle.flood(), a copy per depth
static var STONE: Terrain = load("res://Terrain/stone.tres")  # an Emergency Exit's pocket
const POCKETS := Vector2i(1000, 0)  # where pockets lie: on the map, out of reach but through their doors
const RIFT_FORMATION := "res://Formations/undine_and_sirens.tres"  # what comes out of a Rift's domain
var pockets: Array[Pocket] = []
var demons: Faction = load("res://Factions/demons.tres")
const REPAIR_COST := 0.05  # of a source's capacity, drawn to begin mending a cracked startile
const REPAIR_SPAN := 20.0  # a source reaches (how full it is, in %) / this tiles to mend from: 5 when full
const SICKNESS: Effect = preload("res://Effects/resurrection_sickness.tres")
const REFORMING: Effect = preload("res://Effects/reforming.tres")
const ASPHYXIA: Effect = preload("res://Effects/asphyxia.tres")

@export var spawns: Dictionary[Faction, Vector2i] = {}  # where a player's starter joins each side
@export var rewards: Array[Item] = []  # what the player's side gets for winning (the victory screen; Game.stash)

var player: Unit  # the starter made on the entry screen; null when there's none
var spoils: Array = []  # [item, the side of whoever dropped it], as units fall (_on_died())
var fallen: Array[Unit] = []  # down with a heart spent, getting up as the turn ends (_on_downed())
@export var companions: Array[Role] = []  # starters of these classes join the fight beside the player, as their own side, but the player's class's (the Astral Envoy)
@export var companion_side: Faction  # theirs: allied with the player's (Faction.sides_with_player)
@export var companion_cells: Array[Vector2i] = []  # where they stand, in order
@export var starpanes: Array[Vector2i] = []  # tiles the star lattice crosses: starpanes, joined side-on to their neighbours (the Astral Envoy)
@export var starpower: Dictionary[Vector2i, float] = {}  # starpower sources on the lattice -> how full each starts (0 to 1)
var panes: Dictionary[Vector2i, bool] = {}  # starpanes still whole: a bludgeoning skill used on one with no target breaks it (attempt())
var charge: Dictionary[Vector2i, int] = {}  # Power in each starpower source, up to STAR_CAPACITY (Starsap fills them)

@export var prep := false  # the battle opens in Phase.PREP (as one started from the entry screen does: Game.starter.prep)
var studied: Dictionary[Faction, Dictionary] = {}  # what each side studied in preparation (study()): unit or tile -> recon levels more it reads it at
var noticed: Dictionary[Unit, Dictionary] = {}  # recon a unit has gained on its own (note()): unit -> {unit or tile -> recon levels more it reads it at}
var studied_allies: Dictionary[Faction, Array] = {}  # which of those it studied as allies (studies_left())
var phase := Phase.INITIATIVE:
	set(v):
		if v == phase:
			return
		var was := phase
		phase = v
		phase_changed.emit(was, v)  # before _enter, so a chained change arrives in order
		_enter(v)

var ending_turn := false  # inside end_turn(): a side falling now doesn't pass the turn, end_turn() does

# Whose turn it is. Its units get fresh AP and movement as it starts.
var turn: Faction:
	set(v):
		if v == turn:
			return
		var was := turn
		turn = v
		turns_begun += 1
		for u in members(v):
			u.refresh()
			if u.channel:
				u.channel.turns += 1
		for u in members(v):
			_look_harder(u)
			_starkind(u, false)
		turn_changed.emit(was, v)
		for u in members(v):  # after the signal: poison can end a side, and with it this turn
			_mend(u)

var order: Array[Faction] = []  # turn order, highest initiative first
var rolls: Dictionary[Faction, Array] = {}  # this battle's initiative d20s, per faction
var unit_rolls: Dictionary[Unit, int] = {}  # the same d20s, by who rolled them

# Which unit stands on which cell. TileSet custom data is per tile type, so it can't hold this.
var units: Dictionary[Vector2i, Unit] = {}
var inside: Dictionary[Unit, Unit] = {}  # a mist sharing another unit's tile -> that unit (Coalescing: engulf()); units[] keeps the other

var rng := RandomNumberGenerator.new()
var zones: Array[Zone] = []  # areas laid by skills (Darkstone's darkness)
var revealed: Dictionary[Vector2i, bool] = {}  # sprung traps: no longer concealed
var _seers: Array[Unit] = []  # units that began a Clairvoyance channel, while they hold it (pinged())
var _blind_to_pings := false  # while ping() asks what its side sees without them
const IRE: Skill = preload("res://Skills/ramuts_ire.tres")

# Ramut's Ire waits out this many stalled turns in a row, times the units still standing on the smallest
# side (stealth missions, quieter battles: more; < 0: never; _check_stall()).
@export var ire_grace := 1.0
var stalled_turns: Dictionary[Faction, int] = {}  # each side's turns in a row ended with none of its units making out a foe
var hastened: Dictionary[Faction, int] = {}  # turns taken off each side's wait for the Ire (Pray, to Ramut)
var turns_begun := 0  # sides' turns started so far this battle: when an effect was put on (Unit.Applied.since)
var stalling: Array[Unit] = []  # units stalling the fight as the last turn ended: Ramut's Ire builds on them (_check_stall())
var snares: Dictionary[Vector2i, Snare] = {}  # traps units have laid (lay()), over the ground
var debris: Dictionary[Vector2i, Debris] = {}  # evidence hiding units leave behind (_scatter())
var flames: Dictionary[Vector2i, Flame] = {}  # tiles on fire (Flamewall)
var layers: Dictionary[Vector2i, Array] = {}  # cell -> the layers laid over its ground, top first (lay_layer())
var _concealed_tiles: Array = []  # [source, atlas coords, alternative] of the map's concealed tiles, after a first entry marking them looked for (_maybe_hidden())
var _views: Dictionary[Vector2i, Terrain] = {}  # terrain() of a stacked cell, until its stack changes
@export var stacked: Array[TileStack] = []  # layers the scene lays at the start, bottom-up (leaves, glass...)
var marks: Dictionary[Vector2i, Array] = {}  # cell -> the Marks laid on it, oldest first (lay_mark()): one-use tile effects, disturbed earth
@export var lasting: Array[Faction] = []  # sides that stay in the fight with nobody standing (the Meadows' demons, who keep coming): the battle doesn't end for want of them
@export var sight := true  # units perceive only within their wisdom total in tiles, and make out appearances within half that, the range shared across their side (in_range(); Perception.unit()). Off: no limit
var sighted_when: Dictionary[Faction, Dictionary] = {}  # side -> {foe: {since: turns_begun then, moves: its movement as read, 0 unread}}: how stale a sighting is, and how far the foe could have got since (AI.clues())
var attacks: Dictionary[Faction, Array] = {}  # side -> [{tiles: where an attacker it couldn't place could have struck from, since}] (_note_attack())
var swept: Dictionary[Faction, Dictionary] = {}  # side -> {tile: turns_begun when one of its units last searched it} (search())
var sightings: Dictionary[Faction, Dictionary] = {}  # side -> {foe: where it last made it out}: where its units go looking when none is in sight (AI._hunt())
@export var conditions: Array[StringName] = []  # the area's conditions: fog halves perception distances
@export_range(0.5, 1.5, 0.5) var difficulty := 1.0  # the area's difficulty (Difficulty.area()): 0.5 gentle, 1 standard, 1.5 harsh - spawn caps, portals (the Meadows)
var winner: Faction  # a side that won outright (escape()), whoever's still standing
@export var area_tags: Array[StringName] = []  # what the whole battlefield is (indoors, city, forest, desert...): debris where its tiles say nothing

# What a hiding unit leaves on the ground, by the tags of the tile (then the area): the first that
# matches. Tiles matching none get none.
const DEBRIS_KINDS := [
	[[&"stone", &"indoors", &"city"], "Rubble"],
	[[&"tree", &"outdoors"], "Leaves"],
	[[&"grass", &"shrubbery", &"forest"], "Disturbed foliage, twigs"],
	[[&"mud", &"snow", &"sand", &"mountains", &"desert", &"taiga"], "Depressions"],
]
const HIT_TURNS := 6  # turns an attack from an unseen foe stays a clue to where it is (attacks_on())
const SWEEP_TURNS := 4  # turns a tile its side searched counts as looked over: no guessing there (AI.clues())
const CLEAN_HIDE := 15  # a hiding roll this high or more is a good job: little debris, further off
const FAIR_HIDE := 10  # ...this high, a middling one; below it, a poor one
# By how well it hid (good, middling, poor): [fewest, most] debris left, and [nearest, furthest] tiles off.
const LITTER := [[[1, 2], [2, 4]], [[2, 3], [1, 3]], [[3, 4], [1, 2]]]
const HAZARD_TILES := 2.0  # steering: movement a point of foreseen HP loss weighs as (a 3.5 damage trap, a 1d6, is a 7 tile detour; tuned by the sims, docs/plans/path-foresight.md); AP loss weighs 1 a point
const SUSPECT_TILES := 3.0  # movement a tile it suspects hides something (Read.hint: "disturbed earth?") weighs, at least; the AI used to count one as 10
const HELP_PULL := 0.75  # movement a tile with a known helpful mark (Charge!) takes off a step onto it, in route() and the AI's approach: less than a tile, so it only tips a choice
const STEER_MARGIN := 2  # tiles either side of its straight run that a steered route may wander (route())
const EARTHWORK_COST := 1.5  # disturbed earth (earthwork()): what entering it costs its side's enemies, times the usual


# Evidence a unit left hiding: whoever can make out the tile sees it (but not who left it).
class Debris:
	var kind: String
	var by: Unit
	var faction: Faction
	var since: int
	var far := 4  # how far off it could have been left: past this + its hider's dex mod, the trail's gone cold

	func _init(k: String, u: Unit, t: int) -> void:
		kind = k
		by = u
		faction = u.faction
		since = t


# A mark laid on a tile (lay_mark()): effects put on whoever triggers it, a trigger and a lifetime, so
# later skills lay their own without a kind of their own (Warcry's Charge! and Routed!, disturbed earth
# from Pray). `on`: &"enter" as a unit walks onto the tile (travel(), place()) or &"end" as its turn ends
# there. `who` says whom it triggers on, from its side's view: &"allies", &"foes" or &"any". A trigger puts
# each of `effects` on the unit (at `rank`, for the effect's own turns or `effect_turns`) and uses it up,
# when `uses` runs out (0: it keeps going till its turns do). It lasts `turns` of its side's turns.
# Entering costs those it triggers on `cost` more movement and `wade` times as much (stride()), and
# hazard() counts what a known one would do to a walker. Who knows it's there: its side and those told
# (`known`), everyone when its `concealment` is 0 (fire, Warcry's squares: plainly visible), else
# whoever reads the tile well enough (Perception.tile(), like a trap).
class Mark:
	var kind: StringName  # what it is (&"charge", &"routed", &"earthwork"): its name's key and look
	var name := ""
	var by: Unit
	var faction: Faction
	var effects: Array[Effect] = []
	var rank := 1
	var who := &"any"
	var on := &"enter"
	var turns := 3
	var uses := 1
	var effect_turns := 1  # how many turn-ends its effects last on whoever triggers it: 1 is until its turn ends
	var cost := 0.0
	var wade := 1.0
	var concealment := 0
	var known: Dictionary[Unit, bool] = {}
	var tint := Color.WHITE  # how it's drawn (Overlay): its colour and whether it swells (1), shrinks (-1) or stays (0)
	var swell := 0

	func _init(k: StringName, u: Unit, f: Faction = null) -> void:
		kind = k
		name = String(k).capitalize()
		by = u
		faction = f if f else (u.faction if u else null)

	# Whether it triggers on u: by `who`, as its side sees u.
	func hits(u: Unit) -> bool:
		match who:
			&"allies":
				return Faction.friends(u.faction, faction)
			&"foes":
				return not Faction.friends(u.faction, faction)
		return true

	# Whether o is simply told of it: its side, or someone it was passed word to. Everyone, if nothing hides it.
	func told(o: Unit) -> bool:
		return concealment <= 0 or Faction.friends(o.faction, faction) or o in known

	# Whether it would do u good to step onto it: it triggers on u, harms it nowhere, and puts something helpful on it.
	func helps(u: Unit) -> bool:
		return on == &"enter" and hits(u) and not harms(u) and effects.any(func(e: Effect): return e.helps() > 0)

	# Whether it would hurt u to step onto it: it triggers on u, and costs it movement or puts a harmful effect on it.
	func harms(u: Unit) -> bool:
		return on == &"enter" and hits(u) and (cost > 0.0 or wade > 1.0 or effects.any(func(e: Effect): return e.helps() < 0))


# A tile on fire (Flamewall): whoever enters it, or ends its turn on it, takes 1d8 + its setter's wis
# mod in fire. Burns out after its setter's side's turns.
class Flame:
	var by: Unit
	var faction: Faction
	var turns: int
	var bonus: int

	func _init(u: Unit, t: int) -> void:
		by = u
		faction = u.faction
		turns = t
		bonus = u.mod(&"wisdom")


# A trap a unit laid on a tile. Who knows of it sees it plainly; with Hazard Expert (`word`), its
# setter's allies who weren't told still get a vibe that traps were set there.
class Snare:
	var terrain: Terrain  # the ground with the trap in it, standing in for the map's (Battle.terrain())
	var by: Unit
	var faction: Faction
	var known: Dictionary[Unit, bool] = {}
	var word := false

	func _init(t: Terrain, u: Unit) -> void:
		terrain = t
		by = u
		faction = u.faction


# Concealment laid over tiles: levels by cell, lasting some of the caster faction's turns.
class Zone:
	var kind: StringName
	var levels: Dictionary[Vector2i, int]
	var turns: int
	var faction: Faction
	var allied := false  # conceals only its side's units in it, and not the ground (Pray, to Luun)

	func _init(k: StringName, l: Dictionary[Vector2i, int], t: int, f: Faction, a := false) -> void:
		kind = k
		levels = l
		turns = t
		faction = f
		allied = a

# A layer laid over a tile's ground (tile stacks): what it is, whether the ground beneath acts too, and
# how far a repair has come (a cracked startile).
class Pocket:
	var kind: StringName  # &"domain" (a Rift's) or &"refuge" (an Emergency Exit's)
	var by: Unit
	var skill: Skill
	var origin: Vector2i  # its door on the field
	var door: Vector2i  # its door inside
	var centre: Vector2i
	var cells: Array[Vector2i] = []
	var turns := -1  # its maker's side's turns left before it ends; -1: while its Rift is channeled, the count waiting until it stops
	var open := true  # the field door stands open
	var marks: Array = []  # PortalMarks: [the field door's, the escape portal's]


class Layer:
	var terrain: Terrain
	var passes: bool
	var rank := 0  # a Flood's depth
	var turns := 0  # its setter's side's turns left before it drains away (a Flood); 0: it lasts
	var faction: Faction  # whose turns count it down
	var repairing := 0  # rounds of mending done
	var repair_goal := 0  # rounds it takes - its distance from the source it draws on; 0: not begun
	var source: Variant = null  # that source's cell

	func _init(t: Terrain, through: bool) -> void:
		terrain = t
		passes = through

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	used.connect(func(caster: Unit, skill: Skill, at: Variant, _dealt: int): Downed.acted(caster, skill, at))  # a Downed unit's uses count (Grudge)
	for c in starpower:
		charge[c] = roundi(clampf(starpower[c], 0.0, 1.0) * STAR_CAPACITY)
		lay_layer(c, STARTILE, true)  # an overlay: the ground beneath still counts
	for c in starpanes:
		lay_layer(c, STARPANE, true)
	for st in stacked:
		for c in st.cells:
			lay_layer(c, st.terrain, st.passes())
	if Game.starter:
		prep = prep or Game.starter.get("prep", false)
		player = starter(Game.starter)
		$Units.add_child(player, true)
		_join_companions(Game.starter.role)
		Game.starter = {}  # used up
	for u: Unit in $Units.get_children():
		if u.with_player and player:
			u.faction = player.faction
			u._show_faction()
		if not move(u, u.cell):
			push_error("%s has no free cell at %s" % [u.name, u.cell])
			u.free()
			continue
		_listen(u)
	for u: Unit in units.values():
		for t: Unit in units.values():
			if u.faction and t.faction and not Faction.friends(u.faction, t.faction) and Perception.cover(self, t) == 0:
				sighted(u.faction, t, t.cell)  # each side knows where the others drew up in the open
	for u: Unit in units.values():
		_line_up(u)
	if prep:
		phase = Phase.PREP  # held there till begin()
	else:
		_enter(phase)


# A unit drawn up before the fight faces the nearest foe by faction (it has no facing yet), so the first
# blows have a front, flanks and a rear to land on; one with no foe in the field faces none.
func _line_up(u: Unit) -> void:
	if u.facing != Vector2.ZERO or not u.faction:
		return
	var near: Unit = null
	for t: Unit in units.values():
		if t.faction and not Faction.friends(u.faction, t.faction) and (near == null or Command.tiles(u.cell, t.cell) < Command.tiles(u.cell, near.cell)):
			near = t
	if near:
		u.face(near.cell)


# Preparation over: the initiative roll, and the first turn.
func begin() -> void:
	if phase == Phase.PREP:
		phase = Phase.INITIATIVE


# Studies o may still make in preparation: allies up to its cha mod, foes and tiles up to its wis mod
# (none below 0). ally: which kind.
func studies_left(o: Unit, ally: bool) -> int:
	var cap := maxi(o.mod(&"charisma" if ally else &"wisdom"), 0)
	var allies: int = studied_allies.get(o.faction, []).size()
	var done: int = allies if ally else studied.get(o.faction, {}).size() - allies
	return maxi(cap - done, 0)


# Whether studying k is an ally's kind of study: a unit that seems to be o's side's friend.
func _studies_ally(o: Unit, k: Variant) -> bool:
	if not (k is Unit) or not is_instance_valid(k):
		return false
	var f: Faction = read(o, k).faction
	return f != null and Faction.friends(f, o.faction)


# In preparation, o (the player) studies an ally, a foe or a tile: its side reads it a recon level
# better for the battle (_read()). A foe it scrutinizes besides, looking harder at one that fools it
# (doubt()); a tile, inspecting it (inspect()). False once it has no studies of that kind left
# (studies_left()), or for one already studied.
func study(o: Unit, k: Variant) -> bool:
	if phase != Phase.PREP or (k is Unit and k == o) or (k is Vector2i and not on_map(k)):
		return false
	var mine: Dictionary = studied.get_or_add(o.faction, {})
	if k in mine or studies_left(o, _studies_ally(o, k)) <= 0:
		return false
	var ally := _studies_ally(o, k)
	mine[k] = 1
	if ally:
		studied_allies.get_or_add(o.faction, []).append(k)
	if k is Vector2i:
		inspect(o, k)
	elif not ally and read(o, k).deceived:
		doubt(o, k)
	return true


# Hears what a unit on the field goes through: its falling, and the hits and heals its passives and
# others' have a say in (Unit.hooks(), Behaviour's hooks: Molothrus).
func _listen(u: Unit) -> void:
	u.died.connect(_on_died)
	u.downed.connect(_on_downed)
	u.dbno_changed.connect(_on_dbno)
	u.deferring.connect(_on_deferring)
	u.falling.connect(_on_falling)
	u.taking_hit.connect(_on_taking_hit)
	u.paid.connect(_on_paid)
	u.lost_skills.connect(_on_lost_skills)
	u.being_healed.connect(_on_being_healed)
	u.recovered.connect(_on_recovered)
	u.endurance = u.endurance_max()  # Recovery Endurance, fresh each battle (Burnout)


func _on_taking_hit(u: Unit, blow: Dictionary) -> void:
	_note_attack(u, blow)
	for h in u.hooks():
		blow.damage = h[0].hurt(self, u, h[1], blow.damage)


# Every recovery but regen (Unit.recovered): Burnout's rule.
func _on_recovered(u: Unit, pool: Variant, n: int) -> void:
	Burnout.recovered(self, u, pool, n)


func _on_being_healed(u: Unit, got: Dictionary) -> void:
	for o: Unit in units.values():
		if o != u and o.is_alive():
			for h in o.hooks():
				got.hp = h[0].healing(self, o, h[1], u, got.hp)


func unit_at(c: Vector2i) -> Unit:
	return units.get(c)


# The one place a unit's cell changes, so `units` and positions never drift apart.
func move(u: Unit, c: Vector2i) -> bool:
	var other := unit_at(c)
	if other and other != u:
		return false
	if inside.has(u):
		inside.erase(u)  # out of the tile it shared
	elif unit_at(u.cell) == u:
		units.erase(u.cell)
		_vacated(u.cell)
	u.cell = c
	units[c] = u
	u.position = map.map_to_local(c)
	if u.steadied != null and u.steadied != c:
		u.steadied = null  # it moved off the ground it caught itself over
	u.footing = terrain(c)
	u.ground = u.footing.tags
	return true


# The player's starter unit from the entry screen: {faction, role, name}, wearing what it had on
# (Game.outfit), with the hearts it's been given (Game.hearts).
func starter(s: Dictionary) -> Unit:
	var u := from_role(s.faction, s.role, s.name)
	u.level = clampi(Game.level, 1, Unit.MAX_LEVEL)  # its levels and XP from earlier battles; a point a level gained to learn its skills again
	u.xp = Game.xp
	u.skill_points = u.level - 1
	for slot in Game.outfit:  # what it had on last battle
		u.set(slot, Game.outfit[slot])
	refill(u)
	u.hearts += Game.hearts
	if not Game.equipped.is_empty():  # what it had equipped, once its bar is set up
		u.ready.connect(func(): u.set_equipped(Game.equipped), CONNECT_ONE_SHOT)
	assert(s.faction in spawns, "no spawn for %s" % s.faction.name)
	u.cell = spawns[s.faction]
	return u


# A level 1 unit of a class: its stats and reserves, on side f.
func from_role(f: Faction, role: Role, nick: String) -> Unit:
	var u: Unit = UNIT.instantiate()
	u.name = nick.validate_node_name()
	u.nick = nick
	u.faction = f
	u.role = role
	u.max_hp = Unit.CLASS_HP  # its levels bring the rest (Unit.level_hp())
	for k in role.stats:
		assert(k in Unit.CORE, "role stat %s isn't a unit stat" % k)
		u.set(k, role.stats[k])
	u.reserves.merge(role.reserves)
	return u


# The other starters join (companions): one of each class but the player's, in its starting items, on
# companion_side - allied with the player's side for this battle.
func _join_companions(mine: Role) -> void:
	if not companion_side or companions.is_empty():
		return
	if companion_side.sides_with_player:
		companion_side.allies.assign([player.faction])
	var i := 0
	for role in companions:
		if role == mine or i >= companion_cells.size():
			continue
		var u := from_role(companion_side, role, role.name)
		for slot in role.outfit():
			u.set(slot, role.outfit()[slot])
		u.cell = companion_cells[i]
		$Units.add_child(u, true)
		i += 1


# --- Initiative and tie-breaks

# Each living unit rolls a d20 and its faction sums them (+ Wary-style bonus); highest goes first.
func roll_initiative() -> Array[Faction]:
	rolls.clear()
	unit_rolls.clear()
	for u in units.values():
		if u.faction and u.is_alive():
			if u.faction not in rolls:
				rolls[u.faction] = []
			unit_rolls[u] = roundi(resolve(Check.check(0, 0)).d20 * (1.0 + u.stat(&"opening_ap")))  # a Dagger's edge counts here too
			rolls[u.faction].append(unit_rolls[u])
	for f in lasting:
		if f not in rolls:
			rolls[f] = []  # in the order with nobody standing yet (the Meadows' demons)
	var o: Array[Faction] = []
	o.assign(contest(rolls.keys(), [total]))
	print("Initiative: ", ", ".join(o.map(func(f): return "%s %d" % [f.name, total(f)])))
	initiative_rolled.emit(rolls)
	return o


func total(f: Faction) -> int:
	return rolls[f].reduce(func(sum, d): return sum + d, 0) + initiative_bonus(f)


# Faction-wide and non-stacking: the best bonus any living member brings.
func initiative_bonus(f: Faction) -> int:
	var best := 0
	for u in members(f):
		best = maxi(best, roundi(u.stat(&"initiative")))
	return best


# Orders sides best-first. Each key is tried in turn, then the side's best luck, then its total
# dexterity; a coin decides only sides still tied after all of that.
# A side is a Unit, a Faction, an Array of Units (e.g. "Company A"), or anything the keys rank.
# Resolves a Check against this battle's rng: rolls a d20 (the better or worse of two with edge),
# adds the bonus, and decides the hit - met the target, a natural 20 on an attack, or forced sure.
# The one place a d20 roll is defined (docs/plan-composability.md, seam 1).
func resolve(c: Check) -> Check.Roll:
	if c.is_fixed:  # no die
		var f := Check.Roll.new()
		f.total = c.bonus if is_equal_approx(c.share, 1.0) else floori(c.bonus * c.share)
		return f
	var d := rng.randi_range(1, 20)
	if c.advantage > 0:
		d = maxi(d, rng.randi_range(1, 20))
	elif c.advantage < 0:
		d = mini(d, rng.randi_range(1, 20))
	var r := Check.Roll.new()
	r.d20 = d
	r.total = d + c.bonus if is_equal_approx(c.share, 1.0) else floori((d + c.bonus) * c.share)
	r.target = c.target
	r.crit = c.crits and d >= c.crit_on
	r.hit = c.floor_hit or r.crit or r.total >= c.target
	return r


# A Contest (Glossary): `a` rolls, then `b`, each d20 + its bonus. `a` - usually the one acting - wins
# a tie, unless a_wins_ties is false (breaking free of a grip, getting clear of a wall of fire: the
# one holding the line wins ties).
func beats(a: Check, b: Check, a_wins_ties := true) -> Check.Contest:
	var c := Check.Contest.new()
	c.mine = resolve(a)
	c.theirs = resolve(b)
	c.won = c.mine.total > c.theirs.total or (a_wins_ties and c.mine.total == c.theirs.total)
	return c


# The one check helper every check between two units goes through (docs/plans/checks.md): `a` - the
# one acting - rolls d20 + its check mod in `stat` against b's d20 + its check mod in `against`, and
# wins ties unless o.ties is false. Returns both totals and the winner (Check.Contest). odds() is the
# same check's chance, unrolled: the HUD's forecast and the AI read that. Options (o):
#   role          a's kind, &"offensive" (default) or &"defensive"; b rolls the other
#   bonus         + on a's side (rank, a contingency, zeal); their_bonus: on b's
#   edge          a's advantage (+1) or disadvantage (-1); their_edge: b's
#   tags          the check's tags (an execute, taps, the skill's own), on both sides unless their_tags
#   penalty       off a's side per tile, `tiles` of them (a range penalty)
#   cut           the share of b's total that counts (an execute: Battle.executed())
#   kind          the Check.Kind both sides roll as (Contest; a Save)
#   ties          false: b wins ties (a grip's holder, a wall of fire)
# A stat &"" is that side's bonus alone (a last stand); an Array of stats, the better of them (Hitch).
# `against` a number (b may be null): a total rolled earlier, which doesn't roll again - a look at the roll
# a hider made (investigate()), a fall against a last stand (_borrowed()), Level Down's bar. Its
# their_bonus still adds; ties as above.
func check(a: Unit, stat: Variant, b: Unit, against: Variant, o := {}) -> Check.Contest:
	var s := sides(a, stat, b, against, o)
	return beats(s[0], s[1], o.get("ties", true))


# The chance (0-1) `a` wins check(a, stat, b, against, o), without rolling.
static func odds(a: Unit, stat: Variant, b: Unit, against: Variant, o := {}) -> float:
	var s := sides(a, stat, b, against, o)
	return Check.odds(s[0], s[1], o.get("ties", true))


# The two Check sides check() rolls and odds() weighs.
static func sides(a: Unit, stat: Variant, b: Unit, against: Variant, o := {}) -> Array[Check]:
	var kind: StringName = o.get("role", &"offensive")
	var other := &"defensive" if kind == &"offensive" else &"offensive"
	var tags: Array[StringName] = []
	tags.assign(o.get("tags", []))
	var theirs_tags: Array[StringName] = []
	theirs_tags.assign(o.get("their_tags", tags))
	var k: Check.Kind = o.get("kind", Check.Kind.CONTEST)
	var mine := _side_mod(a, stat, kind, tags) + int(o.get("bonus", 0)) - int(o.get("penalty", 0)) * int(o.get("tiles", 0))
	var mine_side := Check.side(mine, k).edge(int(o.get("edge", 0)))
	var cut := float(o.get("cut", 1.0))
	if against is int:
		return [mine_side, Check.fixed(against + int(o.get("their_bonus", 0))).cut(cut)]
	var theirs := _side_mod(b, against, other, theirs_tags) + int(o.get("their_bonus", 0))
	return [mine_side, Check.side(theirs, k).edge(int(o.get("their_edge", 0))).cut(cut)]


# u's check mod in stat as kind; the better of several stats; none for &"".
static func _side_mod(u: Unit, stat: Variant, kind: StringName, tags: Array[StringName]) -> int:
	if stat is Array:
		var best := -999
		for s: StringName in stat:
			best = maxi(best, u.check_mod(s, kind, tags))
		return best if not stat.is_empty() else 0
	return u.check_mod(stat, kind, tags) if stat != &"" else 0


# Rolls skill's declared check (Skill.check, a SkillCheck) as caster uses it on t: check() with
# skill_opts(); `o` adds to them (tiles: how far a drag goes).
func skill_check(caster: Unit, skill: Skill, t: Unit, o := {}) -> Check.Contest:
	var k := skill.check
	return check(caster, k.mine(skill), t, k.theirs(skill), skill_opts(caster, skill, t, self, o))


# The chance caster wins skill's declared check on t (the HUD's forecast, the AI: hit_chance()).
static func skill_odds(caster: Unit, skill: Skill, t: Unit, b: Battle = null, o := {}) -> float:
	var k := skill.check
	return odds(caster, k.mine(skill), t, k.theirs(skill), skill_opts(caster, skill, t, b, o))


# The helper's options for skill's check as cast() reads them: + its rank impact (ranked), zeal beside
# its target (passion()), its contingency's + hit and edge (requirement(), given the battle), its edge,
# its range penalty over the tiles past the first between them (or o.tiles, a drag's), its tags with the
# caster's skill tags on both sides, an execute's cut, and the foe's slots at stake (Brainfog: fogged()).
static func skill_opts(caster: Unit, skill: Skill, t: Unit, b: Battle = null, o := {}) -> Dictionary:
	var k := skill.check
	var r := caster.rank(skill)
	var ri := caster.mods(skill).irank(r, &"rank_impact")
	var req: Array = b.requirement(caster, skill, t, r) if b else [0, 0, 0, 0, 0.0]
	var tags: Array[StringName] = caster.skill_tags(skill).duplicate()  # (not the skill's own array)
	for x in k.tags:
		if x not in tags:
			tags.append(x)
	var out := {
		bonus = (ri if k.ranked else 0) + passion(caster, t) + int(req[0]),
		edge = clampi(k.edge + int(req[2]), -1, 1),
		tags = tags,
		cut = executed(t, tags, ri),
		penalty = k.penalty(ri, 1),
		tiles = maxi(Command.tiles(caster.cell, t.cell) - 1, 0),
		kind = Check.Kind.SAVE if k.save else Check.Kind.CONTEST,
		their_bonus = fogged(caster, t, ri).reduce(func(sum: int, g: Array): return sum + t.slot_weight(g), 0) if skill.disables else 0,
	}
	out.merge(o, true)
	return out


# The slot groups of t's that caster's curse at rank impact ri would switch off (Brainfog: its
# luck-rounded sqrt(rank), right to left; Unit.disable_order()).
static func fogged(caster: Unit, t: Unit, ri: int) -> Array[Array]:
	return t.disable_order().slice(0, caster.rounded(sqrt(ri)))


func contest(sides: Array, keys: Array[Callable] = []) -> Array:
	var chain: Array = keys.duplicate()
	chain.append_array([best_luck, dexterity])
	var groups := [sides.duplicate()]
	for key: Callable in chain:
		var split := []
		for g: Array in groups:
			if g.size() < 2:
				split.append(g)
				continue
			var by := {}
			for side in g:
				by.get_or_add(snappedf(float(key.call(side)), 0.0001), []).append(side)  # 10 == 10.0
			var values := by.keys()
			values.sort()
			values.reverse()
			for v in values:
				split.append(by[v])
		groups = split
	var out := []
	for g: Array in groups:
		out.append_array(_flip(g))
	return out


func best_luck(side) -> int:
	var best := -999
	for u in members(side):
		best = maxi(best, u.luck)
	return best


func dexterity(side) -> int:
	var sum := 0
	for u in members(side):
		sum += roundi(u.stat(&"dexterity"))
	return sum


# Living units on a side.
func members(side) -> Array[Unit]:
	var pool: Array = []
	if side is Unit:
		pool = [side]
	elif side is Faction:
		pool = (units.values() + inside.keys()).filter(func(u): return u.faction == side)
	elif side is Array:
		pool = side
	var out: Array[Unit] = []
	out.assign(pool.filter(func(u): return u is Unit and u.is_alive()))
	return out


# Coin flips for a still-tied group (a shuffle when more than two).
func _flip(g: Array) -> Array:
	g = g.duplicate()
	for i in range(g.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = g[i]
		g[i] = g[j]
		g[j] = t
	return g


# --- Skills

# Uses an active skill on a target in reach, paying its AP and cost. Used on a foe, an attack
# (Skill.attacks()) rolls first: d20 + the caster's attack mod against the target's Defense for the
# skill's tags. A natural 20 always hits and doubles the damage; a miss does nothing but give the
# target away (it was aimed at). Damage comes from the skill's tier for the caster's rank - at least
# 1 before the target's mitigation - once per rank for multi-hit skills (Strike III). A dual skill
# (the starter spells) puts its effects only on allies, and deals its damage only to foes. Effects
# put on the side whose turn it is get a turn more, since this one isn't among those counted. Skills
# that are investigated (Hide) are, by the enemies that could see the target as it was used: the
# target rolls once, d20 + its mod in the skill's stat + rank - its dissonance, and its effects keep
# that roll for whoever investigates them. A roll an ally's Self-evaluation is in reach of is seen
# (evaluated). A foe a hostile skill hurts, while it's fooled by the caster, looks harder at it
# (doubt()). A skill with a save (Haluca) has the foe save in place of the attack roll: passing, it
# grows suspicious of the caster; failing a curse's (Brainfog), it loses slots of its skills for a
# while (Unit.disable_order()). An automatic skill (Sing) is used on the caster and lands on the nearest units in range
# (auto_targets()), paid once. A traitor told to turn a hostile skill on its real allies refuses, or
# with a positive cha mod misses on purpose - and either way its leader looks harder at it.
func cast(caster: Unit, skill: Skill, target: Unit, spreading := false, picked: Array[Unit] = []) -> bool:
	var depth := _resolving.size()
	if _casting == 0:
		_picked = picked
	_casting += 1
	_aims.append(target)
	var done := _cast(caster, skill, target, spreading)
	_aims.pop_back()
	_casting -= 1
	if _casting == 0:
		_picked = []
	_resolving.resize(depth)
	_done_casting(caster, done)
	return done


# The outermost cast() or cast_at() is over: one of an interrupter's actions spent, if it was its; an
# interrupt granted meanwhile opens.
func _done_casting(caster: Unit, done: bool) -> void:
	if _casting > 0:
		return
	_settle_wear()
	if done:
		_spent_interrupt(caster)
	_open_interrupt()


func _cast(caster: Unit, skill: Skill, target: Unit, spreading := false) -> bool:
	if not _acting(caster) or skill not in caster.actives or skill.on_tile() or not target.is_alive():
		return false
	if (skill.on_self(caster) or (skill.auto and not spreading)) and target != caster:
		return false
	if skill.auto and not spreading:
		var to := auto_targets(caster, skill)
		if to.is_empty() or not caster.pay_for(skill, price_cut(caster, skill, to)):
			return false
		for t in to:
			cast(caster, skill, t, true)
		return true
	if posing(caster) and target.faction == caster.faction and target != caster and skill.hostile:
		if caster.mod(&"charisma") <= 0 or not in_reach(caster, skill, target):
			_refuse(caster)
			return false
		if not caster.pay_for(skill):
			return false
		attacked.emit(caster, target, 1, 1 + caster.attack_mod(skill), target.defense(skill.tags))  # a miss, on purpose
		used.emit(caster, skill, target, 0)
		doubt(caster.follows, caster, -1)  # a whiff: hardly suspicious
		return true
	var foe := not Faction.friends(target.faction, caster.faction)
	if foe and not skill.for_foes() and read(caster, target).attitude(caster) == &"ally":
		foe = false  # support for a foe it takes for an ally (a Friendly stance)
	if not foe and target != caster and skill.for_foes() and not skill.for_allies() and read(caster, target).attitude(caster) != &"ally":
		if not in_reach(caster, skill, target):
			return false
		if _holds_fire(caster, skill, target):
			return true
		foe = true  # friendly fire: it took its ally for something else, and it lands as on a foe
	var mends := not foe and skill.god_tag and caster.deity() == &"eros"  # Eros's Smite heals allies
	if not (skill.for_foes() if foe else (skill.for_allies() or mends)) or not in_reach(caster, skill, target):
		return false
	if not skill.behaviours.all(func(x: Behaviour): return x.fits(self, caster, target)):
		return false  # not a target it can be used on (Resuscitate: only the Downed)
	var spot: Variant = drag_spot(caster, skill, target) if foe and skill.drags() else null
	if foe and skill.drags() and spot == null:
		return false
	if skill.opening and not caster.idle():
		return false  # only as its turn opens (Flamedance)
	if (caster.stat(&"mist") > 0.0) != skill.mist_only:
		return false  # a mist only Coalesces (Vaporize)
	if not caster.shaped_allows(skill):
		return false  # a beast's mind (Beastshape)
	if caster.channel and caster.channel.skill == skill and skill.behaviours.any(func(x: Behaviour): return x.recast_stops()):
		end_channel(caster)  # used again: it stops channeling, free (Clairvoyance)
		return true
	var strength := decay(caster, skill, target)  # set before paying: mana spent is no decay
	if not spreading and not caster.pay_for(skill, rebate(caster, skill, target, foe).x):
		return false
	caster.face(target.cell)  # aiming it turns the caster to face its target (a miss too)
	var r := caster.rank(skill)
	var m := caster.mods(skill)  # its modifiers: per-rank and per-stat values go through them (Modifiers)
	var ri := m.irank(r, &"rank_impact")  # its rank for what rank adds to what it does
	var acts: Behaviour.Cast = cast_of(caster, skill, target, r, foe) if not skill.behaviours.is_empty() else null
	if acts:
		acts.strength = strength
		_resolving.append(acts)
		for bh in skill.behaviours:
			bh.aim(acts)  # before any roll (Sutemi's lunge)
	if target != caster:
		_aimed.get_or_add(caster, {})[target] = aimed(caster, target) + 1
	if &"warlock" in skill.tags:
		caster.chant_up = false  # a primed Chant goes into this one
	_burn(caster, skill)
	if not spreading:
		_discipline(caster, skill, foe)
	if foe and skill.hostile and target != caster:  # attacked: reactions before any roll (Gallantry)
		if not acts:
			acts = cast_of(caster, skill, target, r, foe)  # the moment's cast, whose target a reaction swaps
			acts.strength = strength
			_resolving.append(acts)
		if _swapped(acts, react(&"attacked", target, caster, acts)):
			target = acts.target
			if skill.drags():
				spot = drag_spot(caster, skill, target)
				if spot == null:
					used.emit(caster, skill, target, 0)
					return true
	var before := target.hp
	# Every path below that lands runs the behaviours' apply() (_land()); one that fails (a save or
	# contest lost, a roll missed) runs their missed() instead (_miss()); a channel stopped by using
	# it again (recast_stops(), above) lands nothing and misses nothing. docs/plans/route.md, param-tail.md.
	if acts and skill.behaviours.any(func(x: Behaviour): return x.whole(acts)):
		_land(acts)  # its behaviours are the whole of it (Beastshape, Emergency Exit, an aura, Igna on an ally): no roll, effects or damage of its own
		used.emit(caster, skill, target, before - target.hp)
		return true
	if mends:
		_smite_heal(caster, skill, target, r)
		_lovely(caster, skill, target)
		_land(acts)
		used.emit(caster, skill, target, before - target.hp)
		return true
	var zeal := passion(caster, target)  # Impassioned Fighter: + to the skill's primary mod, beside its target
	var crit := false
	var tags := acts.tags if acts else hit_tags(caster, skill, target if foe else null, self)
	var stags := caster.skill_tags(skill)  # its own tags and its modifiers' (checks, executes)
	var req := requirement(caster, skill, target, r)  # its contingency's payoff, met: [hit, damage, edge, turns, strength]
	var cut := executed(target, stags, ri)  # an execute's share of the foe's defensive check
	var saved_against := 0  # a save it failed (Haluca): what seeing through its effects must beat
	if spot != null:
		var vs := skill_check(caster, skill, target, {tiles = Command.tiles(target.cell, spot)})
		contested.emit(caster, target, vs.mine.total, vs.theirs.total)
		if not vs.won:
			_lose_cover(target)
			_lose_cover(caster)
			_miss(acts)
			used.emit(caster, skill, target, 0)
			return true
		drag(caster, target, spot, skill.drags())
	if foe and skill.engulfs:
		var vs := check(caster, skill.stat(), target, skill.stat(), {bonus = zeal + int(req[0]), edge = int(req[2]), tags = stags, cut = cut})
		contested.emit(caster, target, vs.mine.total, vs.theirs.total)
		if not vs.won:
			_lose_cover(caster)
			_miss(acts)
			used.emit(caster, skill, target, 0)
			return true
		engulf(caster, target)
	var fog: Array[Array] = fogged(caster, target, ri) if foe and skill.disables else ([] as Array[Array])
	if foe and skill.check and not skill.check.drags_to and not skill.check.suspicion:
		var vs := skill_check(caster, skill, target)
		var mine := vs.mine.total
		contested.emit(caster, target, mine, vs.theirs.total)
		if not vs.won:  # the caster wins ties
			_lose_cover(caster)
			if read(target, caster).located():
				suspect(target, caster)  # it felt something try
			_miss(acts)
			used.emit(caster, skill, target, 0)
			return true
		saved_against = mine
	if foe and skill.levels_down:
		if _level_down(caster, skill, target, ri, req) > 0:
			_land(acts)
		else:
			_miss(acts)
		used.emit(caster, skill, target, 0)
		return true
	if foe and skill.kills:
		if _death(caster, skill, target, ri, req):
			_land(acts)
		else:
			_miss(acts)
		used.emit(caster, skill, target, before - target.hp)
		return true
	for g in fog:
		for s: Skill in g:
			target.disable(s, skill.lasts(r, caster) + int(req[3]) + (1 if target.faction == turn else 0), true)
	if foe and skill.chain:  # Strike: a hit at a time (_chain()); its behaviours land with its first hit
		var landed := _chain(caster, skill, target, ri, tags, 0, 0, acts, req)
		if acts and acts.target != target:  # a reaction took the blows in its place (Interject)
			target = acts.target
			before = acts.bag.get(&"hp_before", target.hp)
			tags = acts.tags
		if landed > 0 and acts:
			_land(acts)
			for bh in skill.behaviours:
				bh.dealt(acts, before - target.hp)
		elif landed == 0:
			_miss(acts)
		if target.hp < before:
			expose(target.cell, tags, caster)  # blows land on what it stands on too
		_lose_cover(target)
		_lose_cover(caster)
		if not target.is_alive():  # (downing one that lingers Downed is no kill; its death is)
			caster.gain(&"kill", 1)
		caster.striding = false
		_tidy_debris()
		used.emit(caster, skill, target, before - target.hp)
		if target.hp < before and target.is_alive() and read(target, caster).deceived:
			doubt(target, caster)
		return true
	var overage := 0  # what a roll beat Defense by (Irradiate)
	var natural := false  # a natural 20 (Jugular recasts on one)
	var rolled: Check.Roll = null
	if foe and skill.attacks():
		var bonus := caster.attack_mod(skill) + skill.roll_per_rank * ri + skill.roll_bonus + int(req[0]) + zeal + caster.check_bonus(caster.wielded(skill.stat(), skill.tags), &"offensive") \
				+ discipline_hit(caster) + caster.focus_bonus(skill)  # Focus: the last of it spent on this shot
		var hit := resolve(Check.attack(bonus, target.defense(tags) + guard_of(acts)).edge(clampi(edge_of(skill, acts) + int(req[2]), -1, 1)).keen(discipline_keen(caster)))
		overage = maxi(hit.margin(), 0)
		crit = hit.crit or (skill.sure_crit and hit.hit)  # Jugular: a hit is a critical
		natural = hit.crit
		attacked.emit(caster, target, hit.d20, hit.total, hit.target)
		_evaluate(caster, skill, hit.d20, hit.total)
		rolled = hit
		if not hit.hit:
			_lose_cover(target)
			_miss(acts)
			used.emit(caster, skill, target, 0)
			return true
	if foe and skill.hostile and target != caster:  # hit: reactions before its damage (Interject)
		var rh := react(&"hit", target, caster, acts)
		if _swapped(acts, rh):
			target = acts.target
			before = target.hp
			tags = acts.tags
			if rolled and not rolled.crit and rolled.total < target.defense(tags) + guard_of(acts) + rh.guard:
				attacked.emit(caster, target, rolled.d20, rolled.total, target.defense(tags) + guard_of(acts) + rh.guard)
				_lose_cover(target)
				_miss(acts)
				used.emit(caster, skill, target, 0)  # the roll that hit its first target misses its new one
				return true
	if acts:
		acts.hit = true
	if foe and skill.binds:  # landed (a miss returned above): Judgement's shackles
		_bind(caster, skill, target, ri)
	var known := roundi(caster.stat(&"self_known"))  # what it knew of itself before this (Meditate)
	var eyes := watchers(target) if skill.investigated else ([] as Array[Unit])
	var sights := _sightings(target) if skill.effects.any(func(e: Effect): return e.stat == "concealment") else {}
	var put: Array[Unit.Applied] = []
	if not (skill.dual and foe):
		for e in skill.effects + (skill.grants.effects if skill.grants else ([] as Array[Effect])):
			var n := e.turns if e.turns else skill.lasts(r, caster)
			n += int(req[3]) if n > 0 else 0  # a contingency's + turns (Requirement.turns)
			var a := target.afflict(e, n + (1 if n and target.faction == turn else 0), ri if e.per_rank else r)
			a.total = n
			a.fades = skill.fades
			a.until_move = skill.until_move
			a.lasting = skill.holds()  # held until it breaks free
			a.skill = skill
			a.by = caster
			a.since = turns_begun
			a.roll = saved_against
			a.scale = strength * (m.statf(maxf(caster.mod(e.by_mod), 0.0), &"stat_impact") if e.by_mod else 1.0) * (1.0 + float(req[4]))  # set as it's put on (Rejuvinate's distance, Interdict's str mod, a contingency's strength)
			put.append(a)
			drive(target, e, a)  # shove, fear, entrance
	if skill.respecs:
		caster.respec_room = mini(ri, known)
		meditated.emit(caster, caster.respec_room)
	if skill.investigated:
		var hiding := skill.effects.any(func(e: Effect): return e.stat == "concealment")
		var g := resolve(guise(caster, skill, target, ri, hiding and covered(target.cell)))  # cover (Leaves): advantage to hide
		var guise := g.total
		var seen := _evaluate(target, skill, g.d20, guise)
		for a in put:
			a.roll = guise
			a.evaluated = seen
		investigate(target, skill, eyes, guise)
		if skill.effects.any(func(e: Effect): return e.stat == "concealment"):
			_scatter(target, guise)
	if not sights.is_empty():
		_vanish(target, sights)
	_land(acts)
	if skill.prays:
		pray(caster, ri, target)
	if skill.links:
		_link(caster, skill, r)
	if not foe and skill.heals():
		target.healed_by = caster
		mend(target, skill.healing(caster) + (zeal if skill.stat() in skill.heal_mods else 0) + int(req[1]) if skill.heal_mods or skill.heal_bonus else 0, skill.clears(ri), skill.per_wound * ri)
		target.regain(skill.restores * ri)
	if not foe:
		_lovely(caster, skill, target)
	var t := skill.tier(ri) if foe or not skill.dual else null
	if t:
		assert(t.stat == &"" or t.stat in Unit.CORE, "%s scales on unknown stat %s" % [skill.name, t.stat])
		var hits := ri if skill.hits_per_rank else 1
		var gross := 0
		for i in hits:
			if not target.is_alive():
				break
			var bonus := m.stat(caster.mod(caster.wielded(t.stat, stags), stags), &"stat_impact") + caster.weapon_bonus(t.stat) + (zeal if t.stat == skill.stat() else 0) if t.stat else 0
			if acts:
				for bh in skill.behaviours:
					bonus += bh.bonus(acts)  # Spike: + rank
			var power := maxi(roundi((t.power + roll(t.dice) + bonus + int(req[1])) * (1.0 + caster.stat(&"damage", tags) + discipline_damage(caster, skill))), 1) * (2 if crit else 1)
			gross += power
			if &"siphon" in tags:
				var got := target.siphon(power, tags, caster)  # off its resources, never its HP
				if acts:
					acts.siphoned += got
			elif &"energy" in tags:
				target.drain(power, tags, caster, skill.carry * (ri - 1))
			elif t.direct:
				target.damage(power)
			else:
				target.hit(power, tags, caster)
		if foe and gross > 0 and next_to(caster.cell, target.cell):
			_refill(caster, target, gross)
		if foe and skill.god_tag and gross > 0:
			_smite(caster, target, ri, gross)

		if acts:
			for bh in skill.behaviours:
				bh.dealt(acts, before - target.hp)  # Jam: as much off its Focus
		var glow := roundi(caster.stat(&"irradiate"))
		if foe and glow > 0 and &"light" in tags and overage > 0 and target.is_alive():  # Irradiate
			target.hit(mini(overage, glow + caster.mod(&"charisma")), [&"light"] as Array[StringName], caster)
	if foe and &"curse" in skill.tags and caster.stat(&"breathless") > 0.0 and target.is_alive() and (not put.is_empty() or target.hp < before):
		_choke(caster, target)
	if foe:
		if target.hp < before:
			expose(target.cell, tags, caster)  # blows land on what it stands on too
		_lose_cover(target)
		_lose_cover(caster)
		if not target.is_alive():
			caster.gain(&"kill", 1)  # Sweet Nothings
	caster.striding = false
	_tidy_debris()
	used.emit(caster, skill, target, before - target.hp)
	if foe and skill.hostile and target.hp < before and target.is_alive() and read(target, caster).deceived:
		doubt(target, caster)
	if foe and natural and skill.recast_on_crit and target.is_alive() and _recasts < RECAST_LIMIT:
		_recasts += 1  # Jugular: a natural 20 goes again, free
		cast(caster, skill, target, true)
		_recasts -= 1
	return true


# The skill a Cast is for has landed: past its attack roll, save or contest, or on a path with none.
# Its behaviours do what they do (Behaviour.apply()). Every landing path in cast() comes through here;
# cast_at() too, giving `at`, the tile it's cast on: then they do what they do there (apply_at()).
func _land(c: Behaviour.Cast, at: Variant = null) -> void:
	if not c:
		return
	c.hit = true
	for bh in c.skill.behaviours:
		if at is Vector2i:
			bh.apply_at(c, at)  # cast on a tile (cast_at())
		else:
			bh.apply(c)


# The skill a Cast is for failed: a roll missed, a save or contest lost, a Strike with no hit, a level
# or a life not taken. The counterpart of _land(): its behaviours' missed() run (a refund, a rider on a
# miss), and c.hit stays false. Called before `used`, on every path of cast() that lost.
func _miss(c: Behaviour.Cast) -> void:
	if not c:
		return
	c.hit = false
	for bh in c.skill.behaviours:
		bh.missed(c)


# Whether reaction r swapped its cast's target: the cast's tags are taken afresh for the new one
# (an ambush is against whom it lands on).
func _swapped(c: Behaviour.Cast, r: Behaviour.Reaction) -> bool:
	if c.target == r.subject:
		return false
	c.tags = hit_tags(c.caster, c.skill, c.target if c.foe else null, self)  # (as it stood: the blow's side is read before it turns)
	c.target.face(c.caster.cell)  # one that takes a blow in another's place turns to face its attacker
	return true


# An area skill's blow on u (a cone, a blast: cast_at()) through the moments cast() has: on a foe of a hostile
# skill's caster, `attacked` before it tries (Gallantry), then `hit` once it lands (Interject), as for one unit,
# with a cast of its own under way meanwhile (resolving(): Interject's cut). `tries(victim)` is the share of the
# blow that gets through (Wildfire's dodge; 1 with none; 0 it missed and no `hit` happens); then
# `strike(victim, share)` does the damage, always, 0 when it missed. A reaction may swap the victim
# (retarget()): the one that steps in takes it, as in cast(). Allies, the caster and the unaimed get no
# moment: only a foe is an attack's target. docs/plans/gaps-react-marks.md.
func area_blow(c: Behaviour.Cast, u: Unit, strike: Callable, tries := Callable()) -> void:
	var caster := c.caster
	if not c.skill.hostile or u == caster or Faction.friends(u.faction, caster.faction):
		strike.call(u, float(tries.call(u)) if tries.is_valid() else 1.0)
		return
	var rc := cast_of(caster, c.skill, u, c.rank, true)
	var depth := _resolving.size()
	_resolving.append(rc)
	if _swapped(rc, react(&"attacked", u, caster, rc)):
		u = rc.target
	var share := float(tries.call(u)) if tries.is_valid() else 1.0
	if share > 0.0:
		if _swapped(rc, react(&"hit", u, caster, rc)):
			u = rc.target
		rc.hit = true
	else:
		_miss(rc)  # it dodged: the skill's behaviours hear of it
	strike.call(u, share)
	_resolving.resize(depth)


# The one Cast a skill's behaviours share as it's used (Skill.behaviours: Kick), from its payment on:
# aim(), edge(), guard(), apply(), bonus(), dealt(), felled(). Built by the HUD too, to ask edge() and guard().
func cast_of(caster: Unit, skill: Skill, target: Unit, r: int, foe: bool) -> Behaviour.Cast:
	var c := Behaviour.Cast.new()
	c.battle = self
	c.caster = caster
	c.target = target
	c.meant = target
	c.skill = skill
	c.rank = r
	c.foe = foe
	c.mods = caster.mods(skill)  # read scaled values through them (impact_rank(), stat_mod())
	c.tags = hit_tags(caster, skill, target if foe else null, self)
	c.picked = _picked  # what the outermost cast's caster picked by hand (Behaviour.picks())
	return c


# How many targets caster may pick by hand for skill (its behaviours' picks()).
func picks_of(caster: Unit, skill: Skill) -> int:
	var c := cast_of(caster, skill, caster, caster.rank(skill), false)
	var n := 0
	for bh in skill.behaviours:
		n += bh.picks(c)
	return n


# What the skill takes of its own accord with nothing picked (its behaviours' defaults()), for the HUD's preview.
func defaults_of(caster: Unit, skill: Skill) -> Array[Unit]:
	var c := cast_of(caster, skill, caster, caster.rank(skill), false)
	var out: Array[Unit] = []
	for bh in skill.behaviours:
		for t in bh.defaults(c):
			if t not in out:
				out.append(t)
	return out


# The edge on a skill's attack roll: its own advantage or disadvantage, plus its behaviours' (Gank),
# no more than one either way.
static func edge_of(skill: Skill, c: Behaviour.Cast) -> int:
	var n := -1 if skill.disadvantage else (1 if skill.advantage else 0)
	if c:
		for bh in skill.behaviours:
			n += bh.edge(c)
	return clampi(n, -1, 1)


# What using skill on target saves caster of its price, summed over its behaviours (Behaviour.rebate()):
# x off the price before the roll (what the forecast shows and _cast() pays), y back on a hit.
func rebate(caster: Unit, skill: Skill, target: Unit, foe: bool) -> Vector2:
	var r := Vector2.ZERO
	if not skill.behaviours.is_empty() and target:
		var c := cast_of(caster, skill, target, caster.rank(skill), foe)
		for bh in skill.behaviours:
			r += bh.rebate(c)
	return Vector2(clampf(r.x, 0.0, 1.0), clampf(r.y, 0.0, 1.0))


# The share of skill's price that using it on `targets` takes off before it's paid: what every one of
# them grants (rebate().x), as the one price paid for a spread cast is shared by them all. 0 where there
# is no unit to ask (a tile cast on thin air).
func price_cut(caster: Unit, skill: Skill, targets: Array[Unit]) -> float:
	var cut := 1.0
	var asked := false
	for t in targets:
		if t != null and t != caster:
			asked = true
			cut = minf(cut, rebate(caster, skill, t, not Faction.friends(t.faction, caster.faction)).x)
	return cut if asked else 0.0


# Whether caster could pay for skill on target (after walking `steps` first): at the price a behaviour
# takes a share off (price_cut(), Poach), the one _cast() would pay. What the HUD's reach and the AI's
# strike both ask, with a target to ask.
func can_afford(caster: Unit, skill: Skill, target: Unit, steps := 0.0) -> bool:
	return caster.can_afford_after(skill, steps, price_cut(caster, skill, [target] as Array[Unit]))


# Defense a cast's behaviours give its target against it (Spike).
static func guard_of(c: Behaviour.Cast) -> int:
	var n := 0
	if c:
		for bh in c.skill.behaviours:
			n += bh.guard(c)
	return n


# How many times o has used a skill on t this battle, hit or miss, ally or foe (itself aside): the
# targeting memory (Poach: one it never has).
func aimed(o: Unit, t: Unit) -> int:
	return _aimed.get(o, {}).get(t, 0)


# Whether caster's attack on target ambushes it: as it attacks, the target can't place it, or it's
# concealed from the target or unseen (Read). An ambushing hit carries the ambush tag (hit_tags()), so
# effects and rules tagged ambush count on it; Gank needs one.
func ambushes(caster: Unit, target: Unit) -> bool:
	var r := read(target, caster)
	return not r.located() or r.concealed or not r.seen


# Taken out of the fight: u was downed (a heart spent), went Downed, or was killed - the one place each
# such moment is told (neutralized), how saying which; unshape() (a forced end to a shape) comes here too.
# A cast under way whose target it was hears of it (Behaviour.felled(): Poach).
func neutralize(u: Unit, how: StringName) -> void:
	neutralized.emit(u, u.last_hit_by, how)
	for c in _resolving.duplicate():
		if c.target == u:
			for bh in c.skill.behaviours:
				bh.felled(c, how)
	for w in _wears:  # the use under way that did it: by the blow that struck it, or aimed at it
		if w.target == u or (w.caster == u.last_hit_by and u.last_hit_by != u):
			w.felled[u] = how
	for o: Unit in units.values():
		if o != u and o.is_alive():
			for h in o.hooks():
				h[0].neutralized(self, o, h[1], u, u.last_hit_by, how)  # Deathlust


# A use of s was paid for (Unit.paid) inside a cast: held open, aimed at the cast's target, until the
# outermost cast is done and _settle_wear() lets its caster's passives say what of it is kept.
func _on_paid(u: Unit, s: Skill, w: Exhaustion.Wear) -> void:
	if _casting == 0 or w.gain <= 0.0:
		return
	w.target = _aims.back() if not _aims.is_empty() else null
	_wears.append(w)


# The outermost cast is over: each use paid in it (Wear) goes through its caster's passives' wearing()
# hooks, and what they took off its gain is relieved - the one generic place a passive may cancel or
# lower the exhaustion a skill used would add.
func _settle_wear() -> void:
	var open := _wears
	_wears = []
	for w in open:
		for h in w.caster.hooks():
			h[0].wearing(self, w.caster, h[1], w)
		w.caster.exhaustion.relieve(w.gain - w.uses, w.skill)


# Forces u out of whatever shape it is in - a beast's form (Beastshape) or a mist (Vaporize) - by `by`
# (any source: the Effect stat unshape reaches it through drive()). Neutralized as &"unshaped" if anything
# ended; false if u was in none. Choosing to turn back (Beastshape again) is not this: no neutralize().
func unshape(u: Unit, _by: Unit = null) -> bool:
	var was := false
	if u.form:
		u.unshape()
		shaped.emit(u, &"", &"")
		was = true
	for x in u.slots:
		if x.on and x.skill.passive and x.skill.toggle and x.skill.effects.any(func(e: Effect): return e.stat == "mist"):
			u.toggle(x.skill)
			was = true
	if was:
		neutralize(u, &"unshaped")
	return was


# --- Reactions and interrupts (docs/plans/reactions.md)

# A moment units may react to: every unit on the field whose switched-on passives' behaviours react
# (Behaviour.react()) is asked, in a fixed order (reactors()), each passive at most once, and only while
# its holder reacts() (not Jammed, not stopped). c is the cast under way (its target is what a reaction
# swaps); null when there's none. Returns the moment as the reactions left it.
func react(trigger: StringName, subject: Unit, by: Unit = null, c: Behaviour.Cast = null) -> Behaviour.Reaction:
	var r := Behaviour.Reaction.new()
	r.battle = self
	r.trigger = trigger
	r.subject = subject
	r.by = by
	r.cast = c
	r.locked = c != null and c.locked
	_reacting += 1
	for o in reactors(subject, by):
		for x in reactions_of(o):
			react_with(r, o, x)
	_reacting -= 1
	if c:
		c.locked = r.locked
	return r


# Asks one passive x of holder's about moment r, if it may: holder reacts() and x hasn't reacted to r.
# True when it did (told by reacted, counted by times_reacted()).
func react_with(r: Behaviour.Reaction, holder: Unit, x: Slot) -> bool:
	if not holder.reacts() or r.done.any(func(d: Array): return d[0] == holder and d[1] == x.skill):
		return false
	r.skill = x.skill
	r.rolled = []
	var did := false
	for bh in x.skill.behaviours:
		did = bh.react(r, holder, x.rank) or did
	if did:
		r.done.append([holder, x.skill])
		var n: Dictionary = _reacted.get_or_add(holder, {})
		n[x.skill] = n.get(x.skill, 0) + 1
		reacted.emit(holder, x.skill, r)
	return did


# The order units are asked about a moment: who brought it about, then whom it happens to, then the rest
# by distance from that one (ties in the field's order).
func reactors(subject: Unit, by: Unit = null) -> Array[Unit]:
	var rest: Array[Unit] = []  # (whom it happens to is asked even at 0 HP: Final Act, as it falls)
	for o: Unit in units.values():
		if o != subject and o != by and o.is_alive() and o not in rest:
			rest.append(o)
	var at := subject.cell
	rest.sort_custom(func(a: Unit, b: Unit): return Command.tiles(a.cell, at) < Command.tiles(b.cell, at))
	var out: Array[Unit] = []
	for o in [by, subject]:
		if o and (o.is_alive() or o == subject) and o not in out:
			out.append(o)
	out.append_array(rest)
	return out


# u's switched-on passives that have behaviours (any may react), top to bottom of its hotbar, then the
# rest in their order: the order its reactions resolve in, and Snapping Turtle's.
static func reactions_of(u: Unit) -> Array[Slot]:
	var out: Array[Slot] = []
	out.assign(u.on_passives.filter(func(x: Slot): return not x.skill.behaviours.is_empty()))
	var at := func(x: Slot) -> int:
		var i := u.hotbar.find(x.skill)
		return i if i >= 0 else 1000 + out.find(x)
	out.sort_custom(func(a: Slot, b: Slot): return at.call(a) < at.call(b))
	return out


# How many times u's passive s has reacted this battle (Final Act: once).
func times_reacted(u: Unit, s: Skill) -> int:
	return _reacted.get(u, {}).get(s, 0)


# The cast under way, innermost (what a hook given no cast asks about: Interject's "a hit not aimed at it").
func resolving() -> Behaviour.Cast:
	return _resolving.back() if not _resolving.is_empty() else null


# u gets an interrupt: `actions` skill uses, free of AP, out of turn. It opens once nothing is being cast
# (at once, if nothing is), after any granted before it; while open only u acts, and the interrupted turn
# resumes when it's done (end_interrupt()).
func grant_interrupt(u: Unit, actions := 1) -> void:
	_interrupts.append([u, actions])
	if _casting == 0 and _reacting == 0:
		_open_interrupt()


func _open_interrupt() -> void:
	while interrupter == null and not _interrupts.is_empty() and phase == Phase.TURNS:
		var next: Array = _interrupts.pop_front()
		var u: Unit = next[0]
		if not u.is_alive() or u.stopped():
			_settle(u)
			continue
		interrupter = u
		_interrupt_left = next[1]
		_interrupt_ap = AP.new(INTERRUPT_AP, &"skill")
		u.ap.push_front(_interrupt_ap)  # drawn before any skill-only AP of its own
		interrupt_began.emit(u)
		if not (directed.is_valid() and directed.call(u)):
			AI.interrupt(self, u)  # no one to ask: the AI picks, as headless simulations and the real game alike


# The interrupter is done, or passes (the HUD's End turn, the AI with nothing to do): its free AP goes,
# a unit held up at 0 HP falls (Final Act), and the next interrupt opens, or the turn resumes.
func end_interrupt() -> void:
	var u := interrupter
	if not u:
		return
	interrupter = null
	u.ap.erase(_interrupt_ap)
	_interrupt_ap = null
	_interrupt_left = 0
	interrupt_ended.emit(u)
	_settle(u)
	_open_interrupt()


# A unit held up at 0 HP (Unit.staying) falls, as it would have, unless it got back above 0 meanwhile.
func _settle(u: Unit) -> void:
	if u.staying:
		u.staying = false
		if u.hp <= 0:
			_settling = u  # the same fall, resumed: not a moment to react to again
			u.fall()
			_settling = null


# u, at 0 HP, is about to fall (Unit.falling): its reactions (and others') have their say; one may hold
# it up until its interrupt is done (Final Act).
func _on_falling(u: Unit, hold: Dictionary) -> void:
	if phase != Phase.TURNS or u == _settling:
		return
	var r := react(&"fallen", u, u.last_hit_by, resolving())
	hold.stay = r.stay
	u.staying = r.stay  # (Unit sets it too, once this returns: set now, so its interrupt can open at once)
	if _casting == 0 and _reacting == 0:
		_open_interrupt()


# The free AP an interrupt lent u (none unless it's the interrupter): the HUD shows its own AP without it.
func free_ap(u: Unit) -> float:
	return _interrupt_ap.amount if u == interrupter and _interrupt_ap else 0.0


# One of the interrupter's skill uses is done: the last of them ends its interrupt.
func _spent_interrupt(u: Unit) -> void:
	if u == interrupter:
		_interrupt_left -= 1
		if _interrupt_left <= 0:
			end_interrupt()


# The tags a skill's damage carries for its caster: its own and its modifiers' (Unit.skill_tags(): a Fire
# Insignia's fire), plus its weapon's blows (Skill.weapon_tag:
# Strike - blunt bare-handed) and its god's (Skill.god_tag: Smite - Eros's love, Urlo's energy). Given
# the foe it's used on and the battle: ambush, if it ambushes (ambushes()); and flank or rear, if it comes
# at the foe from the side or behind (Unit.side_of(): a rear attack also takes Unit.REAR_EDGE off Defense).
static func hit_tags(caster: Unit, skill: Skill, foe: Unit = null, b: Battle = null) -> Array[StringName]:
	var out: Array[StringName] = caster.skill_tags(skill).duplicate()
	if foe and b and b.ambushes(caster, foe) and &"ambush" not in out:
		out.append(&"ambush")
	if foe and foe != caster:
		var side := foe.side_of(caster.cell)  # the cone test: from its flank or rear (Unit.side_of())
		if side != &"front":
			out.append(side)
	if skill.weapon_tag:
		var blow: StringName = (caster.weapon.damage_tag if caster.weapon else &"blunt")
		if blow and blow not in out:
			out.append(blow)
	var god := God.tag_of(caster.deity())
	if skill.god_tag and god and god not in out:
		out.append(god)
	return out


# What each god adds to a Smite that hits (Skill.god_tag), at rank r, gross its damage before the
# target's mitigation:
# Luun: a target left at r x 5% of its max HP or less dies (an execute). Sol: it burns for 20% x r of
# the damage as pure fire as its side's turn ends. Urlo: r of its enchantments come off (disenchant()),
# and the caster's own items get those r didn't find (Unit.enchant()). Drael: r ranks of its buffs
# come off (dispel()). Vetruvis: earth damage radiates from it to everyone within r tiles but the
# caster, the damage / (tiles away + 1).
func _smite(caster: Unit, t: Unit, r: int, gross: int) -> void:
	match caster.deity():
		&"luun":
			if t.is_alive() and t.execute_share() <= 0.05 * r:  # full while hale (Bless)
				t.slain_from = t.hp
				if not Downed.finish(t):  # one already Downed dies of it
					t.hp = 0
		&"sol":
			if t.is_alive():
				var burn := Effect.new()
				burn.stat = "bleed"
				burn.name = "Sunburn"
				burn.tags = [&"fire"]
				burn.amount = maxf(roundf(gross * 0.2 * r), 1.0)
				var a := t.afflict(burn, 1 + (1 if t.faction == turn else 0))
				a.by = caster
				a.since = turns_begun
		&"urlo":
			caster.enchant(r - disenchant(t, r))
		&"drael":
			dispel(t, r)
		&"vetruvis":
			for o: Unit in units.values():
				var d := Command.tiles(o.cell, t.cell)
				if o != caster and o != t and o.is_alive() and d <= r:
					o.hit(gross / (d + 1.0), [&"earth"] as Array[StringName], caster)


# Eros's Smite on an ally: it heals what it would have dealt; past full, it overheals at r x 20% of
# what's left over (Unit.over_max).
func _smite_heal(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var m := caster.mods(skill)
	var ri := m.irank(r, &"rank_impact")
	var tier := skill.tier(ri)
	if not tier:
		return
	var n := tier.power + roll(Vector2i(tier.dice.x * (ri if skill.dice_per_rank else 1), tier.dice.y)) + (m.stat(caster.mod(tier.stat, skill.tags), &"stat_impact") if tier.stat else 0) \
			+ int(requirement(caster, skill, t, r)[1])
	var room := t.max_hp + t.over_max - t.hp
	var over := maxi(n - room, 0)
	var extra := roundi(over * 0.2 * ri)
	t.over_max = maxi(t.hp + mini(n, room) + extra - t.max_hp, t.over_max)
	t.healed_by = caster
	t.heal(mini(n, room) + extra)


# Takes up to n enchantments off t's items, weapon first, then armor and trinket: each becomes its plain
# self (Item.enchant 0). How many came off.
func disenchant(t: Unit, n: int) -> int:
	var done := 0
	for slot in [&"weapon", &"armor", &"trinket"]:
		var it: Item = t.get(slot)
		if done < n and it and it.enchant > 0:
			it = it.duplicate()
			it.enchant = 0
			t.set(slot, it)
			done += 1
	t.refit()
	return done


# Starblade: a melee hit gives its wielder back Power - (gross damage / the target's base stat total)
# x the weapon's refills x (1 + its enchantment) of its max, rounded by luck.
func _refill(u: Unit, t: Unit, gross: int) -> void:
	if u.weapon and u.weapon.refills > 0.0:
		var share := float(gross) / maxi(t.base_total(), 1) * u.weapon.refills * (1 + u.weapon.enchant)
		u.grant_energy(Luck.settle(share * u.max_energy, u.luck, true))


# Whom an automatic skill (Sing) lands on: the nearest units in range the caster can place, allies
# and foes alike, no more than its rank.
func auto_targets(caster: Unit, skill: Skill) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if o != caster and o.is_alive() and read(caster, o).located() and in_reach(caster, skill, o):
			out.append(o)
	out.sort_custom(func(x: Unit, y: Unit): return Vector2(x.cell).distance_to(Vector2(caster.cell)) < Vector2(y.cell).distance_to(Vector2(caster.cell)))
	return out.slice(0, caster.mods(skill).irank(caster.rank(skill), &"rank_range"))  # how many it reaches: rank range


# A traitor in the party of a leader on another side (Unit.follows): it acts on that leader's turn
# too, on whatever AP its own turn left it, pretending (Command).
func posing(u: Unit) -> bool:
	return u.follows != null and u.follows.faction != u.faction


# A traitor won't do as it's told, or acted on its own side's turn when it should have rested: its
# leader looks harder at it, at advantage.
func _refuse(u: Unit) -> void:
	refused.emit(u, u.follows)
	doubt(u.follows, u, 1)


# Whether foe t walks toward caster's skill (Sing): only enraptured - convinced the caster is its ally,
# with no suspicion of it - taking it for support. A suspicious one won't, but the song works on its
# suspicion: the skill's check (Skill.check, with suspicion: Sing's wis; skill_check()) takes a stack off.
# One that isn't convinced, with none to
# take, the song does nothing to (it may well walk up to hit the caster all the same).
func lured(caster: Unit, skill: Skill, t: Unit) -> bool:
	if t.suspects(caster) == 0:
		return read(t, caster).attitude(t) == &"ally"
	var vs := skill_check(caster, skill, t)
	contested.emit(caster, t, vs.mine.total, vs.theirs.total)
	if vs.won:
		suspect(t, caster, -1)
	return false


# o grows n stacks more suspicious of t, a unit or a tile (fewer, for a negative n; none left, it
# trusts it again). Of an enemy unit, it passes the word on (spread()) - unless it was told.
func suspect(o: Unit, t: Variant, n := 1, told_of := false) -> void:
	var who: Unit = t if t is Unit else unit_at(t)  # suspicion of a tile works on whoever hides there
	var pleased := n > 0 and who != null and who.faction != o.faction and (o.stat(&"unmask_gain") > 0 or o.stat(&"uncover_gain") > 0)
	var was: Read = read(o, who) if pleased else null
	var before: Read = (read(o, t) if not pleased or t is Vector2i else was) if n > 0 else null
	var hid := _hidden_from(o, who) if pleased else 0
	var first := o.suspects(t) == 0
	var k := o.suspects(t) + n
	if k > 0:
		o.suspicion[t] = k
	else:
		o.suspicion.erase(t)
	if pleased:
		_dialysis(o, who, was, hid)
	if n > 0:
		if first:
			discovered.emit(o, t)
		if _sees_through(before, read(o, t)):
			unmasked.emit(o, t, before)
	if n > 0 and not told_of and t is Unit and o.faction and not Faction.friends(o.faction, t.faction):
		spread(o, t)


# o has grown suspicious of t, an enemy: it tells each ally within WORD + its cha mod tiles (at least 1)
# that's awake and doesn't suspect t yet, which grows a stack suspicious of it in turn - and doesn't
# pass it on. t's passives can stop the word (Behaviour.lets_word(): Bandwagon).
func spread(o: Unit, t: Unit) -> void:
	var reach := maxi(WORD + o.mod(&"charisma"), 1)
	for a: Unit in units.values():
		if a == o or not a.is_alive() or a.asleep() or not Faction.friends(a.faction, o.faction) or a.suspects(t) > 0 \
				or Command.tiles(a.cell, o.cell) > reach:
			continue
		var heard := t.hooks().all(func(h: Array): return h[0].lets_word(self, t, h[1], o, a))
		if heard:
			suspect(a, t, 1, true)
		told.emit(o, a, t, heard)


# Analysis Dialysis: o satisfies its patron, Sweet Nothings back for it, unmasking an enemy t it took
# for friendly or neutral (unmask_gain), or taking levels of concealment off one hiding (uncover_gain
# a level). was: o's read of t before; hid: the levels t hid from o by.
func _dialysis(o: Unit, t: Unit, was: Read, hid: int) -> void:
	var now := read(o, t)
	if was.attitude(o) in [&"ally", &"ignore"] and now.attitude(o) not in [&"ally", &"ignore"] and now.faction != null:
		o.gain(&"patron", roundi(o.stat(&"unmask_gain")))
	var off := hid - _hidden_from(o, t)
	if off > 0:
		o.gain(&"patron", roundi(o.stat(&"uncover_gain")) * off)


# Whether a read `now` sees through what `was` couldn't: a lie it took (deceived) that no longer
# fools it, or something it couldn't make out (net below 0) now plain.
static func _sees_through(was: Read, now: Read) -> bool:
	return (was.deceived and not now.deceived) or (was.net < 0 and now.net >= 0)


# Who makes out t's side and place right now (awake, it in their sight): unit -> its read, for
# _vanish() to compare after something that may hide it.
func _sightings(t: Unit) -> Dictionary:
	var out := {}
	Unit.begin_read()
	for o: Unit in units.values():
		if o != t and o.is_alive() and not o.asleep():
			var r := read(o, t)
			if r.located() and r.faction != null:
				out[o] = r
	Unit.end_read()
	return out


# Those of `before` (_sightings()) that no longer make out t's side or place though it's still well
# within their sight: it vanished before their very eyes. Each takes it to be of the side it seemed
# to be until it sees otherwise (Unit.assumed: Perception), and its trickery still fools them as it
# would (Perception._lie()).
func _vanish(t: Unit, before: Dictionary) -> void:
	if not t.is_alive():
		return
	for o: Unit in before:
		if not o.is_alive() or o.asleep() or in_range(o, t) < 2:
			continue
		var r := read(o, t)
		if not r.located() or r.faction == null:
			o.assumed[t] = before[o].faction
			vanished.emit(o, t, before[o])


# The concealment levels t hides from o by, before o's senses.
func _hidden_from(o: Unit, t: Unit) -> int:
	return Perception._levels(self, t.cell, t, true, o).values().reduce(func(sum, x): return sum + x, 0)


# o looks harder at t, which fools it: d20 + its wis mod (the better of two within wis mod - lie tiles,
# or with edge 1; the worse of two with edge -1) against t's own check, d20 + its cha mod + its lie -
# its dissonance penalty (a less believable lie, the more it lies). The lie is its persona to its
# allies, its trickery to its enemies, plus its clout with o's side (Unit.clout()). Meeting it, o grows a stack more suspicious of t.
func doubt(o: Unit, t: Unit, edge := 0) -> bool:
	var lie := roundi(t.stat(&"persona")) if o.faction == t.faction else roundi(Perception.trickery(t, Read.new(), null, self))
	lie += t.clout(o.faction)  # standing with o's side: its word carries
	var close := Command.tiles(o.cell, t.cell) <= o.mod(&"wisdom") - lie
	var vs := check(o, &"wisdom", t, &"charisma", {edge = -1 if edge < 0 else (1 if edge > 0 or close else 0), their_bonus = lie - t.dissonance_penalty()})
	if vs.won:
		suspect(o, t)
	doubted.emit(o, t, vs.mine.total, vs.theirs.total)
	return vs.won


# As its side's turn starts, u looks harder (doubt()) at each enemy it can place that fools it: the
# enraptured come round on their own, given time. And it inspects the nearest suspicious thing it
# hasn't before (_first_look()).
func _look_harder(u: Unit) -> void:
	if u.asleep():
		return
	for t: Unit in units.values():
		if t.faction != u.faction and t.is_alive():
			var r := read(u, t)
			if r.deceived and r.located():
				doubt(u, t)
	_first_look(u)


# Tiles where o makes out something suspicious but not what: a hint (a vague shape, a vibe) of a
# hidden trap or a hidden unit there, or one it already suspects and still can't make out; or an ally
# whose tags it sees scrambled (Haluca). Nearest first.
func suspicious(o: Unit) -> Array[Vector2i]:
	Unit.begin_read()  # all reads, nothing changed: each unit's effects are found once (Unit._effects())
	var out: Array[Vector2i] = []
	for c in maybe_suspicious(o):
		var r := read(o, c)
		if c != o.cell and (r.hint != "" or (o.suspects(c) > 0 and r.net < 0)):
			out.append(c)
	for t: Unit in units.values():
		if t != o and t.is_alive() and t.cell not in out:
			var r := read(o, t)
			if r.located() and (r.hint != "" or (o.suspects(t) + o.suspects(t.cell) > 0 and r.net < 0) or (t.faction == o.faction and o.scrambles(t))):
				out.append(t.cell)
	Unit.end_read()
	out.sort_custom(func(x: Vector2i, y: Vector2i): return Vector2(x).distance_to(Vector2(o.cell)) < Vector2(y).distance_to(Vector2(o.cell)))
	return out


# The tiles that could look suspicious to o, for suspicious() to read: only concealment levels give a
# tile a hint (Perception.tile(); recon only adds), and those come from darkness over it, hidden ground
# (a trap), marks laid hidden from it, or o's own suspicion of it. Reading every tile of a plane as big as the Meadows' grows,
# for every unit, every turn, was what slowed it.
func maybe_suspicious(o: Unit) -> Array[Vector2i]:
	var out: Dictionary[Vector2i, bool] = {}
	for z in zones:
		if not z.allied:
			for c in z.levels:
				out[c] = true
	var sees := perception_range(o)  # where sight is limited, what o can't perceive can't look odd to it
	for c in _maybe_hidden(o.cell if sees >= 0.0 else null, sees):
		if hidden(c):
			out[c] = true
	for c in marks:  # a mark hidden from o (Mark.told()): its tile may look odd (Perception.tile())
		if marks[c].any(func(m: Mark): return not m.told(o)):
			out[c] = true
	for k in o.suspicion:
		if k is Vector2i:
			out[k] = true
	var kept: Array[Vector2i] = []
	for c: Vector2i in out:
		if map.get_cell_source_id(c) != -1 and (sees < 0.0 or Vector2(c).distance_to(Vector2(o.cell)) <= sees + 0.0001):
			kept.append(c)
	return kept


# Every cell that could be hidden (hidden()): those layered over or trapped (their terrain isn't the
# map's), and those painted with a tile whose terrain is concealed - found by tile, not cell by cell;
# or, given a centre `around`, among the tiles within `r` of it only (cells_near()).
func _maybe_hidden(around: Variant = null, r := -1.0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(layers.keys() + snares.keys())
	if _concealed_tiles.is_empty() and map.tile_set:
		_concealed_tiles.append([])  # looked: the first entry marks it, whatever's found
		var ts := map.tile_set
		for i in ts.get_source_count():
			var src := ts.get_source(ts.get_source_id(i)) as TileSetAtlasSource
			if not src:
				continue
			for t in src.get_tiles_count():
				var at := src.get_tile_id(t)
				for a in src.get_alternative_tiles_count(at):
					var alt := src.get_alternative_tile_id(at, a)
					var d := src.get_tile_data(at, alt)
					var ter: Terrain = d.get_custom_data("terrain") if d and ts.get_custom_data_layer_by_name("terrain") >= 0 else null
					if ter and ter.concealment > 0:
						_concealed_tiles.append([ts.get_source_id(i), at, alt])
	if around != null:
		var kinds := {}
		for k in _concealed_tiles.slice(1):
			kinds[k] = true
		for c in cells_near(around, r) if not kinds.is_empty() else []:
			if [map.get_cell_source_id(c), map.get_cell_atlas_coords(c), map.get_cell_alternative_tile(c)] in kinds:
				out.append(c)
		return out
	for k in _concealed_tiles.slice(1):
		out.append_array(map.get_used_cells_by_id(k[0], k[1], k[2]))
	return out


# The first time o sees something suspicious, it inspects the nearest such thing it hasn't yet.
func _first_look(o: Unit) -> void:
	for c in suspicious(o):
		if c not in o.noticed:
			o.noticed[c] = true
			inspect(o, c)
			return


# As its side's turn ends, o looks around (asleep, it doesn't): the nearest suspicious things within its
# wis mod in tiles, one of them - more often than not. With wis mod 0 or less it looks only at what's
# beside it, once every (1 - wis mod) turns: at 0, every turn; at -1, every other. Each turn in a row
# it has rested widens its look by a tile, takes in one thing more and adds +1 to its checks, up to
# its wis. Moving last with Eyes Forward, it looks ahead instead (_look_ahead()).
func _watch(o: Unit) -> void:
	if _look_ahead(o):
		return
	var m := o.mod(&"wisdom")
	if m <= 0:
		o.unwatched += 1
		if o.unwatched < 1 - m:
			return
	o.unwatched = 0
	survey(o, o.cell, o.rested_turns)


# o inspects around `center` as if it had rested `rested` turns in a row (capped at its wis): the
# suspicious things within max(wis mod, 1) + rested tiles of it, nearest the centre first, 1 + rested
# of them, at +rested. Its turn's end (_watch()).
func survey(o: Unit, center: Vector2i, rested: int) -> int:
	var r := mini(rested, roundi(o.stat(&"wisdom")))
	var reach := maxi(o.mod(&"wisdom"), 1) + r
	var near := suspicious(o).filter(func(c: Vector2i): return Command.tiles(center, c) <= reach)
	near.sort_custom(func(x: Vector2i, y: Vector2i): return Command.tiles(center, x) < Command.tiles(center, y))
	var n := 0
	for c in near.slice(0, 1 + r):
		o.noticed[c] = true
		inspect(o, c, center, r)
		n += 1
	return n



# An investigation skill's look (Observe, Eyes Forward): o inspects every one of `cells` but its own,
# at +bonus, from `center`. How many it grew suspicious of.
func search(o: Unit, cells: Array, center: Variant = null, bonus := 0) -> int:
	var found := 0
	if o.faction and o.faction not in swept:
		swept[o.faction] = {}
	for c: Vector2i in cells:
		if o.faction and c != o.cell:
			swept[o.faction][c] = turns_begun
		if c != o.cell and inspect(o, c, center, bonus):
			o.noticed[c] = true
			found += 1
	return found


# Eyes Forward: a unit ending its turn on a move looks ahead the way it went - rank + wis mod tiles on,
# rank to either side - inspecting every tile there, in place of looking around. False if it didn't.
func _look_ahead(o: Unit) -> bool:
	var rank := roundi(o.stat(&"eyes_forward"))
	var dir := o.facing
	var strode := o.striding
	o.striding = false
	if rank <= 0 or not strode or dir == Vector2.ZERO:
		return false
	var ahead := rank + o.mod(&"wisdom")
	var strip: Array[Vector2i] = []
	var r := ceili(ahead + rank + 1.0)
	for c in _box(o.cell, r):
		var rel := Vector2(c - o.cell)
		var along := rel.dot(dir)
		if along > 0.0 and along <= ahead + 0.5 and absf(rel.cross(dir)) <= rank + 0.5:
			strip.append(c)
	search(o, strip)
	return true


# The cells of the map within r tiles of c, either way: a square to look over, rather than every cell.
func _box(c: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var x := c + Vector2i(dx, dy)
			if map.get_cell_source_id(x) != -1:
				out.append(x)
	return out


# What looking at c from a distance costs o's check: nothing beside it; further off, a point a tile
# from `center` (where it's looking from, or around: Observe), cut to tiles / (rank + 1) by Special
# Eyes.
func distance_penalty(o: Unit, center: Vector2i, c: Vector2i) -> int:
	if Command.tiles(o.cell, c) <= 1:
		return 0
	return Command.tiles(center, c) / (roundi(o.stat(&"keen_eyes")) + 1)


# o investigates a tile: d20 + its wis mod + bonus - the distance penalty, against d20 + the
# concealment there - a hidden enemy's, or a trap's it wasn't told of. Meeting it, it grows a stack
# more suspicious of the tile (of what hides there), and of the enemy hiding on it. With nothing
# hidden there, there's nothing to find: no roll. An ally there whose tags o sees scrambled (Haluca):
# the same check against the spell's roll sets them straight (untangled).
func inspect(o: Unit, c: Vector2i, center: Variant = null, bonus := 0) -> bool:
	var t := unit_at(c)
	var hiding := Perception.cover(self, t) if t and t.faction != o.faction else 0
	var snare: Snare = snares.get(c)
	var trap := terrain(c).concealment if hidden(c) and not (snare and o in snare.known) else 0
	for m in marks_at(c):  # what's laid on it that o wasn't told of
		if not m.told(o):
			trap = maxi(trap, m.concealment)
	var mixed := t != null and t.faction == o.faction and o.scrambles(t)
	if hiding <= 0 and trap <= 0 and not mixed:
		return false
	var look := {bonus = bonus - distance_penalty(o, center if center != null else o.cell, c)}
	if mixed and hiding <= 0 and trap <= 0:
		var a := o.scrambled()
		var seen := check(o, &"wisdom", null, a.roll, look)  # against the roll it scrambled with, spent
		if seen.won:
			a.through.append(t)
		untangled.emit(o, t, seen.mine.total, a.roll)
		return seen.won
	look.their_bonus = maxi(hiding, trap)  # what hides it rolls too: a d20 + that
	var seen := check(o, &"wisdom", null, &"", look)
	if seen.won:
		suspect(o, c)
		if hiding > 0:
			suspect(o, t)
	inspected.emit(o, c, seen.mine.total, seen.theirs.total)
	return seen.won


# u prays to its god (Unit.deity(); Pray), at rank r, on `target` (Drael's alone isn't on itself).
# Ramut: its side waits r turns less for the Ire. Eros: up to r units within r tiles that can see u -
# the nearest first - lose a stack of suspicion of it (only those that see it: it's no help in
# hiding). Sol: darkness within r tiles is gone. Urlo: enchants r unenchanted items of its allies
# within r tiles (Unit.enchant()). Luun: the ground within r tiles under darkness for r turns that
# conceals only its side, a level. Drael: r ranks of debuffs off the target, highest rank first
# (cleanse()). Vetruvis: the ground within r tiles is disturbed earth its enemies wade through, for r
# turns.
func pray(u: Unit, r: int, target: Unit = null) -> void:
	match u.deity():
		&"ramut":
			hastened[u.faction] = hastened.get(u.faction, 0) + r
		&"eros":
			var near: Array[Unit] = []
			for o: Unit in units.values():
				if o != u and o.is_alive() and o.suspects(u) > 0 and Command.tiles(o.cell, u.cell) <= r and not o.asleep() and read(o, u).located():
					near.append(o)
			near.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, u.cell) < Command.tiles(y.cell, u.cell))
			for o: Unit in near.slice(0, r):
				suspect(o, u, -1)
		&"sol":
			for z in zones.filter(func(x: Zone): return x.kind == &"dark"):
				for c in z.levels.keys():
					if Command.tiles(u.cell, c) <= r:
						z.levels.erase(c)
			zones.assign(zones.filter(func(x: Zone): return not x.levels.is_empty()))
		&"urlo":
			var left := r
			var near := members(u.faction).filter(func(o: Unit): return Command.tiles(o.cell, u.cell) <= r)
			near.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, u.cell) < Command.tiles(y.cell, u.cell))
			for o: Unit in near:
				left -= o.enchant(left)
		&"luun":
			var levels: Dictionary[Vector2i, int] = {}
			for c in cells_near(u.cell, r):
				if Command.tiles(u.cell, c) <= r:
					levels[c] = 1
			zones.append(Zone.new(&"dark", levels, r, u.faction, true))
		&"drael":
			cleanse(target if target else u, r)
		&"vetruvis":
			for c in cells_near(u.cell, r):
				if Command.tiles(u.cell, c) <= r:
					lay_mark(c, earthwork(u, r))
	prayed.emit(u, u.deity(), r)


# Takes r ranks of debuffs (effects that hurt it) off t, the highest-ranked first: each loses ranks
# until it has none left, or r runs out. Ramut's Ire isn't Drael's to lift. How many ranks came off.
func cleanse(t: Unit, r: int) -> int:
	return _strip(t, r, -1)


# The same for buffs (effects that help it): Drael's Smite.
func dispel(t: Unit, r: int) -> int:
	return _strip(t, r, 1)


# Takes r ranks of t's effects that help it (way 1) or hurt it (-1), the highest-ranked first. An
# effect easy to remove (Effect.ease: Level Down 2, Level Up 4) loses that many ranks for each spent.
func _strip(t: Unit, r: int, way: int) -> int:
	var those := t.timed.keys().filter(func(e: Effect): return e.helps() == way and e.stat != "ire")
	those.sort_custom(func(x: Effect, y: Effect): return t.timed[x].rank > t.timed[y].rank)
	var left := r
	for e: Effect in those:
		if left <= 0:
			break
		var a: Unit.Applied = t.timed[e]
		var off := mini(left * e.ease, a.rank)
		a.rank -= off
		left -= ceili(off / float(e.ease))
		if a.rank <= 0:
			t.timed.erase(e)
	t._arrange()  # a level effect may have gone
	t.refit()  # or Asphyxia
	return r - left


# A unit hid (its roll: a skill's investigated roll), or moved while hidden (`along` its path): it
# leaves debris on tiles around it - around the path, one fewer - by their tags (debris_kind()). How
# much and how far off goes by how well it hid (LITTER): a good job (CLEAN_HIDE or more) leaves 1-2,
# 2-4 tiles off; a middling one (FAIR_HIDE) 2-3, 1-3 off; a poor one 3-4, within 2.
func _scatter(u: Unit, roll: int, along: Array[Vector2i] = []) -> void:
	var band: Array = LITTER[0 if roll >= CLEAN_HIDE else (1 if roll >= FAIR_HIDE else 2)]
	var n := rng.randi_range(band[0][0], band[0][1]) - (1 if not along.is_empty() else 0)
	var from: Array[Vector2i] = along.duplicate()
	if from.is_empty():
		from.append(u.cell)
	var spots: Array[Vector2i] = []
	var near := {}
	for p in from:
		for c in cells_near(p, band[1][1]):
			near[c] = true
	for c: Vector2i in near:
		var d := 99
		for p in from:
			d = mini(d, Command.tiles(p, c))
		if c != u.cell and c not in along and d >= band[1][0] and d <= band[1][1] and debris_kind(c) != "":
			spots.append(c)
	for i in mini(n, spots.size()):
		var k := rng.randi_range(i, spots.size() - 1)
		var c := spots[k]
		spots[k] = spots[i]
		spots[i] = c
		debris[c] = Debris.new(debris_kind(c), u, turns_begun)
		debris[c].far = band[1][1]


# What u's hiding is worth, for the debris moving leaves: the roll its concealment was put on with
# (Hide's), else a fresh d20 + its dex mod.
func _hide_roll(u: Unit) -> int:
	var best := 0
	for e in u.timed:
		if e.stat == "concealment":
			best = maxi(best, u.timed[e].roll)
	return best if best > 0 else resolve(Check.side(u.check_mod(&"dexterity", &"defensive"), Check.Kind.CHECK).edge(1 if covered(u.cell) else 0)).total


# Debris goes once its hider is revealed (no concealment left, or fallen), or has gone further from
# it than it could have been left (Debris.far) + the hider's dex mod: the trail's cold.
func _tidy_debris() -> void:
	for c in debris.keys():
		var d: Debris = debris[c]
		if not is_instance_valid(d.by) or not d.by.is_alive() or Perception.cover(self, d.by) <= 0 \
				or Command.tiles(d.by.cell, c) > d.far + d.by.mod(&"dexterity"):
			debris.erase(c)


# A tag that only says what the ground is made of, for debris (DEBRIS_KINDS).
static func material(tag: StringName) -> bool:
	return DEBRIS_KINDS.any(func(k: Array): return tag in k[0])


# The debris a hiding unit leaves on c: by the tile's tags, then the area's (DEBRIS_KINDS); "" for none.
func debris_kind(c: Vector2i) -> String:
	for tags in [terrain(c).tags, area_tags]:
		for k in DEBRIS_KINDS:
			if k[0].any(func(t: StringName): return t in tags):
				return k[1]
	return ""


# Debris o can make out (it reads the ground there) that its own side didn't leave: clues to where
# enemies hide.
func evidence(o: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in debris:
		if debris[c].faction != o.faction and read(o, c).net >= 0:
			out.append(c)
	return out


# Its enemies that can see u: awake foes that make it out in plain sight (net -1 or better, seen).
func watchers(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if not Faction.friends(o.faction, u.faction) and o.is_alive() and not o.asleep():
			var r := read(o, u)
			if r.net >= -1 and r.seen:
				out.append(o)
	return out


# Investigating on contact: a unit coming beside a hidden foe - from any tile of its walk - looks into
# what hides it, against the roll the hider made (investigate()); and foes beside where a hiding unit
# ends up look into it the same way.
func _contact(u: Unit, passed: Array[Vector2i]) -> void:
	for o: Unit in units.values():
		if o == u or not o.is_alive() or Faction.friends(o.faction, u.faction):
			continue
		if passed.any(func(c: Vector2i): return next_to(c, o.cell)):
			_feel(u, o)  # u brushes past o
		if next_to(u.cell, o.cell):
			_feel(o, u)  # o finds u beside it


# o, in contact with h, looks into the hiding skill on h it hasn't already seen through, against its roll.
func _feel(o: Unit, h: Unit) -> void:
	if o.asleep() or not h.is_alive():
		return
	for e in h.timed:
		var a := h.timed[e]
		if e.stat == "concealment" and a.skill and a.skill.investigated and a.roll > 0 and o not in a.known_to:
			investigate(h, a.skill, [o] as Array[Unit], a.roll)
			return


# Each of `eyes` looks into what skill just did to u (Hide, Clever Disguise): d20 + its wis mod -
# the better of two d20s within (wis mod - rank) tiles of u - against the roll u made using it.
# Meeting it, it sees through the skill's effects on u for as long as they last.
func investigate(u: Unit, skill: Skill, eyes: Array[Unit], against: int) -> void:
	for o in eyes:
		var close := is_close(o, u, skill)
		var look := check(o, &"wisdom", null, against, {edge = 1 if close else 0})  # against the hider's roll, spent
		var total := look.mine.total
		if look.won:
			for e in skill.effects:
				if e in u.timed:
					u.timed[e].known_to.append(o)
		investigated.emit(o, u, skill, total, against, close)


# The roll `target` makes using `skill` cast by `caster` (cast()): d20 + its mod in the skill's stat (as the
# caster's skill tags check it) + the caster's rank impact `ri` - its dissonance, at advantage under cover.
static func guise(caster: Unit, skill: Skill, target: Unit, ri: int, cover := false) -> Check:
	return Check.side(target.check_mod(skill.stat(), &"defensive", caster.skill_tags(skill)) + ri - target.dissonance_penalty(), Check.Kind.CHECK).edge(1 if cover else 0)


# Whether o is near enough to u to look at what `skill` did to it at advantage: within (wis mod - rank) tiles.
static func is_close(o: Unit, u: Unit, skill: Skill) -> bool:
	return Command.tiles(o.cell, u.cell) <= o.mod(&"wisdom") - u.rank(skill)


# The chance (0-1) at least one of `eyes` sees through `skill` as caster uses it on target (investigate()):
# the guise is one roll for them all, so each of its totals is weighed in turn, then each watcher's look
# against it (their odds are independent after it). The HUD's forecast and the AI read this.
static func seen_odds(caster: Unit, skill: Skill, target: Unit, eyes: Array[Unit], b: Battle = null) -> float:
	var ri := caster.mods(skill).irank(caster.rank(skill), &"rank_impact")
	var hiding := skill.effects.any(func(e: Effect): return e.stat == "concealment")
	var p := 0.0
	for f in Check.totals(guise(caster, skill, target, ri, hiding and b != null and b.covered(target.cell))):
		var unseen := 1.0
		for o in eyes:
			unseen *= 1.0 - odds(o, &"wisdom", null, f[0], {edge = 1 if is_close(o, target, skill) else 0})
		p += f[1] * (1.0 - unseen)
	return p


# u's awake allies, itself among them, whose Self-evaluation reaches it: they see the rolls it makes.
func evaluators(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		if o.faction == u.faction and o.is_alive() and not o.asleep() and o.evaluates() > 0 and Command.tiles(o.cell, u.cell) <= o.evaluates():
			out.append(o)
	return out


# A roll u just made using skill (d20, and its total), seen if one of its evaluators() is in reach.
func _evaluate(u: Unit, skill: Skill, d20: int, total: int) -> bool:
	if evaluators(u).is_empty():
		return false
	evaluated.emit(u, skill, d20, total)
	return true


# The chance (0-1) an attack with s by u hits t: the d20 rolls that reach t's Defense, a natural
# 20 always among them. Given the battle, its behaviours' say on the roll too (edge(), guard(): Gank, Spike).
# A skill whose declared check stands in place of the roll (a save, Drown's drag): the chance it wins
# that (skill_odds(), the one check helper's odds), a drag's penalty over the tiles to its spot.
# `guess` >= 0: the Defense the viewer takes t to have (Read.believed(): what it makes out, a lie too, or a stand-in
# when it can't; the AI and the HUD both pass it); a tagged Defense (rear, magical) still moves it as it moves t's own.
static func hit_chance(u: Unit, s: Skill, t: Unit, b: Battle = null, guess := -1) -> float:
	if s.check and not s.check.suspicion and t != u and not Faction.friends(t.faction, u.faction):
		var spot: Variant = b.drag_spot(u, s, t) if b and s.drags() else null
		return skill_odds(u, s, t, b, {tiles = Command.tiles(t.cell, spot)} if spot != null else {})
	if s.levels_down and t != u and not Faction.friends(t.faction, u.faction):
		return level_odds(u, s, t, u.mods(s).irank(u.rank(s), &"rank_impact"), b)
	if not s.attacks():
		return 1.0
	var c: Behaviour.Cast = b.cast_of(u, s, t, u.rank(s), true) if b and not s.behaviours.is_empty() else null
	var req: Array = b.requirement(u, s, t, u.rank(s)) if b else [0, 0, 0, 0, 0.0]  # its contingency, as cast() reads it
	var tags := c.tags if c else hit_tags(u, s, t, b)
	var p := clampi(21 - ((t.defense(tags) if guess < 0 else guess + t.defense(tags) - t.defense()) + guard_of(c) - u.attack_mod(s) - s.roll_per_rank * u.mods(s).irank(u.rank(s), &"rank_impact") - s.roll_bonus - int(req[0]) - passion(u, t) - u.check_bonus(u.wielded(s.stat(), s.tags), &"offensive") - u.focus_forecast(s)), 1, 20) / 20.0
	var edge := clampi(edge_of(s, c) + int(req[2]), -1, 1)

	if edge < 0:
		return p * p
	return 1.0 - (1.0 - p) * (1.0 - p) if edge > 0 else p


# What s deals in u's hands, before the target's Defense, mitigation and damage effects: {lo, hi, avg}
# over all its hits; empty if it deals none. Read as cast() reads it - its tier, dice and hits at its
# rank impact, its stat at its stat impact (u's modifiers: Unit.mods()), its weapon - and, given its
# target and the battle, its contingency's + damage (requirement()). The HUD's forecast (HUD._hurt())
# and the AI's score (AI.score()) both read it.
static func damage_range(u: Unit, s: Skill, t: Unit = null, b: Battle = null) -> Dictionary:
	var m := u.mods(s)
	var r := u.rank(s)
	var ri := m.irank(r, &"rank_impact")
	var tier := s.tier(ri)
	if not tier:
		return {}
	var hits := ri if s.hits_per_rank else 1
	var count := tier.dice.x * (ri if s.dice_per_rank else (Difficulty.scaled(s.dice_scale, ri) if s.dice_scale else 1))
	var tags := u.skill_tags(s)
	var bonus := (m.stat(u.mod(u.wielded(tier.stat, tags), tags), &"stat_impact") + u.weapon_bonus(tier.stat)) if tier.stat else 0
	if b and t:
		bonus += int(b.requirement(u, s, t, r)[1])
	var lo := maxi(tier.power + count + bonus, 1) * hits
	var hi := maxi(tier.power + count * tier.dice.y + bonus, 1) * hits
	return {lo = lo, hi = hi, avg = (lo + hi) / 2.0}


# What a hit with s by u on t would do beyond damage_range(), as its behaviours foresee it
# (Behaviour.foresee(): Kick's tile, Displace's move) and its own forced-move effects (shove, fear, entrance:
# foresee_drive()): {lo, hi: more HP off t, notes: a line for each rider, riders, spill: for the AI}. The HUD's
# forecast (HUD._hurt()) and the AI's score (AI.score()) both read it. Empty: nothing more.
func foresee(u: Unit, s: Skill, t: Unit) -> Dictionary:
	if not t or (s.behaviours.is_empty() and not s.effects.any(func(e: Effect): return DRIVES.has(StringName(e.stat)))):
		return {}
	var foe := t != u and not Faction.friends(t.faction, u.faction)
	var c := cast_of(u, s, t, u.rank(s), foe)
	var out := {lo = 0, hi = 0, notes = [] as Array[String], riders = 0.0, spill = 0.0}
	var found: Array[Dictionary] = []
	for bh in s.behaviours:
		found.append(bh.foresee(c))
	if t != u and not (s.dual and foe):  # its effects land on the target (cast()); a forced move is read where it would end
		for e in s.effects:
			var dir: int = DRIVES.get(StringName(e.stat), 0)
			if dir != 0:
				var n := roundi(e.amount * (c.impact_rank() if e.per_rank else c.rank) * (c.mods.statf(maxf(u.mod(e.by_mod), 0.0), &"stat_impact") if e.by_mod else 1.0))
				found.append(foresee_drive(u, t, u.cell, dir, n, false, VERBS.get(StringName(e.stat), "Drives it")))
	for f in found:
		var notes: Array = f.get("notes", [])
		out.lo += int(f.get("lo", 0))
		out.hi += int(f.get("hi", 0))
		out.notes.append_array(notes)
		out.riders += float(f.get("riders", notes.size()))
		out.spill += float(f.get("spill", 0.0))
	return out if out.hi > 0 or not out.notes.is_empty() or out.spill != 0.0 else {}


# What f reads with u standing on c, where it could walk to, rather than where it is (foresee() from there: the AI
# lining up a shove), u put back where it was; null if c is taken or u is sharing a tile. A planning question: nothing
# is felt, spoken or sprung on the way.
func standing(u: Unit, c: Vector2i, f: Callable) -> Variant:
	var home := u.cell
	if c == home:
		return f.call()
	if inside.has(u) or unit_at(c) or not on_map(c):
		return null
	var steadied: Variant = u.steadied
	move(u, c)
	var out: Variant = f.call()
	move(u, home)
	u.steadied = steadied
	return out


const PUSH := 0.5  # riders a tile a forced move takes its foe is worth (foresee_drive(): the AI weighs a rider at AI.RIDER)
const VERBS := {&"shove": "Shoves it", &"fear": "Frightens it", &"entrance": "Draws it"}  # a forced-move effect's line in the forecast


# Where displace() (the same arguments) would take t, read without moving it: {went: tiles, left: tiles
# unspent, into: the unit it stops against (null: the edge, or it went all the way), end: the tile it ends on}.
func course(t: Unit, from: Vector2i, dir: int, n: int, teleport := false) -> Dictionary:
	var line := Vector2(t.cell - from).normalized() * signf(dir)
	var at := t.cell
	var went := 0
	var into: Unit = null
	if teleport:
		for k in range(n, 0, -1):
			var c := Vector2i((Vector2(t.cell) + line * k).round())
			if c != t.cell and c != from and on_map(c) and not unit_at(c) and (dir > 0 or Command.tiles(t.cell, c) < Command.tiles(t.cell, from)):
				return {went = k, left = n - k, into = null, end = c}
		return {went = 0, left = n, into = null, end = at}
	for k in range(1, n + 1):
		var c: Vector2i
		if dir < 0:
			if next_to(at, from):
				break
			var d := from - at
			c = at + Vector2i(signi(d.x), signi(d.y))
		else:
			c = Vector2i((Vector2(t.cell) + line * k).round())
			if c == at:
				continue
		var other := unit_at(c) if on_map(c) else null
		if not on_map(c) or (other and other != t):
			into = other
			break
		at = c
		went += 1
	return {went = went, left = n - went, into = into, end = at}


# The forecast of a forced move by `by` (Behaviour.foresee()'s shape, from course()): a line saying how far
# and where t ends; its tiles are riders at PUSH each; a push stopped short slams (`lo`, `hi`, as _slam()
# deals it, and `spill` for the unit it struck, an ally of `by` counting against).
func foresee_drive(by: Unit, t: Unit, from: Vector2i, dir: int, n: int, teleport := false, verb := "Drives it") -> Dictionary:
	var run := course(t, from, dir, n, teleport)
	var out := {lo = 0, hi = 0, notes = [] as Array[String], riders = PUSH * run.went}
	var line := "%s %d tile%s %s to (%d, %d)" % [verb, run.went, "" if run.went == 1 else "s", "toward the caster" if dir < 0 else ("away" if teleport else "back"), run.end.x, run.end.y]
	if dir > 0 and not teleport and run.left > 0:
		var slam: int = SLAM * run.left
		out.lo = slam
		out.hi = slam
		line += ", then slams %s (%d each)" % [run.into.name if run.into else "the edge", slam]
		if run.into:
			out.spill = slam * (-1.0 if Faction.friends(run.into.faction, by.faction) else 1.0)
	out.notes.append(line)
	return out


# A hostile skill aimed at a tile rather than at a unit the caster can make out (the player's
# Ctrl-click): whoever is there takes it as an ordinary cast. If it doesn't land - nobody there, or
# not quite in reach of what is - it's spent on thin air, as long as the tile itself was in reach
# of a Medium target. Returns &"hit", &"miss", or &"" when it couldn't be tried at all.
func attempt(caster: Unit, skill: Skill, c: Vector2i) -> StringName:
	if not _acting(caster) or skill not in caster.actives or not skill.for_foes() or skill.behaviour(&"zone") or not on_map(c):
		return &""
	var t := unit_at(c)
	if t and t != caster and cast(caster, skill, t):
		return &"hit"
	if Vector2(caster.cell).distance_to(Vector2(c)) > skill_range(caster, skill) + 0.0001 or not caster.pay_for(skill):
		return &""
	used.emit(caster, skill, c, 0)
	var broke := not t and expose(c, hit_tags(caster, skill), caster)
	if broke:
		shattered.emit(caster, c)
	_done_casting(caster, true)  # spent on thin air: an interrupter's action all the same
	return &"shattered" if broke else &"miss"


# Hitting a unit, or attacking, gives away where it is: a hidden one loses a level of concealment
# until its side's next turn starts.
func _lose_cover(u: Unit) -> void:
	if Perception.cover(self, u) > 0:
		u.exposed += 1


# Skills cast on a cell, within area_reach(): most do what their behaviours do there (Behaviour.apply_at():
# Darkstone's zone, Flamewall, Solar and Wildfire's cones, Observe, Shields Up!, Well Up); trap skills (Snare) lay a trap there (lay());
# channeled skills (Metea) begin channeling there, and once begun strike where they can (_detonate()).
# A Rift is channeled unless `held` is false (Alt-click): then its count starts at once.
func cast_at(caster: Unit, skill: Skill, c: Vector2i, held := true) -> bool:
	_casting += 1
	var done := _cast_at(caster, skill, c, held)
	_casting -= 1
	_done_casting(caster, done)
	return done


func _cast_at(caster: Unit, skill: Skill, c: Vector2i, held := true) -> bool:
	if not _acting(caster) or skill not in caster.actives or not skill.on_tile() or not on_map(c):
		return false
	if (caster.stat(&"mist") > 0.0) != skill.mist_only:
		return false  # a mist only Coalesces (Vaporize)
	if not caster.shaped_allows(skill):
		return false  # a beast's mind (Beastshape)
	if skill.channel and caster.channel and caster.channel.skill == skill:
		return _detonate(caster, skill, c)
	if skill.rifts and caster.channel and caster.channel.skill == skill:
		return close_rift(caster)  # used again: it stops channeling, and the rift closes
	if Vector2(caster.cell).distance_to(Vector2(c)) > area_reach(caster, skill) + 0.0001:
		return false
	if skill.lays and (unit_at(c) or terrain(c).is_trap()):
		return false
	if skill.rifts and not can_rift(caster, skill, c):
		return false
	var at := unit_at(c)
	if not caster.pay_for(skill, price_cut(caster, skill, [at] as Array[Unit])):
		return false
	caster.face(c)
	_burn(caster, skill)
	if skill.channel:
		end_channel(caster)
		caster.channel = Unit.Channel.new(skill, c)
		channeled.emit(caster, skill, c)
	elif skill.rifts:
		open_rift(caster, skill, c, held)
	elif skill.lays:
		lay(caster, skill, c)
	else:
		_land(cast_of(caster, skill, null, caster.rank(skill), skill.hostile), c)  # its behaviours' apply_at() (Flamewall, Solar, Observe...)
	caster.striding = false
	used.emit(caster, skill, c, 0)
	return true


# A trap skill's trap, laid into the ground at c: the skill's `lays` with its concealment and dice
# multiplier times the setter's rank, plus the setter's mod in its bonus stat; its wounds (Snare:
# Bleeding) last rank + that mod turns, at least 1. The setter knows it;
# for skills tagged trap, so do allies within its charisma mod in tiles (at least 1; trap_word
# multiplies that: Hazard Expert), and with trap_word, allies further off get a vibe of it.
func lay(u: Unit, skill: Skill, c: Vector2i) -> Snare:
	var r := u.mods(skill).irank(u.rank(skill), &"rank_impact")  # its trap's per-rank strength
	var ground := terrain(c)
	var t: Terrain = ground.duplicate()
	var plan := skill.lays
	t.name = plan.name
	var tags: Array[StringName] = []
	tags.assign(ground.tags + plan.tags)
	t.tags = tags
	t.concealment = plan.concealment * r
	t.kind = plan.kind
	t.looks_like = StringName(ground.name)
	t.shape = plan.shape
	t.vibe = plan.vibe
	t.dice = plan.dice
	t.times = plan.times * r
	t.bonus = plan.bonus + (u.mod(plan.bonus_stat, skill.tags) if plan.bonus_stat else 0)
	t.damage_tags = plan.damage_tags
	t.blast = plan.blast
	t.reveals = plan.reveals
	t.level = r
	t.wounds = plan.wounds
	t.wound_turns = maxi(r + (u.mod(plan.bonus_stat, skill.tags) if plan.bonus_stat else 0), 1)
	var snare := Snare.new(t, u)
	snare.known[u] = true
	if &"trap" in skill.tags:
		var word := maxf(u.mod(&"charisma"), 1.0) * (1.0 + u.stat(&"trap_word"))
		for o in members(u.faction):
			if roundi(Vector2(o.cell).distance_to(Vector2(u.cell))) <= word:
				snare.known[o] = true
		snare.word = u.stat(&"trap_word") > 0.0
	snares[c] = snare
	_restack(c)
	revealed.erase(c)
	return snare


# A channeled skill (Metea) strikes, for its smaller strike AP and cost: an explosion on c, which must be
# within (its side's turns since the channel began) tiles of where it was cast - only that tile, the turn
# it's cast - hitting every unit within rank tiles of it but the caster. The channel ends.
func _detonate(caster: Unit, skill: Skill, c: Vector2i) -> bool:
	var ch := caster.channel
	if Command.tiles(ch.at, c) > ch.turns or not caster.pay_strike(skill):
		return false
	caster.channel = null
	var r := caster.rank(skill)
	var m := caster.mods(skill)
	var ri := m.irank(r, &"rank_impact")
	var blast := skill.blast * m.rank(r, &"rank_range")
	var tags := hit_tags(caster, skill)
	var t := skill.tier(ri)
	var hit := {}
	var blasting := cast_of(caster, skill, null, r, skill.hostile)
	for o: Unit in units.values():
		if o == caster or not o.is_alive() or Vector2(o.cell).distance_to(Vector2(c)) > blast + 0.0001:
			continue
		area_blow(blasting, o, func(w: Unit, _share: float):
			var power := maxi(t.power + roll(t.dice) * (ri if skill.dice_per_rank else 1) + (m.stat(caster.mod(t.stat, tags), &"stat_impact") if t.stat else 0) + int(requirement(caster, skill, w, r)[1]), 1) if t else 0
			var was := w.hp
			w.hit(power * (1.0 + caster.stat(&"damage", tags)), tags, caster)
			hit[w] = hit.get(w, 0) + was - w.hp
			_lose_cover(w)
			if not w.is_alive() and w.faction != caster.faction:
				caster.gain(&"kill", 1))
	_lose_cover(caster)
	for at in cells_near(c, blast):
		if Vector2(at).distance_to(Vector2(c)) <= blast + 0.0001:
			expose(at, tags, caster)
	used.emit(caster, skill, c, hit.values().reduce(func(sum, x): return sum + x, 0))
	exploded.emit(caster, skill, c, hit)
	return true


# Where a channeled skill can strike now: tiles within (turns since it began) of where it was cast.
func strike_tiles(u: Unit) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if u.channel:
		for c in cells_near(u.channel.at, u.channel.turns):
			if Command.tiles(u.channel.at, c) <= u.channel.turns:
				out.append(c)
	return out


# --- Items in battle

# Whether u's items can change now: on its side's turn, or once the battle is over.
func outfitting(u: Unit) -> bool:
	return phase == Phase.OVER or _acting(u)


# AP an item takes u to put on or use now (Item.ap_cost(): trinkets 1, weapons 2, armor 10 - dex mod):
# none once the battle's over.
func item_ap(it: Item, u: Unit = null) -> float:
	return it.ap_cost(u) if it and phase == Phase.TURNS else 0.0


# AP putting it on takes u now (taking things off is free).
func equip_ap(u: Unit, it: Item) -> float:
	return item_ap(it, u)


# Puts it on u, paying equip_ap() from its general AP. False (nothing changes) if it can't - or if
# what's in that slot is bound on (Shackles: unshackle() first).
func equip(u: Unit, it: Item) -> bool:
	var there: Item = u.get(it.slot) if it else null
	if not outfitting(u) or not u.can_wear(it) or (there and there.binding) or u.ap_for(&"equip") < equip_ap(u, it) - 0.0001:
		return false
	u.pay(equip_ap(u, it), &"equip")
	u.equip(it)
	return true


# Takes what's in u's slot off, free. What came off, or null if it couldn't.
func unequip(u: Unit, slot: String) -> Item:
	var it: Item = u.get(slot)
	if not it or not outfitting(u) or it.binding:  # shackles come off through unshackle()
		return null
	return u.unequip(slot)


# After a Meditation (respec_room), u moves up to that many points from some core stats into others
# (Unit.respec_by()), all or nothing. The room is spent either way. True if they shifted.
func respec(u: Unit, changes: Dictionary) -> bool:
	if u.respec_room <= 0:
		return false
	var room := u.respec_room
	u.respec_room = 0
	if changes.is_empty() or not u.respec_by(changes, room):
		return false
	respecced.emit(u, changes)
	return true


# Binds a skill's item (Judgement: Shackles) onto t at rank r, weight r, in place of its trinket - stowed
# till they come off. Its Shackled effect (the skill's effects, r turns) is the lock.
func _bind(caster: Unit, skill: Skill, t: Unit, r: int) -> void:
	var it: Item = skill.binds.duplicate()
	it.rank = r
	it.weight = r
	if t.trinket and not t.trinket.binding:
		t.stowed = t.trinket
	t.trinket = it
	t.refit()
	bound.emit(caster, t, it)


# u works at its shackles on its turn, for their rank in AP whatever comes of it: &"unlock" takes them
# off once they're no longer locked (Shackled has run out, or been cleansed); &"pick" lockpicks them
# (a dex check at their `picks` difficulty, their rank); &"pry" pries them apart (str, `prised`). Off,
# its stowed trinket goes back on and the shackles fall away. True if they came off.
func unshackle(u: Unit, how: StringName) -> bool:
	var it := u.trinket
	if not it or not it.binding or not _acting(u) or u.ap_for(&"equip") < it.ranked() - 0.0001:
		return false
	if how == &"unlock" and u.shackled():
		return false
	var diff: StringName = it.picks if how == &"pick" else (it.prised if how == &"pry" else &"")
	if how != &"unlock" and diff == &"":
		return false
	u.pay(it.ranked(), &"equip")
	var done := true
	if how != &"unlock":
		var stat := &"dexterity" if how == &"pick" else &"strength"
		var dc := Difficulty.dc(diff, it.ranked())
		var roll := check(u, stat, null, dc)
		done = roll.won
		freed.emit(u, how, roll.mine.total, dc, done)
	else:
		freed.emit(u, how, 0, 0, true)
	if done:
		for e in u.timed.keys().filter(func(x: Effect): return x.stat == "shackled"):
			u.timed.erase(e)
		u.trinket = u.stowed
		u.stowed = null
		u.refit()
	return done


# Uses an item, paying its AP: a consumable from the stash, used up (a Heart: an extra life for good),
# or the one in u's trinket slot that restores something (a potion: Item.restores; restore()), which
# empties it until the battle ends (Item.empty; refill()). False if it can't.
func use_item(u: Unit, it: Item) -> bool:
	if it == null or not outfitting(u) or not (it.slot == "consumable" or (it == u.trinket and it.restores and not it.empty)):
		return false
	if not u.pay(item_ap(it, u), &"equip"):
		return false
	u.hearts += it.hearts if it.slot == "consumable" else 0
	if it.restores:
		restore(u, it)
	if it == u.trinket:
		u.trinket = it.emptied()
	return true


# Emptied trinkets (potions) fill up again: as each battle ends, for everyone (and a starter's, as it's
# put on: starter()).
static func refill(u: Unit) -> void:
	if u.trinket and u.trinket.empty:
		u.trinket = u.trinket.filled()


# A potion's restoring: (its share x rank) of the max of what it restores, rounded by luck, + the
# user's mod in restore_mod + restore_flat (Health Potion: 15% of max HP + con mod; Sweet Something:
# 1 Sweet Nothing). What it gave back.
func restore(u: Unit, it: Item) -> int:
	var r: Reserve = it.reserve if it.restores == &"reserve" else null
	var most: int = u.max_hp if it.restores == &"hp" else (u.max_energy if it.restores == &"energy" else u.pools().get(r, 0))
	var n := maxi(u.rounded(most * it.restore_share * it.ranked()) + (u.mod(it.restore_mod) if it.restore_mod else 0) + it.restore_flat, 0)
	match it.restores:
		&"hp":
			var was := u.hp
			u.heal(n)
			return u.hp - was
		&"energy":
			return u.grant_energy(n)
	if r:
		var was := u.store(r)
		u.set_store(r, was + n)
		u.note_recovery(r, u.store(r) - was)
		return u.store(r) - was
	return 0


# What side f takes home from the battle: the items units of other sides dropped, and the scenario's
# rewards if it won.
func winnings(f: Faction) -> Array[Item]:
	var out: Array[Item] = []
	for pair in spoils:
		if pair[1] != f:
			out.append(pair[0])
	if won(f):
		out.append_array(rewards)
	return out


# How far from the caster an area skill can be centred: radius + radius_per_rank x rank.
func area_reach(caster: Unit, skill: Skill) -> float:
	return skill.span(caster)


# The levels an area skill of rank r lays around c: rank - distance on every tile that leaves above 0.
func zone_levels(r: int, c: Vector2i) -> Dictionary[Vector2i, int]:
	var levels: Dictionary[Vector2i, int] = {}
	for x in range(c.x - r, c.x + r + 1):
		for y in range(c.y - r, c.y + r + 1):
			var at := Vector2i(x, y)
			var lv := r - floori(Vector2(at).distance_to(Vector2(c)))
			if lv > 0 and on_map(at):
				levels[at] = lv
	return levels


# A tile whose terrain is still concealed (an unsprung trap).
func hidden(c: Vector2i) -> bool:
	return terrain(c).concealment > 0 and c not in revealed


# What o makes out of a unit or a tile. Linked by Coordinate, it makes out as much as the best of the
# others in its link do, up to the link's rank in levels better than it would alone (linked()).
func _linked_read(o: Unit, target: Variant) -> Read:
	var r := _read(o, target)
	var link := o.linked()
	if link == null or (target is Unit and target == o):
		return r
	var best := r.net
	for p in linked(o):
		if not (target is Unit and p == target):
			best = maxi(best, _read(p, target).net)
	var lift := mini(best - r.net, link.rank)
	return r if lift <= 0 else _read(o, target, lift)


# What o makes out, with what its synergized partners make out filling the gaps: the clearest of them.
func read(o: Unit, target: Variant) -> Read:
	Unit.begin_read()  # its effects held still for the read's length (Unit._effects())
	var r := _linked_read(o, target)
	if not (target is Unit and target == o):
		for p in synergized(o):
			if not (target is Unit and p == target):
				var pr := _linked_read(p, target)
				if clearer(pr, r):
					r = pr
	Unit.end_read()
	return r


func _read(o: Unit, target: Variant, extra := 0.0) -> Read:
	if o.faction in studied:
		extra += studied[o.faction].get(target, 0)  # studied in preparation (study())
	if o in noticed:
		extra += noticed[o].get(target, 0)  # learned on its own (note(): bumping into it unseen)
	return Perception.unit(self, o, target, extra) if target is Unit else Perception.tile(self, o, target, extra)


# o gains n recon levels on k (a unit or a tile), its own, for the battle (_read()): bumping into a unit
# it couldn't place (travel()). Anything that teaches one unit about another can add here.
func note(o: Unit, k: Variant, n := 1) -> void:
	var mine: Dictionary = noticed.get_or_add(o, {})
	mine[k] = mine.get(k, 0) + n


# The others o shares what it makes out with: those Coordinate linked along with it (the same caster's
# link, still on them), alive.
func linked(o: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	var link := o.linked()
	if link == null:
		return out
	for p: Unit in units.values():
		if p != o and p.is_alive() and p.linked() and p.linked().by == link.by:
			out.append(p)
	return out


# Coordinate: caster links up with its teammates within its cha mod in tiles (at least 1) and its
# leader, wherever it is, putting the skill's effects on each of them as on itself: they pool what they
# make out (read()).
func _link(caster: Unit, skill: Skill, r: int) -> void:
	var near := maxi(caster.mods(skill).stat(caster.mod(&"charisma"), &"stat_range"), 1)  # its reach: stat range
	for o: Unit in units.values():
		if o == caster or not o.is_alive() or not teammates(caster, o):
			continue
		if Command.tiles(o.cell, caster.cell) <= near or o == caster.follows:
			for e in skill.effects:
				var n := skill.lasts(r, caster)
				var a := o.afflict(e, n + (1 if o.faction == turn else 0), caster.mods(skill).irank(r, &"rank_impact") if e.per_rank else r)
				a.skill = skill
				a.by = caster
				a.since = turns_begun
				drive(o, e, a)  # shove, fear, entrance


# Each takes the other for a teammate (Command: only teammates give each other orders or share a
# party). A persona's stance can put it on the wrong team in an ally's eyes (Read.attitude()); not
# making out its side at all, they still trust it.
func teammates(a: Unit, c: Unit) -> bool:
	return a == c or (_trusts(a, c) and _trusts(c, a))


func _trusts(o: Unit, t: Unit) -> bool:
	if o.stance == "Traitor" and o.faction != t.faction:
		return true  # it pretends to
	var r := read(o, t)
	return r.faction == null or r.attitude(o) == &"ally"


# Dice as Vector2i(count, sides): Vector2i(1, 6) is d6.
func roll(dice: Vector2i) -> int:
	var sum := 0
	for i in dice.x:
		sum += rng.randi_range(1, dice.y)
	return sum


# Skill range (Skill.span(): the starter spells' grows with int mod) + the caster's reach (its reach
# stat, +0.05 per size point) + 0.02 per size point of the target (bigger targets are easier to
# reach). No target: a Medium one.
func skill_range(caster: Unit, skill: Skill, target: Unit = null) -> float:
	var size: float = target.stat(&"size") if target else float(MEDIUM)
	return skill.span(caster) + caster.stat(&"reach") + 0.05 * caster.stat(&"size") + 0.02 * size


# Circle geometry. A near miss (within Luck.MARGIN) is rounding: in only if the caster is luckier.
func in_reach(caster: Unit, skill: Skill, target: Unit) -> bool:
	var over := Vector2(caster.cell).distance_to(Vector2(target.cell)) - skill_range(caster, skill, target)
	if over <= 0.0001:
		return true
	return over < Luck.MARGIN and caster.luck - target.luck > 0


# --- Movement

# Walks the straight line toward `dest` (see walk()), paying movement and the same AP per step.
# A trap it stops on springs. Ground a unit standing still passes by (Meander: Unit.passes_by())
# does nothing to it. Held, it must break free first (_break_free()). Returns the tiles passed.
func travel(u: Unit, dest: Vector2i) -> Array[Vector2i]:
	var passed: Array[Vector2i] = []
	if not _acting(u) or dest == u.cell or u == interrupter:  # an interrupt is skill uses, no walking
		return passed
	if held_by(u) and not _break_free(u):
		return passed
	var w := walk(u, dest)
	passed = w.path
	if w.blocker and not read(u, w.blocker).located():  # it walked into something it couldn't place: that it's there, at least
		note(u, w.blocker)
		bumped.emit(u, w.blocker)
	if not passed.is_empty():
		var from := u.cell
		var sights := _sightings(u)  # those watching it step into cover (_vanish())
		var touched := range(passed.size()).filter(func(i: int): return not u.passes_by(terrain(passed[i]), i + 1))
		var began := u.steps  # the tiles it had walked before this (_toll())
		u.walked(passed.size(), w.costs.reduce(func(sum, x): return sum + x, 0.0))
		for k: StringName in w.bag:
			u.tally[k] = u.tally.get(k, 0) + w.bag[k]
		var blind := obscured(passed[-1])  # what's under the leaves it walks onto, it can't see
		move(u, passed[-1])
		_tow(u, from, passed[-1])
		u.blind_on = passed[-1] if blind else null
		for i in touched:  # stepping in happens on the unit's own turn, which isn't one of those counted
			for e in terrain(passed[i]).afflicts:
				u.afflict(e, (e.turns if e.turns else terrain(passed[i]).turns) + 1)
		u.face(passed[-1] + passed[-1] - (passed[-2] if passed.size() > 1 else from))  # the way its last step went
		u.striding = true
		for c in passed:  # trodden into the ground
			debris.erase(c)
		for c in passed:  # walking into fire, and onto marks
			if c in flames and u.is_alive():
				flame(u, flames[c], "walks into fire")
			if c in marks and u.is_alive():
				_trigger(u, c, &"enter")
		_toll(u, passed, began)  # what it costs to walk, tile by tile
		if Perception.cover(self, u) > 0:
			_scatter(u, _hide_roll(u), passed)
			_vanish(u, sights)
		_tidy_debris()
		_contact(u, passed)
		traveled.emit(u, from, passed)
		_through(u)
		if terrain(u.cell).is_trap() and passed.size() - 1 in touched:
			spring(u.cell, u)
		if u.is_alive():
			_first_look(u)
	return passed


# u, having moved from `from` to `to`, drags along whoever it holds by a grip with tow (Hitch): up to
# that many tiles the same way, a tile at a time, stopping at anything in the way.
func _tow(u: Unit, from: Vector2i, to: Vector2i) -> void:
	var dir := Vector2(to - from).normalized()
	for o: Unit in units.values().duplicate():
		var a := held_by(o) if o != u else null
		if a == null or a.by != u:
			continue
		var n := roundi(o.stat(&"tow"))
		var start := Vector2(o.cell)
		for k in range(1, n + 1):
			var c := Vector2i((start + dir * k).round())
			if c == o.cell:
				continue
			if not on_map(c) or not move(o, c):
				break


# Those u holds in a grapple (held_by(): Drown, Hitch).
func holding(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in units.values():
		var a := held_by(o) if o != u else null
		if a and a.by == u:
			out.append(o)
	return out


# Any grapple u is in lets go, as holder or held: a forced move breaks it.
func _break_grips(u: Unit) -> void:
	var a := held_by(u)
	if a:
		_let_go(u, a.skill)
	for o in holding(u):
		_let_go(o, held_by(o).skill)


# A grip with tow lasts only its holder's turn: as u's side's turn ends, it lets go of those it holds so.
func _release_tows(u: Unit) -> void:
	for o: Unit in units.values().duplicate():
		var a := held_by(o) if o != u else null
		if a and a.by == u and o.stat(&"tow") > 0.0:
			_let_go(o, a.skill)


# The grip holding u (a grapple: Drown's effects), or null.
func held_by(u: Unit) -> Unit.Applied:
	for e in u.timed:
		var a := u.timed[e]
		if a.lasting and a.skill and a.skill.holds():
			return a
	return null


# What trying to break free costs u in movement: 1 + its holder's mod in the grip's stat tiles (at
# least 1); 0 when nothing holds it.
func escape_cost(u: Unit) -> float:
	var a := held_by(u)
	if a == null:
		return 0.0
	return float(maxi(1 + a.by.mod(a.skill.stat(), a.skill.tags), 1)) if a.by else 1.0


# Held, u tries to move away from its holder: it spends escape_cost() movement, then d20 + its mod in
# the grip's stat against its holder's (the holder keeps it on a tie). Won, the grip's gone and it
# walks on with what movement it has left. A holder that's fallen, or isn't beside it, has let go.
func _break_free(u: Unit) -> bool:
	var a := held_by(u)
	var by := a.by
	var s := a.skill
	if not by or not by.is_alive() or not _within_grip(by, u):
		_let_go(u, s)
		return true
	var cost := escape_cost(u)
	if u.move_left() < cost - 0.0001:
		return false
	u.walked(0, cost)
	var vs := check(u, s.stat(), by, s.stat(), {role = &"defensive", tags = s.tags, ties = false})  # the holder wins ties
	struggled.emit(u, by, vs.mine.total, vs.theirs.total)
	if vs.won:
		_let_go(u, s)
		return true
	return false


# The walk toward `dest`: {line, path, costs, blocker} - the straight line, the tiles kept, what each
# cost, and the unit that stopped it short, if one did (it couldn't stand on its tile, or couldn't pay to
# pass it). Leaving a tile costs its exit, entering costs its enter (plus the unit's move_cost effects
# for that ground), and moving through another unit costs pass_cost(). Stops where movement or AP
# runs out, before a hole, short of other units (they can be passed, not stood on), and on a trap.
# Short by a fraction, net luck can squeeze one more tile in - but never luckily onto ground the
# unit doesn't know is bad.
# `expected` gives the walk as `u` sees it coming: ground it can't make out counts as plain, units it
# can't locate aren't in the way, and the rng is left as it was (so the real walk takes this line).
func walk(u: Unit, dest: Vector2i, expected := false) -> Dictionary:
	var state := rng.state
	var ground := func(c: Vector2i) -> Terrain:
		return terrain(c) if not expected or read(u, c).net >= 0 else PLAIN
	var in_way := func(c: Vector2i) -> Unit:
		var o := unit_at(c)
		return o if o and o != u and (not expected or read(u, o).located()) else null
	var blocked := func(c: Vector2i) -> bool:
		return in_way.call(c) != null
	var path: Array[Vector2i] = []
	var costs: Array[float] = []
	var blocker: Unit = null
	var bag := {}  # its steps' hooks' scratch (Behaviour.step_cost()); kept on the unit as it walks (Unit.tally)
	var left := u.move_left() - escape_cost(u)
	if held_by(u) and not expected:
		left = 0.0  # held: travel() breaks it free first
	var ln := route(u, dest, line(u.cell, dest, u.luck, u))  # the straight line, bent round what it knows is bad (route())
	var from: Terrain = ground.call(u.cell)
	for c in ln:
		if not on_map(c) or left <= 0.0001:
			break
		var t: Terrain = ground.call(c)
		var other: Unit = in_way.call(c)
		var cost := stride(u, path[-1] if not path.is_empty() else u.cell, c, from, t, bag, other, expected)
		if cost > left + 0.0001:
			var unknown_bad := t.worth() < 0 and not read(u, c).known_bad()
			if Luck.settle(left / cost, u.luck, not unknown_bad, false) < 1:
				if other and cost - pass_cost(u, other) <= left + 0.0001:
					blocker = other  # it could have paid for the ground, not for getting past
				break
			cost = left  # squeezed in on what was left
		left -= cost
		costs.append(cost)
		path.append(c)
		from = t
		if t.is_trap() and not blocked.call(c) and not u.passes_by(t, path.size()):
			break  # stepped on a trap
	while not path.is_empty() and blocked.call(path[-1]):  # units can be passed, not stood on
		blocker = in_way.call(path[-1])
		path.pop_back()
		costs.pop_back()
	if expected:
		rng.state = state
	return {line = ln, path = path, costs = costs, blocker = blocker, bag = bag}


# What one step of u's costs in movement, from tile `prev` (ground `from`) onto c (ground `t`) with `other`
# in the way: the one price walk() pays, the HUD's reach and preview show and route() weighs, so they
# can't disagree. Entering and leaving the ground, wading, obstruction, its passives' step_cost() hooks
# (Peel; `bag` is their scratch for the walk so far) and moving through the unit in the way.
func stride(u: Unit, prev: Vector2i, c: Vector2i, from: Terrain, t: Terrain, bag: Dictionary, other: Unit, expected := false) -> float:
	var cost := _cost(u, from, t) * wading(u, c, expected) + mark_cost(u, c, expected) + obstruction(u, c, expected)
	for h in u.hooks():
		cost = h[0].step_cost(self, u, h[1], prev, c, cost, bag)  # Peel
	return cost + (pass_cost(u, other) if other else 0.0)


# The ground u makes out on c: what's there, or plain where it can't make it out.
func known_ground(u: Unit, c: Vector2i) -> Terrain:
	return terrain(c) if read(u, c).net >= 0 else PLAIN


# How many hazard estimates u can make a turn: its int mod and its foresight stat (Effect: skills and
# items raise it). Below 0 it plans as if the way were safe: no "?" on the HUD's forecast (HUD.drain()),
# and its route isn't steered round what it knows is bad (route()).
func foresight_allowance(u: Unit) -> int:
	return u.mod(&"intelligence") + roundi(u.stat(&"foresight"))


# What stepping onto c would cost u that an observer reading it as `r` can foresee, by pool (&"hp",
# &"ap"): the one estimate behind the HUD's forecast (HUD.hazard()) and what route() steers by. A known
# trap's dice (times x the average + bonus) and its wounds; the effects ordinary ground it has read
# puts on whoever steps there (afflicts); and fire on the tile (1d8 + its setter's wis mod, at least 1:
# flame(), plainly visible to everyone). Effects that last count each tick they take HP: a bleed (dice
# average + the setter's mod, at least 1, else its amount: _bleed()) and poison (amount x max HP) every
# turn of their length; winded takes AP once. All before mitigation, as a hit isn't rolled. {}: nothing
# foreseen. Only what `r` makes out counts: an unseen trap or ground it can't read owes nothing.
# `nth`, when c is the nth tile of a walk (1 on), adds the toll of u's own per_tile effects (Footsore) for it,
# as _toll() takes it, Meander's wards included (`tolls` false: not - route() leaves out what every tile owes
# alike), and leaves out the trap and the ground's afflicts that standing still (Meander: passes_by()) passes
# by, as travel() does; 0, c on no walk: none of that. `ends`: c is where the walk ends, so what the ground
# puts on whoever ends its turn there (at_end: Magic Stew) counts too.
func hazard(u: Unit, c: Vector2i, r: Read, nth := 0, ends := false, tolls := true) -> Dictionary:
	var out := {}
	if nth > 0 and tolls:
		for e: Effect in u.timed.keys():
			if e.stat == "per_tile" and not u.wards(u.timed[e].rank, nth):
				_owe(out, &"hp", e.amount * (u.timed[e].rank if e.per_rank else 1.0) * u.timed[e].scale)
	var t := terrain(c)
	var by: Unit = null
	var passed := nth > 0 and u.passes_by(t, nth)  # standing still, it walks over the ground without touching it
	if r.trap == true and not passed:
		_owe(out, &"hp", t.times * t.dice.x * (t.dice.y + 1) / 2.0 + t.bonus)
		by = snares[c].by if c in snares and is_instance_valid(snares[c].by) else null
		for e in t.wounds:
			_owe_wound(out, u, e, maxi(t.wound_turns, 1), t.level, by)
	for e in r.afflicts if not passed else ([] as Array[Effect]):  # what ordinary ground does to whoever steps on it, for its turns
		_owe_wound(out, u, e, maxi(e.turns if e.turns else t.turns, 1), 1, null)  # (travel() puts them on at rank 1)
	for e in r.at_end if ends else ([] as Array[Effect]):  # and to whoever ends its turn there (end_turn(): the tick takes that turn)
		_owe_wound(out, u, e, maxi(e.turns if e.turns else t.turns, 1), 1, null)
	for m: Mark in r.marks:  # what the marks it knows of would put on it
		if m.on == &"enter" and m.hits(u):
			for e in m.effects:
				_owe_wound(out, u, e, maxi(e.turns if e.turns else m.effect_turns, 1), m.rank, m.by if is_instance_valid(m.by) else null)
	if c in flames:
		_owe(out, &"hp", maxf(4.5 + flames[c].bonus, 1.0))
	return out


func _owe_wound(out: Dictionary, u: Unit, e: Effect, ticks: int, level: int, by: Unit) -> void:
	match e.stat:
		"bleed":
			_owe(out, &"hp", ticks * maxf(((e.dice.x * (e.dice.y + 1) / 2.0 + (by.mod(e.dice_mod) if by and e.dice_mod else 0)) if e.dice != Vector2i.ZERO else e.amount), 1.0))
		"poison":
			_owe(out, &"hp", ticks * e.amount * (level if e.per_rank else 1) * u.max_hp)
		"winded":
			_owe(out, &"ap", e.amount * (level if e.per_rank else 1))


func _owe(out: Dictionary, key: StringName, n: float) -> void:
	if n > 0.0:
		out[key] = out.get(key, 0.0) + n


# What a hazard() weighs against the way round, in movement: HAZARD_TILES a point of HP, 1 a point of
# anything else. A known trap, detrimental ground or `bad` (a known mark that would harm the walker:
# Mark.harms()) counts at least a tile, whatever the estimate says - but not a trap `passed` by (Meander) - and
# a tile it suspects something of (Read.hint) at least SUSPECT_TILES, if `wary` (a walk goes only by what it
# knows; the AI choosing where to head is wary too: route()'s price).
func dread(owed: Dictionary, r: Read, bad := false, passed := false, wary := false) -> float:
	var n := 0.0
	for key in owed:
		n += owed[key] * (HAZARD_TILES if key == &"hp" else 1.0)
	if (r.known_bad() and not (passed and r.trap == true)) or bad:
		n = maxf(n, 1.0)
	if wary and r.hint != "":
		n = maxf(n, SUSPECT_TILES)
	return n


# The walk's tiles: the straight line `ln` from u to dest, or - when it crosses ground u knows to be
# harmful (a known trap, fire, ground it has read as bad or that afflicts: dread() above 0) - the way
# round it that's cheapest in movement plus dread, if that beats the line's own (a tie keeps the line:
# it only goes round when the way round costs about the same). Only what u knows steers it (read(), never
# the true map; unseen ground counts as plain, units it can't locate aren't in the way), and one with
# a negative foresight allowance plans optimistically, regardless of hazards. Costs come from stride(),
# which walk() pays too, so the plan and the walk can't disagree. Leaves the rng as it was.
# `price`, a Dictionary if given (`wary`: true in it also weighs ground it suspects something of, dread()), is filled with {cost}: what the tiles returned cost it in all (movement, units in the
# way included - stride()'s pass_cost() - plus dread, less what marks draw it): the AI's approach weighs
# the cells it might head for by it (AI._approach()), so it and the walk read one price.
func route(u: Unit, dest: Vector2i, ln: Array[Vector2i], price: Variant = null) -> Array[Vector2i]:
	Unit.begin_read()  # planning only: each unit's effects are found once (Unit._effects())
	var out := _route(u, dest, ln, price)
	Unit.end_read()
	return out


func _route(u: Unit, dest: Vector2i, ln: Array[Vector2i], price: Variant = null) -> Array[Vector2i]:
	var blind := foresight_allowance(u) < 0
	if (ln.size() < 2 or blind) and price == null:
		return ln
	var dreads := {}  # tile (and, for one that stands still, how far along: Meander passes ground by) -> its dread, read once
	var wards := u.meander()
	var wary: bool = price != null and price.get(&"wary", false)
	var dread_of := func(c: Vector2i, nth: int) -> float:
		var key: Variant = c if wards <= 0 else [c, mini(nth, wards + 1)]
		if key not in dreads:
			var r := read(u, c)
			dreads[key] = dread(hazard(u, c, r, nth if wards > 0 else 0, c == dest, false), r, r.marks.any(func(m: Mark): return m.harms(u)), wards > 0 and u.passes_by(terrain(c), nth), wary)
		return dreads[key]
	var danger := 0.0
	var pulled := false  # a known helpful mark on the line's ground, or near enough to bend it
	var near_lo := Vector2i(mini(u.cell.x, dest.x), mini(u.cell.y, dest.y)) - Vector2i(STEER_MARGIN, STEER_MARGIN)
	var near_hi := Vector2i(maxi(u.cell.x, dest.x), maxi(u.cell.y, dest.y)) + Vector2i(STEER_MARGIN, STEER_MARGIN)
	for c in marks:
		if c.x >= near_lo.x and c.y >= near_lo.y and c.x <= near_hi.x and c.y <= near_hi.y and lure(u, c) > 0.0:
			pulled = true
			break
	for i in ln.size():
		danger += dread_of.call(ln[i], i + 1) if on_map(ln[i]) else 0.0
	var searching := (danger > 0.0 or pulled) and ln.size() >= 2 and not blind
	if not searching and price == null:
		return ln
	var grounds := {}
	var ground_of_known := func(c: Vector2i) -> Terrain:
		if c not in grounds:
			grounds[c] = known_ground(u, c)
		return grounds[c]
	var cost_of := func(prev: Vector2i, c: Vector2i, bag: Dictionary, nth: int) -> float:
		var other := unit_at(c)
		return maxf(stride(u, prev, c, ground_of_known.call(prev), ground_of_known.call(c), bag, other if other and other != u and read(u, other).located() else null, true) + dread_of.call(c, nth) - lure(u, c), 0.0) \
				+ 0.00001 * Geometry2D.get_closest_point_to_segment(Vector2(c), Vector2(u.cell), Vector2(dest)).distance_to(Vector2(c))  # ties hug the line
	var bound := 0.0  # the line's own: movement and dread
	var bag := {}
	var prev := u.cell
	for i in ln.size():
		bound += cost_of.call(prev, ln[i], bag, i + 1) if on_map(ln[i]) else INF
		prev = ln[i]
	if price != null:
		price.cost = bound
	if not searching:
		return ln
	var lo := Vector2i(mini(u.cell.x, dest.x), mini(u.cell.y, dest.y)) - Vector2i(STEER_MARGIN, STEER_MARGIN)
	var hi := Vector2i(maxi(u.cell.x, dest.x), maxi(u.cell.y, dest.y)) + Vector2i(STEER_MARGIN, STEER_MARGIN)
	var best := {u.cell: 0.0}
	var came := {}
	var bags := {u.cell: {}}
	var depth := {u.cell: 0}  # tiles walked to reach each
	var open: Array[Vector2i] = [u.cell]
	var done := {}
	while not open.is_empty():
		var at: Vector2i = open[0]
		for c in open:
			if best[c] < best[at]:
				at = c
		open.erase(at)
		if at == dest:
			break
		if at in done:
			continue
		done[at] = true
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var c := at + Vector2i(dx, dy)
				if (dx == 0 and dy == 0) or c in done or not on_map(c) or c.x < lo.x or c.y < lo.y or c.x > hi.x or c.y > hi.y:
					continue
				var b: Dictionary = bags[at].duplicate()
				var g: float = best[at] + cost_of.call(at, c, b, depth[at] + 1)
				if g < bound - 0.001 and g < best.get(c, INF) - 0.000001:
					best[c] = g
					came[c] = at
					bags[c] = b
					depth[c] = depth[at] + 1
					if c not in open:
						open.append(c)
	if dest not in came or best[dest] >= bound - 0.001:
		return ln
	if price != null:
		price.cost = best[dest]
	var out: Array[Vector2i] = []
	var step := dest
	while step != u.cell:
		out.push_front(step)
		step = came[step]
	return out


# Extra movement for u to move through o's tile: o's size, less a share per point of dex mod - u's,
# and o's too if they're allies (it steps aside) - and per point of strength mod with Relay (u's,
# and an ally o's: it gives u a shove). Only Relay can take it below 0, a boost onward.
func pass_cost(u: Unit, o: Unit) -> float:
	var ally := o.faction == u.faction
	var off := PASS_SHARE * (u.mod(&"dexterity") + (o.mod(&"dexterity") if ally else 0))
	var relay := _relay(u) + (_relay(o) if ally else 0.0)
	var cost := o.stat(&"size") * (1.0 - off - relay)
	return cost if relay > 0.0 else maxf(cost, 0.0)


func _relay(u: Unit) -> float:
	return maxf(u.stat(&"relay"), 0.0)  # its Effect is per str mod (Relay): through its holder's modifiers (Modifiers.effect())


# --- Tile marks
# One-use tile effects laid by skills (Mark): a mark on a cell carries effects, a trigger and a lifetime.
# docs/plans/tile-marks.md. Traps stay Snares (they are the ground), fire stays Flames (damage rolled
# every time); disturbed earth is a Mark (earthwork()).

# Lays m on c, over any already there, and tells its side's units it's there (Mark.known).
func lay_mark(c: Vector2i, m: Mark) -> Mark:
	var st: Array = marks.get_or_add(c, [] as Array[Mark])
	for old: Mark in st.duplicate():
		if old.kind == m.kind and old.faction == m.faction:
			st.erase(old)  # laid again by its side: it's renewed, not doubled
	st.append(m)
	for o in members(m.faction):
		m.known[o] = true
	return m


func marks_at(c: Vector2i) -> Array[Mark]:
	var out: Array[Mark] = []
	out.assign(marks.get(c, []))
	return out


func has_mark(c: Vector2i, kind: StringName) -> bool:
	return marks_at(c).any(func(m: Mark): return m.kind == kind)


# The marks on c that o knows of: what its read of the tile makes out (Read.marks).
func known_marks(o: Unit, c: Vector2i) -> Array[Mark]:
	var out: Array[Mark] = []
	if c in marks:
		out.assign(read(o, c).marks)
	return out


func _drop_mark(c: Vector2i, m: Mark) -> void:
	var st: Array = marks.get(c, [])
	st.erase(m)
	if st.is_empty():
		marks.erase(c)


# Disturbed earth (Pray, to Vetruvis): its side's enemies wade through it, EARTHWORK_COST times the usual,
# for r of its side's turns. Not used up by those who cross it.
func earthwork(u: Unit, r: int) -> Mark:
	var m := Mark.new(&"earthwork", u)
	m.name = "Disturbed earth"
	m.who = &"foes"
	m.turns = r
	m.uses = 0
	m.wade = EARTHWORK_COST
	m.tint = Color(0.55, 0.38, 0.2)
	return m


# u comes onto c (walking, travel(); placed, place()) or ends its turn there (end_turn()): each mark there
# set for that trigger that fits it goes off, putting its effects on u, and is used up if it's a one-off.
func _trigger(u: Unit, c: Vector2i, on: StringName) -> void:
	for m in marks_at(c):
		if m.on != on or not m.hits(u) or not u.is_alive() or (m.uses == 0 and m.effects.is_empty()):
			continue  # (what only makes the ground dear to cross - disturbed earth - has nothing to trigger)
		var from: Unit = m.by if is_instance_valid(m.by) else null
		for e in m.effects:
			var n := e.turns if e.turns else m.effect_turns
			var a := u.afflict(e, n + (1 if on == &"end" else 0), m.rank)  # one turn is until its turn ends; as it ends, that tick doesn't count
			a.total = n
			a.by = from
			a.since = turns_begun
			drive(u, e, a)
		if m.uses > 0:
			m.uses -= 1
			if m.uses == 0:
				_drop_mark(c, m)
		marked.emit(c, u, m)


# What walking the tiles `passed` costs u for what hurts it by the tile: each of its per_tile effects
# takes its HP (as its damage tags, environmental if none) for each tile past what Meander passes by
# (Unit.wards(): the effect's rank is its level); `began` is the tiles it had walked before this walk.
func _toll(u: Unit, passed: Array[Vector2i], began: int) -> void:
	for e: Effect in u.timed.keys():
		if e.stat != "per_tile" or e not in u.timed:
			continue
		var a: Unit.Applied = u.timed[e]
		var each: float = e.amount * (a.rank if e.per_rank else 1.0) * a.scale
		var tags: Array[StringName] = e.tags if not e.tags.is_empty() else ([&"environmental"] as Array[StringName])
		for i in passed.size():
			if not u.is_alive():
				return
			if not u.wards(a.rank, i + 1, began):
				toll_paid.emit(u, u.hit(each, tags, a.by if is_instance_valid(a.by) else null))


# A trap goes off: most are revealed for good (Terrain.reveals), and it hits whoever stepped on it
# plus anyone in its blast, putting its wounds on them at its level (Snare: Bleeding). Units with Wary
# V (trap_power) make the traps they set off hit their enemies harder.
func spring(c: Vector2i, by: Unit) -> void:
	var t := terrain(c)
	if t.reveals:
		revealed[c] = true
	sprung.emit(c, by)
	var raw := roll(t.dice) * t.times + t.bonus
	for v in units.values().filter(func(x): return x == by or Vector2(x.cell).distance_to(Vector2(c)) <= t.blast + 0.0001):
		var boost := 1.0 + (by.stat(&"trap_power") if v.faction != by.faction else 0.0)
		react(&"hit", v, snares[c].by if c in snares and is_instance_valid(snares[c].by) else null)  # (no cast to swap)
		v.hit(raw * boost, t.damage_tags)
		for e in t.wounds:  # + 1 on its own turn, which doesn't count
			var a: Unit.Applied = v.afflict(e, t.wound_turns + (1 if v.faction == turn else 0), t.level)
			a.by = snares[c].by if c in snares else null
			a.since = turns_begun


# Movement to step from one tile onto the next: leaving costs `from`'s exit, entering costs `to`'s
# enter, plus the unit's move_cost effects for that ground (u may be null: terrain only), times
# wading().
func step(u: Unit, from: Vector2i, to: Vector2i) -> float:
	return _cost(u, terrain(from), terrain(to)) * wading(u, to) + mark_cost(u, to) + obstruction(u, to)


# Obstruct: what entering c costs u on top, for each foe of u beside c with Obstruct: the larger of half
# the size penalty of moving through that foe (pass_cost()) and half its con mod / 10, + 25% a rank.
# A foe that has lost its reactions (Jammed, helpless: Unit.reacts()) doesn't obstruct.
# Its allies pass freely. `expected`: only foes u can locate count (walk()).
func obstruction(u: Unit, c: Vector2i, expected := false) -> float:
	if not u:
		return 0.0
	var extra := 0.0
	for o: Unit in units.values():
		if o == u or not next_to(o.cell, c) or not o.is_alive() or Faction.friends(o.faction, u.faction):
			continue
		var n := o.stat(&"obstruct")
		if n <= 0.0 or not o.reacts() or (expected and not read(u, o).located()):
			continue
		extra += maxf(0.5 * maxf(pass_cost(u, o), 0.0), 0.5 * o.mod(&"constitution") / 10.0) * (1.0 + 0.25 * n)
	return extra


# What a known helpful mark on c (Mark.helps(): Charge!) takes off stepping onto it, in movement: HELP_PULL,
# once however many there are. What route() and the AI's approach weigh; never what the walk pays.
func lure(u: Unit, c: Vector2i) -> float:
	if c not in marks or u == null:
		return 0.0
	return HELP_PULL if known_marks(u, c).any(func(m: Mark): return m.helps(u)) else 0.0


# What the marks on c make entering it cost u, as a multiplier (wading(): disturbed earth, Pray to Vetruvis,
# costs its side's enemies EARTHWORK_COST times as much) and as movement more (mark_cost(): Routed!), on
# top of whatever the ground and u's effects already make it cost. `expected`: only the marks u knows.
func wading(u: Unit, c: Vector2i, expected := false) -> float:
	var n := 1.0
	for m in _marks_for(u, c, expected):
		n *= m.wade
	return n


func mark_cost(u: Unit, c: Vector2i, expected := false) -> float:
	var n := 0.0
	for m in _marks_for(u, c, expected):
		n += m.cost
	return n


# The entry marks on c that trigger on u: all of them, or (expected) the ones it knows are there.
func _marks_for(u: Unit, c: Vector2i, expected: bool) -> Array[Mark]:
	var out: Array[Mark] = []
	if not u or c not in marks:
		return out
	for m: Mark in (known_marks(u, c) if expected else marks_at(c)):
		if m.on == &"enter" and m.hits(u):
			out.append(m)
	return out


func _cost(u: Unit, from: Terrain, to: Terrain) -> float:
	var swims := u != null and to.depth > 0 and u.has_tag(&"aquatic")  # water is plain going to the aquatic: 1 to enter, nothing dragging (a Pike)
	var cost := maxf(from.exit + (1.0 if swims else to.enter + to.drag) + (u.stat(&"move_cost", to.tags) if u else 0.0), 0.0)
	if u and u.form and &"tunneler" in FORMS[u.form][2] and to.tags.any(func(t: StringName): return t in TUNNELS):
		cost = maxf(cost / maxi(u.form_rank, 1), minf(cost, 1.0))  # a mole: stone and dirt's cost cut by its rank, to 1
	return cost


# The straight line from a to b as ceil(distance) distinct tiles, each the one nearest its point
# on the line (never one already passed). Equally near tiles go through contest(): better and
# cheaper ground (entering and leaving it) for the lucky, worse for the unlucky, a coin at luck 0.
func line(a: Vector2i, b: Vector2i, luck: int, u: Unit = null) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var n := ceili(Vector2(a).distance_to(Vector2(b)) - 0.0001)
	var s := signi(luck)
	for k in range(1, n):
		var p := Vector2(a).lerp(Vector2(b), float(k) / n)
		var near := []
		for x in [floori(p.x), ceili(p.x)]:
			for y in [floori(p.y), ceili(p.y)]:
				var c := Vector2i(x, y)
				if c not in near and c != a and c != b and c not in path:
					near.append(c)
		if near.is_empty():
			near = [Vector2i(p.round())]
		var prev: Vector2i = path.back() if path else a
		path.append(contest(near, [
			func(c: Vector2i) -> float: return -snappedf(Vector2(c).distance_to(p), 0.0001),
			func(c: Vector2i) -> int: return int(on_map(c)),
			func(c: Vector2i) -> int: return s * terrain(c).worth(),
			func(c: Vector2i) -> float: return -s * (step(u, prev, c) + terrain(c).exit),
		])[0])
	if n > 0:
		path.append(b)
	return path


func on_map(c: Vector2i) -> bool:
	return map.get_cell_source_id(c) != -1


# The tiles on the map within r + 0.5 of c: every tile within r by either measure (as the crow flies,
# or Command.tiles()' rounded one), for the caller to narrow by its own. Only the box around c is
# walked, clipped to the map's used rect, so the work is the area's, not the map's (the Meadows' plane
# grows as the party explores). "The tiles within so many of here" goes through this, never a loop over
# map.get_used_cells().
func cells_near(c: Vector2i, r: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if r < 0.0:
		return out
	var n := ceili(r) + 1
	var box := Rect2i(c - Vector2i(n, n), Vector2i(2 * n + 1, 2 * n + 1)).intersection(map.get_used_rect())
	for x in range(box.position.x, box.end.x):
		for y in range(box.position.y, box.end.y):
			var at := Vector2i(x, y)
			if Vector2(at).distance_to(Vector2(c)) <= r + 0.5 and map.get_cell_source_id(at) != -1:
				out.append(at)
	return out


# What whoever's on c deals with: its top layer, composed with each beneath while the one above passes
# (Leaves over glass over grass) - or its ground alone, bare. Cached until the stack changes.
func terrain(c: Vector2i) -> Terrain:
	if layers.get(c, []).is_empty():
		return ground_of(c)
	if c not in _views:
		_views[c] = _compose(c)
	return _views[c]


# The tile beneath every layer: a trap laid in it, else what the map paints.
func ground_of(c: Vector2i) -> Terrain:
	if c in snares:
		return snares[c].terrain
	var d := map.get_cell_tile_data(c)
	var t: Terrain = d.get_custom_data("terrain") if d else null
	return t if t else PLAIN


# --- Tile stacks
# A cell's ground (ground_of()) with layers laid on top: leaves, glass, starpanes, startiles. A unit
# deals with the top layer; one that passes (Leaves; an overlay starpane) lets the one beneath act too,
# and so on down to the ground. Damage reaching a tile makes its layers react (expose()).

func lay_layer(c: Vector2i, t: Terrain, through := t.passes) -> Layer:
	var l := Layer.new(t, through)
	layers.get_or_add(c, []).push_front(l)
	_register(c, t)
	_restack(c)
	return l


func top_layer(c: Vector2i) -> Layer:
	var st: Array = layers.get(c, [])
	return st[0] if not st.is_empty() else null


# The layers whoever's on c deals with: the top, and each beneath while the one above passes.
func reached(c: Vector2i) -> Array[Layer]:
	var out: Array[Layer] = []
	for l: Layer in layers.get(c, []):
		out.append(l)
		if not l.passes:
			break
	return out


# The ground beneath c's layers counts too: every layer down to it passes.
func reaches_ground(c: Vector2i) -> bool:
	var r := reached(c)
	return r.size() == layers.get(c, []).size() and (r.is_empty() or r[-1].passes)


# The deepest thing reached decides what's underfoot; the passing layers above add their drag, exits,
# tags and effects, and the top lends its name.
func _compose(c: Vector2i) -> Terrain:
	var chain: Array[Terrain] = []
	for l in reached(c):
		chain.append(l.terrain)
	if reaches_ground(c):
		chain.append(ground_of(c))
	if chain.size() == 1:
		return chain[0]
	var v: Terrain = chain[-1].duplicate()
	v.douses = chain.any(func(t: Terrain): return t.douses)
	v.tags = v.tags.duplicate()
	v.effects = v.effects.duplicate()
	v.afflicts = v.afflicts.duplicate()
	v.at_end = v.at_end.duplicate()
	v.name = chain[0].name
	for k in range(chain.size() - 2, -1, -1):
		var t: Terrain = chain[k]
		v.drag += t.drag
		v.exit += t.exit
		v.depth += t.depth
		for tag in t.tags:
			if tag not in v.tags:
				v.tags.append(tag)
		v.effects.append_array(t.effects)
		v.afflicts.append_array(t.afflicts)
		v.at_end.append_array(t.at_end)
	return v


func _restack(c: Vector2i) -> void:
	_views.erase(c)
	var u := unit_at(c)
	if u:
		u.footing = terrain(c)
		u.ground = u.footing.tags


# Starpanes and startiles keep the lattice's books (panes, starpower) as they're laid and lost.
func _register(c: Vector2i, t: Terrain) -> void:
	if t.pane:
		panes[c] = true
	if t.source and c not in charge:
		starpower[c] = 0.0
		charge[c] = 0


func _unregister(c: Vector2i, t: Terrain) -> void:
	if t.pane:
		panes.erase(c)
	if t.source:
		starpower.erase(c)
		charge.erase(c)


# A brittle layer breaks into what it leaves (a startile: a cracked startile), or is gone.
func break_layer(c: Vector2i, l: Layer, by: Unit = null) -> void:
	var was := l.terrain
	_unregister(c, was)
	if was.breaks_into:
		l.terrain = was.breaks_into
		l.repairing = 0
		l.repair_goal = 0
		l.source = null
		_register(c, l.terrain)
	else:
		layers[c].erase(l)
	_restack(c)
	layer_broke.emit(c, was, by)


func _lift(c: Vector2i, l: Layer, why: StringName) -> void:
	_unregister(c, l.terrain)
	layers[c].erase(l)
	_restack(c)
	layer_lifted.emit(c, l.terrain, why)


# Damage reaching a tile - aimed at it, over an area, or at whoever's on it - reaches its layers through
# those that pass: brittle ones break to blunt, flammable ones burn away to fire (setting the tile
# alight), windswept ones blow away to wind. A unit on a layer that gave way drops onto what's left.
# True if anything changed.
func expose(c: Vector2i, tags: Array[StringName], by: Unit = null) -> bool:
	var hit := Tags.expand(tags)
	var changed := false
	for l in reached(c):
		var t := l.terrain
		if t.brittle and &"blunt" in hit:
			break_layer(c, l, by)
		elif t.flammable and &"fire" in hit:
			_lift(c, l, &"fire")
			if by:
				flames[c] = Flame.new(by, 2)
		elif t.windswept and &"wind" in hit:
			_lift(c, l, &"wind")
		else:
			continue
		changed = true
	var u := unit_at(c)
	if changed and u and u.is_alive():
		_drop(u)
	return changed


# u lands on what's now beneath it: that ground takes it as if it had stepped in.
func _drop(u: Unit) -> void:
	var t := terrain(u.cell)
	for e in t.afflicts:
		u.afflict(e, (e.turns if e.turns else t.turns) + 1)
	if t.is_trap():
		spring(u.cell, u)


# What's beneath c can't be made out: its top layer obscures (Leaves), and nobody stands on it.
func obscured(c: Vector2i) -> bool:
	var top := top_layer(c)
	return top != null and top.terrain.obscures and unit_at(c) == null


# Concealment checks on c have advantage: a layer reached there gives cover (Leaves).
func covered(c: Vector2i) -> bool:
	return reached(c).any(func(l: Layer): return l.terrain.cover)


# Glass (unstable): ending its turn on it without resting, having moved more than its dex mod in tiles,
# a unit breaks it and makes a dex check against its own inertia (Unit.inertia(): tiles moved + weight) -
# at disadvantage if it stepped in
# blind (Leaves over it). Failing, it drops through onto what's beneath and ends its turn there.
# Passing, it catches itself: what the ground beneath would do to it this turn's end and as its next
# starts is spared, as it's taken to move off (Unit.steadied).
func _teeter(u: Unit, rested: bool) -> void:
	var glass: Layer = null
	for l in reached(u.cell):
		if l.terrain.unstable:
			glass = l
			break
	if not glass or rested or u.steps <= maxi(u.mod(&"dexterity"), 0):
		return
	var dc := u.inertia()  # how badly it screwed up: how far and how heavy it came
	var roll := check(u, &"dexterity", null, dc, {role = &"defensive", edge = -1 if u.blind_on == u.cell else 0})
	break_layer(u.cell, glass)
	teetered.emit(u, roll.mine.total, dc, roll.won)
	if roll.won:
		u.steadied = u.cell
		u.steady_turn = u.turns_taken
	else:
		_drop(u)


# Cracked startiles mend, a round at a time. One not yet begun looks for the lattice: a pane or tile
# linked to a source whose fullness (in %) / REPAIR_SPAN reaches it in tiles, and draws REPAIR_COST of
# a source's capacity from that source to begin ("Repairing X/Y": a round a tile of distance). Done, it
# upgrades into what it repairs into (a startile, a source again, empty).
func _repair_tiles() -> void:
	for c: Vector2i in layers.keys():
		for l: Layer in layers[c]:
			if l.terrain.repairs_into == "":
				continue
			if l.repair_goal == 0:
				var found := _mender(c)
				if found.is_empty():
					continue
				charge[found[1]] -= ceili(REPAIR_COST * STAR_CAPACITY)
				l.source = found[1]
				l.repair_goal = maxi(found[2], 1)
				continue
			l.repairing += 1
			if l.repairing >= l.repair_goal:
				var into: Terrain = load(l.terrain.repairs_into)
				l.terrain = into
				l.repairing = 0
				l.repair_goal = 0
				l.source = null
				_register(c, into)
				_restack(c)
				mended.emit(c, into)


# [the lattice tile c draws on, its source, the distance] for mending c; [] if none reaches.
func _mender(c: Vector2i) -> Array:
	var best: Array = []
	var cost := ceili(REPAIR_COST * STAR_CAPACITY)
	for at in panes.keys() + starpower.keys():
		if at == c:
			continue
		var src: Variant = star_source(at)
		if src == null or charge[src] < cost:
			continue
		var d := Command.tiles(c, at)
		if d <= 100.0 * charge[src] / STAR_CAPACITY / REPAIR_SPAN and (best.is_empty() or d < best[2]):
			best = [at, src, d]
	return best


# --- Turns

# As a unit's side starts its turn: Resurrection Sickness takes 10% of its max HP (none if it's at full
# HP: it's cured), regen heals that fraction of its max HP (clearing wounds up to the
# rank of the strongest regen on it), then poison takes that fraction (each rounded by its luck).
func _mend(u: Unit) -> void:
	_pulse(u)
	_frighten(u)
	for it in u.items():
		if it.heat and u.is_alive():  # Ignauldron
			burned.emit(u, u.hit(it.heat * it.ranked(), [&"fire"] as Array[StringName]), it.name)
		if it.burning and u.is_alive():
			var n := u.hit(maxi(u.rounded(0.1 * it.ranked() * u.max_hp), 1), [&"fire"] as Array[StringName])
			burned.emit(u, n, it.name)
	if SICKNESS in u.timed:  # gone if it starts the turn whole; else it takes its toll, never the last HP
		if u.hp >= u.max_hp:
			u.timed.erase(SICKNESS)
		elif u.hp > 0:  # (it never lifts one Downed)
			u.hp = maxi(u.hp - maxi(roundi(SICKNESS.amount * u.max_hp), 1), 1)
	var regen := u.stat(&"regen", u.state_tags())  # regen tagged downed: only while Downed (Bless)
	var flat := u.stat(&"regen_hp")  # Rejuvinate's cha mod
	if regen > 0.0 or flat > 0.0:
		var power := 0
		for pair in u._effects():
			if pair[0].stat in ["regen", "regen_hp"]:
				power = maxi(power, pair[1])
		mend(u, Luck.settle(regen * u.max_hp + flat, u.luck, true), power)
	var poison := u.stat(&"poison")
	if poison > 0.0 and u.is_alive():
		u.damage(Luck.settle(poison * u.max_hp, u.luck, false))


# The effect e has just been put on u as a (a.by set): if it's a forced move (shove, fear, entrance) u is driven
# amount tiles x rank x its strength, away from whoever put it on or toward them (displace(), tagged with the
# effect's own name). Shove is instant: nothing stays on. Nobody put it on (a flame): it moves no one.
func drive(u: Unit, e: Effect, a: Unit.Applied) -> void:
	if e.stat == "unshape":
		u.timed.erase(e)  # nothing stays on
		unshape(u, a.by)
		return
	var dir: int = DRIVES.get(StringName(e.stat), 0)
	if dir == 0:
		return
	if a.by and a.by != u and a.by.is_alive() and u.is_alive():
		displace(u, a.by.cell, dir, roundi(e.amount * (a.rank if e.per_rank else 1) * a.strength(e)), false, [StringName(e.stat)] as Array[StringName], a.by)
	if e.stat == "shove" and u.timed.get(e) == a:
		u.timed.erase(e)


# As its side's turn starts, each fear and entrance still on u drives it again - not the turn it was put on,
# which drove it already (drive()) - from where its source stands now.
func _frighten(u: Unit) -> void:
	for e in u.timed.keys():
		if e.stat in ["fear", "entrance"] and u.is_alive() and e in u.timed and u.timed[e].since != turns_begun:
			drive(u, e, u.timed[e])


# As its side's turn ends, each bleed on u takes its dice + the mod of whoever put it on (at least 1) -
# but not the turn it was put on.
func _bleed(u: Unit) -> void:
	for e in u.timed.keys():
		if e.stat == "bleed" and u.is_alive() and u.timed[e].since != turns_begun:
			var by := u.timed[e].by
			var n := roll(e.dice) + (by.mod(e.dice_mod) if by and e.dice_mod else 0) if e.dice != Vector2i.ZERO else roundi(e.amount)
			u.damage(maxi(n, 1))


# Regeneration Pulse, as u's side starts its turn: once every (its side's lives left, at least 1) of
# them - more often as its lives run out - it heals each ally within PULSE_REACH tiles, itself too,
# (1d4 + 5% of their max HP) x its pulse.
func _pulse(u: Unit) -> void:
	var k := roundi(u.stat(&"pulse"))
	if k <= 0:
		return
	u.pulse_wait += 1
	if u.pulse_wait < maxi(lives_left(u.faction), 1):
		return
	u.pulse_wait = 0
	var healed := {}
	for o in members(u.faction):
		if Command.tiles(o.cell, u.cell) <= PULSE_REACH:
			var was := o.hp
			o.healed_by = u
			o.heal(k * (roll(Vector2i(1, 4)) + Luck.settle(0.05 * o.max_hp, o.luck, true)))
			healed[o] = o.hp - was
	pulsed.emit(u, healed)


# A side's lives: the hearts of its units still on the field (fallen ones too), and how many are left.
func lives(f: Faction) -> int:
	var n := 0
	for u: Unit in units.values():
		if u.faction == f:
			n += u.lives()
	return n


func lives_left(f: Faction) -> int:
	var n := 0
	for u: Unit in units.values():
		if u.faction == f:
			n += u.lives_left()
	return n


# u took mortal damage with a heart left: it lies where it fell, holding its tile, beyond harm - no
# effects, nothing it was channeling - until the turn ends (end_turn()).
func _on_downed(u: Unit) -> void:
	u.timed.clear()
	u.disabled.clear()
	end_channel(u)
	if u not in fallen:
		fallen.append(u)
	downed.emit(u)
	neutralize(u, &"downed")


# u went Downed (down but not out), was saved from it, or died of it: the rules are Downed's.
# caster is about to use skill, one only for foes, on an ally it can't tell is one (hidden, or passing
# for something else: Read.attitude()); a skill for allies and foes alike (dual) does by each what it
# should, as before. First a hidden wis check - the player sees no roll, only what comes of it - at the
# standard difficulty: passing, it holds its fire. The action is spent (AP and cost, as on a miss) but
# cut off as an interrupt cuts it (interrupt(), Jam's: its own hiding, channel, guard end), nothing of
# it reaching the ally, and its side reads that ally better for the rest of the battle - as many recon
# levels as the ally hides from it by (studied, _read()), which normally shows its side. False: it
# didn't catch itself (or can't pay), and the cast goes on.
func _holds_fire(caster: Unit, skill: Skill, ally: Unit) -> bool:
	if not check(caster, &"wisdom", null, Difficulty.dc(&"standard")).won:
		return false
	if not caster.pay_for(skill):
		return false
	interrupt(caster)
	var mine: Dictionary = studied.get_or_add(caster.faction, {})
	mine[ally] = maxi(mine.get(ally, 0), maxi(_hidden_from(caster, ally), 1))
	held_fire.emit(caster, ally)
	used.emit(caster, skill, ally, 0)
	return true


# u put its death off (Unit.defer()): in its own side's turn, that turn's end doesn't count.
func _on_deferring(u: Unit, how: StringName) -> void:
	if how == &"begin":
		u.defer_fresh = u.faction == turn
	borrowed.emit(u, how)


# A side's turn ends: for each of its units on borrowed time (Unit.deferred) a round passes - but the
# one it went on borrowed time in - and what harmed it in its window is replayed in order
# (Unit.replay_harms()). Its last round over, it makes a check against an execute at its defer rank:
# its last stand (cut by how whole it is: Unit.execute_share(), helped by checks tagged execute) against
# d20 + that rank, the execute winning ties. Failing, it falls as it would have (Unit.fall(): Downed, if
# it can); passing, it lives on, at 1 HP if it had none. Then each ages its log of harms.
func _borrowed(side: Array[Unit]) -> void:
	for u in side:
		if u.deferred > 0:
			if u.defer_fresh:
				u.defer_fresh = false
			else:
				u.replay_harms()
				borrowed.emit(u, &"replay")
				u.deferred -= 1
				if u.deferred == 0:
					var r := u.defer_rank
					if check(null, &"", null, last_stand(u, r), {bonus = r}).won:  # d20 + rank against its last stand
						borrowed.emit(u, &"executed")
						u.fall()
					else:
						if u.hp <= 0:
							u.hp = 1
						borrowed.emit(u, &"survived")
		u.age_harms()


func _on_dbno(u: Unit, how: StringName) -> void:
	Downed.changed(self, u, how)
	dbno_changed.emit(u, how)
	if how == &"down":
		neutralize(u, &"down")


# The fallen get up at full HP as the turn ends, each bringing what it summons (a Regeneration Probe)
# onto the nearest free tile. One getting up on its Red Spinel Ring (its last life) gets up at the ring's
# share of its max HP instead, with Resurrection Sickness.
func _revive() -> void:
	for u in fallen.duplicate():
		fallen.erase(u)
		if not is_instance_valid(u):
			continue
		u.reviving = false
		u.refit()  # what was on it (Asphyxia) went as it fell
		var ring: Item = u.trinket if u.ring_lives() > 0 and u.hearts_used > u.lives() - u.ring_lives() else null
		if ring:  # a Red Spinel Ring, spent last: rank x 10% of max HP, more than full past rank 10, and sick for rank turns
			var n := maxi(roundi(u.max_hp * ring.revives * ring.rank), 1)
			u.over_max = maxi(n - u.max_hp, 0)
			u.hp = n
			u.afflict(SICKNESS, ring.rank + (1 if u.faction == turn else 0), ring.rank)
		else:
			u.hp = u.max_hp
		var came: Unit = summon(u.summons, u.faction, u.cell) if u.summons else null
		revived.emit(u, came)


# Brings a unit of `scene` onto side f, on the free tile nearest c. Null if there's no room.
# `unseen_by`: a side that mustn't see it arrive - it lands on the nearest free tile where none of that
# side make it out (read(): perception, concealment, its own hiding, a partner's eyes), or doesn't come
# (null). Where sight isn't limited every unit is seen, so there it's ignored.
func summon(scene: PackedScene, f: Faction, c: Vector2i, unseen_by: Faction = null) -> Unit:
	var u: Unit = scene.instantiate()
	u.faction = f
	$Units.add_child(u, true)
	var eyes: Array[Unit] = members(unseen_by) if unseen_by and sight else ([] as Array[Unit])
	var spot: Variant
	if eyes.is_empty():
		spot = free_near(c)
	else:
		# The first guess is the nearest tile past every one's perception range (a distance, cheap), read only
		# to confirm; a nearer spot (concealed, hidden) is found only if no such guess reads unseen.
		spot = free_near(c, func(x: Vector2i) -> bool: return beyond_sight(x, eyes) and unseen_at(u, x, eyes))
		if spot == null:
			spot = free_near(c, func(x: Vector2i) -> bool: return unseen_at(u, x, eyes))
	if spot == null:
		$Units.remove_child(u)
		u.free()
		return null
	move(u, spot)
	_listen(u)
	if f == turn:
		u.refresh()
	return u


# The free tile on the map nearest c (c itself if it's free), or null: looked for in widening boxes,
# so a crowded spot on a big map costs its neighbourhood, not the map. `ok`: what else a tile must be.
func free_near(c: Vector2i, ok := Callable()) -> Variant:
	var used := map.get_used_rect()
	var far := maxi(maxi(absi(c.x - used.position.x), absi(c.x - used.end.x)), maxi(absi(c.y - used.position.y), absi(c.y - used.end.y)))
	var n := 2
	var tried := {}
	while true:
		var free := cells_near(c, n).filter(func(x: Vector2i): return x not in tried and not unit_at(x))
		free.sort_custom(func(x: Vector2i, y: Vector2i): return Vector2(x).distance_to(Vector2(c)) < Vector2(y).distance_to(Vector2(c)))
		for x: Vector2i in free:
			if Vector2(x).distance_to(Vector2(c)) > n and n <= far:
				break  # something nearer may lie outside this box
			tried[x] = true
			if not ok.is_valid() or ok.call(x):  # nearest first: `ok` asked as few times as it can be
				return x
		if n > far:
			return null
		n *= 2
	return null


# Whether c is past every one of `eyes`' perception range: a distance, no read.
func beyond_sight(c: Vector2i, eyes: Array[Unit]) -> bool:
	for o in eyes:
		if Vector2(c).distance_to(Vector2(o.cell)) <= perception_range(o):
			return false
	return true


# Whether none of `eyes` would make u out were it standing on c (read(): located or not).
func unseen_at(u: Unit, c: Vector2i, eyes: Array[Unit]) -> bool:
	var was := u.cell
	u.cell = c
	var seen := eyes.any(func(o: Unit): return o != u and read(o, u).located())
	u.cell = was
	return not seen


# The turn passes. A channel held since an earlier turn holds through this one only if its unit met
# rest's requirements (Unit.idle(): no AP spent, no move past Meander); otherwise it ends - one that
# met them keeps its channel instead of resting (Unit.activity()). Units that rested get energy back
# (Unit.recover()); each gets over a use of every skill, more if it rested (Exhaustion.recover()); and every unit awake looks
# around (_watch()); a traitor in another side's party that didn't rest gives
# itself away (_refuse()); held ones take their holder's grip (_grip()), and wounds bleed (_bleed());
# Ramut's Ire looks for a stall (_check_stall()); ground puts its turn-end
# effects on whoever is on it (Magic Stew); a sleeper with an ally beside it wakes up; then timed
# effects count down and zones wear off, and the fallen get back up (_revive()).
func end_turn() -> void:
	if phase != Phase.TURNS:
		return
	if interrupter:
		end_interrupt()  # an interrupt still open passes as the turn ends
	var ending := turn
	var was_order := order.duplicate()  # a side can fall out of it below: its successor is still the next one standing
	ending_turn = true  # so _on_died() doesn't pass the turn too: it's passed once, at the end
	var side := members(turn)
	for u in side:
		u.unspent = u.ap_left()  # what it left unspent (Spike)
		_release_tows(u)  # a towing grip lasts its holder's turn
		if u.channel and u.channel.turns > 0 and not u.idle():
			end_channel(u)  # it moved or acted: the channel's lost
		elif u.channel:
			u.channel_held(u.idle())  # a switch of what it runs on carries more over (Unit.toggle())
	for u in side:
		if u.channel:
			for bh in u.channel.skill.behaviours:
				bh.held(self, u)  # Clairvoyance: the pings move, then it ranks up
	for u in side:
		var rested := u.activity() == &"rest"
		if rested:
			_chant(u)
			if u.devotions().any(func(vow: SkillTab): return vow.satisfied_by == &"rest_whole") and u.hp >= u.max_hp:
				u.gain(&"patron", 1)  # Hogel: resting whole
		u.recover()
		u.exhaustion.recover(rested, u.mod(&"constitution"))
		_starlight(u)
		u.rested_turns = u.rested_turns + 1 if rested else 0
		if not u.asleep():
			_watch(u)
		if not u.idle() and posing(u):
			_refuse(u)
	for u in side:
		_grip(u)
		_bleed(u)
		if u.is_alive() and u.cell in flames:
			flame(u, flames[u.cell], "ends its turn in fire")
		if u.is_alive() and u.cell in marks:
			_trigger(u, u.cell, &"end")
	side = members(turn)  # a grip can drown one, a wound bleed one out
	for u in side:
		_teeter(u, u.idle())
		u.blind_on = null
	side = members(turn)  # a drop can land one on something deadly
	for u in side:
		if u.steadied != null and u.steady_turn != u.turns_taken:
			u.steadied = null  # it stayed a turn on what it caught itself over: no more reprieve
		if u.steadied == u.cell:
			continue  # caught itself this turn: spared what the ground beneath does at turn's end
		for e in u.footing.at_end if u.footing else ([] as Array[Effect]):
			u.afflict(e, (e.turns if e.turns else u.footing.turns) + 1)  # + 1: the tick below takes this turn
	for u in side:
		if u.asleep() and side.any(func(o: Unit): return o != u and next_to(o.cell, u.cell)):
			u.wake()
	for u in side:
		u.tick()
	for u in members(turn):
		_sap(u)
		_synergize(u)
	for u in members(turn):
		_starkind(u, true)
	for z in zones.filter(func(x: Zone): return x.faction == turn):
		z.turns -= 1
	zones.assign(zones.filter(func(x: Zone): return x.turns > 0))
	for c in flames.keys():
		if flames[c].faction == turn:
			flames[c].turns -= 1
			if flames[c].turns <= 0:
				flames.erase(c)
	_drain(turn)
	_tick_pockets(turn)
	if not order.is_empty() and turn == order[-1]:
		_repair_tiles()  # a round has passed
	for c in marks.keys():
		for m: Mark in marks[c].duplicate():
			if m.faction == turn:
				m.turns -= 1
				if m.turns <= 0:
					_drop_mark(c, m)
	_tidy_debris()
	_borrowed(members(turn))  # and for those on borrowed time
	Downed.end_round(members(turn))  # a round passes for the Downed
	_revive()
	_check_stall()
	ending_turn = false
	if phase != Phase.TURNS:
		return
	var at := was_order.find(ending)
	for k in range(1, was_order.size() + 1):
		var next: Faction = was_order[(at + k) % was_order.size()]
		if next in order:
			turn = next
			return


# A side's turn ends. If none of its units could make out a single foe it would fight while enemies
# stand (only the Passive or Aggressive they seem to be counts too), the turn was stalled, by the foes
# hiding or posing (concealment, trickery, a front); a turn that wasn't starts its count over. Once
# more turns in a row have stalled than its grace(), Ramut's Ire builds a rank on each of them, a rank
# a stalled turn.
func _check_stall() -> void:
	var side := members(turn)
	var foes: Array = units.values().filter(func(t: Unit): return not Faction.friends(t.faction, turn) and t.is_alive())
	stalling.clear()
	if side.is_empty() or foes.is_empty() or foes.any(func(t: Unit): return side.any(_sees_foe.bind(t))):
		stalled_turns[turn] = 0
		return
	stalled_turns[turn] = stalled_turns.get(turn, 0) + 1
	for t: Unit in foes:
		if _hides(t):
			stalling.append(t)
	if ire_grace < 0.0 or stalled_turns[turn] <= grace(turn):
		return
	for u in stalling:
		_ire(u)


# Stalled turns in a row side f waits out before the Ire: the units still standing on the smallest side
# in the fight, times ire_grace, less whatever its prayers to Ramut took off (at least 0).
func grace(f: Faction) -> float:
	var counts := {}
	for u: Unit in units.values():
		if u.is_alive():
			counts[u.faction] = counts.get(u.faction, 0) + 1
	var fewest: int = counts.values().min() if not counts.is_empty() else 0
	return maxf(ire_grace * fewest - hastened.get(f, 0), 0.0)


func _sees_foe(o: Unit, t: Unit) -> bool:
	var r := read(o, t)
	return r.located() and r.attitude(o) == &"foe"


# Hides or poses: concealment, trickery or a front of its own.
func _hides(t: Unit) -> bool:
	var kinds: Array[StringName] = [&"dark", &"light", &"sound", &"sight"]
	return t.stat(&"concealment", kinds) > 0 or t.stat(&"trickery", kinds) > 0 or Perception.fronts(t)


# Ramut's Ire builds a rank on u, each defeating a rank of its concealment and trickery, against
# everyone, for the rest of the battle: what it took to stop the stall stays taken.
func _ire(u: Unit) -> void:
	var rank := 1
	for e in IRE.effects:
		rank = (u.timed[e].rank + 1) if e in u.timed else 1
		var a := u.afflict(e, 0, rank)
		a.skill = IRE
		a.lasting = true
	stalled.emit(u, rank)


# Still held as its side's turn ends (a grapple: Drown's effects), u drowns while submerged (the
# skill's drowns dice + its holder's mod in the skill's stat) -
# and, fooled by its holder, looks harder at it. A holder that's fallen, or isn't beside it (or on its
# tile) any more, lets go.
func _grip(u: Unit) -> void:
	var a := held_by(u)
	if a == null:
		return
	var by := a.by
	var s := a.skill
	if not by or not by.is_alive() or not _within_grip(by, u):
		_let_go(u, s)
		return
	var before := u.hp
	if s.drowns != Vector2i.ZERO and u.is_alive() and submerged(u) and not u.has_tag(&"aquatic"):  # the aquatic breathe water
		u.hit(roll(s.drowns) + by.mod(s.stat(), s.tags), s.tags, by)
	gripped.emit(u, by, before - u.hp)
	if u.is_alive() and u.hp < before and read(u, by).deceived:
		doubt(u, by)


# A unit left c (moved, fell): a mist that shared the tile has it to itself now.
func _vacated(c: Vector2i) -> void:
	for m: Unit in inside.keys():
		if m.cell == c and not unit_at(c):
			inside.erase(m)
			units[c] = m
			return


# Mist u (Coalescing) moves into t's tile and shares it: inside it, units[] still t's. It leaves when
# it moves or is moved, and has the tile once t is gone from it.
func engulf(u: Unit, t: Unit) -> void:
	if inside.has(u):
		inside.erase(u)
	elif unit_at(u.cell) == u:
		units.erase(u.cell)
		_vacated(u.cell)
	u.cell = t.cell
	u.position = map.map_to_local(t.cell)
	inside[u] = t



# u steps out through an escape portal: its side wins the battle at once (the Meadows).
func escape(u: Unit) -> void:
	if phase == Phase.OVER:
		return
	winner = u.faction
	phase = Phase.OVER


# How far o perceives others in tiles: its wisdom total, halved in fog; -1 where sight isn't limited.
func perception_range(o: Unit) -> float:
	if not sight:
		return -1.0
	return o.stat(&"wisdom") * (0.5 if &"fog" in conditions else 1.0)


# How far t is within o's side's sight, shared across the side: 2 within half some one of its range
# (it makes out how t looks), 1 within some one's range (only where it is), 0 beyond them all. 2
# where sight isn't limited.
func in_range(o: Unit, t: Unit) -> int:
	if not sight:
		return 2
	var best := 0
	var side: Array[Unit] = members(o.faction) if o.faction else ([] as Array[Unit])
	if o not in side:
		side.append(o)
	for a in side:
		var reach := perception_range(a)
		var d := Vector2(a.cell).distance_to(Vector2(t.cell))
		if d <= reach / 2.0 + 0.0001:
			return 2
		if d <= reach + 0.0001:
			best = 1
	return best


# Side f made out foe t at c: where its units will look for it once it's out of sight (AI._hunt()).
# `moves`: how far it makes the foe's walk, when it could read that (0: it couldn't).
func sighted(f: Faction, t: Unit, c: Vector2i, moves := 0.0) -> void:
	if f not in sightings:
		sightings[f] = {}
	sightings[f][t] = c
	if f not in sighted_when:
		sighted_when[f] = {}
	sighted_when[f][t] = {since = turns_begun, moves = moves}


# How many whole rounds ago (turns of all the sides) turn `since` of turns_begun was.
func rounds_since(since: int) -> int:
	var sides := {}
	for u: Unit in units.values():
		sides[u.faction] = true
	return ceili((turns_begun - since) / float(maxi(sides.size(), 1)))


# The tiles foe t could have reached from `from` on `budget` movement, as viewer o can reckon it:
# ground o makes out (known_ground(); the rest plain), every step priced by stride() as t's walk would be
# paid (its movement effects, Peel), no one standing in its way, within `budget` tiles as the crow flies
# (walk() goes in lines). Includes `from`.
func reckon_reach(o: Unit, t: Unit, from: Vector2i, budget: float) -> Array[Vector2i]:
	var best := {from: 0.0}
	var bags := {from: {}}
	var grounds := {}
	var ground_of := func(c: Vector2i) -> Terrain:
		if c not in grounds:
			grounds[c] = known_ground(o, c)
		return grounds[c]
	var open: Array[Vector2i] = [from]
	var done := {}
	while not open.is_empty():
		var at: Vector2i = open[0]
		for c in open:
			if best[c] < best[at]:
				at = c
		open.erase(at)
		if at in done:
			continue
		done[at] = true
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var c := at + Vector2i(dx, dy)
				if (dx == 0 and dy == 0) or c in done or not on_map(c):
					continue
				var bag: Dictionary = bags[at].duplicate()
				var g: float = best[at] + stride(t, at, c, ground_of.call(at), ground_of.call(c), bag, null, true)
				if g <= budget + 0.0001 and g < best.get(c, INF) - 0.000001:
					best[c] = g
					bags[c] = bag
					if c not in open:
						open.append(c)
	var out: Array[Vector2i] = []
	for c: Vector2i in best:
		if Vector2(c).distance_to(Vector2(from)) <= budget + 0.0001:  # a walk goes in a line: ceil(distance) tiles, not a diagonal's two
			out.append(c)
	return out


# A unit took a blow in a cast from a foe it can't place: its side knows which side of it the blow landed
# on (the hit's tags: flank, rear; else front) and how far that skill reaches, not the tile: every tile
# on that side within the skill's reach is where it could have come from. Kept for HIT_TURNS of turns.
func _note_attack(u: Unit, blow: Dictionary) -> void:
	var by: Unit = blow.by
	var cast := resolving()
	if not u.faction or _casting == 0 or not cast or cast.caster != by or not is_instance_valid(by) or by == u or Faction.friends(by.faction, u.faction) or read(u, by).located():
		return
	var side: StringName = &"rear" if &"rear" in blow.tags else (&"flank" if &"flank" in blow.tags else &"front")
	var reach := skill_range(by, cast.skill, u)
	var tiles: Array[Vector2i] = []
	for c in _box(u.cell, ceili(reach)):
		if c != u.cell and Vector2(c).distance_to(Vector2(u.cell)) <= reach + 0.0001 and u.side_of(c) == side:
			tiles.append(c)
	if not attacks.has(u.faction):
		attacks[u.faction] = []
	attacks[u.faction].append({tiles = tiles, since = turns_begun})


# The attacks on side f in the last HIT_TURNS turns that it couldn't place the attacker of.
func attacks_on(f: Faction) -> Array:
	var kept: Array = attacks.get(f, []).filter(func(a: Dictionary): return turns_begun - a.since <= HIT_TURNS)
	attacks[f] = kept
	return kept


# Whether one of f's units searched c within SWEEP_TURNS of turns.
func swept_lately(f: Faction, c: Vector2i) -> bool:
	return turns_begun - swept.get(f, {}).get(c, -999) <= SWEEP_TURNS


# Where side f last made out each foe still standing (forgetting the fallen).
func last_seen(f: Faction) -> Dictionary:
	var out: Dictionary = sightings.get(f, {})
	for t in out.keys():
		if not is_instance_valid(t) or not t.is_alive():
			out.erase(t)
	return out


# --- Pockets: a Rift's domain, an Emergency Exit's refuge
# A pocket is part of the map out of reach (POCKETS on), entered and left only by its doors, the field's
# and its own. It ends when its turns run out: its maker's side come back in a clump beside the field
# door, and whatever else is in it goes with it.

# Whether nothing stands between a and b: every tile on the straight line between is on the map and
# holds no earthwork.
func clear_line(a: Vector2i, b: Vector2i) -> bool:
	for c in line(a, b, 0):
		if c != a and c != b and (not on_map(c) or has_mark(c, &"earthwork")):
			return false
	return true


# A Rift's domain's difficulty: 0.5 a rank, up to 1.5.
static func rift_difficulty(rank: int) -> float:
	return clampf(0.5 * rank, 0.5, 1.5)


# Paints terrain t onto c: a tile of the map's tile set that carries it, made at run time if there's
# none - from its own art (Terrain.look), else the placeholder tinted.
func paint(c: Vector2i, t: Terrain, tint := Color.WHITE) -> void:
	var ts := map.tile_set
	for n in ts.get_source_count():
		var id := ts.get_source_id(n)
		var from := ts.get_source(id) as TileSetAtlasSource
		for i in from.get_tiles_count() if from else 0:
			var at := from.get_tile_id(i)
			for k in from.get_alternative_tiles_count(at):
				var alt := from.get_alternative_tile_id(at, k)
				if from.get_tile_data(at, alt).get_custom_data("terrain") == t:
					map.set_cell(c, id, at, alt)
					return
	if t.look:
		var own := TileSetAtlasSource.new()
		own.texture = t.look
		own.texture_region_size = ts.tile_size
		var id := ts.add_source(own)  # in the set first: only then do its tiles carry its custom data layer
		own.create_tile(Vector2i.ZERO)
		own.get_tile_data(Vector2i.ZERO, 0).set_custom_data("terrain", t)
		map.set_cell(c, id, Vector2i.ZERO, 0)
		return
	var src := ts.get_source(0) as TileSetAtlasSource
	var alt := src.create_alternative_tile(Vector2i.ZERO)
	src.get_tile_data(Vector2i.ZERO, alt).set_custom_data("terrain", t)
	src.get_tile_data(Vector2i.ZERO, alt).modulate = tint
	map.set_cell(c, 0, Vector2i.ZERO, alt)


func _new_pocket(kind: StringName, by: Unit, skill: Skill, origin: Vector2i) -> Pocket:
	var p := Pocket.new()
	p.kind = kind
	p.by = by
	p.skill = skill
	p.origin = origin
	p.centre = POCKETS + Vector2i(0, 40 * pockets.size())
	var r := 4 if kind == &"domain" else 2
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var off := Vector2i(x, y)
			if kind == &"refuge" or absi(x) + absi(y) <= r:  # a domain: a diamond; a refuge: a square
				p.cells.append(p.centre + off)
				paint(p.centre + off, PLAIN if kind == &"domain" else STONE, Color(0.85, 1.15, 0.8) if kind == &"domain" else Color(0.6, 0.6, 0.65))
	p.door = p.centre + Vector2i(-r, 0)
	pockets.append(p)
	for c in [origin, p.centre]:
		var m := PortalMark.new()
		m.turns = p.turns
		add_child(m)
		move_child(m, map.get_index() + 1)
		m.position = map.map_to_local(c)
		p.marks.append(m)
	return p


# Rift at c: a door to a domain, open both ways. Channeled, it lasts while the caster channels it (its
# turns infinite), its count (rift_turns()) starting once it stops; cast unchanneled, the count starts
# at once. Demons wait there - a formation at the rift's difficulty, at the caster's level.
func open_rift(by: Unit, skill: Skill, c: Vector2i, held := true) -> bool:
	var r := by.mods(skill).irank(by.rank(skill), &"rank_impact")  # its difficulty and its count are what rank does
	if not can_rift(by, skill, c):
		return false
	var p := _new_pocket(&"domain", by, skill, c)
	if held:
		end_channel(by)
		by.channel = Unit.Channel.new(skill, c)
	else:
		p.turns = rift_turns(r)
		for m in p.marks:
			m.turns = p.turns
	if demons not in order:
		order.append(demons)  # their turns come too
	var f: Formation = load(RIFT_FORMATION)
	var roster := f.roster(rift_difficulty(r))
	for i in roster.size():
		var u := summon(roster[i], demons, p.centre + Vector2i(2, 0) + (f.offsets[i] if i < f.offsets.size() else Vector2i(0, i)))
		if u:
			u.level = by.level
			u.refresh()
	if held:
		channeled.emit(by, skill, c)
	return true


# How many of its maker's side's turns a Rift stays once its count starts: 3 x its difficulty.
static func rift_turns(rank: int) -> int:
	return ceili(3.0 * rift_difficulty(rank))


# Skills its items lent went with them (Unit.lost_skills): a channel on one stops, a Rift's count starting as it
# does; a switch of what it runs on (Mana) in progress is a channel, and ends the same.
func _on_lost_skills(u: Unit, skills: Array[Skill]) -> void:
	if u.channel and u.channel.skill in skills:
		end_channel(u)


# u stops channeling whatever it was: a Rift's count starts (close_rift()).
func end_channel(u: Unit) -> void:
	if u.channel and u.channel.skill.rifts:
		close_rift(u)
	u.channel = null


# u is interrupted (Jam): everything it keeps up by constant attention ends - its channel (a Rift's
# count starts), hiding (what lasts until it moves: Hide), Shields Up!'s guard, a primed Chant, and the
# watch it builds resting turns in a row (survey()). What ended, by name: &"channel", &"hiding",
# &"guard", &"chant", &"watch".
func interrupt(u: Unit) -> Array[StringName]:
	var ended: Array[StringName] = []
	if u.channel:
		end_channel(u)
		ended.append(&"channel")
	for e in u.timed.keys():
		var a: Unit.Applied = u.timed[e]
		if a.until_move:
			u.timed.erase(e)
			if &"hiding" not in ended:
				ended.append(&"hiding")
		elif a.skill and a.skill.behaviour(&"guard"):
			u.timed.erase(e)
	if u.guard:
		u.guard = false
		ended.append(&"guard")
	if u.chant_up or u.chant_gains > 0:
		u.chant_up = false
		u.chant_gains = 0
		ended.append(&"chant")
	if u.rested_turns > 0:
		u.rested_turns = 0
		ended.append(&"watch")
	interrupted.emit(u, ended)
	return ended


# u, channeling a skill that senses (Clairvoyance), senses every foe its side can't see (none of it has
# it located, pings aside) within `reach` tiles of where it stands, walls or not. Each is pinged at its
# tile - its side then knows where it is and nothing more (Perception.unit(), HUD.view()) - and u grows
# a stack more suspicious of that tile. The channel's pings before are dropped.
func ping(u: Unit, reach: int) -> void:
	var ch := u.channel
	ch.pings.clear()
	if u not in _seers:
		_seers.append(u)
	var side := members(u.faction)
	_blind_to_pings = true
	for t: Unit in units.values():
		if t.is_alive() and not Faction.friends(t.faction, u.faction) and Command.tiles(u.cell, t.cell) <= reach \
				and not side.any(func(a: Unit): return read(a, t).located()):
			ch.pings[t] = t.cell
	_blind_to_pings = false
	for t in ch.pings:
		suspect(u, ch.pings[t])


# Where side f has sensed foes by Clairvoyance: foe -> the tile it was pinged at, over every channel of
# it its units hold (none while ping() looks).
func pinged(f: Faction) -> Dictionary[Unit, Vector2i]:
	var out: Dictionary[Unit, Vector2i] = {}
	if _blind_to_pings or _seers.is_empty():
		return out
	_seers.assign(_seers.filter(func(u: Unit): return is_instance_valid(u) and u.is_alive() and u.channel))
	for u in _seers:
		if u.faction == f:
			out.merge(u.channel.pings)
	return out


# Whether a Rift can open at c: free dry ground, in a clear line from its caster below rank III.
func can_rift(by: Unit, skill: Skill, c: Vector2i) -> bool:
	return not unit_at(c) and depth(c) == 0 and (by.rank(skill) >= 3 or clear_line(by.cell, c))


# Its maker stops channeling its Rift: its count starts (rift_turns()), the doors still open both ways;
# when it runs out, its maker's side comes back and the domain goes, with whatever else is in it.
func close_rift(by: Unit) -> bool:
	var s := by.channel.skill if by.channel else null
	by.channel = null
	for p in pockets:
		if p.by == by and p.kind == &"domain" and p.turns < 0:
			p.turns = rift_turns(by.mods(s).irank(by.rank(s), &"rank_impact") if s else 1)
			for m in p.marks:
				m.turns = p.turns
	return true


func _in_pocket(c: Vector2i) -> Pocket:
	for p in pockets:
		if c in p.cells:
			return p
	return null


# The free tile of pocket p nearest c, its door left clear.
func free_near_in(p: Pocket, c: Vector2i) -> Vector2i:
	var best := p.centre
	var d := INF
	for x in p.cells:
		if x != p.door and not unit_at(x) and Vector2(x).distance_to(Vector2(c)) < d:
			best = x
			d = Vector2(x).distance_to(Vector2(c))
	return best


# A walk that ends on a door goes through it: the field door into its pocket, the pocket's own back out
# beside the field door.
func _through(u: Unit) -> void:
	for p in pockets:
		if p.open and u.cell == p.origin:
			move(u, free_near_in(p, p.door + Vector2i(1, 0)))
			return
		if u.cell == p.door and p.open:
			var out: Variant = free_near(p.origin + Vector2i(1, 0))
			if out != null:
				move(u, out)
			return


# Pockets count down as their maker's side ends its turns; one that runs out ends.
func _tick_pockets(side: Faction) -> void:
	for p in pockets.duplicate():
		if p.turns > 0 and p.by and p.by.faction == side:
			p.turns -= 1
			for m in p.marks:
				m.turns = p.turns
			if p.turns <= 0:
				end_pocket(p)


# Its maker's side back in a clump beside the field door; whatever else is in it goes with it.
func end_pocket(p: Pocket) -> void:
	for u: Unit in units.values() + inside.keys():
		if u.cell in p.cells and u.is_alive():
			if p.by and Faction.friends(u.faction, p.by.faction):
				var out: Variant = free_near(p.origin)
				if out != null:
					move(u, out)
			else:
				units.erase(u.cell)
				inside.erase(u)
				u.queue_free()
	for c in p.cells:
		map.erase_cell(c)
	for m in p.marks:
		m.queue_free()
	pockets.erase(p)


# Whether `by` can still hold u: beside it, or engulfing it on its own tile (a mist Undine).
func _within_grip(by: Unit, u: Unit) -> bool:
	return by.cell == u.cell or next_to(by.cell, u.cell)


# --- Water
# Water's depth is in unit sizes: deeper than a unit's size, it's submerged (and so can be drowned).

# How deep the water on c stands: its ground's and each Flood's laid on it, added up.
func depth(c: Vector2i) -> int:
	return terrain(c).depth


# Whether u is under water: deeper than its size, or engulfed by whoever holds it on its own tile.
func submerged(u: Unit) -> bool:
	if depth(u.cell) > _size(u):
		return true
	var a := held_by(u)
	return a != null and a.by != null and a.by.cell == u.cell


# Floods c to `rank` deep for `turns` of its setter's side's turns (Well Up): a layer over what's there,
# slowing movement and putting out fire. Laid again, it keeps the deeper and the longer.
func flood(c: Vector2i, rank: int, turns: int, by: Unit = null) -> void:
	if rank <= 0 or not on_map(c):
		return
	for l: Layer in layers.get(c, []):
		if l.rank > 0:
			if rank > l.rank:
				l.rank = rank
				l.terrain = _flood_terrain(rank)
			l.turns = maxi(l.turns, turns)
			_restack(c)
			douse(c)
			return
	var l := lay_layer(c, _flood_terrain(rank), true)
	l.rank = rank
	l.turns = turns
	l.faction = by.faction if by else turn
	douse(c)


var _floods := {}  # rank -> the Flood terrain at that depth


func _flood_terrain(rank: int) -> Terrain:
	if rank not in _floods:
		var t: Terrain = FLOOD.duplicate()
		t.depth = rank
		t.drag = FLOOD.drag * rank
		t.name = "Flood %s" % Skill.roman(rank)
		_floods[rank] = t
	return _floods[rank]


# Puts out fire on c (water, a Flood).
func douse(c: Vector2i) -> void:
	flames.erase(c)


# Floods drain as their setter's side ends its turns.
func _drain(side: Faction) -> void:
	for c: Vector2i in layers.keys():
		for l: Layer in layers[c].duplicate():
			if l.rank > 0 and l.turns > 0 and l.faction == side:
				l.turns -= 1
				if l.turns <= 0:
					layers[c].erase(l)
					_restack(c)


func _let_go(u: Unit, s: Skill) -> void:
	for e in s.effects:
		u.timed.erase(e)
	for e in u.timed.keys():
		if u.timed[e].lasting and u.timed[e].skill == s:
			u.timed.erase(e)  # a grip its behaviour put on (Hitch)


# Forced movement (Behaviours/displace.gd, Kick, Send Off, the shove, fear and entrance effects): t moves up
# to n tiles from `from` - away (dir 1) along the line from it through t, or toward it (dir -1), a step at a
# time straight for it, stopping beside it - a tile at a time, stopping short of the map's edge, a hole or
# another unit. Ground it's moved over does nothing to it, and it doesn't turn (docs/plans/facing.md).
# Teleporting, it goes straight to the furthest free tile on that line, n tiles out or nearer (place(): a
# trap there springs), never past `from`. Returns the tiles it went (0: none).
# Whoever moved lets go: a grapple t is held in, or holds others in, ends (_let_go()). Driven away and
# stopped short by a unit or the edge, t takes SLAM blunt damage for each tile unspent - and the unit it
# struck the same (docs/plans/fear.md). `tags` (shove, fear, entrance) ride on the move (driven) and on that
# damage, so effects and passives tagged so count on it; `by` is who drove it, credited with the blow.
func displace(t: Unit, from: Vector2i, dir: int, n: int, teleport := false, tags: Array[StringName] = [], by: Unit = null) -> int:
	var line := Vector2(t.cell - from).normalized() * signf(dir)
	var start := t.cell
	var went := 0
	var hit := false
	if teleport:
		for k in range(n, 0, -1):
			var c := Vector2i((Vector2(start) + line * k).round())
			if c != start and c != from and on_map(c) and not unit_at(c) and (dir > 0 or Command.tiles(start, c) < Command.tiles(start, from)) and place(t, c):
				went = k
				break
	else:
		for k in range(1, n + 1):
			var c: Vector2i
			if dir < 0:
				if next_to(t.cell, from):
					break
				var d := from - t.cell
				c = t.cell + Vector2i(signi(d.x), signi(d.y))
			else:
				c = Vector2i((Vector2(start) + line * k).round())
				if c == t.cell:
					continue
			if not on_map(c) or not move(t, c):
				if dir > 0:
					hit = _slam(t, c, n - went, tags, by)
				break
			went += 1
	if went > 0:
		_break_grips(t)
	if went > 0 or hit:
		driven.emit(t, by, tags, went, hit)
	return went


# SLAM blunt damage to t for each of the `left` tiles it didn't get, driven into c (the unit there, or the
# map's edge); the unit takes the same. True if it hurt (the push was stopped, with tiles to spare).
func _slam(t: Unit, c: Vector2i, left: int, tags: Array[StringName], by: Unit) -> bool:
	if left <= 0 or not t.is_alive():
		return false
	var hurt: Array[StringName] = [&"blunt"]
	hurt.append_array(tags.filter(func(x: StringName): return x not in hurt))
	var other := unit_at(c) if on_map(c) else null
	t.hit(SLAM * left, hurt, by)
	if other and other != t and other.is_alive():
		other.hit(SLAM * left, hurt, by)
	return true


# Draws t up to n tiles toward `to`, a step at a time, stopping beside it or at anything in the way (displace()).
func pull(t: Unit, to: Unit, n: int, tags: Array[StringName] = [], by: Unit = null) -> int:
	return displace(t, to.cell, -1, n, false, tags, by)


# Drives t up to n tiles straight away from `from` (displace()). Returns the tiles it went.
func push(t: Unit, from: Unit, n: int, tags: Array[StringName] = [], by: Unit = null) -> int:
	return displace(t, from.cell, 1, n, false, tags, by)


# Teleports t up to n tiles straight away from `from` (displace()). False if no tile on the line is free.
func send(t: Unit, from: Unit, n: int) -> bool:
	return displace(t, from.cell, 1, n, true) > 0


# Puts u on c without walking there (a teleport): no movement paid, no trail of debris, nothing
# brushed past on the way - but a trap there springs, and it takes its first look around.
func place(u: Unit, c: Vector2i) -> bool:
	if not move(u, c):
		return false
	if terrain(c).is_trap():
		spring(c, u)
	if c in marks and u.is_alive():
		_trigger(u, c, &"enter")
	if u.is_alive():
		_first_look(u)
	return true


# A heal: its wounds of rank `power` or less cleared (an effect's wound flag), then hp back, plus
# per_wound for each wound cleared (First Aid: rank). Returns the wounds cleared.
func mend(t: Unit, hp: int, power: int, per_wound := 0) -> int:
	var n := 0
	for e in t.timed.keys():
		if e.wound and t.timed[e].rank <= power:
			t.timed.erase(e)
			n += 1
	t.heal(hp + per_wound * n)
	return n


# Where a dragging skill (Drown) would take t: the nearest free ground with its tag, by how far t
# must be dragged, that the caster could walk to (within its movement); null if there's none.
func drag_spot(caster: Unit, skill: Skill, t: Unit) -> Variant:
	var best: Variant = null
	for c in cells_near(caster.cell, caster.stat(&"movement")):
		if skill.drags() not in terrain(c).tags or (unit_at(c) and unit_at(c) != t):
			continue
		if Command.tiles(caster.cell, c) > caster.stat(&"movement"):
			continue
		if best == null or Command.tiles(t.cell, c) < Command.tiles(t.cell, best) or (Command.tiles(t.cell, c) == Command.tiles(t.cell, best)
				and Command.tiles(caster.cell, c) < Command.tiles(caster.cell, best)):
			best = c
	return best


# Off a dragging skill's contest roll: its check's range penalty a tile it must drag the foe (Drown: 1),
# less (rank - 1) a tile (SkillCheck.penalty()).
static func drag_penalty(skill: Skill, rank: int, n: int) -> int:
	return skill.check.penalty(rank, n) if skill.check else 0


# Drags t onto `to` and the caster in beside it: onto free ground with the tag if there's any (Drown:
# submerging both), else the nearest free tile. Ground passed over does nothing to either.
func drag(caster: Unit, t: Unit, to: Vector2i, tag: StringName) -> void:
	move(t, to)
	var best := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c := to + Vector2i(dx, dy)
			if c == to or not on_map(c) or (unit_at(c) and unit_at(c) != caster):
				continue
			var key := [int(tag in terrain(c).tags), -Command.tiles(caster.cell, c)]
			if best.is_empty() or key > best[0]:
				best = [key, c]
	if not best.is_empty() and best[1] != caster.cell:
		move(caster, best[1])


# What a persona of rank p can put forward through Personify: stances (Friendly from II, the wrong
# team from III), a level it claims (II), and a name from its pools (III).
static func stances(p: int) -> Array[String]:
	var out: Array[String] = [""]
	if p >= 2:
		out.append("Friendly")
	if p >= 3:
		out.append_array(["Enemy", "Aggressive", "Passive", "Traitor"])
	return out


# Personify's active half (Skill.hybrid): pays its AP, then changes what u's persona puts forward, as
# far as its persona rank allows - up to its Personify rank of changes a use (persona_changes()). It
# advertises while it puts anything forward, and stops once it puts nothing (or clears it all).
# changes: {vibe: Array[String] (I), stance: String (II: Friendly; III: the rest), shows_level: int
# (II; 0: none claimed), tags: Array[StringName] (identity, III), adjective, noun: String (III),
# clear: bool (everything off, as one change)}.
func personify(u: Unit, s: Skill, changes: Dictionary) -> bool:
	if not _acting(u) or not s.hybrid or u.rank(s) == 0 or persona_changes(u, s, changes) > u.rank(s) or not u.pay_for(s):
		return false
	var p := persona_rank(u, s)
	if changes.get("clear", false):
		changes = {vibe = [], stance = "", shows_level = 0, tags = [], adjective = "", noun = ""}
	if changes.get("stance", u.stance) in stances(p):
		u.stance = changes.get("stance", u.stance)
	if p >= 2:
		u.shows_level = maxi(changes.get("shows_level", u.shows_level), 0)
	if p >= 1 and changes.has("vibe"):
		u.shows_vibe.assign(changes.vibe)
	if p >= 3 and changes.has("tags"):
		u.shows_tags.assign(changes.tags)
	if p >= 3 and (changes.has("adjective") or changes.has("noun")):
		u.set_alias(changes.get("adjective", ""), changes.get("noun", ""))
	var forward := not (u.shows_vibe.is_empty() and u.shows_tags.is_empty()) or u.stance != "" or u.shows_level > 0 or u.alias != ""
	if forward != u.is_on(s):
		u.toggle(s)
	used.emit(u, s, u, 0)
	return true


# How many things `changes` changes about u's persona: its stance, the level it claims and the name it
# goes by count one each; each vibe word or identity tag put on or taken off, one each. Clearing it
# all is one.
static func persona_changes(u: Unit, _s: Skill, changes: Dictionary) -> int:
	if changes.get("clear", false):
		return 1
	var n := 0
	for k in ["stance", "shows_level"]:
		if changes.has(k) and changes[k] != u.get(k):
			n += 1
	if (changes.has("adjective") or changes.has("noun")) and (changes.get("adjective", "") + " " + changes.get("noun", "")).strip_edges() != u.alias:
		n += 1
	for pair in [["vibe", u.shows_vibe], ["tags", u.shows_tags]]:
		if changes.has(pair[0]):
			var now: Array = changes[pair[0]]
			n += now.filter(func(x): return x not in pair[1]).size() + pair[1].filter(func(x): return x not in now).size()
	return n


# u's persona rank with s switched on.
static func persona_rank(u: Unit, s: Skill) -> int:
	return roundi(u.stat(&"persona")) + (0 if u.is_on(s) else u.rank(s))


func _acting(u: Unit) -> bool:
	if interrupter:
		return u == interrupter and phase == Phase.TURNS and u.is_alive() and not u.stopped()  # only it, until it's done
	return phase == Phase.TURNS and (u.faction == turn or (posing(u) and u.follows.faction == turn)) and u.is_alive() and not u.stopped()


# Touching, diagonals included.
static func next_to(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


# The sides in turn order that count toward the battle's end: all but neutral ones (Starmen).
func fighting() -> Array[Faction]:
	var out: Array[Faction] = []
	out.assign(order.filter(func(f: Faction): return not f.neutral))
	return out


# How many sides are still fighting, allies counting as one.
func sides_left() -> int:
	var heads: Array[Faction] = []
	for f in fighting():
		if not heads.any(func(h: Faction): return Faction.friends(h, f)):
			heads.append(f)
	return heads.size()


# A side holding the field once the battle's over (allies hold it together), or null.
func victor() -> Faction:
	if winner:
		return winner if phase == Phase.OVER else null
	var left := fighting()
	return left[0] if phase == Phase.OVER and sides_left() == 1 and not left.is_empty() else null


# Whether side f won: the battle's over, it's still standing, and it or an ally holds the field.
func won(f: Faction) -> bool:
	return victor() != null and Faction.friends(victor(), f) and members(f).size() > 0


# --- The star lattice (the Astral Envoy)

func on_lattice(c: Vector2i) -> bool:
	return c in panes or c in starpower


# The starpower source c draws on: itself, or the fullest source joined to it through whole starpanes,
# side-on. Null if it's off the lattice or linked to none.
func star_source(c: Vector2i) -> Variant:
	if not on_lattice(c):
		return null
	var seen := {c: true}
	var queue: Array[Vector2i] = [c]
	var best: Variant = null
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		if at in starpower and (best == null or charge[at] > charge[best]):
			best = at
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = at + d
			if n not in seen and on_lattice(n):
				seen[n] = true
				queue.append(n)
	return best


# How much faster Power comes back on c: x2 linked to a source with a little Power in it, up to x5 to a
# full one; x1 off the lattice, or linked only to empty sources.
func star_rate(c: Vector2i) -> float:
	var s: Variant = star_source(c)
	if s == null or charge[s] <= 0:
		return 1.0
	return lerpf(STAR_SLOW, STAR_FAST, charge[s] / float(STAR_CAPACITY))


# As its side's turn ends, on the lattice: Power back at star_rate() x its resting rate ((con mod +
# wis mod) / 2, at least 1), whatever it did; Energy that isn't Power gets STAR_ENERGY of the boost.
func _starlight(u: Unit) -> void:
	var m := star_rate(u.cell)
	if m <= 1.0:
		return
	var k := maxi(u.rounded((u.mod(&"constitution") + u.mod(&"wisdom")) / 2.0), 1)
	u.grant_energy(u.rounded(k * m) if u.powered() else u.rounded(k * (m - 1.0) * STAR_ENERGY))


# How far a unit's sap reaches another: a tile side-on, +0.25 a size step past Medium of each, so
# larger units reach (and are reached on) diagonals.
func sap_reach(u: Unit, o: Unit) -> float:
	return 1.0 + 0.25 * (maxi(_size(u) - MEDIUM, 0) + maxi(_size(o) - MEDIUM, 0))


func _size(u: Unit) -> int:
	return roundi(u.stat(&"size")) if u.race else u.size


# Starsap, as its side's turn ends: it drains its sap in Energy (Power) from each unit of another side
# in sap_reach(), HP once their Energy runs out, into its own Power; what it can't hold fills the
# starpower sources, emptiest first. Once every source is full, it saps no more.
func _sap(u: Unit) -> void:
	var n := roundi(u.stat(&"sap"))
	if n <= 0 or (not charge.is_empty() and charge.values().all(func(x: int): return x >= STAR_CAPACITY)):
		return
	var drained := {}
	var got := 0
	for o: Unit in units.values():
		if Faction.friends(o.faction, u.faction) or not o.is_alive() or Vector2(o.cell).distance_to(Vector2(u.cell)) > sap_reach(u, o) + 0.0001:
			continue
		var off := mini(o.energy, n)
		o.energy -= off
		o.damage(n - off)
		drained[o] = n
		got += n
	if drained.is_empty():
		return
	got -= u.grant_energy(got)
	var sources := charge.keys()
	sources.sort_custom(func(a: Vector2i, b: Vector2i): return charge[a] < charge[b])
	for c: Vector2i in sources:
		var put := mini(got, STAR_CAPACITY - charge[c])
		charge[c] += put
		got -= put
	sapped.emit(u, drained)


# Starkind, as its side's turn starts or ends: ending it off the lattice, it loses (1 - 0.2 x rank) of
# its max HP. On the lattice at full Power, it grows a Reforming stack each time; otherwise it loses
# one. Once its stacks reach its level, it reforms (Unit.reforms_into: a Starman) at full strength.
func _starkind(u: Unit, ending: bool) -> void:
	var k := u.starkind()
	if k <= 0 or not u.is_alive():
		return
	var on := on_lattice(u.cell)
	if ending and not on:
		u.damage(maxi(ceili(maxf(1.0 - 0.2 * k, 0.0) * u.max_hp), 1))
		if not u.is_alive():
			return
	var stacks: int = u.timed[REFORMING].rank if REFORMING in u.timed else 0
	stacks = stacks + 1 if on and u.energy >= u.max_energy else maxi(stacks - 1, 0)
	if stacks <= 0:
		u.timed.erase(REFORMING)
		return
	var a := u.afflict(REFORMING, 1, stacks)
	a.rank = stacks
	a.lasting = true
	if stacks >= u.lv() and u.reforms_into:
		var c := u.cell
		units.erase(c)
		u.get_parent().remove_child(u)
		var now := summon(load(u.reforms_into), u.faction, c)
		reformed.emit(u, now)
		u.queue_free()


# Breathtaking: a curse that lands gives its target a stack of Asphyxia - each 1% x the caster's
# Breathtaking rank of its max HP gone (Applied.scale) - holding for (1 + that rank) of its turns since
# the last, then falling a stack a turn.
func _choke(caster: Unit, t: Unit) -> void:
	var k := roundi(caster.stat(&"breathless"))
	var a: Unit.Applied
	if ASPHYXIA in t.timed:
		a = t.timed[ASPHYXIA]
		a.rank += 1
	else:
		a = t.afflict(ASPHYXIA, 1, 1)
	a.turns = 1 + k + (1 if t.faction == turn else 0)
	a.fades = true
	a.scale = maxf(a.scale, k)
	a.by = caster
	a.since = turns_begun
	t.refit()


# --- Strike

# A chain skill (Strike) on a foe: up to rank hits (one, with Brutal Strike's single), each rolling on
# its own - d20 + its attack mod (and bracing) - a hit in a row, against Defense; a miss ends it. Each
# hit landed in a row takes 1 off the rolls and damage after it. Its Strike passives (Effect stats)
# shape it: decisive (after a critical the rest land; damage by the higher of dex and str mod), brutal
# (the first hit + its weapon's rank + this), steady (the first this hits: no penalty, and a miss
# doesn't end it), featured (the first this hits + cha mod, up to this), recording (the first this hits
# try to curse the foe's leftmost skill: _record()), and its element (imbued, or Elemental Mastery:
# the element's tag, the first hit + its highest mental mod). Landing 12 hits with Strike! (restrike),
# it strikes again at once with restrike - 1 more (up to three times: a bowling game's strikes); 36 in
# all (PERFECT_HITS) is a Perfect: PERFECT_HEAL healed at once. How many hits landed.
# `r` is its rank as it hits (rank_impact, through its caster's modifiers: Battle.cast()); `acts` its
# behaviours' Cast (their guard, edge and bonus on each roll); `req` its contingency's payoff
# (requirement(): + to hit, damage, edge).
func _chain(caster: Unit, skill: Skill, t: Unit, r: int, tags: Array[StringName], extra := 0, depth := 0, acts: Behaviour.Cast = null, req: Array = [0, 0, 0, 0, 0.0]) -> int:
	var tier := skill.tier(r)
	if not tier:
		return 0
	var hits := (1 if caster.stat(&"single") > 0.0 else r) + extra
	var m := caster.mods(skill)
	var steady := roundi(caster.stat(&"steady"))
	var featured := roundi(caster.stat(&"featured"))
	var recording := roundi(caster.stat(&"recording"))
	var decisive := caster.stat(&"decisive") > 0.0
	var brutal := roundi(caster.stat(&"brutal"))
	var elemental := caster.stat(&"elemental") > 0.0
	var element := caster.element if caster.element else God.tag_of(caster.deity(), &"fire")
	var imbued := caster.imbued > 0
	var blow := tags.duplicate()
	if (imbued or elemental) and element not in blow:
		blow.append(element)
	var mental := m.stat(maxi(maxi(caster.mod(&"intelligence"), caster.mod(&"wisdom")), caster.mod(&"charisma")), &"stat_impact")  # the element's bonus: stat impact
	var zeal := passion(caster, t)  # Impassioned Fighter
	var landed := 0
	var gross := 0
	var row := 0  # hits in a row so far
	var sure := false
	for i in hits:
		if not t.is_alive():
			break
		var penalty := 0 if i < steady else row
		var bonus := caster.attack_mod(skill) + zeal + caster.check_bonus(caster.wielded(skill.stat(), tags), &"offensive") - penalty + discipline_hit(caster) + int(req[0])
		var hit := resolve(Check.attack(bonus, t.defense(blow) + guard_of(acts)).edge(clampi(edge_of(skill, acts) + int(req[2]), -1, 1)).sure(sure).keen(discipline_keen(caster)))
		var crit := hit.crit
		attacked.emit(caster, t, hit.d20, hit.total, hit.target)
		_evaluate(caster, skill, hit.d20, hit.total)
		if hit.hit and acts and skill.hostile and t != caster:  # hit: reactions before its damage (Interject)
			var rh := react(&"hit", t, caster, acts)
			if _swapped(acts, rh):
				t = acts.target
				acts.bag[&"hp_before"] = t.hp
				blow = acts.tags.duplicate()
				if (imbued or elemental) and element not in blow:
					blow.append(element)
				zeal = passion(caster, t)
				hit.target = t.defense(blow) + guard_of(acts) + rh.guard
				hit.hit = hit.crit or hit.total >= hit.target
				if not hit.hit:
					attacked.emit(caster, t, hit.d20, hit.total, hit.target)
		if not hit.hit:
			row = 0
			if i < steady:
				continue
			break
		if crit and decisive:
			sure = true
		var stat := tier.stat
		if decisive and stat and caster.mod(&"dexterity", tags) > caster.mod(caster.wielded(stat, tags), tags):
			stat = &"dexterity"
		var power := tier.power + roll(tier.dice) - penalty + int(req[1])
		if stat:
			power += m.stat(caster.mod(caster.wielded(stat, tags), tags), &"stat_impact") + caster.weapon_bonus(stat) + (zeal if stat == skill.stat() else 0)
		if acts:
			for bh in skill.behaviours:
				power += bh.bonus(acts)
		if i < featured:
			power += clampi(caster.mod(&"charisma"), 0, featured)
		if i == 0:
			power += (brutal + (caster.weapon.ranked() if caster.weapon else 0)) if brutal > 0 else 0
			power += mental * (int(imbued) + int(elemental))
		var dealt := maxi(roundi(power * (1.0 + caster.stat(&"damage", blow) + discipline_damage(caster, skill))), 1) * (2 if crit else 1)
		t.hit(dealt, blow, caster)
		gross += dealt
		landed += 1
		row += 1
		if i < recording and t.is_alive():
			_record(caster, t)
	if gross > 0 and next_to(caster.cell, t.cell):
		_refill(caster, t, gross)  # Starblade
	if imbued and depth == 0:
		caster.imbued -= 1
	var again := roundi(caster.stat(&"restrike"))
	if landed >= 12 and again > 0 and depth < 3 and t.is_alive():  # Strike!: a strike, bowled
		landed += _chain(caster, skill, t, r, tags, again - 1, depth + 1, acts, req)
	if depth == 0 and landed >= PERFECT_HITS:  # three strikes in a row: a perfect game
		caster.heal(PERFECT_HEAL)
		perfect.emit(caster)
	return landed


# Record Striker: the foe's wis (and bracing) against the striker's highest mental mod; failing, the
# skill in its leftmost hotbar slot goes a rank down for its next turn (a curse).
func _record(caster: Unit, t: Unit) -> void:
	var first: Skill = null
	for s in t.hotbar:
		if s:
			first = s
			break
	if not first:
		return
	var mind: StringName = [&"intelligence", &"wisdom", &"charisma"].reduce(func(best: StringName, x: StringName): return x if caster.mod(x) > caster.mod(best) else best, &"intelligence")
	var vs := check(caster, mind, t, &"wisdom")
	contested.emit(caster, t, vs.mine.total, vs.theirs.total)
	if not vs.won:
		return
	var e := Effect.new()
	e.stat = "rank"
	e.amount = -1.0
	e.name = "Recorded"
	e.skills = [first] as Array[Skill]
	var a := t.afflict(e, 1 + (1 if t.faction == turn else 0))
	a.by = caster
	a.since = turns_begun


# --- Beastshape

# Beasts a Druid can take the form of (Beastshape): form -> [the ground it thrives on (tile tags), the
# biomes it belongs to, its traits]. A mote thrives on any elemental ground (MOTES). Traits count as
# its tags while shaped (Unit.has_tag()). Traits built: haste (+rank movement), tunneler (stone and dirt
# cost rank times less, to 1), elementstrike (its Strikes carry the ground's element, rank uses:
# Elemental Strike's way) and aquatic (a pike: water costs 1 to enter, never drowns - _cost(), _grip()). Climber, blindsense,
# floating, siphon and coalesce wait (docs/todo/classes.md: Druid).
const FORMS := {
	&"rabbit": [[&"grass", &"dirt"], [&"sylvan", &"montane", &"xeric", &"nival"], [&"haste"]],
	&"squirrel": [[&"wood", &"leaves", &"brush", &"shrubbery"], [&"sylvan", &"montane"], [&"climber"]],
	&"mole": [[&"stone", &"dirt", &"rock"], [&"sylvan", &"montane", &"xeric"], [&"blindsense", &"tunneler"]],
	&"wisp": [[&"star", &"void"], [&"astral"], [&"siphon", &"floating"]],
	&"pike": [[&"water", &"wet"], [&"thalassic"], [&"aquatic"]],
	&"mote": [[], [&"astral"], [&"elementstrike", &"coalesce"]],
}
# Elemental ground a mote thrives on: tile tag -> [the element its Strikes carry, the elemental it
# would Coalesce into].
const MOTES := {
	&"water": [&"water", "Undine"], &"wet": [&"water", "Undine"], &"dark": [&"dark", "Wraith"], &"light": [&"light", "Seraph"],
	&"magic": [&"magical", "Sandestin"], &"stone": [&"earth", "Oread"], &"rock": [&"earth", "Oread"], &"earth": [&"earth", "Oread"],
	&"grass": [&"nature", "Sprite"], &"leaves": [&"nature", "Sprite"], &"shrubbery": [&"nature", "Sprite"], &"fire": [&"fire", "Ifrit"],
	&"sand": [&"air", "Djinn"], &"desert": [&"air", "Djinn"], &"ice": [&"ice", "Hrimling"], &"snow": [&"ice", "Hrimling"],
}
const TUNNELS: Array[StringName] = [&"stone", &"dirt", &"rock"]


# The beast u could become where it stands: [form, element] for the first of FORMS of a biome it
# picked thriving on its ground (a mote: the first elemental tag there), or [] for none.
func form_for(u: Unit) -> Array:
	var biomes := u.biomes()
	for f: StringName in FORMS:
		if not (FORMS[f][1] as Array).any(func(b: StringName): return b in biomes):
			continue
		if f == &"mote":
			for t in u.ground:
				if t in MOTES:
					return [f, MOTES[t][0]]
		elif (FORMS[f][0] as Array).any(func(t: StringName): return t in u.ground):
			return [f, &""]
	return []


# --- Sol's fire

# Fire a unit takes from a burning tile: 1d8 + its setter's wis mod (at least 1), fire and
# environmental (Flamedance wards it).
func flame(u: Unit, f: Flame, why: String) -> void:
	var by: Unit = f.by if is_instance_valid(f.by) else null
	react(&"hit", u, by)  # a moment with no cast to swap (Behaviour.Reaction.cast is null): the ground did it
	var n := u.hit(maxi(roll(Vector2i(1, 8)) + f.bonus, 1), [&"fire", &"environmental"] as Array[StringName], by)
	burned.emit(u, n, why)


# Whether `at` lies in a cone from `from`, aimed at angle `aim`, `half` radians to either side, `long`
# tiles out (Behaviours/cone.gd: Solar, Wildfire).
func in_cone(from: Vector2i, at: Vector2i, aim: float, half: float, long: float) -> bool:
	var to := Vector2(at - from)
	return to.length() <= long + 0.0001 and absf(angle_difference(aim, to.angle())) <= half + 0.0001


# Evading (Glossary: Evadable): a dex check against dc. Passing, none of it lands (0); failing by a
# quarter of the dc or less, half (0.5); otherwise all of it (1). Without its reactions (Unit.reacts(): Jammed,
# helpless), it can't try: all of it.
func evade(u: Unit, dc: int) -> float:
	if not u.reacts():
		evaded.emit(u, 0, dc, 1.0)
		return 1.0
	var roll := check(u, &"dexterity", null, dc, {role = &"defensive"})
	var share := 0.0 if roll.won else (0.5 if roll.mine.total >= ceili(dc * 0.75) else 1.0)
	evaded.emit(u, roll.mine.total, dc, share)
	return share


# Using a skill from a burning slot (Unit.burning_slots()) burns its user.
func _burn(u: Unit, s: Skill) -> void:
	var i := u.hotbar.find(s)
	var hot := u.burning_slots()
	if i >= 0 and i in hot:
		var n := u.hit(hot[i][0], [&"fire"] as Array[StringName], hot[i][1])
		burned.emit(u, n, "its slot burns")


# Discipline (a toggle): an attack on a foe burns all the AP its user has left (not dex move AP) into
# it (Unit.disciplined, for this attack). What that buys is its points, discipline_points(): each is
# DISCIPLINE_HIT to hit, DISCIPLINE_DAMAGE x the attack's stat mod (at least 1) more damage, and a whole
# one a face lower to crit on. Holding a reserve that aims (Focus), it gets half the points back into
# it, rounded up. The less it has spent this turn, the more there is to burn.
func _discipline(u: Unit, s: Skill, foe: bool) -> void:
	u.disciplined = 0
	if u.stat(&"discipline") <= 0.0 or not foe or not (s.attacks() or s.chain):
		return
	var left := 0.0
	for p in u.ap:
		if p.only != &"move":
			left += p.amount
	var burn := floori(left + 0.0001)
	if burn > 0 and u.pay(burn, &"skill"):
		u.disciplined = burn
		for r in u.pools():  # a steadied mind: Focus comes back a little
			if r.aims and u.pools()[r] > 0:
				u.set_store(r, u.store(r) + ceili(discipline_points(u) / 2.0 - 0.0001))
		disciplined.emit(u, burn)


# What a AP burned at Discipline rank r buys: a ^ (r / (r + 1)). One AP is one point at any rank; past
# that returns diminish, less so each rank, flattening toward one point an AP (docs/plans/small-notes.md).
static func discipline_curve(a: float, r: float) -> float:
	return pow(a, r / (r + 1.0)) if a > 0.0 and r > 0.0 else 0.0


# u's points of Discipline on the attack it's making (0 between attacks).
static func discipline_points(u: Unit) -> float:
	return discipline_curve(u.disciplined, u.stat(&"discipline"))


static func discipline_hit(u: Unit) -> int:
	return roundi(discipline_points(u) * DISCIPLINE_HIT)


static func discipline_keen(u: Unit) -> int:
	return floori(discipline_points(u) + 0.0001)


# The damage share it adds to s's hits: DISCIPLINE_DAMAGE a point, times s's stat mod (at least 1).
static func discipline_damage(u: Unit, s: Skill) -> float:
	if u.disciplined <= 0:
		return 0.0
	return discipline_points(u) * DISCIPLINE_DAMAGE * maxi(u.mod(u.wielded(s.stat(), s.tags), s.tags), 1)


# Chant, as its side's turn ends with it having waited (rested) through it: its next rank Sweet
# Nothing gains each bring one more, and its next Warlock skill is used a rank higher.
func _chant(u: Unit) -> void:
	var r := roundi(u.stat(&"chant"))
	if r > 0:
		u.chant_gains = maxi(u.chant_gains, r)
		u.chant_up = true
		chanted.emit(u, r)


# --- Last stands, Level Down and Death

# A general defensive check of the whole unit: d20 + its average stat mod (Unit.average_mod()). Against
# an execute (Death, at its rank), cut by how hurt it is: x (HP left / max HP, Unit.execute_share()) /
# rank - and a check that executes, so check effects tagged execute add to it (Unit.check_bonus()).
func last_stand(u: Unit, execute := 0) -> int:
	var c := Check.check(stand_bonus(u, execute), 0, Check.Kind.LAST_STAND)
	return resolve(c.cut(stand_share(u, execute))).total


# What a last stand adds to its d20 (last_stand()), and the share of it that counts.
static func stand_bonus(u: Unit, execute := 0) -> int:
	var bonus := u.check_bonus(&"", &"defensive", [&"execute"] as Array[StringName]) if execute > 0 else 0
	return u.average_mod() + u.best_defensive_bonus() + bonus


static func stand_share(u: Unit, execute := 0) -> float:
	return u.execute_share() / execute if execute > 0 else 1.0


# The share of a foe's defensive check that counts against an execute (a skill tagged execute, its own
# tag or a modifier's: Unit.skill_tags()) at rank
# r: its HP left / max HP (Unit.execute_share(): full while hale) / r, as Death cuts a last stand. 1
# against anything else.
# `by`: the skill, or its tags as its caster uses it (Unit.skill_tags()).
static func executed(t: Unit, by: Variant, r: int) -> float:
	var tags: Array = by.tags if by is Skill else by
	return t.execute_share() / maxi(r, 1) if &"execute" in tags else 1.0


# What skill's contingency (Skill.requires) gives caster using it on target at rank r: [hit, damage,
# edge], all 0 unmet. Its share and payoff go through the caster's modifiers (lambda: Modifiers.share(),
# pay()); a penalty's payoff (below 0) lambda leaves as it is.
func requirement(caster: Unit, skill: Skill, target: Unit, r: int) -> Array:
	var q := skill.requires
	if q == null:
		return [0, 0, 0, 0, 0.0]
	var m := caster.mods(skill) if q.beneficial() else Modifiers.NONE
	var allies := units.values().filter(func(o: Unit): return Faction.friends(o.faction, caster.faction))
	if not q.met(caster, target, r, m.share(q.share), allies, roundi(caster.stat(&"concealment"))):
		return [0, 0, 0, 0, 0.0]
	return [m.pay(q.hit), m.pay(q.damage), q.edge, m.pay(q.turns), q.strength * m.potency if q.strength > 0.0 else q.strength]



# Level Down: rank rolls of d20 + the caster's mod, each beating the higher of the foe's average stat
# mod + level and its last stand. Each that does takes a level off it, for as many turns (rank - misses):
# the skill's level effect at that rank, brittle (easily cleansed).
# `r`: its rank impact (Battle.cast()); `req`: its contingency's payoff (+ to each roll, its edge). How
# many levels it took.
func _level_down(caster: Unit, skill: Skill, t: Unit, r: int, req: Array = [0, 0, 0, 0, 0.0]) -> int:
	var bar := maxi(level_floor(t), last_stand(t))
	var hits := 0
	for i in r:
		var roll := check(caster, skill.stat(), null, bar, level_opts(caster, skill, req))
		contested.emit(caster, t, roll.mine.total, bar)
		if roll.won:  # beating the bar, not meeting it
			hits += 1
	_lose_cover(caster)
	_lose_cover(t)
	if hits > 0:
		for e in skill.effects:
			var a := t.afflict(e, hits + (1 if t.faction == turn else 0), hits)
			a.total = hits
			a.skill = skill
			a.by = caster
			a.since = turns_begun
	leveled.emit(caster, t, hits)
	return hits



# What Level Down's bar never falls below: t's average stat mod + its level (the rest is its last stand).
static func level_floor(t: Unit) -> int:
	return t.average_mod() + t.lv()


# The helper's options for one of Level Down's rolls: its contingency's + hit and edge, the caster's skill
# tags; a roll must beat the bar, not meet it.
static func level_opts(caster: Unit, skill: Skill, req: Array) -> Dictionary:
	return {bonus = int(req[0]), edge = int(req[2]), tags = caster.skill_tags(skill), ties = false}


# The chance (0-1) Level Down by caster takes at least a level off t (_level_down()): the bar is one last
# stand rolled for all `ri` rolls, so each of its totals is weighed in turn and the rolls, each its odds
# against that bar, are independent after it. The HUD's forecast and the AI read this (hit_chance()).
static func level_odds(caster: Unit, skill: Skill, t: Unit, ri: int, b: Battle = null) -> float:
	var req: Array = b.requirement(caster, skill, t, caster.rank(skill)) if b else [0, 0, 0, 0, 0.0]
	var opts := level_opts(caster, skill, req)
	var p := 0.0
	for f in Check.totals(Check.check(stand_bonus(t), 0, Check.Kind.LAST_STAND)):
		var each := odds(caster, skill.stat(), null, maxi(level_floor(t), f[0]), opts)
		p += f[1] * (1.0 - pow(1.0 - each, ri))
	return p


# Impassioned Fighter: what its holder adds to a skill's primary mod used on a unit beside it.
static func passion(caster: Unit, target: Unit) -> int:
	return roundi(caster.stat(&"impassioned")) if target and target != caster and next_to(caster.cell, target.cell) else 0


# Lovely Caster: a love skill (tagged love, or carrying it for its caster - an Eros Smite) used on an
# adjacent ally also heals it that share of its max HP.
func _lovely(caster: Unit, skill: Skill, t: Unit) -> void:
	var share := caster.stat(&"lovely")
	if share > 0.0 and t != caster and t.is_alive() and next_to(caster.cell, t.cell) and &"love" in hit_tags(caster, skill):
		t.healed_by = caster
		mend(t, maxi(roundi(share * t.max_hp), 1), 0)


# How strong a skill that decays with distance (Rejuvinate: Skill.decays) lands from caster on target:
# less its share a tile past the first between them, at least 0 - none off when the caster would pay
# for it wholly with mana. 1 for other skills.
func decay(caster: Unit, skill: Skill, target: Unit) -> float:
	if skill.decays <= 0.0:
		return 1.0
	var fund: Variant = caster.funding(skill)
	if fund is Reserve and (fund as Reserve).name == "Mana":
		return 1.0
	return maxf(1.0 - skill.decays * maxi(Command.tiles(caster.cell, target.cell) - 1, 0), 0.0)


# Death: the foe's last stand against an execute at the skill's rank, against d20 + the caster's mod
# (the caster wins ties). Failing, it takes 1 true damage and dies at once - keeping the HP it had for
# revival and die-hard effects (Unit.slain_from). A heart left, it goes down as usual.
# `r`: its rank impact (Battle.cast()); `req`: its contingency's payoff. Whether it killed.
func _death(caster: Unit, skill: Skill, t: Unit, r: int, req: Array = [0, 0, 0, 0, 0.0]) -> bool:
	var vs := check(caster, skill.stat(), t, &"", {bonus = int(req[0]), edge = int(req[2]), tags = caster.skill_tags(skill), their_bonus = stand_bonus(t, r), cut = stand_share(t, r)})  # its last stand; the caster wins ties
	contested.emit(caster, t, vs.mine.total, vs.theirs.total)
	_lose_cover(caster)
	_lose_cover(t)
	if not vs.won:
		return false
	t.slain_from = t.hp
	if not Downed.finish(t):  # one already Downed dies of it
		t.damage(1)
		t.hp = 0
	caster.gain(&"kill", 1)
	return true



# --- Synergy

# The others o shares what it makes out with: its leader, or its party, where either of the two has
# Synergy (leaders share with their whole party, members with their leader) - within the leader's
# command range of its party (Command.party_reach_of(): a Quartz Ring makes it endless).
func synergized(o: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for p: Unit in units.values():
		if p == o or not p.is_alive() or p.faction != o.faction or not (p.follows == o or o.follows == p):
			continue
		var lead := p if o.follows == p else o
		if (o.stat(&"synergy") > 0.0 or p.stat(&"synergy") > 0.0) and Command.tiles(o.cell, p.cell) <= Command.party_reach_of(lead):
			out.append(p)
	return out


# The clearer of two reads: more detail, then HP made out, then not fooled.
static func clearer(a: Read, b: Read) -> bool:
	if a.net != b.net:
		return a.net > b.net
	if (a.hp != null) != (b.hp != null):
		return a.hp != null
	return b.deceived and not a.deceived


# As its side's turn ends, o gets its own first look at what its synergized partners make out that it
# needs a check for: suspicious tiles (inspect()), and units under a deceiving skill they saw through
# (investigate(), against that skill's roll). Once each.
func _synergize(o: Unit) -> void:
	for p in synergized(o):
		for c in suspicious(p):
			if c not in o.noticed:
				o.noticed[c] = true
				inspect(o, c)
		for t: Unit in units.values():
			if t == o or o.noticed.has(t):
				continue
			for e in t.timed:
				var a: Unit.Applied = t.timed[e]
				if a.skill and a.skill.investigated and p in a.known_to and o not in a.known_to:
					o.noticed[t] = true
					investigate(t, a.skill, [o] as Array[Unit], a.roll)
					break


# u fell: its foes standing near share its worth (_share()), two shares to whoever struck it last,
# wherever it stands (if still standing and not on u's side). A unit pays out for falling only once.
func _award(u: Unit) -> void:
	if u.paid_fall:
		return
	u.paid_fall = true
	var k := u.last_hit_by
	if k and (not is_instance_valid(k) or not k.is_alive() or Faction.friends(k.faction, u.faction)):
		k = null
	_share(u, k, false)


# u, down or dead, was brought back by `by` (a resurrection, or healed back up from going down): its
# side standing near shares its worth (_share()), two shares to `by`. A unit pays out for this only
# once. Hearts and a Red Spinel Ring get a unit up on their own: nobody brings it back.
func rescued(u: Unit, by: Unit) -> void:
	if u.paid_rise:
		return
	u.paid_rise = true
	_share(u, by if by and by != u and is_instance_valid(by) and by.is_alive() else null, true)


# u's worth (Unit.xp_worth()), split in shares: one for each unit standing within XP_NEAR of it - its
# foes as it falls, its side as it's saved - and two for k (the one who felled or saved it, if any).
# Each share rounds, at least 1 XP. The player's starter keeps its levels for the next battle
# (Game.level, Game.xp).
func _share(u: Unit, k: Unit, saved: bool) -> void:
	var near: Array[Unit] = []
	for o: Unit in $Units.get_children():
		if o != u and o != k and o.is_alive() and Faction.friends(o.faction, u.faction) == saved \
				and Vector2(o.cell).distance_to(Vector2(u.cell)) <= XP_NEAR + 0.0001:
			near.append(o)
	var shares := near.size() + (2 if k else 0)
	if shares == 0:
		return
	var each := u.xp_worth() / float(shares)
	if k:
		_pay(k, maxi(roundi(each * 2.0), 1), u, saved)
	for o in near:
		_pay(o, maxi(roundi(each), 1), u, saved)


func _pay(o: Unit, n: int, from: Unit, saved: bool) -> void:
	if o.level >= Unit.MAX_LEVEL:
		return
	var levels := o.gain_xp(n)
	if o == player:
		Game.level = o.level
		Game.xp = o.xp
		Game.equipped = o.get_equipped()  # a level may have auto-equipped something
	gained_xp.emit(o, n, levels, from, saved)


func _on_died(u: Unit) -> void:
	if inside.has(u):
		inside.erase(u)
	elif unit_at(u.cell) == u:
		units.erase(u.cell)
		_vacated(u.cell)
	u.timed.clear()  # nothing ticks for the dead
	end_channel(u)
	neutralize(u, &"killed")
	_award(u)
	var it := u.loot.roll(rng) if u.loot else null
	if it:
		spoils.append([it, u.faction])
		dropped.emit(u, it)
	if u.reverts_to:  # a Starman falls back into a Starmote, keeping what Power it had
		var mote := summon(load(u.reverts_to), u.faction, u.cell)  # (a Starman)
		if mote:
			mote.energy = u.energy
			reverted.emit(u, mote)
	for o in units.values():
		if o.faction == u.faction:
			return  # faction still standing
	if u.faction in lasting:
		return  # more of them will come
	var i := order.find(u.faction)
	order.erase(u.faction)
	zones.assign(zones.filter(func(z: Zone): return z.faction != u.faction))  # nothing left to tick them
	for c in marks.keys():
		for m: Mark in marks[c].duplicate():
			if m.faction == u.faction:
				_drop_mark(c, m)
	if sides_left() < 2:
		phase = Phase.OVER
	elif turn == u.faction and not ending_turn:
		turn = order[i % order.size()]  # (a turn that is ending passes itself: end_turn())


func _enter(p: Phase) -> void:
	match p:
		Phase.INITIATIVE:
			order = roll_initiative()
			phase = Phase.TURNS if sides_left() > 1 else Phase.OVER
		Phase.TURNS:
			turn = order[0]
		Phase.OVER:
			for u: Unit in $Units.get_children():
				refill(u)
