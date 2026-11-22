extends Behaviour

# Telepathy: for one ally a turn within rank tiles, its holder commands by its rank in place of its
# charisma mod - reach, orders and hotbar slots all go by it (Command.cha_for()). Until it carries an
# order, any ally within rank tiles may be the one; the first it carries an order to (its rank beating
# the holder's charisma) is bound to it for the rest of the turn (Command.linked; new_turn() frees it).


func command_mod(c: Command, holder: Unit, rank: int, u: Unit) -> int:
	var m := mods_on(holder)
	if (c.linked != null and c.linked != u) or Command.tiles(holder.cell, u.cell) > m.irank(rank, &"rank_range"):
		return NO_MOD
	return m.irank(rank, &"rank_impact")


func ordered(c: Command, holder: Unit, rank: int, u: Unit) -> void:
	var m := mods_on(holder)
	if c.linked == null and m.irank(rank, &"rank_impact") > holder.mod(&"charisma") and Command.tiles(holder.cell, u.cell) <= m.irank(rank, &"rank_range"):
		c.linked = u


# Its terms: an ally within rank tiles (range) takes orders as if its cha mod were its rank (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "ally reach")
	t.add(&"rank_impact", "commands as")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var reach := c.range_rank()
	return ("Once a turn, an ally within {r:%d} tile%s takes your orders as if your charisma mod were {r:%d}: as far, as many, as many hotbar slots. "
			+ "The first ally you order through it is the one, until your next turn") % [reach, "" if reach == 1 else "s", c.impact_rank()]
