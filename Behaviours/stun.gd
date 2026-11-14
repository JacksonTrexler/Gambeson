extends Behaviour

# Stun: a very difficult blow (its roll_bonus); landing, the foe makes a difficult con check at its rank
# (a check that taps: it carries the skill's tags, `taps` among them, so whatever helps with such checks
# helps here - Unit.check_bonus()). Failing, it's Stunned for rank turns: helpless (tapped unless
# something lets it act anyway), a wound a heal of its rank clears, and easy to cleanse (Effect.ease 2).
# A stun that stops it breaks its attention too (Battle.interrupt(): a channel, hiding, a guard...).

const STUNNED: Effect = preload("res://Effects/stunned.tres")


func apply(c: Cast) -> void:
	if not c.foe or not c.target.is_alive():
		return
	var dc := Difficulty.dc(&"difficult", c.rank)
	var roll := c.battle.resolve(Check.check(c.target.check_mod(&"constitution", &"defensive", c.skill.tags), dc, Check.Kind.SAVE))
	c.bag[&"stunned"] = not roll.hit
	if roll.hit:
		return
	c.put(STUNNED, c.rank)
	if c.target.stopped():
		c.bag[&"interrupted"] = c.battle.interrupt(c.target)


func describe(rank: int) -> String:
	return "Landing, the foe makes a %s %s %s (DC %d, a check that %s); failing, it's Stunned for {r:%d} turn%s: %s - %s unless something lets it act. A %s: a heal clearing rank {r:%d} takes it off; easy to cleanse (half its rank)" % [
			Glossary.term(&"difficult"), Glossary.mod(&"con", true), Glossary.term(&"check", "check"), Difficulty.dc(&"difficult", rank),
			Glossary.term(&"taps", "taps"), rank, "" if rank == 1 else "s",
			Glossary.term(&"helpless", "helpless"), Glossary.term(&"tapped", "tapped"), Glossary.term(&"wound", "wound"), rank]
