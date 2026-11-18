extends Test

# Forced movement as one behaviour (Behaviours/displace.gd) over one primitive (Battle.displace()): any
# skill that carries a Displace knocks back, draws in or teleports what it lands on - not Sing's or Send
# Off's alone - and whoever it moves faces along it (docs/plans/w2-facing.md).


# Hex with no roll (it always lands), carrying d.
func bolt(d: Displace) -> Skill:
	var s: Skill = hex.duplicate()
	s.rolls = false
	s.behaviours = [d] as Array[Behaviour]
	return s


func caster_with(s: Skill, r := 1) -> Unit:
	v(1).learned.append(slot(s, r))
	v(1).refresh()
	return v(1)


func test_any_skill_knocks_back() -> void:
	var d := Displace.new()
	d.tiles = 2
	var s := bolt(d)
	var u := caster_with(s)
	stage(lancin, {u: Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).facing = Vector2(-1, 0)
	ok(b.cast(u, s, v(3)) and v(3).hp < 300, "a plain damage skill lands (took %d)" % (300 - v(3).hp))
	ok(v(3).cell == Vector2i(6, 3), "and its Displace drives the foe 2 tiles straight back (%s)" % v(3).cell)
	ok(v(3).facing == Vector2(1, 0), "the foe faces along the push (%s)" % v(3).facing)
	ok("Drives it up to 2 tiles straight away from the caster" in s.describe(1), s.describe(1))
	ok(&"push" in SkillTerms.of(s).channels[&"rank_impact"], "its push is rank impact: modifiers see it")


func test_draw_in() -> void:
	var d := Displace.new()
	d.toward = true
	d.tiles = 3
	var s := bolt(d)
	var u := caster_with(s)
	stage(lancin, {u: Vector2i(2, 3), v(3): Vector2i(7, 3)})
	v(3).max_hp = 300
	v(3).hp = 300
	ok(b.cast(u, s, v(3)) and v(3).cell == Vector2i(4, 3), "drawn 3 tiles toward the caster (%s)" % v(3).cell)
	v(1).refresh()
	ok(b.cast(u, s, v(3)) and v(3).cell == Vector2i(3, 3), "stopping beside it (%s)" % v(3).cell)
	ok(Displace.draws(s) == d and not Displace.draws(hex), "the AI sees a skill that draws (Displace.draws())")


func test_allies_only_when_asked() -> void:
	var d := Displace.new()
	var s := bolt(d)
	s.hostile = false
	s.tiers = [] as Array[Tier]
	var u := caster_with(s)
	stage(lancin, {u: Vector2i(2, 3), v(2): Vector2i(3, 3)})
	ok(b.cast(u, s, v(2)) and v(2).cell == Vector2i(3, 3), "a push moves only a foe")
	d.foes_only = false
	v(1).refresh()
	ok(b.cast(u, s, v(2)) and v(2).cell == Vector2i(4, 3), "unless it says allies too (%s)" % v(2).cell)


func test_teleport_toward() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 3), v(4): Vector2i(4, 3)})
	ok(b.displace(v(3), v(1).cell, -1, 4, true) == 3 and v(3).cell == Vector2i(5, 3),
			"teleported toward: the furthest free tile on the line within reach, never onto a unit (%s)" % v(3).cell)
	ok(b.displace(v(3), v(1).cell, -1, 9, true) == 2 and v(3).cell == Vector2i(3, 3), "over one in the way, but never onto or past the one it's drawn to (%s)" % v(3).cell)
	ok(b.displace(v(3), v(1).cell, -1, 9, true) == 0 and v(3).cell == Vector2i(3, 3), "already beside it: nowhere nearer")
