extends Test

# Heal and Megaheal (Skills/heal.tres, Skills/megaheal.tres; Behaviours/heal.gd): Eros, tier 8. An ally
# gets back d8s by magnitude of rank (Heal moderate: 1.5 x rank, Megaheal extreme: 3 x rank), + the
# caster's wis mod + rank. Megaheal costs more. Both reach Burnout like any heal.

var heal: Skill = load("res://Skills/heal.tres")
var megaheal: Skill = load("res://Skills/megaheal.tres")
var eros: SkillRoot = load("res://Trees/eros.tres")


# What s at rank r heals v(2), cast by v(1), over 80 seeds: [lowest, highest].
func spread(s: Skill, r: int) -> Array:
	v(1).learned.append(slot(s, r))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	v(2).constitution = 40  # no Burnout loss in the way
	var lo := 9999
	var hi := 0
	for seed in 80:
		b.rng.seed = seed
		v(2).max_hp = 300
		v(2).hp = 1
		v(2).endurance = 99
		v(1).refresh()
		v(1).energy = v(1).max_energy
		ok(b.cast(v(1), s, v(2)), "%s cast" % s.name)
		lo = mini(lo, v(2).hp - 1)
		hi = maxi(hi, v(2).hp - 1)
	return [lo, hi]


func test_place() -> void:
	ok(eros.branch(heal).tier == 8 and eros.branch(megaheal).tier == 8, "both at tier 8 on Eros")
	ok(megaheal.cost > heal.cost and megaheal.ap > heal.ap, "Megaheal costs more")
	ok(not heal.hostile and not megaheal.hostile, "used on allies")


func test_heal() -> void:
	var m := v(1).mod(&"wisdom")
	var got := spread(heal, 2)  # 3d8 + wis mod + 2
	ok(got[0] >= 3 + m + 2 and got[1] <= 24 + m + 2 and got[1] - got[0] >= 10, "Heal II: 3d8 + wis mod + 2 (%s)" % [got])
	ok(heal.describe(2).contains("3d8"), heal.describe(2))


func test_megaheal() -> void:
	var m := v(1).mod(&"wisdom")
	var got := spread(megaheal, 2)  # 6d8 + wis mod + 2
	ok(got[0] >= 6 + m + 2 and got[1] <= 48 + m + 2 and got[1] - got[0] >= 15, "Megaheal II: 6d8 + wis mod + 2 (%s)" % [got])
	ok(megaheal.describe(1).contains("3d8"), megaheal.describe(1))


func test_burnout() -> void:
	v(1).learned.append(slot(megaheal, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	v(2).constitution = -20  # fails every check
	v(2).max_hp = 300
	v(2).hp = 1
	v(2).endurance = 2
	v(1).energy = v(1).max_energy
	b.cast(v(1), megaheal, v(2))
	ok(v(2).endurance == 1, "a big heal on a low-con ally: a failed con check, 1 RE")


func test_gated() -> void:
	ok(eros.branch(heal).after == [load("res://Skills/rejuvinate.tres")] and eros.branch(heal).needs == 4, "Heal: after Rejuvinate, and 4 Eros skills")
	ok(eros.branch(megaheal).after == [heal] and eros.branch(megaheal).needs == 4, "Megaheal: after Heal, and 4 Eros skills")
