extends Test

# Bludgeon (Skills/bludgeon.tres, Behaviours/bludgeon.gd): blunt 1d8 + str, + 1d4 bludgeoning already
# (a blunt weapon, or none); a hit leaves the foe Winded: rank AP off its next turn.

var bludgeon: Skill = load("res://Skills/bludgeon.tres")
var blunt_bh = preload("res://Behaviours/bludgeon.gd")


func test_winded() -> void:
	v(1).learned.append(slot(bludgeon, 2))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	ok(b.cast(v(1), bludgeon, v(3)), "used")
	ok(&"blunt" in Battle.hit_tags(v(1), bludgeon), "blunt")
	b.end_turn()
	ok(is_equal_approx(v(3).ap_left(), v(3).full_ap() - 2.0), "Winded: 2 AP off its next turn (%s of %s)" % [v(3).ap_left(), v(3).full_ap()])


func test_bludgeoning() -> void:
	ok(blunt_bh.bludgeoning(v(1)) == (v(1).weapon == null or v(1).weapon.damage_tag == &"blunt"), "bare-handed or blunt: bludgeoning")
	var sword := Item.new()
	sword.damage_tag = &"slash"
	var was := v(1).weapon
	v(1).weapon = sword
	ok(not blunt_bh.bludgeoning(v(1)), "a sword: not")
	v(1).weapon = was
	ok(not bludgeon.ai and "Winded" in bludgeon.describe(1), bludgeon.describe(1))
