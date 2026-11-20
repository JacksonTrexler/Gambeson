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
