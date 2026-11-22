extends Behaviour

# The Burning Bag: used on itself, the one item there is, taken from whoever has it (or the stash) and put
# on its caster at the skill's rank (rank impact); what the caster wore there goes to the stash, if it's
# the player's.

@export var item: Item


func whole(_c: Cast) -> bool:
	return true


func apply(c: Cast) -> void:
	var b := c.battle
	var caster := c.caster
	for o: Unit in b.get_node("Units").get_children():
		for slot in CharacterSheet.SLOTS:
			var worn: Item = o.get(slot)
			if worn and worn.name == item.name:
				o.unequip(slot)
	for x in Game.stash.duplicate():
		if x.name == item.name:
			Game.stash.erase(x)
	var mine: Item = item.duplicate()
	mine.rank = c.impact_rank()
	var old: Item = caster.get(mine.slot)
	caster.equip(mine)
	if old and b.player and caster.faction == b.player.faction:
		Game.stash.append(old)


# Only carries out its numbers: no unique effect.
func impact() -> StringName:
	return &""


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "retrieves")


func describe(rank: int) -> String:
	return "Takes the %s from wherever it is and puts it on, at rank {r:%d}" % [item.name if item else "item", rank]


func describe_as(c: Cast) -> String:
	return describe(c.impact_rank())
