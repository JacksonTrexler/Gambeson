extends Test

# Skill points: one per level gained, spent unlocking skills a unit's class, species and accrued
# knowledge offer (Unit.options(), Unit.unlock()).

var relay: Skill = load("res://Skills/relay.tres")
var lightvision: Skill = load("res://Skills/lightvision.tres")


func pip() -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/paladin.tres"), name = "Pip"})
	b.get_node("Units").add_child(u)
	return u


func test_level_up() -> void:
	v(1).level_up()
	ok(v(1).level == 2 and v(1).skill_points == 1, "a level up brings a skill point")


func test_unlock() -> void:
	var u := pip()
	var o := u.options()
	ok(o[&"class"] == [favour, lightvision] and o[&"species"] == [relay] and o[&"knowledge"].is_empty(),
			"a halfling paladin: Favour and Lightvision from its class, Relay from its species")
	ok(not u.unlock(relay), "no points, no unlocking")
	u.level_up()
	ok(u.unlock(relay) and u.rank(relay) == 1 and u.skill_points == 0, "a point unlocks Relay, rank I")
	ok(relay not in u.options()[&"species"] and u.sources()[&"species"] == [relay], "no longer on offer, still listed where it came from")
	u.level_up()
	ok(not u.unlock(strike) and u.skill_points == 1, "only what's on offer")
	u.lore.append(hex)
	ok(u.options()[&"knowledge"] == [hex] and u.unlock(hex) and u.hotbar[1] == hex, "accrued knowledge; an active goes on the hotbar")
	u.free()


func test_known_aren_t_offered() -> void:
	var al: Unit = b.get_node("Units/Alabaster")
	al.lore.append(strike)
	ok(al.options()[&"knowledge"].is_empty(), "a skill it already has isn't on offer")
