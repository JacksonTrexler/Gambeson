class_name Loot
extends Resource

# What a unit drops as it falls (Unit.loot; Battle._on_died()): with `chance`, one of `items`, picked
# by weight (the Astral Princess: Heart Up 1, a Heart 3 - 25% and 75%).
@export var items: Array[Item] = []
@export var weights: Array[float] = []  # one per item; missing ones weigh 1
@export var chance := 1.0


func roll(rng: RandomNumberGenerator) -> Item:
	if items.is_empty() or rng.randf() >= chance:
		return null
	var total := 0.0
	for i in items.size():
		total += weight(i)
	var at := rng.randf() * total
	for i in items.size():
		at -= weight(i)
		if at < 0.0:
			return items[i]
	return items[-1]


func weight(i: int) -> float:
	var w: float = weights[i] if i < weights.size() else 1.0
	return w * (items[i].rarity_pull() if i < items.size() and items[i] else 1.0)


# "Heart Up (25%) or Heart (75%)".
func describe() -> String:
	var total := 0.0
	for i in items.size():
		total += weight(i)
	var parts := []
	for i in items.size():
		parts.append("%s (%d%%)" % [items[i].name, roundi(100.0 * chance * weight(i) / total)])
	return " or ".join(parts)
