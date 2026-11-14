extends Test

# Forage: a stub on the Ranger's Survival ?? tree, the survival specialist guest tree Survivalist opens.

var forage: Skill = load("res://Skills/forage.tres")


func test_forage() -> void:
	ok(forage.stub == "?81" and load("res://Trees/survival.tres").skills() == [forage], "a stub, waiting on ?81: Survival's first skill")
	ok(load("res://Roles/ranger.tres").tabs_of(forage).map(func(t: SkillTab): return t.title()) == ["Path: Survival ??"], "on the Ranger's Survival tab")
