class_name Tags

# Child tags also count as their parent: a slash is a physical hit.
const PARENT := {&"slash": &"physical", &"pierce": &"physical", &"blunt": &"physical"}


static func expand(tags: Array[StringName]) -> Array[StringName]:
	var out := tags.duplicate()
	for t in tags:
		if t in PARENT and PARENT[t] not in out:
			out.append(PARENT[t])
	return out
