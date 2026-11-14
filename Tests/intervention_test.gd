extends Test

# Intervention (Skills/intervention.tres), on Eros's tree after Renew: gives an ally within rank tiles
# Bless for rank turns - three effects, all data on the check-tag seam, none naming another skill:
#   regen 5% x rank tagged downed: it heals that much each turn only while Downed (Unit.state_tags());
#   hale: executes go by its full HP (Unit.execute_share());
#   check +rank tagged taps, execute, defensive: every check that would tap or execute it, whatever
#   skill asks for it, as long as the check carries its tags (Unit.check_bonus()).

var intervention: Skill = load("res://Skills/intervention.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")
var stun: Skill = load("res://Skills/stun.tres")
var death: Skill = load("res://Skills/death.tres")


func bless(r := 3) -> void:
	v(1).learned.append(slot(intervention, r))
	v(2).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(6, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	v(2).max_hp = 100
	v(2).hp = 100
	ok(b.cast(v(1), intervention, v(2)), "Intervention III reaches an ally 2 tiles off")


func test_intervention() -> void:
	bless()
	ok(v(2).timed.keys().filter(func(e: Effect): return e.name == "Bless").size() == 3, "Bless: three effects as one")
	ok(&"bless" in intervention.tags and Glossary.TERMS.has(&"bless"), "a bless skill, the word in the Glossary")
	var eros: SkillRoot = load("res://Trees/eros.tres")
	ok(eros.branch(intervention) != null, "on Eros (Cleric and Paladin)")
	ok(Glossary.plain(intervention.markup(3)).contains("each turn (downed)"), "described: %s" % Glossary.plain(intervention.markup(3)))


# The seam: any check carrying taps or execute gets +rank, and any execute takes it to be whole - Stun
# and Death, and a throwaway skill made here, alike.
func test_seam() -> void:
	bless()
	for t: Array in [[&"taps"], [&"execute"], stun.tags, death.tags]:
		var tags: Array[StringName] = []
		tags.assign(t)
		ok(v(2).check_bonus(&"constitution", &"defensive", tags) == 3, "+3 to a defensive check tagged %s" % [tags])
	ok(v(2).check_bonus(&"constitution", &"defensive") == 0 and v(2).check_bonus(&"constitution", &"offensive", [&"taps"]) == 0, "nothing to other checks, nor its own offensive ones")
	var later := Skill.new()  # a skill nobody has made yet, tagged taps and execute
	later.tags = [&"magical", &"taps", &"execute"]
	later.save = &"wisdom"
	v(2).hp = 5
	ok(v(2).check_mod(&"wisdom", &"defensive", later.tags) == v(2).mod(&"wisdom") + 3, "it gets the bonus")
	ok(is_equal_approx(Battle.executed(v(2), later, 2), 0.5), "and its execute goes by full HP, at 5 of 100 (%.2f)" % Battle.executed(v(2), later, 2))


func test_downed() -> void:
	bless()
	v(2).hp = 50
	b._mend(v(2))
	ok(v(2).hp == 50, "standing, its regen does nothing")
	v(2).damage(50)
	v(2).damage(30)
	ok(v(2).dbno != null and v(2).hp == -30, "Downed (%d)" % v(2).hp)
	b._mend(v(2))
	ok(v(2).hp == -15, "15%% back a turn at rank III (%d)" % v(2).hp)
	b._mend(v(2))
	b._mend(v(2))
	ok(v(2).hp == 15 and v(2).dbno == null, "and up, saved, in time (%d)" % v(2).hp)
