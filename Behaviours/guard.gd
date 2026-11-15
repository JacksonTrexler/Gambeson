extends Behaviour

# Shields Up!, aimed at a tile: its user faces it behind its shield (Unit.guard) - damage from a source
# whose tile lies within the 90 degree cone that way is cut by the skill's effects, which it puts on
# itself - until its next turn, or until an interrupt drops its guard (Battle.interrupt()).


func apply_at(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var caster := c.caster
	var skill := c.skill
	caster.guard = true
	caster.face(cell)
	for e in skill.effects:
		var n := e.turns if e.turns else maxi(skill.lasts(c.rank, caster), 1)
		var a := caster.afflict(e, n + (1 if caster.faction == b.turn else 0), c.rank)
		a.skill = skill
		a.by = caster
		a.since = b.turns_begun


func tile_target() -> StringName:
	return &"tile"


func describe(_rank: int) -> String:
	return "Faces a tile (an unobstructed one, occupied or not), until its next turn: damage from a source whose tile lies within the 90 degree cone that way is cut"
