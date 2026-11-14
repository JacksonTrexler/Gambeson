class_name Tags

# Child tags also count as their parent: a slash is a physical hit.
const PARENT := {&"slash": &"physical", &"pierce": &"physical", &"blunt": &"physical", &"foundation": &"pillar"}

# enchanted and honed: each gives rank +1 to the item or skill carrying it (Item.ranked(), Unit.rank()), and
# never both (mechanic.py check, Tests/items_test.gd). Only enchanted is what Pray, Smite and the rest ask
# about; honed is material perfection and triggers none of it.
const QUALITIES: Array[StringName] = [&"enchanted", &"honed"]


# Every tag's colour (mechanic.py tag --color; mechanic.py color retunes one): where its word is drawn
# (Glossary links, damage floaters, the hotbar stripe) and as trim on what carries it (Item.trim()). A
# child without its own takes its parent's (PARENT). One system: elements by convention, disciplines,
# resources and factions in the colours the UI already gives them, generic terms in their Glossary
# kind's colour (Glossary.KINDS). Read it with color(). Any key a rule asks about may join: a modifier
# symbol too.
const COLOR := {
	# elements and what blows are made of
	&"fire": Color("#f08a55"), &"water": Color("#68aee8"), &"earth": Color("#c49a66"), &"light": Color("#f2e39a"),
	&"dark": Color("#9d8fe0"), &"energy": Color("#6fd8e4"), &"love": Color("#ee95c0"), &"ice": Color("#a8e0f0"),
	&"wind": Color("#cfe8d8"), &"air": Color("#cfe8d8"), &"nature": Color("#7fb85a"), &"sound": Color("#4fc1b0"),
	&"sight": Color("#62b6e8"), &"star": Color("#bfe3ff"), &"astral": Color("#f0cf5a"), &"physical": Color("#d0d0d0"),
	&"bludgeon": Color("#d0d0d0"), &"elemental": Color("#e0b070"), &"energized": Color("#6fd8e4"),
	# disciplines (SkillTab.GENERAL) and resources (Reserves/)
	&"martial": Color("#d27a70"), &"specialist": Color("#82b86e"), &"magical": Color("#a98bdb"),
	&"stamina": Color("#cce04d"), &"channeled": Color("#a86bf2"), &"overcharge": Color("#6fd8e4"),
	&"siphon": Color("#8f9ef0"), &"drain": Color("#8fd0e8"),
	# the divine and the damned (SkillTab.GODS, CLASSES, Factions/)
	&"divine": Color("#e3c873"), &"holy": Color("#f5e6a8"), &"radiant": Color("#fff0a0"), &"sol": Color("#f08a55"),
	&"bless": Color("#f2d27a"), &"shrine": Color("#e3c873"), &"idealism": Color("#e8dcb0"), &"lawful": Color("#c8d4e8"),
	&"curse": Color("#9a4f8a"), &"malevolent": Color("#8a3a5a"), &"warlock": Color("#9a7bd1"), &"demon": Color("#d94073"),
	&"abyssal": Color("#6a2a5a"), &"shade": Color("#5a5a78"), &"siren": Color("#3fa8a0"), &"undine": Color("#68c8d8"),
	# what units are
	&"monster": Color("#a0705a"), &"beast": Color("#b08a5a"), &"construct": Color("#a7b1bd"), &"fish": Color("#7ab8c8"),
	&"boss": Color("#c04a6a"), &"aquatic": Color("#68aee8"), &"rotting": Color("#8a9a5a"), &"tall": Color("#b8c0cc"),
	# stats
	&"str": Color("#e0705a"), &"dex": Color("#8fdc8c"), &"con": Color("#d9935e"), &"int": Color("#6f9be0"),
	&"wis": Color("#9fd6c8"), &"cha": Color("#e08fc8"),
	# what a skill is for
	&"offensive": Color("#ff9e8a"), &"defensive": Color("#74b4e8"), &"supportive": Color("#8fdc8c"),
	&"beneficial": Color("#6fdc8c"), &"detrimental": Color("#ff6b5e"), &"damage": Color("#ff9e8a"),
	&"dangerous": Color("#e8665a"), &"environmental": Color("#b9cf8a"), &"unique": Color("#e8c547"),
	&"ambush": Color("#5b4a6e"), &"bracing": Color("#a7b1bd"), &"finesse": Color("#c9ced8"), &"dubious": Color("#b39ddb"),
	# materials, forms, weights, qualities (PLAIN: never trim)
	&"metal": Color("#a7b1bd"), &"iron": Color("#8a8f9c"), &"cloth": Color("#c8b89a"), &"padded": Color("#c8b89a"),
	&"mail": Color("#a7b1bd"), &"wood": Color("#a0784a"), &"stone": Color("#9a948a"), &"rock": Color("#8a847a"),
	&"glass": Color("#cfeaff"), &"gem": Color("#d06a9a"), &"blade": Color("#c9ced8"), &"book": Color("#b59a78"),
	&"potion": Color("#c8a0e0"), &"ring": Color("#e8c547"), &"shackles": Color("#8a8f9c"), &"treat": Color("#f0b0c8"),
	&"stew": Color("#c08a5a"), &"heavy": Color("#8a8f9c"), &"medium": Color("#a7b1bd"),
	&"enchanted": Color("#b49ae6"), &"honed": Color("#d6dbe4"),
	# ground (Glossary kind ground: #b9cf8a)
	&"grass": Color("#7d9a3c"), &"shrubbery": Color("#5f7d33"), &"bramble": Color("#6a7a3a"), &"leaves": Color("#a3842f"),
	&"moist": Color("#7ab8a0"), &"wet": Color("#68aee8"), &"shallow": Color("#8ac8e8"), &"flowing": Color("#68aee8"),
	&"rough": Color("#9a8a6a"), &"outdoors": Color("#b9cf8a"), &"pillar": Color("#cfd4dc"),
	&"burning": Color("#f08a55"), &"submerged": Color("#4f8fd0"), &"flood": Color("#68aee8"), &"drowning": Color("#4f8fd0"),
	&"trap": Color("#d9a05a"), &"sticky": Color("#b9cf8a"), &"disturbed_earth": Color("#8a6a45"), &"darkness": Color("#7b6fe0"),
	&"starpane": Color("#bfe3ff"), &"on_enter": Color("#b9cf8a"), &"layer": Color("#b9cf8a"), &"lets_through": Color("#b9cf8a"),
	&"obscuring": Color("#b9cf8a"), &"cover": Color("#7d9a3c"), &"brittle": Color("#cfeaff"), &"unstable": Color("#c9a66b"),
	&"flammable": Color("#f0a070"), &"windswept": Color("#cfe8d8"), &"repairing": Color("#ffe48a"), &"turn_end": Color("#b9cf8a"),
	# checks (Glossary kind check: #f0d48a); the difficulties run green to red
	&"attack": Color("#f0d48a"), &"critical": Color("#ffd75e"), &"advantage": Color("#9fe08a"), &"disadvantage": Color("#ff8a7a"),
	&"save": Color("#f0d48a"), &"contest": Color("#f0d48a"), &"check": Color("#f0d48a"), &"last_stand": Color("#f0d48a"),
	&"investigate": Color("#62b6e8"), &"defense": Color("#74b4e8"), &"mod": Color("#f0d48a"), &"evadable": Color("#f0d48a"),
	&"trivial": Color("#9fe08a"), &"easy": Color("#c6e07a"), &"approachable": Color("#e8d870"), &"standard": Color("#f0c060"),
	&"difficult": Color("#f0985a"), &"unfair": Color("#e8665a"), &"impossible": Color("#c04a6a"),
	&"intense": Color("#f0985a"), &"severe": Color("#e8665a"), &"taps": Color("#f0d48a"), &"execute": Color("#c8323c"),
	# damage (Glossary kind damage: #ff9e8a)
	&"true": Color("#f4f4f4"), &"unblockable": Color("#ff9e8a"),
	# conditions (Glossary kind condition: #d8a6e6)
	&"held": Color("#d8a6e6"), &"wound": Color("#d0605a"), &"enraptured": Color("#ee95c0"), &"suspicion": Color("#b07ae8"),
	&"pinged": Color("#62b6e8"), &"concealment": Color("#8a86b8"), &"disabled": Color("#9aa0ae"), &"exhaustion": Color("#c8a87a"),
	&"downed": Color("#ff6b5e"), &"blinded": Color("#e8d8a0"), &"soaked": Color("#68aee8"), &"asleep": Color("#9db4ff"),
	&"self_knowledge": Color("#d8a6e6"), &"aura": Color("#d8a6e6"), &"asphyxia": Color("#8fa3b8"), &"burning_slot": Color("#f08a55"),
	&"perfect": Color("#e8c547"), &"jammed": Color("#d8a6e6"), &"burnout": Color("#c0704a"), &"recovery_endurance": Color("#d8a6e6"),
	&"tapped": Color("#9aa0ae"), &"helpless": Color("#9aa0ae"), &"reduced": Color("#d8a6e6"),
	# whom a skill is used on (Glossary kind target: #c8d0dc; foe and ally as the HUD draws them)
	&"foe": Color("#ff6b5e"), &"ally": Color("#6fdc8c"), &"ally_or_foe": Color("#c8d0dc"), &"self": Color("#c8d0dc"),
	&"tile": Color("#c8d0dc"), &"area": Color("#c8d0dc"), &"nearest": Color("#c8d0dc"), &"range": Color("#c8d0dc"),
}
const NEUTRAL := Color("#c9ccd4")  # a word with no colour, nor a parent with one

# Words too plain to mark what carries them: materials, forms, weights, qualities, stats and generic
# categories. mark() passes over them, so a Metal Ring of fire is trimmed fire, and a plain one not at all.
const PLAIN: Array[StringName] = [&"metal", &"iron", &"cloth", &"padded", &"mail", &"wood", &"stone", &"rock", &"glass",
		&"gem", &"blade", &"book", &"potion", &"ring", &"shackles", &"treat", &"stew", &"heavy", &"medium", &"enchanted",
		&"honed", &"str", &"dex", &"con", &"int", &"wis", &"cha", &"offensive", &"defensive", &"supportive", &"beneficial",
		&"detrimental", &"damage", &"unique", &"finesse", &"bracing", &"tall"]
# Words too broad to say what a blow is made of: a damage floater (HUD) passes over them too.
const BROAD: Array[StringName] = [&"martial", &"magical", &"specialist", &"physical"]


# A tag's colour: its own, else its parent's (a slash is physical's), else NEUTRAL.
static func color(word: StringName) -> Color:
	if word in COLOR:
		return COLOR[word]
	if word in PARENT and PARENT[word] in COLOR:
		return COLOR[PARENT[word]]
	return NEUTRAL


# Whether it has a colour, its own or its parent's (mechanic.py check asks the same of every tag).
static func coloured(word: StringName) -> bool:
	return word in COLOR or (word in PARENT and PARENT[word] in COLOR)


# The tag that marks what carries these: the first with a colour that isn't PLAIN (nor in skip, nor a
# child of something in skip). &"" if none. Item.trim(), the hotbar stripe, damage floaters.
static func mark(tags: Array, skip: Array = []) -> StringName:
	for t: StringName in tags:
		if coloured(t) and t not in PLAIN and t not in skip and PARENT.get(t, &"") not in skip:
			return t
	return &""


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
