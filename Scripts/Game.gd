class_name Game

# Choices made before a battle (the entry screen) that the battle picks up. Static, so it
# survives scene changes without an autoload.
static var starter := {}  # {faction: Faction, role: Role, name: String}
static var difficulty := 0.0  # the area difficulty of the floor of Gamut's Tower the portal taken stands on (Battle.difficulty); 0: the scene's own
static var dungeon: Dungeon  # the dungeon entered at Gamut's Tower: what winning it brings there (Meadows: Battle.rewards)
static var hero := {}  # the player's starter as picked - {faction: Faction, role: Role, name: String} - kept for the save (Save) after Battle uses `starter` up; Entry's Continue plays it again
static var outfit := {}  # what the player's starter has on, by slot (weapon, armor, trinket): it keeps it from battle to battle
static var level := 1  # the player's starter's level, and its XP toward the next (Battle._award()): kept from battle to battle
static var xp := 0
static var hearts := 0  # extra lives the starter has been given for good (a Heart)
static var lapses := {}  # the starter's Unit.lapses_out() (leaned, waived), kept with the save so what it learned on a lent skill still lapses
static var equipped: Array = []  # the player's starter's hotbar, skill by slot (null empty): it keeps what it equipped from battle to battle (Unit.set_equipped())
static var stash: Array[Item] = []  # items the player's side has won (Battle.spoils), to equip or use between and in battles
# The player's persistent units, each a Unit.to_dict(): the hero (the leader) first, then those it can bring along
# (Entry: one of each other starting class). Kept between battles and in the save; the fields above (level, xp, outfit,
# hearts, equipped, lapses) are the leader's own, kept live as before, and win over its entry where both say.
static var roster: Array[Dictionary] = []
static var party: Array[int] = []  # the roster entries a battle fields (the Party screen): 0, the leader, always among them; at most party_size()
static var fielded := {}  # roster index -> the Unit standing for it in the battle now (Battle._field_party()): keep() reads them back


# How many the Party holds, the leader among them: its base charisma mod if positive (at least +0), plus its
# level / 4 (at least 1). A size of 1 is the leader going solo: no one to bring (?216).
static func party_size(lvl: int, charisma: int) -> int:
	return maxi(floori((charisma - 10) / 2.0), 0) + maxi(lvl / 4, 1)


# The Party's size for the leader: Game.level, and the charisma its class gives (a unit's base score: nothing
# raises it in play but effects, which don't count here).
static func leader_party_size() -> int:
	var r: Variant = hero.get("role")
	return party_size(level, r.stats.get(&"charisma", 10) if r else 10)


# The party as it stands: valid roster indices, the leader first, cut to the size it may have.
static func party_now() -> Array[int]:
	var out: Array[int] = []
	if not roster.is_empty():
		out.append(0)
	for i in party:
		if i > 0 and i < roster.size() and i not in out and out.size() < leader_party_size():
			out.append(i)
	return out


# Each fielded unit's state back into its roster entry (Save.pack(), and as the battle leaves the tree; the battle's
# end saves).
# The leader's lapses_out() is its own too (Game.lapses), as its bar is (HUD._keep_bar()).
static func keep() -> void:
	var lead: Variant = fielded.get(0)
	if is_instance_valid(lead):
		lapses = lead.lapses_out()
	for i in fielded:
		var u: Variant = fielded[i]
		if is_instance_valid(u) and i < roster.size():
			roster[i] = u.to_dict()


# Back to a new game's start (Save.erase()).
static func reset() -> void:
	starter = {}
	difficulty = 0.0
	dungeon = null
	hero = {}
	outfit = {}
	level = 1
	xp = 0
	hearts = 0
	stash = []
	lapses = {}
	equipped = []
	roster = []
	party = []
	fielded = {}
