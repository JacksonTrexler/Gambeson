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
	var saved := c.battle.check(c.target, &"constitution", null, dc(c), save_opts(c)).won
	c.bag[&"stunned"] = not saved
	if saved:
		return
	c.put(STUNNED, c.rank)
	if c.target.stopped():
		c.bag[&"interrupted"] = c.battle.interrupt(c.target)


# Its save's DC, and the helper's options for the foe's roll of it (the cast's own tags help it: checks tagged taps).
static func dc(c: Cast) -> int:
	return Difficulty.dc(&"difficult", c.rank)


static func save_opts(c: Cast) -> Dictionary:
	return {role = &"defensive", kind = Check.Kind.SAVE, tags = c.tags}


# What a hit would bring: the chance the foe fails its save (Battle.odds(), the roll apply() makes).
func foresee(c: Cast) -> Dictionary:
	if not c.foe:
		return {}
	var p := 1.0 - Battle.odds(c.target, &"constitution", null, dc(c), save_opts(c))
	return {notes = ["Stuns it (%d%%)" % roundi(p * 100.0)] as Array[String], riders = p}


func describe(rank: int) -> String:
	return "Landing, the foe makes a %s %s %s (DC %d, a check that %s); failing, it's Stunned for {r:%d} turn%s: %s - %s unless something lets it act. A %s: a heal clearing rank {r:%d} takes it off; easy to cleanse (half its rank)" % [
			Glossary.term(&"difficult"), Glossary.mod(&"con", true), Glossary.term(&"check", "check"), Difficulty.dc(&"difficult", rank),
			Glossary.term(&"taps", "taps"), rank, "" if rank == 1 else "s",
			Glossary.term(&"helpless", "helpless"), Glossary.term(&"tapped", "tapped"), Glossary.term(&"wound", "wound"), rank]
