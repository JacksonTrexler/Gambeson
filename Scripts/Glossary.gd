class_name Glossary

# The game's terms, each defined once (TERMS) and explained on its Guide page, so a skill or tile says
# "Save" or "Burning" rather than how the dice fall. Descriptions are written in a light markup naming
# what each piece is:
#   {k:attack}       a term, by its name ({k:attack|Attacks}: in other words)
#   {o:str mod}      a mod of whoever uses it - offense
#   {d:wis mod}      a mod of whoever it's used on - defense
#   {r:3}            a number that grows with rank
#   {t:3 turns}      how long
#   {x:fire}         a damage tag
# plain() reads it as plain text (tests, the spellbook's lines); rich() as BBCode for a RichTextLabel:
# each kind in its colour, terms hoverable for their definition and clickable ("term:attack" meta: the
# Guide's page for it).

const OFFENSE := Color("#eba25e")  # warm: what the user brings
const DEFENSE := Color("#74b4e8")  # cool: what the target resists with
const RANK := Color("#e8c547")
const TIME := Color("#9fd6c8")
const TAG := Color("#c9ccd4")
const KINDS := {&"check": Color("#f0d48a"), &"damage": Color("#ff9e8a"), &"condition": Color("#d8a6e6"),
		&"ground": Color("#b9cf8a"), &"target": Color("#c8d0dc")}
const PAGES := {&"check": &"checks", &"damage": &"checks", &"condition": &"conditions", &"ground": &"ground", &"target": &"skills"}
const ELEMENTS := {&"fire": Color("#f08a55"), &"light": Color("#f2e39a"), &"dark": Color("#9d8fe0"), &"water": Color("#68aee8"),
		&"earth": Color("#c49a66"), &"energy": Color("#6fd8e4"), &"love": Color("#ee95c0"), &"magical": Color("#b49ae6"),
		&"physical": Color("#d0d0d0"), &"slash": Color("#d0d0d0"), &"pierce": Color("#d0d0d0"), &"blunt": Color("#d0d0d0")}

# id -> [name, kind, definition]. Definitions keep clear of square brackets (BBCode).
const TERMS := {
	&"attack": ["Attack", &"check", "d20 + the attacker's mod, against the target's Defense: meeting it hits. A natural 20 is a Critical."],
	&"critical": ["Critical", &"check", "A natural 20 on an attack: double damage."],
	&"advantage": ["Advantage", &"check", "Two d20s rolled; the better counts."],
	&"disadvantage": ["Disadvantage", &"check", "Two d20s rolled; the worse counts."],
	&"save": ["Save", &"check", "The target rolls d20 + its own mod against d20 + the user's mod and the skill's rank. Failing, it takes the effects."],
	&"contest": ["Contest", &"check", "Both roll d20 + their mods; the higher wins."],
	&"check": ["Check", &"check", "d20 + the mod named, against what the skill says."],
	&"last_stand": ["Last Stand", &"check", "A foe's resistance to being undone: d20 + its average stat mod."],
	&"investigate": ["Investigate", &"check", "d20 + wis mod to see through a disguise, a persona or what's hidden."],
	&"defense": ["Defense", &"check", "What an attack must meet to hit: set by armor, plus what raises it."],
	&"mod": ["Mod", &"check", "A stat's modifier: (stat - 10) / 2, rounded down. Orange mods are the user's own; blue ones, the target's."],
	&"evadable": ["Evadable", &"check", "A dex check can dodge it: passing, none of it lands; failing by a quarter of the DC or less, half of it."],
	&"trivial": ["Trivial", &"check", "A check anyone makes: DC 1."],
	&"easy": ["Easy", &"check", "DC (rank + 1) + rank, or 4 without a rank."],
	&"approachable": ["Approachable", &"check", "DC (rank + 2) + rank x 2, or 8 without a rank. Picking a lock: a rogue of about its rank manages."],
	&"standard": ["Standard", &"check", "DC (rank + 3) + rank x 2, or 12 without a rank."],
	&"difficult": ["Difficult", &"check", "DC (rank + 4) + rank x 3, or 16 without a rank."],
	&"unfair": ["Unfair", &"check", "DC (rank + 5) + rank x 3, or 20 without a rank. Prying apart shackles built not to break."],
	&"impossible": ["Impossible", &"check", "DC (rank + 6) + rank x 3, or 30 without a rank."],
	&"intense": ["Intense", &"check", "Scales with rank: 2.5 x rank, rounded up."],
	&"extreme": ["Extreme", &"check", "Scales with rank: 3 x rank, rounded up."],
	&"true": ["True", &"damage", "Damage nothing reduces or redirects: it goes straight to HP."],
	&"unblockable": ["Unblockable", &"damage", "Damage mitigation doesn't reduce."],
	&"drain": ["Drain", &"damage", "Energy damage takes Energy (or Power) first; only what's past it reaches HP."],
	&"held": ["Held", &"condition", "Grappled: moving away first takes movement and a contest to break free. Each turn it ends held, it takes its holder's grip."],
	&"wound": ["Wound", &"condition", "A lasting hurt with a rank; a heal clearing at least that rank takes it off."],
	&"enraptured": ["Enraptured", &"condition", "Fooled by a unit's persona, with no suspicion of it."],
	&"suspicion": ["Suspicion", &"condition", "Stacks of doubt about a unit's persona: each makes it harder to fool."],
	&"pinged": ["Pinged", &"condition", "Sensed by a channeled Clairvoyance: a foe out of sight shown as a black shape where it was last sensed. Only where, not who or what side; gone once the channel ends."],
	&"concealment": ["Concealment", &"condition", "Levels of hiding: what's under it must be investigated past them to be seen."],
	&"disabled": ["Disabled", &"condition", "A skill slot switched off for some turns. A cursed one quivers."],
	&"exhaustion": ["Exhaustion", &"condition", "Each use of a skill a unit hasn't got over adds half that skill's AP and cost to its next use, and counts half against its other skills of the same kind (martial, specialist, magical). A turn's end takes one use off each; resting takes off the con mod more, or below 1 a part of one: 1 / (1 - con mod)."],
	&"downed": ["Downed", &"condition", "Down but not out, on its last life: at 0 HP or below it lingers for a few of its side's turns. Healed above 0 it is saved. It dies when its HP passes its limit below 0, or its rounds run out."],
	&"asleep": ["Asleep", &"condition", "Can't act. An ally ending the turn beside it wakes it for the next one."],
	&"self_knowledge": ["Self-knowledge", &"condition", "How well a unit knows itself, in levels: a Meditation shifts its stats no further than it knew itself before."],
	&"aura": ["Aura", &"condition", "Used on itself, it goes on allies within range too."],
	&"asphyxia": ["Asphyxia", &"condition", "Stacks of max HP gone; they start falling after a few turns."],
	&"burning_slot": ["Burning slot", &"condition", "A hotbar slot on fire: using the skill in it burns its user."],
	&"perfect": ["Perfect", &"condition", "36 Strike hits in a row: 300 HP healed at once."],
	&"burning": ["Burning", &"ground", "Ground on fire: fire damage to whoever enters it or ends a turn there."],
	&"submerged": ["Submerged", &"ground", "Under water deeper than the unit's size (Medium is 3; a Pond is 5, Shallows 1, a Flood its rank), or engulfed by whoever holds it on its own tile. Only the submerged can be drowned."],
	&"flood": ["Flood", &"ground", "Water laid over a tile, its rank its depth: it slows movement, puts out fire, and drains away once its rounds are up."],
	&"drowning": ["Drowning", &"condition", "Held and submerged: damage each turn it ends that way, until it breaks free or gets its head above water."],
	&"trap": ["Trap", &"ground", "Hidden harm under a tile, sprung by whoever steps in. Its setter's side may know where."],
	&"sticky": ["Sticky", &"ground", "Ground that takes more movement to leave."],
	&"disturbed_earth": ["Disturbed earth", &"ground", "Ground that costs its maker's enemies 50% more to enter."],
	&"darkness": ["Darkness", &"ground", "Ground that conceals whoever stands in it."],
	&"starpane": ["Starpane", &"ground", "A pane of the star lattice, carrying starpower between sources. A bludgeoning blow breaks it."],
	&"on_enter": ["On entering", &"ground", "Put on whoever steps onto the tile."],
	&"layer": ["Layer", &"ground", "Laid over a tile's ground. A unit deals with the top layer only, unless it lets through."],
	&"lets_through": ["Lets through", &"ground", "Whoever is on it deals with what's beneath it too: leaves, an overlay starpane."],
	&"obscuring": ["Obscuring", &"ground", "What's beneath can't be made out until someone stands on it. Stepping in blind, checks the ground beneath imposes come at disadvantage."],
	&"cover": ["Cover", &"ground", "Advantage to concealment checks made on it."],
	&"brittle": ["Brittle", &"ground", "Blunt damage breaks it - aimed at it, over an area, or at whoever stands on it. Whoever stood on it lands on what's beneath."],
	&"unstable": ["Unstable", &"ground", "Ending a turn on it without resting, having moved more than your dex mod in tiles, breaks it. A dex check: fail and you drop to what's beneath; pass and you're spared it while you move off."],
	&"flammable": ["Flammable", &"ground", "Fire burns it away and sets the tile alight."],
	&"windswept": ["Windswept", &"ground", "Wind blows it away."],
	&"repairing": ["Repairing", &"ground", "Mending from a nearby power source: a round for each tile between them."],
	&"turn_end": ["At turn end", &"ground", "Put on whoever ends a turn on the tile."],
	&"foe": ["Foe", &"target", "Used on an enemy unit."],
	&"ally": ["Ally", &"target", "Used on a unit of its own side, itself too."],
	&"ally_or_foe": ["Ally or foe", &"target", "Used on anyone: what it does may differ by side."],
	&"self": ["Self", &"target", "Used on its user alone."],
	&"tile": ["Tile", &"target", "Aimed at a tile rather than a unit."],
	&"area": ["Area", &"target", "Aimed at a tile, working on the ground around it."],
	&"nearest": ["Nearest", &"target", "Used at once, landing on the nearest units in range."],
	&"range": ["Range", &"target", "How many tiles away it reaches, before reach and size. Gold parts grow with rank; orange ones are the user's mods."],
}

static var _token := RegEx.create_from_string("\\{([kodrtx]):([^}|]+)(?:\\|([^}]+))?\\}")


# A term's token: "{k:save}", or "{k:save|saves}" shown as other words.
static func term(id: StringName, shown := "") -> String:
	assert(id in TERMS, "no term %s" % id)
	return "{k:%s%s}" % [id, "|" + shown if shown else ""]


# A stat's mod, by its full or short name: "{o:str mod}" (the user's), "{d:wis mod}" (the target's).
static func mod(stat: StringName, defending := false) -> String:
	return "{%s:%s mod}" % ["d" if defending else "o", String(stat).left(3)]


static func name_of(id: StringName) -> String:
	return TERMS[id][0] if id in TERMS else String(id).capitalize()


static func define(id: StringName) -> String:
	return TERMS[id][2] if id in TERMS else ""


static func colour(id: StringName) -> Color:
	return KINDS[TERMS[id][1]] if id in TERMS else TAG


# The Guide page a term is explained on.
static func page(id: StringName) -> StringName:
	return PAGES[TERMS[id][1]] if id in TERMS else &""


static func plain(text: String) -> String:
	var out := ""
	var at := 0
	for m in _token.search_all(text):
		out += text.substr(at, m.get_start() - at) + _shown(m)
		at = m.get_end()
	return out + text.substr(at)


static func rich(text: String) -> String:
	var out := ""
	var at := 0
	for m in _token.search_all(text):
		out += _escape(text.substr(at, m.get_start() - at)) + _bbcode(m)
		at = m.get_end()
	return out + _escape(text.substr(at))


static func _shown(m: RegExMatch) -> String:
	if m.get_string(3):
		return m.get_string(3)
	return name_of(StringName(m.get_string(2))) if m.get_string(1) == "k" else m.get_string(2)


static func _bbcode(m: RegExMatch) -> String:
	var shown := _escape(_shown(m))
	var what := m.get_string(2)
	match m.get_string(1):
		"k":
			return "[url=term:%s][hint=\"%s\"][color=#%s]%s[/color][/hint][/url]" % [what, define(StringName(what)).replace("\"", ""), colour(StringName(what)).to_html(false), shown]
		"o":
			return "[color=#%s]%s[/color]" % [OFFENSE.to_html(false), shown]
		"d":
			return "[color=#%s]%s[/color]" % [DEFENSE.to_html(false), shown]
		"r":
			return "[color=#%s]%s[/color]" % [RANK.to_html(false), shown]
		"t":
			return "[color=#%s]%s[/color]" % [TIME.to_html(false), shown]
	return "[color=#%s]%s[/color]" % [ELEMENTS.get(StringName(what), TAG).to_html(false), shown]


static func _escape(s: String) -> String:
	return s.replace("[", "[lb]")


# A rich-text tooltip for markup (SkillGrid, SkillWheel, SkillSlot, SkillEntry: _make_custom_tooltip).
static func tooltip(text: String) -> Control:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	var long := text.length() > 48 or "\n" in text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if long else TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = 180 if long else 0
	l.text = rich(text)
	return l
