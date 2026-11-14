extends Behaviour

# Telepathy: for one ally a turn within rank tiles, its holder commands by its rank in place of its
# charisma mod - reach, orders and hotbar slots all go by it (Command.cha_for()). Until it carries an
# order, any ally within rank tiles may be the one; the first it carries an order to (its rank beating
# the holder's charisma) is bound to it for the rest of the turn (Command.linked; new_turn() frees it).


func command_mod(c: Command, holder: Unit, rank: int, u: Unit) -> int:
	if (c.linked != null and c.linked != u) or Command.tiles(holder.cell, u.cell) > rank:
		return NO_MOD
	return rank


func ordered(c: Command, holder: Unit, rank: int, u: Unit) -> void:
	if c.linked == null and rank > holder.mod(&"charisma") and Command.tiles(holder.cell, u.cell) <= rank:
		c.linked = u


func describe(rank: int) -> String:
	return ("Once a turn, an ally within {r:%d} tile%s takes your orders as if your charisma mod were {r:%d}: as far, as many, as many hotbar slots. "
			+ "The first ally you order through it is the one, until your next turn") % [rank, "" if rank == 1 else "s", rank]
