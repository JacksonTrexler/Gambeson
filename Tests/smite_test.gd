extends Test

# Smite by god (Battle._smite(), Battle._smite_heal()), at tier 3; Level Up (a buff easy to dispel);
# and a level curse taking back the last skill purchases (Unit.unranked()).

var smite: Skill = load("res://Skills/smite.tres")
var level_up: Skill = load("res://Skills/level_up.tres")
var paladin: Role = load("res://Roles/paladin.tres")


# A Paladin of `god` beside v(3), sure to hit (cha mod 15), Smite at rank r.
func smiter(god: StringName, r := 1) -> Unit:
	var u := b.starter({faction = lancin, role = paladin, name = "Pip"})
	b.get_node("Units").add_child(u)
	stage(lancin, {u: Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(6, 3), v(1): Vector2i(3, 3)})
	u.god = god
	u.charisma = 40
	u.learned.append(slot(smite, r))
	u.refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).armor = null
	return u


func test_tier() -> void:
	var u := b.starter({faction = lancin, role = paladin, name = "Pip"})
	ok(smite.min_tier == 3 and u.missing(smite).begins_with("Tier 3: learn 2 skills first"), u.missing(smite))
	u.learned.append(slot(load("res://Skills/favour.tres")))
	u.learned.append(slot(load("res://Skills/pray.tres")))
	ok(u.missing(smite) == "", "two learned: open")
	u.free()


func test_eros() -> void:
	var u := smiter(&"eros", 5)
	ok(&"love" in Battle.hit_tags(u, smite), "love")
	v(1).hp = v(1).max_hp
	ok(b.cast(u, smite, v(1)) and v(1).hp > v(1).max_hp, "on an ally: a heal, overhealing at rank V (%d / %d)" % [v(1).hp, v(1).max_hp])


func test_luun() -> void:
	var u := smiter(&"luun", 1)
	v(3).max_hp = 100
	v(3).hp = 40
	b._smite(u, v(3), 1, 10)
	ok(v(3).is_alive(), "rank I: 40% left is above 5%")
	v(3).hp = 20
	b._smite(u, v(3), 5, 10)
	ok(not v(3).is_alive() and v(3).slain_from == 20, "rank V: at 25% or less, it dies")


func test_sol() -> void:
	var u := smiter(&"sol", 2)
	b.cast(u, smite, v(3))
	var burn: Effect = null
	for e in v(3).timed:
		if e.name == "Sunburn":
			burn = e
	ok(burn != null and burn.stat == "bleed" and &"fire" in burn.tags, "a hit leaves it burning")
	var gross := 300 - v(3).hp
	ok(burn and is_equal_approx(burn.amount, maxf(roundf(gross * 0.4), 1.0)), "for 40%% of the damage at rank II (%s of %d)" % [burn.amount if burn else -1.0, gross])
	var hp := v(3).hp
	b._bleed(v(3))
	ok(v(3).hp == hp - roundi(burn.amount) or v(3).timed[burn].since == b.turns_begun, "as its side's turn ends")


func test_urlo() -> void:
	var u := smiter(&"urlo", 1)
	var blade: Item = load("res://Items/rapier.tres").duplicate()
	blade.enchant = 1
	v(3).weapon = blade
	u.weapon = load("res://Items/broadsword.tres")
	b.cast(u, smite, v(3))
	ok(v(3).weapon.enchant == 0 and u.weapon.enchant == 0, "rank I: its one enchantment comes off; none left over for the caster")
	var u2 := smiter(&"urlo", 2)
	u2.weapon = load("res://Items/broadsword.tres")
	v(3).weapon = null
	b.cast(u2, smite, v(3))
	ok(u2.weapon.enchant == 1, "nothing to take: the caster's own weapon is enchanted instead")


func test_drael() -> void:
	var u := smiter(&"drael", 2)
	var up := effect("luck", 1)
	v(3).afflict(up, 3, 3)
	b.cast(u, smite, v(3))
	ok(up in v(3).timed and v(3).timed[up].rank == 1, "rank II: two ranks of its buffs off")


func test_vetruvis() -> void:
	var u := smiter(&"vetruvis", 2)
	v(4).max_hp = 300
	v(4).hp = 300
	v(1).max_hp = 300
	v(1).hp = 300
	b._smite(u, v(3), 2, 30)
	ok(v(4).hp == 300 - 15 or v(4).hp == 300 - 14, "a tile away: 30 / 2 (%d)" % (300 - v(4).hp))
	ok(v(1).hp == 290, "two away, an ally too: 30 / 3 (%d)" % (300 - v(1).hp))
	ok(u.hp == u.max_hp, "never the caster")


func test_level_up() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(1).learned.append(slot(level_up, 2))
	v(1).wisdom = 20
	v(1).refresh()
	var lv := v(2).lv()
	ok(b.cast(v(1), level_up, v(2)) and v(2).lv() == lv + 2, "rank II: two levels")
	var a: Unit.Applied = v(2).timed[level_up.effects[0]]
	ok(a.total == 2, "for rank turns")
	ok(b.dispel(v(2), 1) == 1 and level_up.effects[0] not in v(2).timed and v(2).lv() == lv, "easy to dispel: one rank spent takes four")


func test_unranked() -> void:
	var snare: Skill = load("res://Skills/snare.tres")
	var hide: Skill = load("res://Skills/hide.tres")
	v(1).lore.append_array([snare, hide])
	v(1).skill_points = 3
	ok(v(1).unlock(snare) and v(1).unlock(hide) and v(1).skill_points == 1, "Snare, then Hide; a point left")
	var curse := effect("level", -1)
	curse.per_rank = true
	v(1).afflict(curse, 2, 2)
	ok(v(1).unranked() == {hide: 1} and v(1).rank(hide) == 0 and hide not in v(1).actives, "two levels down, one point spare: the last purchase (Hide) is undone")
	v(1).timed.erase(curse)
	ok(v(1).rank(hide) == 1 and hide in v(1).actives, "back as the curse ends")
