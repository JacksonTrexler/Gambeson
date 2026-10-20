class_name Game

# Choices made before a battle (the entry screen) that the battle picks up. Static, so it
# survives scene changes without an autoload.
static var starter := {}  # {faction: Faction, role: Role, name: String}
