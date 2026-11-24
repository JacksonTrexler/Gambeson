class_name Bio
extends Resource

# Who a unit is, past its stats (Unit.bio): how it behaves, how it looks, what it's made of and whom it
# has standing with. Scenes/<unit>.tscn carry one; Util/unit.py new writes it.
#   behaviour   drives its AI (AI.act()): timid waits for a stronger ally and backs off the aggressive;
#               brave charges the strongest; aggressive presses the weakest and heals last; helpful goes
#               to the wounded to heal them; stoic does as little as it can - holds, striking what comes;
#               vindictive holds grudges - goes after whoever landed blows on it or its side this fight (Unit.wrongs),
#               and whoever its grudges name; flirty aids, and only softly strikes, whom it fancies (AI._fancies());
#               flippant skirts the field aimlessly, out of reach, until it has lost FLIPPANT of its max HP this
#               fight (Unit.harmed), then turns aggressive (Unit.temper()); power hungry steps beside whoever holds
#               the most Power (else Energy, else reserves) and drains it, foes and neutrals alike (AI._feed());
#               pragmatic heals by cost (Unit.tends); compliant goes for whom its leader goes for, or would (AI._orders());
#               hungry wants skills that give back what they take (drain, siphon) on whoever they take most from (AI._hungry()).
#   also        further behaviours beside `behaviour`, each as it would add to that one (Unit.tempered(): a Starman is
#               flippant, and vindictive and power hungry besides)
#   appearance  what it looks like at a glance (Soldier, Knight, Caster): who can't make out its class
#   adjectives  goes by this, with the adjectives before it ("Injured Soldier"), and guesses from them
#               (Perception.looks(), AI._level()).
#   properties  what it's made of or full of (Aquatic, Rotting): their effects are always on it.
#   prefers     what it leans toward as it spends skill points (Unit.auto_spec()): skill tags (fire, healing), postures
#               (offensive, supportive, defensive) or kinds (active, passive, toggle). Plain words an item may add to.
#   spec        how it spends them: exploratory (new skills), training (ranks in those it has), remedial (what its
#               make-up holds least of); empty: its class tree, cheapest first. Outside its class tree only for a preference.
#   favours     gods it holds dear (God ids; a book's deity+): a unit with no god of its own prays to the first (Unit.deity()),
#               and spends skill points toward their domains (Unit.auto_spec(): God.tag)
#   clout       standing with a side: to that side's units its persona goes this much further (allies)
#               or its trickery does (foes), and doubting it is that much harder (Battle.doubt()).

const BEHAVIOURS: Array[StringName] = [&"timid", &"brave", &"aggressive", &"helpful", &"stoic", &"vindictive", &"flirty", &"flippant", &"power_hungry", &"pragmatic", &"compliant", &"hungry"]
const SPECS: Array[StringName] = [&"exploratory", &"training", &"remedial"]  # how it spends skill points (spec; Unit.auto_spec())
const FLIPPANT := 0.18  # the share of its max HP a flippant unit loses in a fight before it turns aggressive (Unit.temper())
# A temper in a few words (the Guide's character page). Keyed by BEHAVIOURS; bio_test checks they match.
const TEMPERS := {&"timid": "waits for a stronger ally, backs off", &"brave": "charges the strongest", &"aggressive": "presses the weakest",
	&"helpful": "heals the wounded", &"stoic": "holds, strikes what comes", &"vindictive": "goes after whoever hurt it or its own",
	&"flirty": "aids, and only softly strikes, whom it fancies", &"flippant": "skirts the field aimlessly until it has lost 18% of its HP, then presses",
	&"power_hungry": "drains whoever holds the most Power, if confident or oblivious", &"pragmatic": "heals by cost, where it counts",
	&"compliant": "goes for whom its leader goes for", &"hungry": "feeds on what its blows give back"}
# How much stronger than itself an observer takes one of each appearance to be, in levels, when it
# can't read the level (AI._level()). Unlisted: as strong as itself.
const STANDING := {"knight": 2, "soldier": 1, "brute": 1, "beast": 1, "caster": 0, "scout": 0, "tradefolk": -1, "everyman": -1}
# What an adjective makes an observer guess: aura (as Unit.aura, -2 ominous .. +2 benevolent) where it
# can't read one, standing (levels, on top of the appearance's), hurt (taken for bloodied).
const ADJECTIVES := {
	"beautiful": {aura = 1}, "precious": {aura = 1}, "radiant": {aura = 1},
	"horrific": {aura = -1, standing = 1}, "repulsive": {aura = -1}, "rotting": {aura = -1},
	"injured": {standing = -1, hurt = true},
}

@export var behaviour := &""  # one of BEHAVIOURS; empty: none in particular (Unit.behaviour's specials still apply)
@export var also: Array[StringName] = []  # more of BEHAVIOURS, beside `behaviour` (Unit.tempered())
@export var appearance := ""  # "Knight"; empty: its class's noun (Role.noun)
@export var adjectives: Array[String] = []  # "Beautiful", "Horrific", "Injured", "Repulsive"
@export var properties: Array[Property] = []  # Properties/*.tres: Aquatic, Energized, Radiant, Rotting
@export var clout: Dictionary[Faction, int] = {}  # side -> standing with it
@export var grudges: Array[String] = []  # whom a vindictive one goes after on sight: a name, class, race, identity tag or look ("Starman", "undead"; names())
@export var fancies: Array[String] = []  # whom a flirty one feels for (names()); none: anyone of high charisma (AI._fancies())
@export var prefers: Array[StringName] = []  # tags, postures or kinds of skill it spends its points toward (Unit.auto_spec())
@export var favours: Array[StringName] = []  # gods it holds dear (God ids: a book's deity+): Unit.deity() when it has none, the domains it spends points toward
@export var spec := &""  # one of SPECS; empty: its class tree, cheapest first
@export_multiline var text := ""  # a line or two about it, shown on its own sheet


# What a book's tweak ({kind, word}: behaviour, prefers or favours, Item.tweaks()) changes in a bio, plain words in its lists.
const TWEAKS: Array[StringName] = [&"behaviour", &"prefers", &"favours"]


# Whether b (null: none) already has tweak t: its behaviour or one of its tempers, a preference, a favoured god.
static func holds(b: Bio, t: Dictionary) -> bool:
	if b == null:
		return false
	match t.kind:
		&"behaviour":
			return b.behaviour == t.word or t.word in b.also
		&"prefers":
			return t.word in b.prefers
		&"favours":
			return t.word in b.favours
	return true


# A copy of b (a scene's bio is shared among its units; null: a fresh one) with tweak t on it: a behaviour is its lead temper if it
# has none, else one more beside it (also); a preference or a god joins its list. One it holds already comes back as it is.
static func tweaked(b: Bio, t: Dictionary) -> Bio:
	var out: Bio = b.duplicate() if b else Bio.new()
	if holds(b, t):
		return out
	match t.kind:
		&"behaviour":
			if out.behaviour == &"":
				out.behaviour = t.word
			else:
				out.also = _added(out.also, t.word)
		&"prefers":
			out.prefers = _added(out.prefers, t.word)
		&"favours":
			out.favours = _added(out.favours, t.word)
	return out


# What a player's unit keeps of its bio between battles, as plain JSON (Unit.to_dict(): its books' tweaks), and back (null: nothing).
func kept() -> Dictionary:
	return {behaviour = str(behaviour), also = also.map(str), prefers = prefers.map(str), favours = favours.map(str)}


static func from_kept(d: Variant) -> Bio:
	if not d is Dictionary or d.is_empty():
		return null
	var out := Bio.new()
	out.behaviour = StringName(str(d.get("behaviour", "")))
	for k in ["also", "prefers", "favours"]:
		var l: Array[StringName] = []
		for w in d.get(k, []):
			l.append(StringName(str(w)))
		out.set(k, l)
	return out


static func _added(list: Array[StringName], w: StringName) -> Array[StringName]:
	var out: Array[StringName] = list.duplicate()
	out.append(w)
	return out


# Whether any of words names the unit read as r: a word of its name or looks, its class, its identity tags (race, role, unit tags).
static func names(words: Array[String], r: Read) -> bool:
	if words.is_empty() or r == null:
		return false
	var its := PackedStringArray()
	for w in (r.name + " " + r.looks).to_lower().split(" ", false):
		its.append(w)
	for t in r.tags:
		its.append(String(t).to_lower())
	if r.role:
		its.append(r.role.name.to_lower())
	return words.any(func(w: String): return w.to_lower() in its)


# Levels more (or less) than itself an observer guesses one looking like this to be ("Injured Knight": 1).
static func standing(looks: String) -> int:
	var n := 0
	for w in looks.to_lower().split(" ", false):
		n += STANDING.get(w, 0) + ADJECTIVES.get(w, {}).get("standing", 0)
	return n


# The aura one looking like this seems to give off: its adjectives' (Repulsive -1), clamped to -2..2.
static func aura(looks: String) -> int:
	var n := 0
	for w in looks.to_lower().split(" ", false):
		n += ADJECTIVES.get(w, {}).get("aura", 0)
	return clampi(n, -2, 2)


# Whether one looking like this looks hurt ("Injured").
static func hurt(looks: String) -> bool:
	return Array(looks.to_lower().split(" ", false)).any(func(w: String): return ADJECTIVES.get(w, {}).get("hurt", false))


# A unit's bio as its viewer may know it, in Glossary markup: temper, what it looks like (adjectives and
# appearance), what it's made of. r is the viewer's Read of it (Battle.read()), null for the viewer's own.
# A foe the viewer can't name shows nothing; one a persona fools shows the persona's looks and no temper
# or properties; else temper and properties as the Read allows them (an insightful viewer, its identity).
static func line(t: Unit, r: Read = null) -> String:
	var temper: StringName = t.temper()
	var looks: Array[String] = []
	var props: Array[String] = []
	if r:
		if r.name == "":
			return ""
		temper = r.temper
		if r.deceived:
			temper = &""
			looks.assign(t.shows_adjectives)
			if t.alias_noun:
				looks.append(t.alias_noun)
		elif t.bio:
			looks.assign(t.bio.adjectives)
			looks.append(Perception.kind_noun(t))
		if not r.deceived:
			props.assign(r.properties.map(func(p: Property) -> String: return p.name))
	else:
		looks.assign(t.bio.adjectives if t.bio else [])
		if t.bio and t.bio.appearance:
			looks.append(t.bio.appearance)
		props.assign(t.bio.properties.map(func(p: Property) -> String: return p.name) if t.bio else [])
	var out: PackedStringArray = []
	if temper:
		out.append("{x:%s|%s}" % [temper, String(temper).capitalize()])
	if not looks.is_empty():
		out.append(" ".join(looks))
	for p in props:
		out.append("{x:%s|%s}" % [p.to_lower(), p])
	return " · ".join(out)
