extends Behaviour

# Kick: what lies on the tile between the kicker and its foe - the one at the kicker's feet, first on
# the line between them (Battle.line()) - goes at the foe. The first that fits: a trap springs on the
# foe; water soaks it; loose ground (leaves, sand, debris) blinds it; a hole or an edge leaves it no
# footing, driven back rank tiles. Bare ground: just the blow. Beside it, nothing between: a 1-tile push.

const BLINDED: Effect = preload("res://Effects/blinded.tres")
const SOAKED: Effect = preload("res://Effects/soaked.tres")
const LOOSE: Array[StringName] = [&"leaves", &"sand", &"loose"]
const HOLES: Array[StringName] = [&"hole", &"edge", &"pit"]


# The tile kicked at the foe, or null with nothing between them.
static func between(b: Battle, from: Unit, to: Unit) -> Variant:
	var path := b.line(from.cell, to.cell, from.luck - to.luck, from)
	return path[0] if path.size() > 1 else null


# What a tile gives a kick: &"trap", &"water", &"loose", &"hole", or &"" (bare ground).
static func kind(b: Battle, c: Vector2i) -> StringName:
	if not b.on_map(c):
		return &"hole"
	var t := b.terrain(c)
	if t.is_trap():
		return &"trap"
	if &"water" in t.tags:
		return &"water"
	if t.tags.any(func(x: StringName): return x in LOOSE) or c in b.debris:
		return &"loose"
	if t.tags.any(func(x: StringName): return x in HOLES):
		return &"hole"
	return &""


# What this kick would kick, from what lies between now: {what: &"trap" .. &"beside", at: its tile or null}.
# apply() acts on it, foresee() reports it - the one reading of the ground.
static func outcome(b: Battle, from: Unit, to: Unit) -> Dictionary:
	var at: Variant = between(b, from, to)
	return {what = kind(b, at) if at != null else &"beside", at = at}


const PUSH := Battle.PUSH  # riders a tile it drives its foe is worth


# For the forecast and the AI (Battle.foresee()): the tile's rider, as a hit would give it. A trap's
# damage is its dice, before the target's mitigation; the note names the rest. Beyond the target: a trap's
# blast takes its dice off each other unit within it (foes' count for the kicker, its own side's, itself
# among them, against: `spill`), and a drive is read to where it really stops (driven()): its tiles are
# riders at PUSH each, stopped short it slams (`lo`, `hi`, `spill` for the unit it struck).
func foresee(c: Cast) -> Dictionary:
	if not c.foe:
		return {}
	var o := outcome(c.battle, c.caster, c.target)
	var turns := "%d turn%s" % [c.rank, "" if c.rank == 1 else "s"]
	var out := {lo = 0, hi = 0, notes = [] as Array[String]}
	match o.what:
		&"trap":
			var t := c.battle.terrain(o.at)
			out.lo = t.dice.x * t.times + t.bonus
			out.hi = t.dice.x * t.dice.y * t.times + t.bonus
			out.notes.append("Kicks the trap onto it: it springs")
			var mean: float = (out.lo + out.hi) / 2.0
			var foes := 0
			var own := 0
			for x: Unit in c.battle.units.values():
				if x != c.target and x.is_alive() and Vector2(x.cell).distance_to(Vector2(o.at)) <= t.blast + 0.0001:
					if Faction.friends(x.faction, c.caster.faction):
						own += 1
					else:
						foes += 1
					out.spill = out.get("spill", 0.0) + (-mean if Faction.friends(x.faction, c.caster.faction) else mean)
			if foes + own > 0:
				out.notes.append("Its blast catches %d foe%s and %d of its own" % [foes, "" if foes == 1 else "s", own])
			out.riders = 1.0
		&"water":
			out.notes.append("Soaks it (%s)" % turns)
		&"loose":
			out.notes.append("Blinds it (%s)" % turns)
		&"hole", &"beside":
			return c.battle.foresee_drive(c.caster, c.target, c.caster.cell, 1, c.impact_rank() if o.what == &"hole" else 1)
	return out


func apply(c: Cast) -> void:
	if not c.foe:
		return
	var b := c.battle
	var o := outcome(b, c.caster, c.target)
	var at: Variant = o.at
	var what: StringName = o.what
	c.bag[&"kicked"] = what
	match what:
		&"trap":
			b.spring(at, c.target)
		&"water":
			c.put(SOAKED, c.impact_rank())
		&"loose":
			c.put(BLINDED, c.impact_rank())
		&"hole":
			b.push(c.target, c.caster, c.impact_rank(), [&"shove"] as Array[StringName], c.caster)
		&"beside":
			b.push(c.target, c.caster, 1, [&"shove"] as Array[StringName], c.caster)


# Its push into a hole is rank tiles, and the Soaked and Blinded it leaves their rank and turns: all rank impact.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "push, soaked, blinded")


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	var turns := "{t:%d turn%s}" % [rank, "" if rank == 1 else "s"]
	return "\n".join([
		"Kicks what lies at its feet, between it and the foe, at the foe:",
		"A trap: it springs on the foe",
		"Water: %s (%s) for %s" % [Glossary.term(&"soaked"), SOAKED.markup(rank), turns],
		"Leaves, sand or debris: %s (%s) for %s" % [Glossary.term(&"blinded"), BLINDED.markup(rank), turns],
		"A hole or an edge: drives it {r:%d} tile%s straight back" % [c.impact_rank(), "" if c.impact_rank() == 1 else "s"],
		"Beside it, nothing between: drives it 1 tile straight back",
	])
