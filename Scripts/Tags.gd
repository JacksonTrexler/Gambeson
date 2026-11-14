class_name Tags

# Child tags also count as their parent: a slash is a physical hit.
const PARENT := {&"slash": &"physical", &"pierce": &"physical", &"blunt": &"physical", &"foundation": &"pillar"}

# enchanted and honed: each gives rank +1 to the item or skill carrying it (Item.ranked(), Unit.rank()), and
# never both (mechanic.py check, Tests/items_test.gd). Only enchanted is what Pray, Smite and the rest ask
# about; honed is material perfection and triggers none of it.
const QUALITIES: Array[StringName] = [&"enchanted", &"honed"]


static func quality_rank(tags: Array[StringName]) -> int:
	return 1 if &"enchanted" in tags or &"honed" in tags else 0


static func exclusive(tags: Array[StringName]) -> bool:
	return not (&"enchanted" in tags and &"honed" in tags)


static func expand(tags: Array[StringName]) -> Array[StringName]:
	var out := tags.duplicate()
	for t in tags:
		if t in PARENT and PARENT[t] not in out:
			out.append(PARENT[t])
	return out
