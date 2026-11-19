extends Behaviour

# Scrap Plating: its holder wears one armor more, in a slot of its own (Behaviour.armor_slot()), that confers no more
# than rank Defense. Its AP drag is the armor's own, in full, on top of the armor proper's (Unit.armor_drag()).


func armor_slot() -> bool:
	return true


func slot_defense(_holder: Unit, rank: int, defense: int) -> int:
	return mini(defense, rank)


func describe(rank: int) -> String:
	return "An armor slot more: the armor in it confers at most %d Defense, and drags in full" % rank
