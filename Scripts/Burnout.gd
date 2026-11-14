class_name Burnout
extends RefCounted

# Burnout (Glossary: burnout, recovery_endurance): recovering Energy or HP by any means but resting wears a
# unit out. The one rule every recovery passes through: Unit.heal() and Unit.grant_energy() (and
# Unit.note_recovery() for anything else) tell Unit.recovered, Battle hands it here. Regen (Unit.recover())
# never comes here. The unit's Recovery Endurance (Unit.endurance) starts each battle at max(con mod, 0)
# and refills only on a resting turn taken at full (Unit.recover()).
#  - Depleted (RE 0 or below as it recovers): a con check, DC CHECK_DC; failing cuts the max of what came
#    back by LOSS x (1 + |RE|) of the amount, rounded, at least 1, for good (Unit.burn()), and an HP
#    recovery takes 1 RE.
#  - Energy (Power, Overcharge, a reserve) always spends 1 RE, depleted or not.
#  - One heal of more than max(con mod, 0) x BIG of max HP: a con check against the excess; failing, -1 RE.

const CHECK_DC := 12  # the flat Standard rung (Difficulty)
const LOSS := 0.1
const BIG := 0.2  # of max HP, a con mod


# What came back: n of pool (&"hp", &"energy" or a Reserve) to u. Rolls through b (Battle.resolve()).
static func recovered(b: Battle, u: Unit, pool: Variant, n: int) -> void:
	if n <= 0 or not u.is_alive():
		return
	var hp: bool = pool is StringName and pool == &"hp"
	var re := u.endurance
	if re <= 0 and not _passes(b, u, CHECK_DC):
		u.burn(pool, maxi(u.rounded(LOSS * (1 + absi(re)) * n), 1))
		if hp:
			u.endurance -= 1
	if not hp:
		u.endurance -= 1  # reenergizing always spends RE
	else:
		var excess := n - floori(maxi(u.mod(&"constitution"), 0) * BIG * u.max_hp)
		if excess > 0 and not _passes(b, u, excess):
			u.endurance -= 1


static func _passes(b: Battle, u: Unit, dc: int) -> bool:
	return b.resolve(Check.check(u.check_mod(&"constitution", &"defensive"), dc, Check.Kind.SAVE)).hit
