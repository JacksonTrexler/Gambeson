extends Behaviour

# Slot cost: the hotbar slots its skill takes, an explicit number that stands over any default (Skill.slots_taken(): 1,
# or what its rarity tag gives - rare 2, epic 3, legendary 4, mythic 5). 1 on a rare skill makes it an ordinary one; more
# on an ordinary one makes it dear. It does nothing when the skill is used: it is read as the skill is slotted
# (Unit.slot_cost(), bar_place()). It says the cost; a skill with only a rarity tag says it as Skill.markup() does.

@export var slots := 1


func slots_taken() -> int:
	return maxi(slots, 1)


func describe(_rank: int) -> String:
	return Skill.slots_line(slots) if slots > 1 else "Takes 1 hotbar slot, whatever its rarity"
