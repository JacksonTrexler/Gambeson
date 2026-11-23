extends "res://Behaviours/summon_per_rank.gd"

# Thesis of Theseus: designs and summons a Monster (Unit.monster(), Roles/monster.tres) of a path its caster
# chooses (choices(): Starmen, Sirens, Skeletons; the HUD asks), at a level of its rank impact, its path's traits
# free. One a cast, by Skeleton's summon rules (summon_per_rank.gd): it keeps rank + stat mod AP on arriving,
# and past the soft cap the furthest of the caster's own go Disturbed. With no path chosen (the AI, a quick cast)
# it picks the path its side holds fewest of (a unit with any of a path's traits counts for it), ties by the
# battle's roll.


func count(_c: Cast) -> int:
	return 1


# For the AI's price (AI._summon()): a class unit at level L weighs as L + 1 Skeletons (a level 1 Monster's ~10 HP and
# a dagger against a Skeleton's 6 HP), none past the soft cap.
func bodies(c: Cast) -> int:
	return super.bodies(c) * (c.impact_rank() + 1)


func choices(_c: Cast) -> Array[String]:
	var out: Array[String] = []
	out.assign(Unit.monster_paths().keys())
	return out


# The path it summons: the one chosen, else the one the caster's side holds fewest of (ties by c.battle.rng).
func path(c: Cast) -> String:
	if c.chose in Unit.monster_paths():
		return c.chose
	return Unit.fewest_path(c.battle.members(c.caster.faction) if c.battle else ([] as Array[Unit]), c.battle.rng if c.battle else null)


func make(c: Cast, cell: Vector2i) -> Unit:
	var p := path(c)
	var u := Unit.monster(c.caster.faction, p, c.impact_rank(), "%s Monster" % p)
	return c.battle.bring(u, c.caster.faction, cell) if u else null


func tile_target() -> StringName:
	return &"tile"


# Its rank is the Monster's level (rank impact); raising a unit is a thing of its own (impactful).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "level")
	if t.impact == &"":
		t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var r_mod := "{r:%d} + %s" % [c.impact_rank(), c.mod_text(c.skill.stat() if c.skill else &"intelligence")]
	return "Designs a Monster of a path you pick (%s) and raises it at level {r:%d} on the free tile nearest a tile, on your side, its path's traits free: an ordinary unit that keeps %s AP on arriving. It holds %s of what it raised in hand; past that, the furthest become %s for good" % [", ".join(Unit.monster_paths().keys()), c.impact_rank(), r_mod, r_mod, Glossary.term(&"disturbed", "Disturbed")]
