extends Test

# Behaviours/summon_per_rank.gd, through Skeleton (Skills/skeleton.tres): a tile cast raises per_rank x rank
# units of its scene on the caster's side, on the free tiles nearest the tile aimed at, spent for the turn;
# they are ordinary units - tagged, killed like any other, and told as such (neutralized).

var skeleton: Skill = load("res://Skills/skeleton.tres")


func test_summon_per_rank() -> void:
	var caster := v(1)
	caster.learned.append(slot(skeleton, 2))
	roomy(caster)
	stage(lancin, {caster: Vector2i(4, 3), v(3): Vector2i(9, 3)})
	var before := b.members(lancin).size()
	ok(b.cast_at(caster, skeleton, Vector2i(6, 3)), "cast on a tile 2 away")
	var raised := b.members(lancin).filter(func(u: Unit): return &"undead" in u.tags)
	ok(raised.size() == 4 and b.members(lancin).size() == before + 4, "rank 2: 2 x 2 skeletons, on the caster's side (%d)" % raised.size())
	ok(raised.all(func(u: Unit): return Command.tiles(u.cell, Vector2i(6, 3)) <= 1 and u.ap_left() == 0.0), "each by the tile aimed at, with its turn's AP spent")
	ok(skeleton.describe(2).contains("4 Skeletons") or skeleton.describe(2).contains("{r:4} Skeletons"), "it says the count: %s" % skeleton.describe(2))
	var got := []
	b.neutralized.connect(func(u: Unit, _by: Unit, how: StringName): got.append([u, how]))
	raised[0].hp = 0
	ok(got == [[raised[0], &"killed"]], "a skeleton dies like any unit: %s" % [got])
	b.end_turn()
	b.end_turn()
	ok(raised[1].ap_left() > 0.0, "next turn it has its AP")
