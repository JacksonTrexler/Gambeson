extends Behaviour

# Deathlust: what it does, in a line or two. STUB(skill.py)


# An active skill's: runs as it lands. A passive's works through Behaviour's hooks instead (lets_word,
# hurt, healing, affinity, command_mod, ordered: Scripts/Behaviour.gd) - replace this with those it needs, or add a hook there.
func apply(c: Cast) -> void:
	pass  # STUB(skill.py): c.battle, c.caster, c.target, c.rank; c.put(effect, turns) puts one on the target


func describe(rank: int) -> String:
	return "STUB(skill.py) Deathlust at rank %d" % rank  # Glossary markup, one line: what apply() does
