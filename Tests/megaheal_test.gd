extends Test

# Heal and Megaheal (Skills/heal.tres, Skills/megaheal.tres; Behaviours/heal.gd): Eros, tier 8. An ally
# gets back d8s by magnitude of rank (Heal moderate: 1.5 x rank, Megaheal severe: 3 x rank), + the
# caster's wis mod + rank. Megaheal costs more. Both reach Burnout like any heal.

var heal: Skill = load("res://Skills/heal.tres")
var megaheal: Skill = load("res://Skills/megaheal.tres")
var eros: SkillRoot = load("res://Trees/eros.tres")


# What s at rank r heals v(2), cast by v(1), over 80 seeds: [lowest, highest].
func spread(s: Skill, r: int) -> Array:
	v(1).learned.append(slot(s, r)); v(1).sync_bar()
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
	ok(eros.branch(heal).tier > 0 and eros.branch(heal).tier == eros.branch(megaheal).tier, "both at one tier on Eros")
	ok(not heal.hostile and not megaheal.hostile, "used on allies")


# One rule (Behaviours/heal.gd: d8s by magnitude of rank), a row each: Heal moderate, Megaheal severe.
func test_dice() -> void:
	var m := v(1).mod(&"wisdom")
	for row: Array in [[heal, 3, 24, 10, "3d8"], [megaheal, 6, 48, 15, "3d8"]]:
		var got := spread(row[0], 2)  # n d8 + wis mod + 2
		ok(got[0] >= row[1] + m + 2 and got[1] <= row[2] + m + 2 and got[1] - got[0] >= row[3], "%s II: %dd8 + wis mod + 2 (%s)" % [row[0].name, row[1], got])
		v(1).learned.pop_back(); v(1).sync_bar()
	ok(heal.describe(2).contains("3d8") and megaheal.describe(1).contains("3d8"), "%s, %s" % [heal.describe(2), megaheal.describe(1)])


func test_burnout() -> void:
	v(1).learned.append(slot(megaheal, 3)); v(1).sync_bar()
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
