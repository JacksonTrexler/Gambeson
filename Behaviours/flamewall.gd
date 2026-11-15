extends Behaviour

# Flamewall, cast on a tile: it and rank tiles to either side of it, across the caster's line to it,
# catch fire for rank of the caster's side's turns. A unit standing on one makes a dex check against the
# caster's wis (Battle.check(): the wall wins ties) to get clear; failing, it burns at once.
# Its width is rank range, its turns rank impact (its caster's modifiers).


func apply_at(c: Cast, cell: Vector2i) -> void:
	var b := c.battle
	var caster := c.caster
	var d := Vector2i(signi(cell.x - caster.cell.x), signi(cell.y - caster.cell.y))
	var across := Vector2i(-d.y, d.x) if d != Vector2i.ZERO else Vector2i(1, 0)
	var tiles: Array[Vector2i] = [cell]
	for i in range(1, c.range_rank() + 1):
		tiles.append(cell + across * i)
		tiles.append(cell - across * i)
	for t in tiles:
		if not b.on_map(t) or b.terrain(t).douses:  # no fire on water
			continue
		b.flames[t] = Battle.Flame.new(caster, c.impact_rank())
		var u := b.unit_at(t)
		if u and u.is_alive():
			var vs := b.check(u, &"dexterity", caster, &"wisdom", {role = &"defensive", their_tags = caster.skill_tags(c.skill), ties = false})  # the wall wins ties
			b.contested.emit(u, caster, vs.mine.total, vs.theirs.total)
			if not vs.won:
				b.flame(u, b.flames[t], "is caught in the wall")


func tile_target() -> StringName:
	return &"tile"


# Its width is rank range, its turns rank impact; setting fire is a rider (tame).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "flamewall")
	t.add(&"rank_impact", "flamewall")
	if t.impact == &"":
		t.impact = &"tame"


func describe(rank: int) -> String:
	return _say(rank, rank)


func describe_as(c: Cast) -> String:
	return _say(c.range_rank(), c.impact_rank())


func _say(wide: int, turns: int) -> String:
	return "Sets the tile and {r:%d} to either side of it, across the caster's line, %s for {t:%d turns}: 1d8 + %s {x:fire} to whoever enters or ends a turn there. One standing there makes a %s (%s) to get clear" \
			% [wide, Glossary.term(&"burning", "burning"), turns, Glossary.mod(&"wis"), Glossary.term(&"check", "check"), Glossary.mod(&"dex", true)]
