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
	var siphoned := 0  # what its siphon damage took off the target's resources (Unit.siphon()), by the time dealt() runs
	var mods: Modifiers  # its caster's modifiers on it (Unit.mods()): read scaled values through them
	var tags: Array[StringName] = []  # its hit's tags (Battle.hit_tags()): modifier tags among them (Unit.skill_tags()), ambush when it ambushes (Battle.ambushes())

	# Its rank for what rank adds to what it does (rank_impact) or to its reach (rank_range), through
	# its caster's modifiers: a whole number, at least 1 (Kick's push).
	func impact_rank() -> int:
		return mods.irank(rank, &"rank_impact") if mods else rank

	func range_rank() -> int:
		return mods.irank(rank, &"rank_range") if mods else rank

	# A stat mod m its caster adds to what it does (stat_impact) or to its reach (stat_range), through
	# its modifiers.
	func stat_mod(m: int, channel := &"stat_impact") -> int:
		return mods.stat(m, channel) if mods else m
	var hit := false  # it landed: past its attack roll, if it makes one

	# Puts e on the target for its turns (+ 1 on its side's turn, which doesn't count), marked as this
	# cast's, as a skill's own effects are.
	func put(e: Effect, turns: int) -> Unit.Applied:
		var a := target.afflict(e, turns + (1 if target.faction == battle.turn else 0), rank)
		a.total = turns
		a.skill = skill
		a.by = caster
		a.since = battle.turns_begun
		return a


func apply(_c: Cast) -> void:
	pass


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


# The share of its AP price the cast saves, expected, given p the chance it lands: what the AI weighs.
func refunds(c: Cast, p: float) -> float:
	var r := rebate(c)
	return r.x + r.y * p


# Defense the cast costs its own caster, through its next turn (Sutemi's Off Balance: a point a tile
# lunged) - what the AI prices against the blow. Pure.
func unguarded(_c: Cast) -> int:
	return 0


# What a hit would do beyond its damage, foreseen as the cast is planned and as Battle.foresee() reads it
# for the HUD's forecast and the AI: {lo, hi: more HP it takes off the target, notes: Array[String]: one
# line for each rider it puts on it}. Pure (no rolls spent). Empty: nothing more.
func foresee(_c: Cast) -> Dictionary:
	return {}


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


# What apply() does at this rank, in Glossary markup: one or more lines of the skill's description.
func describe(_rank: int) -> String:
	return ""


# The same as its holder has it (Skill.markup() given a unit): c has the caster (or null), the skill, its
# rank and the caster's modifiers (c.mods) - no battle, no target. A behaviour that reads its numbers
# through c.impact_rank() / range_rank() / stat_mod() overrides this to say them the same way, so a
# modifier shows wherever it acts; by default, describe() at the rank.
func describe_as(c: Cast) -> String:
	return describe(c.rank)



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


# A moment others may react to (Battle.react()): who it happens to, who brought it about, and the cast
# under way, if any. Reactions read and change it, in order (Battle.reactors()), each at most once:
# swap the cast's target (retarget()), lock it, add Defense against a roll already made, hold a falling
# unit up, or give the holder an interrupt (Battle.grant_interrupt()).
class Reaction:
	var battle: Battle
	var trigger: StringName  # &"attacked" (a hostile skill aimed at subject, before its roll), &"hit" (it landed on subject, before damage), &"fallen" (subject reached 0 HP), &"snap" (Snapping Turtle: subject, its holder, uses an offensive skill on by)
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

	# A reaction's check: holder's mod in stat (a defensive check, with the passive's tags: effects tagged
	# reaction count on it) against `against`'s (an offensive one), holder winning ties. Kept for the log.
	func contest(holder: Unit, stat: StringName, against: Unit) -> bool:
		var vs := battle.check(holder, stat, against, stat, {role = &"defensive", tags = holder.skill_tags(skill), their_tags = []})
		rolled = [vs.mine.total, vs.theirs.total]
		return vs.won

	# Whether holder already reacted to this moment with some passive.
	func reacted(holder: Unit) -> bool:
		return done.any(func(d: Array): return d[0] == holder)


# The holder's passive meets a moment it may react to (Battle.react(); r.trigger says which, r.skill is
# this passive): what it does, if anything, true when it reacted. Asked only while the holder reacts()
# (not Jammed or stopped), and once per moment. A skill whose behaviour reacts carries the reaction tag.
func react(_r: Reaction, _holder: Unit, _rank: int) -> bool:
	return false
