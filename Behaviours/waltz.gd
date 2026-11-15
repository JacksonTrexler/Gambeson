extends Behaviour

# Waltz of Vapors: fog around its caster, radius rank + the better of its dex and cha mods, concealing at
# its rank; it lasts through its next turn, so it's kept up by using it again as each turn opens (the AI's
# Undine does: AI._undine()). Its radius is rank range (and stat range), its concealment rank impact.


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	var b := c.battle
	var u := c.caster
	var tags := u.skill_tags(c.skill)
	var r := c.impact_rank()
	var reach := c.range_rank() + c.stat_mod(maxi(u.mod(&"dexterity", tags), u.mod(&"charisma", tags)), &"stat_range")
	var levels: Dictionary[Vector2i, int] = {}
	for x in range(u.cell.x - reach, u.cell.x + reach + 1):
		for y in range(u.cell.y - reach, u.cell.y + reach + 1):
			var at := Vector2i(x, y)
			if b.on_map(at) and Vector2(at).distance_to(Vector2(u.cell)) <= reach + 0.0001:
				levels[at] = r
	b.zones = b.zones.filter(func(z: Battle.Zone): return not (z.kind == &"fog" and z.faction == u.faction and z.levels.has(u.cell)))  # the last waltz lifts
	b.zones.append(Battle.Zone.new(&"fog", levels, 2, u.faction))


# Only carries out its numbers: no unique effect.
func impact() -> StringName:
	return &""


func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "fog")
	t.add(&"rank_impact", "fog")
	t.add(&"stat_range", "fog")


func describe(rank: int) -> String:
	var c := Cast.new()
	c.rank = rank
	return describe_as(c)


func describe_as(c: Cast) -> String:
	var k: float = c.mods.k[&"stat_range"] if c.mods else 1.0
	return "Fog around the caster, radius {r:%d} + the better of its dex and cha mods%s, concealing at {r:%d}. Kept up only by using it again as each of its turns opens" % [
			c.range_rank(), "" if k == 1.0 else " x %s" % Skill.num(snappedf(k, 0.01)), c.impact_rank()]
