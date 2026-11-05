class_name Command
extends RefCounted

# The player's hold over their side. The leader is the unit they made; on its side's turn it gives
# orders to allies within reach() tiles of it: its charisma mod, at least 1. It can also gather a
# party of up to party_size() allies (the same mod, at least 1), who hear its orders from
# PARTY_REACH times as far. The command and party stats (effects) add to the reach and party size.
# A commanded ally uses only the first slots() of its hotbar - the leader's charisma mod - so at +0
# or below it can only be told to move. Allies without an order this turn act on their own when it
# ends.

const PARTY_REACH := 2.0

var battle: Battle
var leader: Unit
var party: Array[Unit] = []
var ordered: Dictionary[Unit, bool] = {}  # given an order this turn


func _init(b: Battle, l: Unit) -> void:
	battle = b
	leader = l


# Tiles between two cells: the straight-line distance, rounded (a diagonal step is 1 tile).
static func tiles(a: Vector2i, b: Vector2i) -> int:
	return roundi(Vector2(a).distance_to(Vector2(b)))


func faction() -> Faction:
	return leader.faction


func reach() -> int:
	return maxi(leader.mod(&"charisma") + roundi(leader.stat(&"command")), 1)


func party_reach() -> float:
	return reach() * PARTY_REACH


func party_size() -> int:
	return maxi(leader.mod(&"charisma") + roundi(leader.stat(&"party")), 1)


# How many hotbar slots, from the first, a commanded ally will use.
func slots() -> int:
	return maxi(leader.mod(&"charisma"), 0)


# Whether u may be told to use hotbar slot i: the leader uses all of its own.
func slot_open(u: Unit, i: int) -> bool:
	return u == leader or i < slots()


# Whether u may be told to use (or switch) s: it must sit in a slot that's open to orders.
func may_use(u: Unit, s: Skill) -> bool:
	if u == leader:
		return true
	for i in mini(slots(), u.hotbar.size()):
		if u.hotbar[i] == s:
			return true
	return false


# The leader and its party: the units that are the player's own.
func ours(u: Unit) -> bool:
	return u == leader or u in party


# Close enough to the leader to hear its orders (whoever's turn it is).
func in_range(u: Unit) -> bool:
	if u == leader:
		return true
	if not leader.is_alive() or u.faction != leader.faction:
		return false
	return tiles(leader.cell, u.cell) <= (party_reach() if u in party else float(reach()))


# Takes an order right now: alive and awake, on the leader's side on its turn, and in range.
func can_order(u: Unit) -> bool:
	return u != null and u.is_alive() and not u.asleep() and leader.is_alive() \
			and battle.phase == Battle.Phase.TURNS and battle.turn == leader.faction and in_range(u)


# Allies join from within plain order range while there's room.
func can_join(u: Unit) -> bool:
	return u != leader and u.is_alive() and leader.is_alive() and u.faction == leader.faction \
			and u not in party and party.size() < party_size() and tiles(leader.cell, u.cell) <= reach()


func join(u: Unit) -> bool:
	if not can_join(u):
		return false
	party.append(u)
	return true


func leave(u: Unit) -> void:
	party.erase(u)


func order(u: Unit) -> void:
	ordered[u] = true


# Allies on the leader's side with no order this turn: they act on their own as it ends.
func idle() -> Array[Unit]:
	var out: Array[Unit] = []
	out.assign(battle.members(leader.faction).filter(func(u: Unit): return u != leader and u not in ordered))
	return out


# The leader's side starts a turn: orders are fresh, and the fallen leave the party.
func new_turn() -> void:
	ordered.clear()
	party.assign(party.filter(func(u: Unit): return u.is_alive()))
