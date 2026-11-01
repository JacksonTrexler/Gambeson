class_name Game

# Choices made before a battle (the entry screen) that the battle picks up. Static, so it
# survives scene changes without an autoload.
static var starter := {}  # {faction: Faction, role: Role, name: String}
static var outfit := {}  # what the player's starter has on, by slot (weapon, armor, trinket): it keeps it from battle to battle
static var hearts := 0  # extra lives the starter has been given for good (a Heart)
static var stash: Array[Item] = []  # items the player's side has won (Battle.spoils), to equip or use between and in battles
