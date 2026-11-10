class_name Behaviour
extends Resource

# One verb a skill performs, what it does (apply) and what it says (describe) side by side, so the two
# can't drift (seam 3, docs/plan-composability.md). A skill lists them (Skill.behaviours); Battle.cast()
# runs them in order once the skill has landed - past its attack roll, its effects on - beside the
# Skill.gd flags, which stay for the skills that use them. New behaviour goes here: a script in
# Behaviours/ extending this, never a new flag (Util/skill.py new --behaviour <name> stubs one).


# A landing skill, as its behaviours see it. `bag` is scratch they share, in order: one can leave
# something for the next.
class Cast:
	var battle: Battle
	var caster: Unit
	var target: Unit
	var skill: Skill
	var rank := 1
	var foe := true
	var bag := {}

	# Puts e on the target for its turns (+ 1 on its side's turn, which doesn't count), marked as this
	# cast's, as a skill's own effects are.
	func put(e: Effect, turns: int) -> Unit.Applied:
		var a := target.afflict(e, turns + (1 if target.faction == battle.turn else 0), rank)
		a.total = turns
		a.skill = skill
		a.by = caster
		a.since = battle.turns_begun
		return a


func apply(_c: Cast) -> void:
	pass


# What apply() does at this rank, in Glossary markup: one or more lines of the skill's description.
func describe(_rank: int) -> String:
	return ""
