extends Behaviour

# Observe, cast on a tile: the caster searches every tile within max(wis mod, 1) + rank of it, as if it
# had rested rank turns (+rank, capped at its wis; Battle.search()) - not just what looks suspicious:
# where to look is its to judge. Its rank is rank impact.


# How far from the tile it looks, at rank r (its rank impact): wis mod (at least 1) + r, r capped at its
# wis - what the AI aims by too (AI._search()).
static func reach(o: Unit, r: int) -> int:
	return maxi(o.mod(&"wisdom"), 1) + mini(r, roundi(o.stat(&"wisdom")))


func apply_at(c: Cast, cell: Vector2i) -> void:
	var o := c.caster
	var r := mini(c.impact_rank(), roundi(o.stat(&"wisdom")))
	var far := reach(o, c.impact_rank())
	c.battle.search(o, c.battle.map.get_used_cells().filter(func(x: Vector2i): return Command.tiles(cell, x) <= far), cell, r)


func tile_target() -> StringName:
	return &"tile"


# Its rank - turns rested, tiles looked over - is rank impact.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "observe")


func describe(rank: int) -> String:
	return _say(rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank())


func _say(ri: int) -> String:
	return "Inspects around a tile as if it had rested {t:%d turn%s}: every tile within %s (at least 1) + {r:%d} tiles of it, at +{r:%d}, -1 a tile from it" \
			% [ri, "" if ri == 1 else "s", Glossary.mod(&"wis"), ri, ri]
