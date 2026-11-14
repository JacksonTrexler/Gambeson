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
# each kind in its colour, terms and tags in their own (Tags.color()), terms hoverable for their
# definition and clickable ("term:attack" meta: the Guide's page for it).

const OFFENSE := Color("#eba25e")  # warm: what the user brings
const DEFENSE := Color("#74b4e8")  # cool: what the target resists with
const RANK := Color("#e8c547")
const TIME := Color("#9fd6c8")
const KINDS := {&"check": Color("#f0d48a"), &"damage": Color("#ff9e8a"), &"condition": Color("#d8a6e6"),
		&"ground": Color("#b9cf8a"), &"target": Color("#c8d0dc")}
const PAGES := {&"check": &"checks", &"damage": &"checks", &"condition": &"conditions", &"ground": &"ground", &"target": &"skills"}
# Each term's and tag's colour is Tags.COLOR's (Tags.color()); KINDS is the palette generic terms take.

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
	&"severe": ["Severe", &"check", "Scales with rank: 3 x rank, rounded up."],
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
	&"exhaustion": ["Exhaustion", &"condition", "Each use of a skill a unit hasn't got over adds half that skill's AP and cost to its next use, and counts half against its other skills of the same kind (martial, specialist, magical). A turn's end takes one use off each; resting (not holding a channel) takes off the con mod more, or below 1 a part of one: 1 / (1 - con mod)."],
	&"downed": ["Downed", &"condition", "Down but not out, on its last life: at 0 HP or below it lingers for a few of its side's turns. Healed above 0 it is saved. It dies when its HP passes its limit below 0, or its rounds run out."],
	&"blinded": ["Blinded", &"condition", "Grit in the eyes: its attacks and offensive checks come at a minus."],
	&"soaked": ["Soaked", &"condition", "Drenched and heavy: it moves less."],
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
	&"stamina": ["Stamina", &"check", "A skill that does more when paid with Stamina (an Adventurer's Energy counts, for its martial, specialist and general skills)."],
	&"channeled": ["Channeled", &"condition", "Held by its caster from turn to turn. As each of its turns after the one it was cast in ends, it holds only if the caster met resting's requirements, no AP spent and no move past Meander; otherwise it ends. A channeling unit isn't resting: keeping the channel is what it gets instead of rest's benefits. Cast again to stop it, free."],
	&"jammed": ["Jammed ??", &"condition", "Interrupted, it has lost its reactions until its next turn is over: it can't dodge, so all of an evadable attack lands, it can't guard behind its shield, and it doesn't obstruct its foes."],
	&"siphon": ["Siphon", &"damage", "Its damage comes off the target's resources instead of its HP: its Overcharge first, then what it last paid from, then Energy, then its other reserves. Power is easier to siphon: half again as much."],
	&"overcharge": ["Overcharge", &"condition", "An extra buffer of Energy, spent before any of its own on a cost - and counted toward what it can afford. It decays to nothing over the turns it was given for, the turn it came not counting."],
	&"aquatic": ["Aquatic", &"condition", "At home in water: a step into water costs it 1 movement, however deep, and nothing slows it there; it can't be drowned. The Aquatic property gives it; so does a Druid's Pike form."],
	&"burnout": ["Burnout", &"condition", "Recovering Energy or HP by any means but resting wears a unit out. Each Energy grant spends 1 Recovery Endurance; with none left, every recovery asks a con check (DC 12), and failing cuts that pool's max by 10% x (1 + |RE|) of what came back, lasting. One heal of more than con mod x 20% of max HP asks a con check against the excess: failing costs 1 RE."],
	&"recovery_endurance": ["Recovery Endurance", &"condition", "RE: how many recoveries a unit takes before Burnout bites - max(con mod, 0) as a battle starts, back in full after a resting turn ended at full Energy. It can run below 0."],
	&"tapped": ["Tapped", &"condition", "Can't act and takes no orders: out of AP, ordered as far as its leader allows this turn, or helpless with nothing that lets it act. Not an effect: it lifts the moment its cause does."],
	&"helpless": ["Helpless", &"condition", "Can't act, move, take or give orders, dodge, guard or obstruct: tapped while it lasts, unless something lets it act in a reduced capacity. Stunned, asleep, and Downed without a will to fight on are helpless."],
	&"taps": ["Taps", &"check", "A check that can leave its loser tapped, such as resisting a stun. Whatever helps against such checks helps against every one of them."],
	&"reduced": ["Reduced capacity ??", &"condition", "Acting where it would otherwise be tapped, by a permit such as Mindless Fury or Drone: fewer actions, or its mental stats held down."],
	&"enchanted": ["Enchanted", &"condition", "Blessed gear (or a skill that is): rank +1. Pray makes it; honed is the material kind and never counts."],
	&"honed": ["Honed", &"condition", "Material perfection: rank +1, and none of what enchanted does. Never both."],
	&"bless": ["Bless", &"condition", "A divine buff: a Downed unit under it recovers HP each turn, executes against it go by its full HP, and checks that would tap or execute it get its rank. Intervention gives it."],
	&"execute": ["Execute", &"check", "An instant death check, cut by how hurt its target is: HP left over max HP, over its rank. Whatever helps against such checks helps against every one of them."],
	&"ambush": ["Ambush", &"check", "An attack made from concealment, or by one its target cannot see or place. Effects and skills tagged ambush count on it."],
}

# Terms registered while the game runs (a mod's, a test's throwaway tag): id -> [name, kind, definition],
# read wherever a term's kind is asked (kind()), so a rule keyed on kinds takes them with no code change.
static var added := {}


# What a blow is made of, damage in kind though they have no Glossary term: elements and blows (Tags.COLOR's
# first group).
const DAMAGE_TAGS: Array[StringName] = [&"fire", &"water", &"earth", &"light", &"dark", &"energy", &"love", &"ice",
		&"wind", &"air", &"nature", &"sound", &"star", &"astral", &"magical", &"physical", &"slash", &"pierce", &"blunt", &"bludgeon"]


# A term's kind (check, damage, condition, ground, target): TERMS first, then added; a blow's stuff
# (DAMAGE_TAGS) is damage; "" for a word it doesn't know.
static func kind(id: StringName) -> StringName:
	if id in TERMS:
		return TERMS[id][1]
	if id in added:
		return added[id][1]
	if id in DAMAGE_TAGS:
		return &"damage"
	return &""


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
	return Tags.color(id)


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
	return "[color=#%s]%s[/color]" % [Tags.color(StringName(what)).to_html(false), shown]


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
