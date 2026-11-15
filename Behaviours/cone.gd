extends Behaviour

# A cone from the caster toward the tile it's cast on, `degrees` wide, hitting the units in it; every tile
# in it is exposed to its tags (Battle.expose()).
# Solar (plain): + 15 degrees a rank past I (rank range), its range long; everyone in it, the caster too,
# takes d20 + the caster's wis score in fire.
# Wildfire (evadable): `reach_scale` of its rank long, landing on every unit in it but the caster. Each
# tries to dodge (Battle.evade(): the skill's difficulty at its rank impact); what lands is its tier's
# dice x `dice_scale` of its rank + its stat's mod. A unit of its bane (earth) dodges at impossible and,
# hit, is hit as a crit.

@export var degrees := 0.0  # its width at rank I
@export var evadable := false  # whoever it lands on makes a dex check against its difficulty to dodge it: passing, none of it; failing by a quarter of the DC or less, half (Battle.evade())


# Its width in degrees at a rank, through its caster's modifiers m: an evadable cone's is fixed, a plain
# one's grows 15 a rank past I (rank range).
func width(rank: int, m: Modifiers = Modifiers.NONE) -> float:
	return degrees if evadable else degrees + 15.0 * (m.rank(rank, &"rank_range") - 1.0)


func apply_at(c: Cast, cell: Vector2i) -> void:
	if evadable:
		_evadable(c, cell)
	else:
		_plain(c, cell)


func _evadable(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var caster := c.caster
	var skill := c.skill
	var half := deg_to_rad(width(c.rank, c.mods)) / 2.0
	var long := b.area_reach(caster, skill)
	var aim := Vector2(cell - caster.cell).angle()
	var ri := c.impact_rank()
	var t := skill.tier(ri)
	var tags := c.tags
	var hit := {}
	for u: Unit in b.units.values():
		if u == caster or not u.is_alive() or not b.in_cone(caster.cell, u.cell, aim, half, long):
			continue
		var bane := skill.bane != &"" and u.has_tag(skill.bane)
		var share := b.evade(u, Difficulty.dc(&"impossible" if bane else skill.difficulty, ri))  # the check it imposes: at its rank impact
		if share <= 0.0 or not t:
			hit[u] = 0
			continue
		var dice := Vector2i(t.dice.x * (Difficulty.scaled(skill.dice_scale, ri) if skill.dice_scale else 1), t.dice.y)
		var power := (t.power + b.roll(dice) + (c.stat_mod(caster.mod(t.stat, tags)) if t.stat else 0) + int(b.requirement(caster, skill, u, c.rank)[1])) * (2 if bane else 1)
		hit[u] = u.hit(power * share * (1.0 + caster.stat(&"damage", tags)), tags, caster)
		b._expose(u)
	b._expose(caster)
	for at in b.map.get_used_cells():
		if at != caster.cell and b.in_cone(caster.cell, at, aim, half, long):
			b.expose(at, tags, caster)
	b.exploded.emit(caster, skill, cell, hit)


func _plain(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var caster := c.caster
	var half := deg_to_rad(width(c.rank, c.mods)) / 2.0
	var aim := Vector2(cell - caster.cell).angle()
	var long := b.area_reach(caster, c.skill)
	var hit := {}
	for u: Unit in b.units.values():
		if u == caster or (u.is_alive() and b.in_cone(caster.cell, u.cell, aim, half, long)):
			hit[u] = u.hit(b.roll(Vector2i(1, 20)) + roundi(caster.stat(&"wisdom")), [&"fire"] as Array[StringName], caster)
	for at in b.map.get_used_cells():
		if at != caster.cell and b.in_cone(caster.cell, at, aim, half, long):
			b.expose(at, [&"fire"] as Array[StringName], caster)
	b.exploded.emit(caster, c.skill, cell, hit)


func tile_target() -> StringName:
	return &"area"


# A plain cone's width is rank range. An evadable one is a check (its dodge) whose DC is rank impact.
func terms(t: SkillTerms) -> void:
	if not evadable:
		t.add(&"rank_range", "cone")
	elif t.skill.difficulty:
		t.add(&"rank_impact", "difficulty")
	if evadable:
		t.check = true


func describe(rank: int) -> String:
	var c := Cast.new()
	c.rank = rank
	return describe_as(c)


func describe_as(c: Cast) -> String:
	var m: Modifiers = c.mods if c.mods else Modifiers.NONE
	if not evadable:
		return "A {r:%d} degree cone, its range long: 1d20 + {o:wis score} {x:fire} to everyone in it, the caster too" % roundi(width(c.rank, m))
	var s := c.skill
	var long := maxi(ceili(m.rank(c.rank, &"rank_range") * Difficulty.MAGNITUDE[s.reach_scale]), 1) if s and s.reach_scale else 0
	var lines := ["A {r:%d} degree cone, {r:%d} tiles long: it lands on every unit in it but the caster" % [roundi(degrees), long]]
	if s and s.difficulty:
		lines.append("%s: a %s %s (%s, DC {r:%d}) - passing, none of it lands; failing by a quarter of the DC or less, half"
				% [Glossary.term(&"evadable"), Glossary.term(s.difficulty), Glossary.term(&"check", "check"), Glossary.mod(&"dex", true), Difficulty.dc(s.difficulty, m.irank(c.rank, &"rank_impact"))])
	return "\n".join(lines)
