class_name Luck

# Near misses within this much count as rounding, decided by net luck (standard: a miss).
const MARGIN := 0.5


# Rounding decided by net luck (my luck minus my opponent's, or just mine with no opponent):
#   net > 0: rounds my way.   net == 0: the situation's standard rule.   net < 0: against me.
# up_is_good: whether rounding up favours me. standard_up: the rule at net 0 (default: against me).
static func settle(x: float, net: int, up_is_good: bool, standard_up := not up_is_good) -> int:
	x = snappedf(x, 0.0001)  # 100 * 0.01 must be 1, not 1.0000001
	var up := standard_up
	if net > 0:
		up = up_is_good
	elif net < 0:
		up = not up_is_good
	return ceili(x) if up else floori(x)


# How settle() (or any rounding) took x to n, for the amount's sign (Battle.passive(), HUD floaters): -1 down, 1 up, 0 exact.
static func rounded(x: float, n: int) -> int:
	var d := n - snappedf(x, 0.0001)
	return int(signf(d)) if absf(d) < 1.0 else 0
