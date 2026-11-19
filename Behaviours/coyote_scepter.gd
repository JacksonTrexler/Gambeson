extends Behaviour

# Coyote Scepter (lent by the Coyote Scepter, an epic weapon): skills its holder disables last rank turns longer,
# and their unit gets the Coyote Charm buff and the Curse of the Coyote at that rank (coyote_charm.gd: lend()): the
# disabling waits rank turns, then lands for its full, longer turns - the curse barring cleanses and heals.

const Charm := preload("res://Behaviours/coyote_charm.gd")


func disabling(b: Battle, holder: Unit, rank: int, u: Unit, d: Dictionary) -> void:
	if holder == d.by and holder != u:
		d.turns += rank
		Charm.lend(b, u, rank)


func describe(rank: int) -> String:
	return "Skills it %s last %d turns longer, and their unit gets the Coyote Charm and the Curse of the Coyote %s: the disabling waits %d turns first" % [
			Glossary.term(&"disabled", "disables"), rank, Skill.roman(rank), rank]
