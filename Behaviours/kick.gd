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


func apply(c: Cast) -> void:
	if not c.foe:
		return
	var b := c.battle
	var at: Variant = between(b, c.caster, c.target)
	var what: StringName = kind(b, at) if at != null else &"beside"
	c.bag[&"kicked"] = what
	match what:
		&"trap":
			b.spring(at, c.target)
		&"water":
			c.put(SOAKED, c.rank)
		&"loose":
			c.put(BLINDED, c.rank)
		&"hole":
			b.push(c.target, c.caster, c.impact_rank())
		&"beside":
			b.push(c.target, c.caster, 1)


# Its push into a hole is rank tiles: rank -> impact.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "push")


func describe(rank: int) -> String:
	var turns := "{t:%d turn%s}" % [rank, "" if rank == 1 else "s"]
	return "\n".join([
		"Kicks what lies at its feet, between it and the foe, at the foe:",
		"A trap: it springs on the foe",
		"Water: %s (%s) for %s" % [Glossary.term(&"soaked"), SOAKED.markup(rank), turns],
		"Leaves, sand or debris: %s (%s) for %s" % [Glossary.term(&"blinded"), BLINDED.markup(rank), turns],
		"A hole or an edge: drives it {r:%d} tile%s straight back" % [rank, "" if rank == 1 else "s"],
		"Beside it, nothing between: drives it 1 tile straight back",
	])
