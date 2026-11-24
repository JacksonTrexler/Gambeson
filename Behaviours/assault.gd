extends Behaviour

# Assault: its caster picks up to rank + 1 allies, in order, then up to rank foes (else the nearest of each), and
# they assault at once (AI.assault()): each in the order picked walks and uses its leftmost attack on up to rank
# of the foes, the nearest to it first. Each pays its own movement, AP and cost. With no free tile beside its
# foe, an ally standing there may step aside (a medium wis + dex hybrid check); statuses bearing `assault` that one
# gains are shared by them all for the assault.


# Who joins: the allies picked (alive, not the caster), in order, up to rank + 1; none picked, the nearest.
static func allies_of(c: Cast) -> Array[Unit]:
	var n := c.range_rank() + 1
	var out: Array[Unit] = []
	for o in c.picked:
		if out.size() < n and _mate(c, o) and o not in out:
			out.append(o)
	return out if not out.is_empty() else _nearest(c, n, true)


# Whom they assault: the foes picked it still makes out, up to rank; none picked, the nearest.
static func foes_of(c: Cast) -> Array[Unit]:
	var n := c.range_rank()
	var out: Array[Unit] = []
	for o in c.picked:
		if out.size() < n and o.is_alive() and not Faction.friends(o.faction, c.caster.faction) and c.battle.read(c.caster, o).located() and o not in out:
			out.append(o)
	return out if not out.is_empty() else _nearest(c, 1, false)


static func _mate(c: Cast, o: Unit) -> bool:
	return o != c.caster and o.is_alive() and Faction.friends(o.faction, c.caster.faction)


# The n nearest allies (mates) or foes it makes out.
static func _nearest(c: Cast, n: int, mates: bool) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in c.battle.units.values():
		if (_mate(c, o) if mates else (o.is_alive() and not Faction.friends(o.faction, c.caster.faction))) and c.battle.read(c.caster, o).located():
			out.append(o)
	out.sort_custom(func(x: Unit, y: Unit): return Command.tiles(x.cell, c.caster.cell) < Command.tiles(y.cell, c.caster.cell))
	return out.slice(0, n)


func picks(c: Cast) -> int:
	return 2 * c.range_rank() + 1


func allies(c: Cast) -> int:
	return c.range_rank() + 1


func defaults(c: Cast) -> Array[Unit]:
	return _nearest(c, c.range_rank() + 1, true) + _nearest(c, 1, false)


func fits(_b: Battle, caster: Unit, target: Unit) -> bool:
	return target == caster


func apply(c: Cast) -> void:
	var foes := foes_of(c)
	if not foes.is_empty():
		AI.assault(c.battle, allies_of(c), foes, c.range_rank())


func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "allies and foes picked, foes each attacks")


func describe(rank: int) -> String:
	return _say(rank)


# As its holder has it: its modifiers on how many it picks.
func describe_as(c: Cast) -> String:
	return _say(c.range_rank())


func _say(rank: int) -> String:
	return "Pick up to {r:%d} allies, in order, then up to {r:%d} foe%s (else the nearest of each): at once each ally, in that order, moves and uses its leftmost {k:attack} on up to {r:%d} of the foes, the nearest to it first, paying its own way. With no free tile beside its foe, an ally standing there may step aside (a medium wis + dex hybrid {k:check}). A status bearing {k:assault} that one gains is shared by all of them, and ends with the assault" % [rank + 1, rank, "" if rank == 1 else "s", rank]
