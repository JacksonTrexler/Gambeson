extends Behaviour

# Ambush, cast on a tile: the caster lies in wait over up to rank (impact) empty tiles its weapon - its first
# hostile active not aimed at a tile - reaches, the nearest the tile it aimed at. Each is a hidden mark
# (Battle.Mark: concealment rank, seen through as a trap is: inspect()) that a foe walking onto stops on
# (Mark.halts), and is struck there by that weapon, out of turn (Battle.grant_interrupt()'s aim, as
# Opportunist) - unless the caster takes it for a friend (a lie, a persona: it holds its blow). Each
# tile is used up by the first it fires on; the rest last until its side's next turn ends (TURNS).

const TURNS := 2  # of its side's turn ends (Battle.Mark.turns): the one it's laid in, and the next


# The skill it strikes with: u's first hostile active that isn't aimed at a tile, or null.
static func weapon(u: Unit) -> Skill:
	for s in u.actives:
		if s.hostile and not s.on_tile():
			return s
	return null


func apply_at(c: Cast, cell: Vector2i) -> void:
	var w := weapon(c.caster)
	if w == null:
		return
	for at in footprint(c, cell):
		var m := Battle.Mark.new(&"ambush", c.caster)
		m.name = "Ambush"
		m.skill = c.skill
		m.rank = c.impact_rank()
		m.who = &"foes"
		m.halts = true
		m.concealment = c.impact_rank()
		m.turns = TURNS
		m.tint = Color(0.75, 0.2, 0.2)
		c.battle.lay_mark(at, m)


# The empty tiles within its weapon's reach (a Medium foe's) nearest `cell`, up to its rank impact.
func footprint(c: Cast, cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var w := weapon(c.caster)
	if w == null:
		return out
	var b := c.battle
	var reach := b.skill_range(c.caster, w)
	for x in b.cells_near(c.caster.cell, reach):
		if x != c.caster.cell and b.on_map(x) and b.unit_at(x) == null and Vector2(x).distance_to(Vector2(c.caster.cell)) <= reach + 0.0001:
			out.append(x)
	out.sort_custom(func(p: Vector2i, q: Vector2i):
		var dp := Vector2(p).distance_squared_to(Vector2(cell))
		var dq := Vector2(q).distance_squared_to(Vector2(cell))
		return dp < dq or (dp == dq and (p.x < q.x or (p.x == q.x and p.y < q.y))))
	return out.slice(0, c.impact_rank())


func tile_target() -> StringName:
	return &"tile"


# A foe walked into one of its marks: the layer strikes it with its weapon, free, unless it reads the
# walker as a friend (or as nothing it would hit).
func tripped(b: Battle, m: Battle.Mark, u: Unit) -> void:
	var by := m.by
	if not is_instance_valid(by) or not by.is_alive() or not u.is_alive():
		return
	var w := weapon(by)
	if w == null or b.read(by, u).attitude(by) in [&"ally", &"ignore", &""]:
		return
	b.grant_interrupt(by, 1, {w: by.rank(w)}, {}, u)


# Tiles watched grow with rank (impact).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "tiles watched")


func describe(rank: int) -> String:
	return _say(rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank())


func _say(n: int) -> String:
	return "Lies in wait over up to {r:%d} empty tile%s its first attack reaches, nearest the one aimed at: hidden ({r:%d} concealment), until its side's next turn ends. A foe that walks onto one stops there and is struck by that attack, out of turn - unless the caster takes it for a friend. Each tile fires once." \
			% [n, "" if n == 1 else "s", n]
