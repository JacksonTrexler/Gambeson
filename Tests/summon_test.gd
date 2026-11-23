extends Test

# Behaviours/summon_per_rank.gd, through Skeleton (Skills/skeleton.tres): a tile cast raises per_rank x rank
# units of its scene on the caster's side, on the free tiles nearest the tile aimed at, spent for the turn;
# they are ordinary units - tagged, killed like any other, and told as such (neutralized).

var skeleton: Skill = load("res://Skills/skeleton.tres")


func test_summon_per_rank() -> void:
	var caster := v(1)
	caster.learned.append(slot(skeleton, 2)); caster.sync_bar()
	roomy(caster)
	stage(lancin, {caster: Vector2i(4, 3), v(3): Vector2i(9, 3)})
	var before := b.members(lancin).size()
	ok(b.cast_at(caster, skeleton, Vector2i(6, 3)), "cast on a tile 2 away")
	var raised := b.members(lancin).filter(func(u: Unit): return &"undead" in u.tags)
	ok(raised.size() == 4 and b.members(lancin).size() == before + 4, "rank 2: 2 x 2 skeletons, on the caster's side (%d)" % raised.size())
	# the AP rule: they keep rank + cast mod (+ Wake and Rake's rank, by the summon tag), the rest spent
	var keep: int = 2 + caster.mod(&"intelligence", caster.skill_tags(skeleton))
	ok(raised.all(func(u: Unit): return &"summon" in u.tags and Command.tiles(u.cell, Vector2i(6, 3)) <= 1 and is_equal_approx(u.ap_left(), minf(keep, u._ap_start.reduce(func(a, x): return a + x, 0.0)))), "each by the tile aimed at, keeping rank + mod AP (%d), the rest spent" % keep)
	ok(raised[0].ap_left() > 0.0 or keep <= 0, "it keeps some")
	ok(skeleton.describe(2).contains("4 Skeletons") or skeleton.describe(2).contains("{r:4} Skeletons"), "it says the count: %s" % skeleton.describe(2))
	var got := []
	b.neutralized.connect(func(u: Unit, _by: Unit, how: StringName): got.append([u, how]))
	raised[0].hp = 0
	ok(got == [[raised[0], &"killed"]], "a skeleton dies like any unit: %s" % [got])
	var wake: Skill = load("res://Skills/wake_and_rake.tres")
	caster.learned.append(slot(wake, 3)); caster.sync_bar()
	ok(wake.describe(3).contains("3"), "Wake and Rake says its rank: %s" % wake.describe(3))
	caster.ap[0].amount = 99.0
	ok(b.cast_at(caster, skeleton, Vector2i(6, 4)), "a second cast, with Wake and Rake III")
	var more := b.members(lancin).filter(func(u: Unit): return &"undead" in u.tags and u not in raised)
	ok(more.size() == 4 and more.all(func(u: Unit): return is_equal_approx(u.ap_left(), minf(keep + 3, u._ap_start.reduce(func(a, x): return a + x, 0.0)))), "Wake and Rake adds its rank (3) to what they keep")
	ok(more.all(func(u: Unit): return u.ap_left() > raised[1].ap_left()), "more than the first batch kept")
	b.end_turn()
	b.end_turn()
	ok(raised[1].ap_left() > 0.0, "next turn it has its AP")


# The AI raises a host (AI._summon(), priced by Behaviour.bodies()): with a foe in sight and room under its soft cap,
# near itself toward the foe; not with no foe in sight, nor with its hand full.
func test_ai_raises_host() -> void:
	var caster := v(1)
	caster.learned.append(slot(skeleton, 1)); caster.sync_bar()
	roomy(caster)
	caster.intelligence = 14  # soft cap 1 + 2: room for a cast's two
	caster.ap[0].amount = 99.0
	stage(lancin, {caster: Vector2i(4, 3), v(3): Vector2i(30, 3)})
	var log: Array[String] = []
	ok(not AI._summon(b, caster, AI._reads(b, caster), log), "no foe within sight: no host")
	b.move(v(3), Vector2i(10, 3))
	var before := b.members(lancin).size()
	var reads := AI._reads(b, caster)
	ok(AI._summon(b, caster, reads, log), "a foe 6 tiles off: it raises one (%s)" % [log])
	var raised := b.members(lancin).filter(func(u: Unit): return &"undead" in u.tags)
	ok(raised.size() == 2 and b.members(lancin).size() == before + 2, "rank I: two bodies")
	ok(raised.all(func(u: Unit): return Command.tiles(u.cell, Vector2i(10, 3)) < Command.tiles(caster.cell, Vector2i(10, 3))), "on tiles toward the foe")
	var cap: int = skeleton.behaviours[0].cap(b.cast_of(caster, skeleton, null, 1, true))
	while raised.size() < cap:  # its own in hand up to the soft cap (rank + int mod)
		var more := b.summon(load("res://Scenes/skeleton.tscn"), lancin, Vector2i(5, 5))
		more.raised_by = caster
		raised.append(more)
	caster.ap[0].amount = 99.0
	ok(not AI._summon(b, caster, reads, log), "its hand full (the soft cap, %d): no more" % cap)
