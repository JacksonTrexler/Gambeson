class_name Luck

# Luck decides ties and rounding. At 1 or more, fractions round the holder's way; at 0 or
# less they round against it (mitigation down, damage taken up).
static func settle(x: float, luck: int, more_is_better: bool) -> int:
	x = snappedf(x, 0.0001)  # 100 * 0.01 must be 1, not 1.0000001
	return ceili(x) if (luck >= 1) == more_is_better else floori(x)


# Near misses: each luck past 1 stretches thresholds (like movement reach) by 0.1.
static func reach(luck: int) -> float:
	return 0.1 * maxi(luck - 1, 0)
