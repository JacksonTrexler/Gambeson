extends Behaviour

# Warcry: it picks up to rank foes it can see, the nearest first, and lays marks (Battle.Mark) on the
# first rank tiles of the line to each: the nearer half - rank / 2, rounded up - Charge! (allies who enter
# regain rank dex AP and deal +10% x rank damage until their turn ends), the farther half Routed! (foes
# who enter pay rank more movement). Each is used up by the first to enter it and fades after a few of
# its side's turns (turns + rank). A tile one line has marked, another doesn't mark again.

const CHARGE: Effect = preload("res://Effects/charge.tres")
const CHARGE_AP: Effect = preload("res://Effects/charge_ap.tres")
const CHARGE_TINT := Color(1.0, 0.45, 0.1)  # hot orange, swelling
const ROUTED_TINT := Color(0.62, 0.12, 0.5)  # dark magenta, collapsing (not the blues of water and the movement outline)


# The foes the caster can see, nearest first, up to its rank in range.
static func picks(b: Battle, caster: Unit, n: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in b.units.values():
		if o.is_alive() and not Faction.friends(o.faction, caster.faction) and b.read(caster, o).located():
			out.append(o)
	out.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, caster.cell) < Command.tiles(y.cell, caster.cell))
	return out.slice(0, n)


# The tiles it marks toward foe t: the first `n` of the line, short of the foe's own tile.
static func tiles(b: Battle, caster: Unit, t: Unit, n: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in b.line(caster.cell, t.cell, caster.luck, caster):
		if c != t.cell and c != caster.cell and b.on_map(c):
			out.append(c)
	return out.slice(0, n)


# Worth casting: a foe in sight, and none of the caster's own marks are still up.
func marks(b: Battle, u: Unit) -> bool:
	return not picks(b, u, 1).is_empty() and not b.marks.values().any(func(st: Array): return st.any(func(m: Battle.Mark): return m.by == u))


func fits(_b: Battle, caster: Unit, target: Unit) -> bool:
	return target == caster


func apply(c: Cast) -> void:
	var rank := c.impact_rank()
	var turns := c.skill.lasts(c.rank, c.caster)
	var charged := ceili(rank / 2.0)
	var taken := {}
	for t in picks(c.battle, c.caster, c.range_rank()):
		var at := tiles(c.battle, c.caster, t, rank)
		for i in at.size():
			if at[i] in taken:
				continue
			taken[at[i]] = true
			c.battle.lay_mark(at[i], routed(c, turns, rank) if i >= charged else charge(c, turns, rank))


func charge(c: Cast, turns: int, rank: int) -> Battle.Mark:
	var m := Battle.Mark.new(&"charge", c.caster)
	m.name = "Charge!"
	m.effects.assign([CHARGE_AP, CHARGE])
	m.who = &"allies"
	m.rank = rank
	m.turns = turns
	m.tint = CHARGE_TINT
	m.swell = 1
	return m


func routed(c: Cast, turns: int, rank: int) -> Battle.Mark:
	var m := Battle.Mark.new(&"routed", c.caster)
	m.name = "Routed!"
	m.who = &"foes"
	m.rank = rank
	m.cost = float(rank)
	m.turns = turns
	m.tint = ROUTED_TINT
	m.swell = -1
	return m


# Its terms: tiles laid, effects and cost grow with rank (impact), and so does how many foes it picks (range).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "tiles marked, Charge! and Routed!")
	t.add(&"rank_range", "foes picked")


func describe(rank: int) -> String:
	return _say(rank, rank, rank, 2 + rank)


# As its holder has it: its modifiers on how many foes and tiles, and the skill's turns.
func describe_as(c: Cast) -> String:
	return _say(c.rank, c.range_rank(), c.impact_rank(), c.skill.lasts(c.rank, c.caster))


func _say(_rank: int, foes: int, tiles: int, turns: int) -> String:
	return "Picks up to {r:%d} foe%s it can see, the nearest first, and marks the first {r:%d} tile%s of the line to each: the nearer half %s, the farther half %s. Each is used up by the first to enter it and lasts {t:%d turn%s}.\n%s: allies who enter regain {r:%d} dex AP and deal +{r:%d%%} damage until their turn ends.\n%s: foes who enter pay {r:%d} more movement" % [
			foes, "" if foes == 1 else "s", tiles, "" if tiles == 1 else "s", "Charge!", "Routed!", turns, "" if turns == 1 else "s", "Charge!", tiles, tiles * 10, "Routed!", tiles]
