extends Behaviour

# Sutemi: throws itself at a foe up to rank tiles off - lunging, a tile at a time straight for it, to
# beside it (as Sing's pull draws a unit: no movement spent, the ground underfoot does nothing) - then
# strikes. It's left Off Balance: -1 Defense for each tile lunged, through its next turn.

const OFF_BALANCE: Effect = preload("res://Effects/off_balance.tres")


# The tiles u would lunge through toward `to`, at most n, stopping beside it or at anything in the way.
static func lunge(b: Battle, u: Unit, to: Unit, n: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var at := u.cell
	for i in n:
		if Battle.next_to(at, to.cell):
			break
		var d := to.cell - at
		var c := at + Vector2i(signi(d.x), signi(d.y))
		if not b.on_map(c) or (b.unit_at(c) and b.unit_at(c) != u):
			break
		out.append(c)
		at = c
	return out


func _rank(caster: Unit) -> int:
	for s in caster.actives:
		if self in s.behaviours:
			return caster.rank(s)
	return 1


# Only where the lunge ends beside the foe.
func fits(b: Battle, caster: Unit, target: Unit) -> bool:
	var path := lunge(b, caster, target, _rank(caster))
	return Battle.next_to(path[-1] if not path.is_empty() else caster.cell, target.cell)


func aim(c: Cast) -> void:
	if not c.foe:
		return
	var path := lunge(c.battle, c.caster, c.target, c.rank)
	for cell in path:
		c.battle.move(c.caster, cell)
	c.bag[&"lunged"] = path.size()
	if not path.is_empty():
		var a := c.caster.afflict(OFF_BALANCE, 1 + (1 if c.caster.faction == c.battle.turn else 0), path.size())
		a.total = 1
		a.skill = c.skill
		a.by = c.caster
		a.since = c.battle.turns_begun


func describe(rank: int) -> String:
	return "First lunges up to {r:%d} tile%s straight for the foe, to beside it (no movement spent). Then %s: -1 Defense for each tile lunged, through its next turn" % [
			rank, "" if rank == 1 else "s", OFF_BALANCE.name]
