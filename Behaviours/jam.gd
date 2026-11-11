extends Behaviour

# Jam: a light blow that breaks the foe's concentration. Landing, it interrupts the foe
# (Battle.interrupt(): its channel, hiding, guard, a primed Chant, its resting watch all end) and, the
# instant stun, leaves it Jammed - no reactions (no dodging, guarding or obstructing) - until its next
# turn is over. There is no focus meter yet: the blow's damage is plain physical damage.

const JAMMED: Effect = preload("res://Effects/jammed.tres")


func apply(c: Cast) -> void:
	if not c.foe or not c.target.is_alive():
		return
	c.bag[&"interrupted"] = c.battle.interrupt(c.target)
	c.put(JAMMED, 1)


func describe(_rank: int) -> String:
	return "Interrupts it: what it keeps up by constant attention ends - a %s, hiding, a guard, a primed Chant, its watch from resting. Then %s (no reactions: it can't dodge, guard or obstruct) through its next turn" % [
			Glossary.term(&"channeled", "channel"), Glossary.term(&"jammed", "Jammed")]
