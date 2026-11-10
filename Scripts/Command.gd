class_name Command
extends RefCounted

# The player's hold over their side. The leader is the unit they made; on its side's turn it gives
# orders to allies within reach() tiles of it: its charisma mod, at least 1. It can also gather a
# party of up to party_size() allies (the same mod, at least 1), who hear its orders from
# PARTY_REACH times as far. The command and party stats (effects) add to the reach and party size.
# A commanded ally uses only the first slots() of its hotbar - the leader's charisma mod - so at +0
# or below it can only be told to move. Each turn the leader gives orders to at most ally_cap()
# allies, and at most order_cap() orders to each (both its charisma mod, at least 1); its own
# actions are its own. Allies without an order this turn act on their own when it ends.
# Leadership learned or carried stands in for charisma: the strategy and tactics stats (Strategist,
# Tactician; a Strategy Guide, a Tactician's Playbook) add to the two caps on top of that floor of 1,
# and command_mod (Grand Design) to the charisma mod itself, here and nowhere else (cha_of()).

const PARTY_REACH := 2.0

var battle: Battle
var leader: Unit
var party: Array[Unit] = []
var ordered: Dictionary[Unit, int] = {}  # orders given this turn, by unit (the leader's own moves count here too, uncapped)
var locked: Dictionary[Unit, bool] = {}  # a wasted intent order barred it from more commands this faction turn (HUD.issue_intent)


func _init(b: Battle, l: Unit) -> void:
	battle = b
	leader = l


# Tiles between two cells: the straight-line distance, rounded (a diagonal step is 1 tile).
static func tiles(a: Vector2i, b: Vector2i) -> int:
	return roundi(Vector2(a).distance_to(Vector2(b)))


func faction() -> Faction:
	return leader.faction


func reach() -> int:
	return reach_of(leader)


func party_reach() -> float:
	return party_reach_of(leader)


# A leader's charisma mod as it commands: its own, plus its command_mod stat (Grand Design: +1 a
# rank). Everything here that goes by charisma goes by this.
static func cha_of(l: Unit) -> int:
	return l.mod(&"charisma") + roundi(l.stat(&"command_mod"))


func cha() -> int:
	return cha_of(leader)


# How far a leader's orders carry: its cha mod + its command stat (a Quartz Ring: no limit), at least 1.
static func reach_of(l: Unit) -> int:
	return maxi(cha_of(l) + roundi(l.stat(&"command")), 1)


# ...and to its party: PARTY_REACH times as far (Synergy's reach too: Battle.synergized()).
static func party_reach_of(l: Unit) -> float:
	return reach_of(l) * PARTY_REACH


func party_size() -> int:
	return maxi(cha() + roundi(leader.stat(&"party")), 1)


# How many allies the leader may give orders to in a turn: its cha mod, at least 1, and its strategy
# stat on top of that (Strategist, a Strategy Guide: a rank each) - never fewer than 1.
func ally_cap() -> int:
	return maxi(maxi(cha(), 1) + ally_bonus(), 1)


# How many orders it may give each of them in a turn: its cha mod, at least 1, and its tactics stat
# on top of that (Tactician, a Tactician's Playbook: a rank each) - never fewer than 1.
func order_cap() -> int:
	return maxi(maxi(cha(), 1) + order_bonus(), 1)


# What its skills and items add to the two caps.
func ally_bonus() -> int:
	return roundi(leader.stat(&"strategy"))


func order_bonus() -> int:
	return roundi(leader.stat(&"tactics"))


# What a cap goes by, for the HUD's reasons: "charisma +1", "charisma +3 as it commands" (Grand
# Design), "charisma -1, +2 from skills and items".
func basis(bonus := 0) -> String:
	var text := "charisma %+d" % cha()
	if cha() != leader.mod(&"charisma"):
		text += " as it commands"
	if bonus != 0:
		text += ", %+d from skills and items" % bonus
	return text


# Allies (the leader aside) given an order this turn.
func commanded() -> int:
	return ordered.keys().filter(func(u: Unit): return u != leader).size()


# Whether the turn's caps leave u another order: it's the leader, or it has orders left and is one of
# the allies already commanded, or there's room for one more.
func under_caps(u: Unit) -> bool:
	return u == leader or (ordered.get(u, 0) < order_cap() and (u in ordered or commanded() < ally_cap()))


# How many hotbar slots, from the first, a commanded ally will use.
func slots() -> int:
	return maxi(cha(), 0)


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


# Close enough to the leader to hear its orders (whoever's turn it is): an ally, or a traitor of
# another side posing as one in its party (Battle.posing()).
func in_range(u: Unit) -> bool:
	if u == leader:
		return true
	if not leader.is_alive() or (u.faction != leader.faction and u.follows != leader):
		return false
	return tiles(leader.cell, u.cell) <= (party_reach() if u in party else float(reach()))


# Takes an order right now: alive and awake, not one that acts on its own (uncontrolled), on the leader's side on its turn, in range,
# within the turn's caps (under_caps()), and each taking the other for a teammate (Battle.teammates()).
func can_order(u: Unit) -> bool:
	return could_order(u) and in_range(u)


# Would take an order right now were it in range: all can_order() asks but that. One this holds for
# out of range stays in colour on the map, its glow weaker (HUD.command_state()).
func could_order(u: Unit) -> bool:
	return u != null and u.is_alive() and not u.asleep() and not u.uncontrolled and leader.is_alive() \
			and u not in locked and battle.phase == Battle.Phase.TURNS and battle.turn == leader.faction \
			and under_caps(u) and battle.teammates(leader, u)


# Allies join from within plain order range while there's room, if each takes the other for a
# teammate - a traitor of another side among them, pretending.
func can_join(u: Unit) -> bool:
	return u != leader and u.is_alive() and leader.is_alive() and not u.uncontrolled \
			and u not in party and party.size() < party_size() and tiles(leader.cell, u.cell) <= reach() \
			and battle.teammates(leader, u)


func join(u: Unit) -> bool:
	if not can_join(u):
		return false
	party.append(u)
	u.follows = leader
	return true


func leave(u: Unit) -> void:
	party.erase(u)
	if u.follows == leader:
		u.follows = null


func order(u: Unit) -> void:
	ordered[u] = ordered.get(u, 0) + 1


# A wasted intent order: u takes no more commands this faction turn (HUD default orders).
func lock(u: Unit) -> void:
	order(u)
	locked[u] = true


# Allies on the leader's side with no order this turn, and traitors posing in its party: they act on
# their own as it ends.
func idle() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in battle.members(leader.faction) + party.filter(func(x: Unit): return x.faction != leader.faction and x.is_alive()):
		if u != leader and u not in ordered:
			out.append(u)
	return out


# The leader's side starts a turn: orders are fresh, and the fallen leave the party, as do those it
# no longer takes for teammates (a traitor seen through).
func new_turn() -> void:
	ordered.clear()
	locked.clear()
	for u in party.filter(func(x: Unit): return not x.is_alive() or not battle.teammates(leader, x)):
		leave(u)
