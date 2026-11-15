extends Behaviour

# An aura (Flamecharm, Flamedance): used on itself, its skill's effects go on every ally within rank
# tiles - itself too - and that is the whole of it. Splitting (Flamecharm), from rank V only the nearest
# rank of them, its strength shared out (Applied.scale). Its reach and how many it splits among are rank
# range; its effects' rank, rank impact; the split starts at rank V as its holder has it.

@export var splits := false


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	var b := c.battle
	var caster := c.caster
	var r := c.rank
	var rr := c.range_rank()
	var near: Array = b.units.values().filter(func(o: Unit): return o.is_alive() and Faction.friends(o.faction, caster.faction) and Command.tiles(o.cell, caster.cell) <= rr)
	near.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, caster.cell) < Command.tiles(y.cell, caster.cell))
	var share := 1.0
	if splits and r >= 5:
		near = near.slice(0, rr)
		share = 1.0 / maxi(near.size(), 1)
	for o: Unit in near:
		for e in c.skill.effects:
			var n := c.skill.lasts(r, caster)
			var a := o.afflict(e, n + (1 if o.faction == b.turn else 0), c.impact_rank() if e.per_rank else r)
			a.total = n
			a.scale = share
			a.skill = c.skill
			a.by = caster
			a.since = b.turns_begun


# Its effects are what it does: no unique effect of its own.
func impact() -> StringName:
	return &""


func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "aura")


func describe(rank: int) -> String:
	return _say(rank)


func describe_as(c: Cast) -> String:
	return _say(c.range_rank())


func _say(rr: int) -> String:
	return "%s: also on every ally within {r:%d} tile%s%s" % [Glossary.term(&"aura"), rr, "" if rr == 1 else "s", " - from rank V only the nearest {r:%d}, its strength split among them" % rr if splits else ""]
