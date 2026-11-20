class_name Behaviour
extends Resource

# One verb a skill performs, what it does (apply) and what it says (describe) side by side, so the two
# can't drift (seam 3, docs/plan-composability.md). A skill lists them (Skill.behaviours); Battle.cast()
# runs them in order once the skill has landed - past its attack roll, its effects on - beside the
# Skill.gd flags, which stay for the skills that use them. New behaviour goes here: a script in
# Behaviours/ extending this, never a new flag (Util/skill.py new --behaviour <name> stubs one).


# A landing skill, as its behaviours see it. `bag` is scratch they share, in order: one can leave
# something for the next.
class Cast:
	var battle: Battle
	var caster: Unit
	var target: Unit
	var locked := false  # no reaction may swap its target any more (Gallantry; Interject snapped)
	var meant: Unit  # the unit it was aimed at, before any reaction swapped its target (Interject's "a hit not aimed at it")
	var skill: Skill
	var rank := 1
	var foe := true
	var bag := {}
	var picked: Array[Unit] = []  # the units its caster chose by hand, when a behaviour asks for picks() (empty: it chooses itself)
	var siphoned := 0  # what its siphon damage took off the target's resources (Unit.siphon()), by the time dealt() runs
	var mods: Modifiers  # its caster's modifiers on it (Unit.mods()): read scaled values through them
	var tags: Array[StringName] = []  # its hit's tags (Battle.hit_tags()): modifier tags among them (Unit.skill_tags()), ambush when it ambushes (Battle.ambushes())

	# Its rank for what rank adds to what it does (rank_impact) or to its reach (rank_range), through
	# its caster's modifiers: a whole number, at least 1 (Kick's push).
	func impact_rank() -> int:
		return mods.irank(rank, &"rank_impact") if mods else rank

	# A cast of no one at rank r: its base, for describe().
	static func at(r: int) -> Cast:
		var c := Cast.new()
		c.rank = r
		return c

	# Stat x's mod as channel `ch` reads it, in markup: "cha mod", or "1.75 x cha mod" under a modifier
	# (a describe_as() line's; Skill._mod()).
	func mod_text(x: StringName, ch := &"stat_impact") -> String:
		return Skill._mod(x, ch, mods if mods else Modifiers.NONE)

	func range_rank() -> int:
		return mods.irank(rank, &"rank_range") if mods else rank

	# + on its caster's side of a check it makes: Density's or Diluted's shift (Modifiers.check).
	func check_shift() -> int:
		return mods.check if mods else 0

	# A stat mod m its caster adds to what it does (stat_impact) or to its reach (stat_range), through
	# its modifiers.
	func stat_mod(m: int, channel := &"stat_impact") -> int:
		return mods.stat(m, channel) if mods else m
	var hit := false  # it landed: past its attack roll, if it makes one
	var strength := 1.0  # what its skill's `decays` leaves of it, set as it was cast (Battle.decay()): every effect it puts on has it (put())

	# Puts e on the target for its turns (+ 1 on its side's turn, which doesn't count), marked as this
	# cast's, as a skill's own effects are (a per-rank one at its rank impact, as Battle puts them).
	func put(e: Effect, turns: int) -> Unit.Applied:
		var a := target.afflict(e, turns + (1 if target.faction == battle.turn else 0), impact_rank() if e.per_rank else rank)
		a.total = turns
		a.scale = strength
		a.skill = skill
		a.by = caster
		a.since = battle.turns_begun
		battle.drive(target, e, a)  # shove, fear, entrance
		return a


func apply(_c: Cast) -> void:
	pass


# How many targets its caster may pick by hand, beyond the one it is aimed at (0: none). Where it is
# more than 0 the HUD lets a click on a visible foe toggle it into Cast.picked (up to this many) while the
# skill is selected, and Battle.cast() carries them; the behaviour reads them in apply() and, with none
# picked, chooses for itself (Warcry: the nearest), as the AI always does. Pure.
func picks(_c: Cast) -> int:
	return 0


# The targets it takes when nothing is picked (a skill with picks()): the HUD draws them faintly before the
# first pick, so a quick cast is no surprise. Warcry: the nearest foes. Pure; apply() should choose the same.
func defaults(_c: Cast) -> Array[Unit]:
	return []


# What apply() does is the whole of the cast `c` (Battle.cast()): it lands at once, past any reactions,
# with no roll, contest, effects or damage of the skill's own (Beastshape, Emergency Exit, an aura, Igna
# on an ally). Pure: asked once the skill is paid for and aimed.
func whole(_c: Cast) -> bool:
	return false


# The unique effect it gives its skill in the cost calculator's terms (SkillTerms impact), where the
# skill names none: &"tame" for doing a thing of its own, &"impactful" for a big one (Beastshape),
# &"" for one that only carries out what its numbers say (Send Off's teleport). Pure.
func impact() -> StringName:
	return &"tame"


# A skill cast on a tile rather than a unit (Battle.cast_at(): Flamewall, Solar, Observe), paid for and
# aimed at `cell`: what it does there. c has no target. A behaviour that has this says so in tile_target().
func apply_at(_c: Cast, _cell: Vector2i) -> void:
	pass


# The tiles apply_at() would cover were its skill cast on `cell` (a Battle.cast_of() with no target), for
# the HUD's preview: who stands in them glows, and the overlay shades them. Empty: no area of its own.
# Pure.
func footprint(_c: Cast, _cell: Vector2i) -> Array[Vector2i]:
	return []


# The skill it's on failed (Battle._miss()): its attack roll missed, its save or contest was lost (a drag,
# a grapple, a level down), its Strike hit nothing, its level or its life wasn't taken. The counterpart
# of apply(), which runs only when it lands: a refund, a rider on a miss. Not run on a cast that is
# stopped or refused before it's tried, nor for a foe's dodge of a tile skill's area (area_blow() hands
# those to missed() too, on a Cast of the victim's own).
func missed(_c: Cast) -> void:
	pass


# How a skill it's on is aimed, if apply_at() makes it a tile skill (Skill.on_tile(), Skill.target()):
# &"tile", or &"area" for one that covers ground around the tile (a cone, a zone); empty: not on a tile.
func tile_target() -> StringName:
	return &""


# Once the skill is paid for and aimed, before any roll (Battle.cast()): what comes first (Sutemi's
# lunge, Poach's discount). The cast's target may still be missed.
func aim(_c: Cast) -> void:
	pass


# Advantage (+1) or disadvantage (-1) it adds to the cast's attack roll, summed with the skill's own
# and clamped (Gank: disadvantage unless it ambushes). Asked by the HUD's hit chance too: no side effects.
func edge(_c: Cast) -> int:
	return 0


# Defense the target adds against this attack (Spike: its unspent AP). No side effects: the HUD asks too.
func guard(_c: Cast) -> int:
	return 0


# Damage added to each of the cast's hits that lands (Spike: + rank).
func bonus(_c: Cast) -> int:
	return 0


# The cast's own target was neutralized (Battle.neutralized: downed, Downed, killed...) as it resolved,
# how saying which (Poach: regain).
func felled(_c: Cast, _how: StringName) -> void:
	pass


# Whether the skill can be used on target at all (Battle.cast() asks before it's paid for; Resuscitate:
# only a Downed unit). Every behaviour on it must allow it.
func fits(_b: Battle, _caster: Unit, _target: Unit) -> bool:
	return true


# The reason shown when fits() says no.
func unfit() -> String:
	return "Not for that one"


# What using the skill as `c` (caster, target, skill, rank set; not run) would give the target back, as
# expected amounts by pool: &"hp", &"energy", or a Reserve. Only what the AI reads, to see what a skill
# is for (AI._restores(): it casts a restorer on whoever is short of what it restores) - so a new
# healing behaviour declares it here and the AI picks it up. Empty: it restores nothing.
func restores(_c: Cast) -> Dictionary:
	return {}


# What the cast saves its caster of its AP and cost, as shares (0-1): x is sure, known before the roll
# (Poach's bloodied foe): Battle.rebate() takes it off the price, so the forecast and the payment both
# show it. y comes back only on a hit (Slam Jam): paid in full, then Unit.refund()ed from apply(); the
# forecast shows it as "on hit". Pure; the one hook a behaviour declares a conditional discount with.
func rebate(_c: Cast) -> Vector2:
	return Vector2.ZERO


# How many bodies its cast `c` adds to its caster's side (a summon: Skeleton's two a rank), for the AI to price. Pure.
func bodies(_c: Cast) -> int:
	return 0


# The share of its AP price the cast saves, expected, given p the chance it lands: what the AI weighs.
func refunds(c: Cast, p: float) -> float:
	var r := rebate(c)
	return r.x + r.y * p


# The tiles of movement the cast gives its caster this turn, as it would be paid for now (Move; a
# payment that counts as Stamina gives more). What the AI weighs a skill by when its foe is a few tiles
# out of reach on foot (AI._stretch()). Pure.
func strides(_c: Cast) -> int:
	return 0


# Defense the cast costs its own caster, through its next turn (Sutemi's Off Balance: a point a tile
# lunged) - what the AI prices against the blow. Pure.
func unguarded(_c: Cast) -> int:
	return 0


# How much of a blow the AI plans (r: the moment as it would come, r.skill this passive, r.cast the blow) its
# holder's reaction would likely take from it (0-1): turning it to itself, or into something its caster
# didn't count on. The same eligibility react() has, no rolls spent (Reaction.odds()); a reaction that
# does nothing the caster would mind leaves the default. AI._foiled() asks it for the foes' reactions it can
# make out, and takes the blow's value down by what's likely to be lost. Pure.
func foils(_r: Reaction, _holder: Unit, _rank: int) -> float:
	return 0.0


# What a hit would do beyond its damage, foreseen as the cast is planned and as Battle.foresee() reads it
# for the HUD's forecast and the AI: {lo, hi: more HP it takes off the target, notes: Array[String]: one
# line for each rider it puts on it}. Optionally for the AI alone: `riders` (how many of its notes it can
# count on, expected: a rider that lands one time in two is 0.5, a note that only reports is 0; default,
# one for each note), `afflicts` (a cc it puts on the target - a status bearing the cc tag - as the share of the
# target's next turn it takes, 0-1, as likely as it lands: Stun's helpless is all of it, Jam's lost reactions a
# part; the AI prices it by what that turn is worth, AI._afflicting(), not as a rider) and `spill` (HP it takes off others net, the caster's foes' less its friends': Kick's
# trap blast and slam). Pure (no rolls spent). Empty: nothing more.
func foresee(_c: Cast) -> Dictionary:
	return {}


# What the holder's reaction (r: the moment, as foils() has it) would cost the blow's author in HP, expected
# and on top of what foils() takes off the blow (Final Act's free action, taken against whoever finished it).
# The AI takes it off the blow's worth (AI._reprisal()), never below what FOILED leaves. Pure.
func reprisal(_r: Reaction, _holder: Unit, _rank: int) -> float:
	return 0.0


# Whether the cast brings a Downed target back up (Resuscitate): the AI prefers it to a plain heal on one
# (AI._heal()), where the two would else tie by list order. Pure.
func revives(_c: Cast) -> bool:
	return false


# After its damage lands (Battle.cast(), the same Cast apply() had): `n`, the HP the target lost to it
# (Jam drains as much of its Focus); what a siphon took is c.siphoned (Energy Transfer).
func dealt(_c: Cast, _n: int) -> void:
	pass


# The terms it adds to its skill's (SkillTerms: what scales how, a check, damage, its impact), so the
# cost calculator prices it and modifiers find it eligible: t.add(&"rank_impact", "push"), t.check = true.
func terms(_t: SkillTerms) -> void:
	pass


# The modifiers on its holder's use of the skill it's on (Unit.mods()), for a hook given only the holder
# and a rank (a passive's): its rank and stat reads go through them (holder_rank(), Peel's reach).
func mods_on(holder: Unit) -> Modifiers:
	if holder == null or not holder.emblems():
		return Modifiers.NONE
	for x in holder.slots:
		if self in x.skill.behaviours:
			return holder.mods(x.skill)
	return Modifiers.NONE


# A hook's rank as channel c reads it through its holder's modifiers (mods_on()): whole, at least 1.
func holder_rank(holder: Unit, rank: int, c := &"rank_impact") -> int:
	return mods_on(holder).irank(rank, c)


# An equipment skill's armor (Unit.armor_defense()): the Defense it sets for `holder`, at `rank`, from `item`, the
# armor lending it. NO_ARMOR: it sets none (the usual), so the unit goes by what its other equipment sets, or unarmored
# (dex mod + con mod). Armor.
const NO_ARMOR := -999999


func armor(_holder: Unit, _rank: int, _item: Item) -> int:
	return NO_ARMOR


# An armor slot its passive gives its holder beyond the first (Unit.plate_skills(), Unit.plating): one armor more
# worn in it, its Defense added to what the armor proper sets and its AP drag and weight to what that costs. The
# rest of the slot's rules are these hooks, each defaulting to a plain slot. Power Armor, Scrap Plating.
func armor_slot() -> bool:
	return false


# Whether that slot works now, at `rank` (Unit.plates()): off, the armor in it stays worn and counts for nothing.
func slot_works(_holder: Unit, _rank: int) -> bool:
	return true


# The Defense the armor worn in that slot confers, given the `defense` its equipment skills set for it.
func slot_defense(_holder: Unit, _rank: int, defense: int) -> int:
	return defense


# An attack of `power` damage that the armor in that slot blocked: it would have hit without it (Battle.roll_attack()).
func slot_blocked(_b: Battle, _holder: Unit, _rank: int, _power: int) -> void:
	pass


# The points of its holder's Power (Energy, or the reserve it runs on) that same block takes off it: what slot_blocked() takes,
# said before the roll so a foe can price it (AI.score()). 0: a plain slot.
func slot_toll(_holder: Unit, _rank: int, _power: int) -> int:
	return 0


# How many hotbar slots its skill takes, where it says (SlotCost: a number of its own, over what the skill's rarity tag
# gives); 0: it has no say. Skill.slots_taken() asks every behaviour, Unit.slot_cost() the unit.
func slots_taken() -> int:
	return 0


# It is its skill's own effect of an enchanted item: lent by one, the skill isn't ranked up by the enchantment
# (Item.skill_rank(), Skill.enchants()), it does its enchanted thing instead (Armor: +1 Defense).
func owns_enchant() -> bool:
	return false


# Used again while its caster channels it: the channel stops there, free, and nothing else happens
# (Battle.cast(); Clairvoyance).
func recast_stops() -> bool:
	return false


# Its skill's channel held through its holder's side's turn end (Battle.end_turn(); Clairvoyance:
# the pings move, then the channel's rank rises).
func held(_b: Battle, _holder: Unit) -> void:
	pass


# It senses foes out of sight, and acts on what it sensed rather than holding still for its channel:
# the AI casts it with nothing else to go on (AI._scry(); Clairvoyance).
func senses() -> bool:
	return false


# It lays tile marks (Battle.lay_mark()) that would do something now - foes in sight to lay them toward, and
# none of its own still up: the AI casts it before it advances (AI._rally(); Warcry).
func marks(_b: Battle, _u: Unit) -> bool:
	return false


# A passive's: the AP a summoned unit `who` keeps on arriving, beyond what the summon gives (Behaviours/summon_per_rank.gd
# asks every passive its summoner has); `rank` is the holder's rank in it. Pure (Wake and Rake: its rank, for a `summon` unit).
func summon_ap(_holder: Unit, _rank: int, _who: Unit) -> int:
	return 0


# What apply() does at this rank, in Glossary markup: one or more lines of the skill's description.
func describe(_rank: int) -> String:
	return ""


# The same as its holder has it (Skill.markup() given a unit): c has the caster (or null), the skill, its
# rank and the caster's modifiers (c.mods) - no battle, no target. A behaviour that reads its numbers
# through c.impact_rank() / range_rank() / stat_mod() overrides this to say them the same way, so a
# modifier shows wherever it acts; by default, describe() at the rank.
func describe_as(c: Cast) -> String:
	return describe(c.rank)


# A behaviour whose numbers scale (it declares rank or stat terms) writes its text once, in describe_as(),
# and has describe() say it at the base: `func describe(rank): return describe_as(Cast.at(rank))`. A sweep
# (sweep_test) holds each to it: a rho-up modifier must change what it says.



# Hooks: what a switched-on passive's behaviours do outside a cast (Unit.hooks()), each given the
# holder and the passive's rank. Each does nothing unless a behaviour says otherwise.

# Whether word that `teller` has grown suspicious of the holder reaches `listener`, an ally of the
# teller's (Battle.spread(); Bandwagon: a cha check).
func lets_word(_b: Battle, _holder: Unit, _rank: int, _teller: Unit, _listener: Unit) -> bool:
	return true


# What a step from `from` to `to` costs the holder, walking, where it costs `cost` so far (Battle.walk(),
# which the HUD's reach and preview use too). `bag` is shared by one walk's steps (Peel counts its tiles).
func step_cost(_b: Battle, _holder: Unit, _rank: int, _from: Vector2i, _to: Vector2i, cost: float, _bag: Dictionary) -> float:
	return cost


# The holder is about to take damage d from a hit (Unit.taking_hit, Battle._on_taking_hit()): how much it still takes
# (Molothrus passes some on).
func hurt(_b: Battle, _holder: Unit, _rank: int, d: int) -> int:
	return d


# u was taken out of the fight (Battle.neutralize(): how is &"downed", &"down" or &"killed"; by, who last hit it, may
# be null), anywhere on the field; the holder is another unit, standing (Deathlust: one dying near it
# eases its exhaustion).
func neutralized(_b: Battle, _holder: Unit, _rank: int, _u: Unit, _by: Unit, _how: StringName) -> void:
	pass


# u's skills d.skills are about to be switched off for d.turns (Unit.disable(), Battle._on_disabling()): d.by
# disables it (null: nobody), d.curse marks a curse's. The holder is d.by (asked first) or u itself: change
# d.turns (Coyote Scepter: + rank), or put something on u - a postponing status holds the disabling off
# (the postpone stat: Coyote Charm).
func disabling(_b: Battle, _holder: Unit, _rank: int, _u: Unit, _d: Dictionary) -> void:
	pass


# The holder is about to die an instant death, with HP left (Unit.slay(): Death, Luun's Smite): set d.defer to put
# it on borrowed time for that many rounds instead (Unit.defer(); an enchanted Coyote Charm).
func slain(_b: Battle, _holder: Unit, _rank: int, _d: Dictionary) -> void:
	pass


# A use of w.skill the holder paid for is over, with its whole cast (Battle._settle_wear()): w.gain is what it added to
# the holder's exhaustion, w.uses what it keeps - lower it (0: none) to ease it; w.felled holds whom it took out
# of the fight, and how (w.killed()). Deathlust: a skill that killed gains no exhaustion.
func wearing(_b: Battle, _holder: Unit, _rank: int, _w: Exhaustion.Wear) -> void:
	pass


# A skill use the holder makes (Battle.use_of()): its outermost cast() or cast_at() and everything inside it -
# every attack roll, an automatic repeat an effect sets off (Strike!'s restrike, Jugular's recast) - until it
# returns; a use chosen afresh (re-aimed by hand, or picked in an interrupt: Chaser) is another. Its rolls carry
# its `id` (Check.Roll.use); opening_rolls counts within it. The payload its passives read and change: at stage
# &"hit", once for each attack that lands (each Strike hit, any attacking skill's blow), before its damage:
# `dealt` is that hit's (0 deals none), `roll` its roll (crit, glance), `landed` the hits on `target` before it
# this use, `skill` the skill hitting, `bonus`, `defense` and `edge` what it rolled with (before a Strike row's
# penalty: Battle.attack_check() takes them). At stage &"end", as the use closes, once for each unit it landed
# on (`struck`): `landed` the hits on it, `dealt` 0 - what it's set to lands on `target` as one more blow, with
# `tags`; `missed` set, it missed. Heavy Strike: every hit's damage held back, then landed as one blow on a last roll.
class Volley:
	var battle: Battle
	var caster: Unit
	var id := 0  # the use's token: its rolls carry it (Check.Roll.use)
	var target: Unit
	var skill: Skill
	var tags: Array[StringName] = []
	var stage := &"hit"
	var dealt := 0
	var landed := 0
	var struck := {}  # Unit -> attacks of this use that landed on it
	var roll: Check.Roll
	var bonus := 0
	var defense := 0
	var edge := 0
	var missed := false
	var first := false  # the first of its side to use a skill this turn (Battle.first_to_act(): First Chair)
	var impact := 0  # impact its passives add to every effect of the use, damage and healing (opening(): Harmony's First Chair)
	var bag := {}  # scratch its passives share across the use (Heavy Strike's pools, Chaser's once)
	var chain := {}  # shared by the use and the uses it sets off (Chaser's chases): its friction (Battle.loops()), Chaser's count


# A skill use as the AI plans it (AI._use_ratio()), before it rolls: the rolls it makes on `target` and what they are
# expected to deal, friction counted (the odds of a roll ahead in the use: Battle.friction_ahead()). A chain (Strike)
# stops at its first miss. `worth` is the damage the use is expected to deal, -1 until counted; a passive that changes
# how a use lands (forecasting()) sets it.
class Forecast:
	var battle: Battle
	var caster: Unit
	var skill: Skill
	var target: Unit
	var tags: Array[StringName] = []  # the attack's (Battle.hit_tags())
	var guess := -1  # the Defense it takes the target to have (Battle.hit_chance()'s)
	var rolls := 1  # attack rolls the use makes, at most
	var per := 0.0  # the damage of each that lands, average
	var worth := -1.0
	var flat := false  # odds() as the first roll's all through: no friction

	# [hit, critical, glance] odds of the use's roll `i` (0 first), `plus` more to hit.
	func odds(i: int, plus := 0) -> Array[float]:
		return Battle.attack_odds(caster, skill, target, battle, guess, 0 if flat else i, plus)

	# The chance that exactly k of its rolls land, k = 0 up: each lands with its own odds, and it ends at the first miss.
	func spread() -> Array[float]:
		var out: Array[float] = []
		var live := 1.0
		for i in rolls:
			var p := odds(i)[0]
			out.append(live * (1.0 - p))
			live *= p
		out.append(live)
		return out

	# What landing rolls alone deal on average: per for each.
	func landings() -> float:
		var sum := 0.0
		var k := 0
		for p in spread():
			sum += p * k * per
			k += 1
		return sum


# The holder's skill use (v: a Volley), as each attack lands and once it's done: change what lands (Heavy Strike).
func striking(_b: Battle, _holder: Unit, _rank: int, _v: Volley) -> void:
	pass


# The holder's skill use, as the AI weighs it (f: a Forecast): a passive that changes how the blows of a use land
# (Heavy Strike pools them behind one last roll) tells what the use is then expected to deal in f.worth. Pure.
func forecasting(_b: Battle, _holder: Unit, _rank: int, _f: Forecast) -> void:
	pass


# t, any unit but the holder, is about to be healed n (Unit.being_healed): how much of it t still gets
# (Molothrus siphons some).
func healing(_b: Battle, _holder: Unit, _rank: int, _t: Unit, n: int) -> int:
	return n


# The Affinity a learned passive's holder has for s, a skill on tree t of a choice it picked, where
# the choice alone gives it `a` (Unit.guest_affinity(); Illusionist: none of the guest penalty for
# the first rank of its school's spells). Read off its slot, whether or not it's switched on.
func affinity(_holder: Unit, _rank: int, _s: Skill, _t: SkillTab, a: int) -> int:
	return a


# What the holder, leading c, may count instead of its charisma mod when it orders u (Command.cha_for();
# Telepathy: its rank, for one ally a turn; Word to the Wise: its wis mod). The best answer of all its
# passives, or its charisma, wins. NO_MOD: nothing to offer.
const NO_MOD := -99


func command_mod(_c: Command, _holder: Unit, _rank: int, _u: Unit) -> int:
	return NO_MOD


# The holder, leading c, has just given u an order (Command.order(); Telepathy binds to it for the turn).
func ordered(_c: Command, _holder: Unit, _rank: int, _u: Unit) -> void:
	pass


# A teammate of the holder (itself too) opens a use of a skill (v: the Volley: v.caster, v.skill, v.first), before
# it rolls: a passive may add impact to the use (v.impact: Harmony's First Chair). Only the outermost use of a unit.
func opening(_b: Battle, _holder: Unit, _rank: int, _v: Volley) -> void:
	pass


# u, a teammate of the holder (itself too), has just passed a check it rolled: a contest or save it won, an attack
# that landed (Battle.check(), roll_attack()). Harmony builds a bonus on it.
func passed(_b: Battle, _holder: Unit, _rank: int, _u: Unit) -> void:
	pass


# A moment others may react to (Battle.react()): who it happens to, who brought it about, and the cast
# under way, if any. Reactions read and change it, in order (Battle.reactors()), each at most once:
# swap the cast's target (retarget()), lock it, add Defense against a roll already made, hold a falling
# unit up, or give the holder an interrupt (Battle.grant_interrupt()).
class Reaction:
	var battle: Battle
	var trigger: StringName  # &"attacked" (a hostile skill aimed at subject, before its roll), &"hit" (it landed on subject, before damage), &"crit" (by rolled a critical hit on subject: Chaser), &"fallen" (subject reached 0 HP), &"snap" (Snapping Turtle: subject, its holder, uses an offensive skill on by)
	var subject: Unit
	var by: Unit  # who brought it about: the attacker (null: nobody, a flame)
	var cast: Cast  # the cast under way (its target is what retarget() swaps), or null
	var skill: Skill  # the passive being asked now (Battle.react() sets it before each)
	var locked := false  # its cast's target can't be swapped again (Gallantry): kept on the cast, for the moments after
	var guard := 0  # Defense its new target adds against the roll already made (Interject at rank 5+)
	var stay := false  # a falling subject holds at 0 HP until its interrupt is done (Final Act)
	var done: Array = []  # [holder, skill] that reacted, in order
	var rolled: Array = []  # [total, against] of the check the reaction just made, for the log (empty: none)

	# Makes `to` the cast's target in place of its own, unless the target is locked or it has no cast.
	func retarget(to: Unit) -> bool:
		if locked or cast == null or to == null or to == cast.target or not to.is_alive():
			return false
		cast.target = to
		return true

	# A reaction's check: holder's mod in stat + bonus (a defensive check, with the passive's tags: effects tagged
	# reaction count on it) against `against`'s (an offensive one), holder winning ties. Kept for the log.
	func contest(holder: Unit, stat: StringName, against: Unit, bonus := 0) -> bool:
		var vs := battle.check(holder, stat, against, stat, {role = &"defensive", tags = holder.skill_tags(skill), their_tags = [], bonus = bonus})
		rolled = [vs.mine.total, vs.theirs.total]
		return vs.won

	# The chance (0-1) contest() passes, without rolling: what a reaction's foils() weighs.
	func odds(holder: Unit, stat: StringName, against: Unit, bonus := 0) -> float:
		return Battle.odds(holder, stat, against, stat, {role = &"defensive", tags = holder.skill_tags(skill), their_tags = [], bonus = bonus})

	# Whether holder already reacted to this moment with some passive.
	func reacted(holder: Unit) -> bool:
		return done.any(func(d: Array): return d[0] == holder)


# The holder's passive meets a moment it may react to (Battle.react(); r.trigger says which, r.skill is
# this passive): what it does, if anything, true when it reacted. Asked only while the holder reacts()
# (not Jammed or stopped), and once per moment. A skill whose behaviour reacts carries the reaction tag.
func react(_r: Reaction, _holder: Unit, _rank: int) -> bool:
	return false
