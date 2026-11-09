class_name Guide

# How the game is played, a page at a time (Settings: the Guide). Panels link to their page with an
# "i" in a corner (GuideLink); a term clicked in a description opens the page defining it. The
# Checks, Conditions and Ground pages are the Glossary's terms of those kinds.

const HEAD := "[color=#e8c547]%s[/color]"

# id -> [title, BBCode]; in tab order. Glossary pages are filled in by text().
const PAGES := {
	&"play": ["Playing", """[color=#e8c547]Selecting[/color]
Click a unit to select it; Tab steps through the units taking orders. Shift-click a foe to look it over without attacking.

[color=#e8c547]Moving and acting[/color]
With a unit that takes orders selected, hover a tile to plan a move and click to walk there. Click a foe to walk into reach and use slot 1 on it. A number key (or clicking a slot) arms that skill: click its target, or press it again to put it away. A switched passive turns on or off instead. Ctrl-click a tile to strike at whatever may be there; Alt-click casts a Rift unchanneled. Esc or right-click backs out.

[color=#e8c547]Your side[/color]
Allies within your charisma reach take orders. P invites one to your party, which hears you from twice as far. H holds an ally where it is. Space ends the turn; allies you didn't order act on their own. Initiative is each side's d20s plus its best bonus."""],
	&"skills": ["Skills", """[color=#e8c547]Points and ranks[/color]
A skill point comes with each level. Unlocking a skill takes 1; raising one from rank r to r + 1 takes 1 + r². The button in the footer shows the cost in its square, and lights up when you can pay it.

[color=#e8c547]Tiers[/color]
Skills sit in tiers, T0 (what a unit starts with) at the bottom, growing up. A skill's tier is 1 plus the skills learned before it. A skill names what it needs when it can't be learned yet.

[color=#e8c547]Tabs[/color]
Each tab is a tree, in its colour: a class's own, its callings and gods, its species, what it knows, then the general trees on the far right (General, Martial, Specialist, Caster). General-tree skills need 3 skills of their tier or higher; Generalist, Martialist, Journeyman and Thaumaturgist open their trees without that. An Adventurer's own tree is a wheel. A dashed skill isn't built yet.

[color=#e8c547]Reading a skill[/color]
Every skill leads with the same line: its target (Foe, Ally, Self, Tile...), its range, its AP and its cost. In what it does, [color=#eba25e]orange[/color] mods are the user's own, [color=#74b4e8]blue[/color] ones the target's; [color=#e8c547]gold[/color] numbers grow with rank, [color=#9fd6c8]teal[/color] ones say how long. Underlined words are terms: hover one for what it means, click it for its page."""],
	&"hotbar": ["Hotbar", """[color=#e8c547]Spellbook[/color]
B opens the spellbook: every skill a unit knows, by rank. Drag a skill onto a hotbar slot; right-click a slot to empty it. Only your own units' hotbars can be changed.

[color=#e8c547]Slots[/color]
Red, purple and green slots hold only martial, magic and specialist skills. A green-trimmed slot is a lucky unit's clover slot: it greys out while that luck is gone. A dimmed slot is disabled for a while; a quivering one is cursed; a burning one burns whoever uses it."""],
	&"character": ["Character", """[color=#e8c547]Items[/color]
The character sheet shows a unit's weapon, armor and trinket, and the stash. On its side's turn (or once the battle is over) a unit of yours puts items on from the stash, takes them off, or uses up a consumable. In battle, putting on or using an item costs its AP; taking one off is free.

[color=#e8c547]The stash[/color]
Bosses, commanders and won battles give items. Hearts are extra lives."""],
	&"persona": ["Persona", """[color=#e8c547]Personify[/color]
Personify puts forward a persona: how others take a unit. Each persona rank opens more of it: a vibe at I, a stance and a claimed level at II, identity tags and a name to go by at III. Changing it costs Personify's AP.

[color=#e8c547]Fooling[/color]
A unit a persona fools takes it at its word: enraptured while it has no suspicion of it. Suspicion comes in stacks, each making it harder to fool. Showing what it isn't is dissonance, counting against the unit's own rolls."""],
	&"board": ["The board", """[color=#e8c547]Reading the board[/color]
While planning a move, blue tiles are safe, yellow ones unsure and dark red ones known to be bad; a '?' on a move cost means the walk crosses unsure ground. A black shape is something you can't identify; a marked area is where something is only suspected. Hover a tile for its effects.

[color=#e8c547]Rolls[/color]
Attacks and the other checks are a d20 plus a mod; the forecast gives the chance to hit when you can make the target out. The Checks page has each kind."""],
	&"checks": ["Checks", ""],
	&"conditions": ["Conditions", ""],
	&"ground": ["Ground", ""],
}
const GLOSSARY := {&"checks": [&"check", &"damage"], &"conditions": [&"condition"], &"ground": [&"ground"]}


static func ids() -> Array:
	return PAGES.keys()


static func title(id: StringName) -> String:
	return PAGES[id][0] if id in PAGES else ""


# A page's text: its own, or its Glossary terms, each a paragraph.
static func text(id: StringName) -> String:
	if id not in GLOSSARY:
		return PAGES[id][1] if id in PAGES else ""
	return "\n\n".join(terms(id).map(func(t: StringName) -> String:
		return "[color=#%s]%s[/color]  %s" % [Glossary.colour(t).to_html(false), Glossary.name_of(t), Glossary.define(t)]))


# The terms a Glossary page lists, in order.
static func terms(id: StringName) -> Array:
	var kinds: Array = GLOSSARY.get(id, [])
	return Glossary.TERMS.keys().filter(func(t: StringName) -> bool: return Glossary.TERMS[t][1] in kinds)
