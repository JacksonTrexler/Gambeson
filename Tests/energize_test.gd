extends Test

# Energize (Skills/energize.tres, Behaviours/energize.gd): tier 4 General, 0 Energy, 2 AP. It spends AP in
# pairs, up to rank pairs and the room it has, 1 Energy a pair; past a full bar, Overcharge up to rank x
# 20% of its total resource. One recovery for Burnout: 1 RE.

var energize: Skill = load("res://Skills/energize.tres")


func ready(u: Unit, ap: float) -> void:
	u.refresh()
	var pools: Array[AP] = [AP.new(ap)]
	u.ap = pools
	u.constitution = 40  # passes its Burnout checks
	u.endurance = 10


func test_energize() -> void:
	v(1).learned.append(slot(energize, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var u := v(1)
	ok(energize.cost == 0 and energize.ap == 2.0 and (load("res://Trees/general.tres") as SkillTab).roots[0].branch(energize).tier == 4, "0 Energy, 2 AP, tier 4 of General")
	u.max_energy = 10
	u.energy = 0
	ready(u, 10.0)
	ok(b.cast(u, energize, u) and u.energy == 3 and is_equal_approx(u.ap_left(), 4.0), "rank 3, 10 AP: 3 pairs, 3 Energy, 4 AP left")
	ok(u.endurance == 9, "one recovery: 1 RE")
	u.energy = 0
	ready(u, 3.0)
	ok(b.cast(u, energize, u) and u.energy == 1 and is_equal_approx(u.ap_left(), 1.0), "3 AP: one pair only")
	u.energy = 9
	ready(u, 10.0)
	b.cast(u, energize, u)
	ok(u.energy == 10 and u.overcharge == 2, "1 to fill the bar, the other 2 as Overcharge")
	ok(Behaviours_cap(u) == 6, "Overcharge cap: 20% x 3 x 10 total resource = 6")
	u.overcharge = 5
	ready(u, 10.0)
	b.cast(u, energize, u)
	ok(u.overcharge == 6 and is_equal_approx(u.ap_left(), 8.0), "only the room left: 1 point, its own pair")
	ok(energize.describe(3).contains("Overcharge"), "it says what it does: %s" % energize.describe(3))


func Behaviours_cap(u: Unit) -> int:
	return load("res://Behaviours/energize.gd").over_cap(u, 3)
