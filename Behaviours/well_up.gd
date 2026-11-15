extends Behaviour

# Well Up, aimed at a tile: floods it rank deep and the tiles beside it a rank less, for rank of its
# side's turns (Battle.flood()). Its rank is rank impact.


func apply_at(c: Cast, cell: Vector2i) -> void:
	var r := c.impact_rank()  # its depth and turns
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var at: Vector2i = cell + Vector2i(dx, dy)
			c.battle.flood(at, r if at == cell else r - 1, r, c.caster)


func tile_target() -> StringName:
	return &"tile"


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "wells")


func describe(rank: int) -> String:
	return _say(rank)


func describe_as(c: Cast) -> String:
	return _say(c.impact_rank())


func _say(ri: int) -> String:
	return "Floods the tile {r:%d} deep and the tiles beside it {r:%d}, for {t:%d turns}" % [ri, maxi(ri - 1, 0), ri]
