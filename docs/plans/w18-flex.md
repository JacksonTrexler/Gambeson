# w18-flex: flex trees offered while levelling; Scout (martial)

User: "Ranger General, Scout Martial: Rogues, Paladins have access to Scout Martial as a flex option. Flex trees reflect backgrounds, professions, hobbies etc that aren't full fledged classes. exclusive flex tree users may make for interesting NPCs or hirelings but generally flex trees are bonuses offered as part of leveling a class. Most classes get one flex tree per 10 levels. Rogues and Bards get one every 5, Adventurers get one every 3. flex trees have prereqs, they are slackened for Rogues and Bards (`generalist`), adventurers and jesters don't have requirements (`jack`)."

## Readings (existing machinery)
- Flex trees today = general tabs with a `SkillTab.grant` key (Student, Journeyman: w5-tree). Opened by `Role.general` (native) or `Unit.grant_tree(key)` (run time, `trees_granted`, saved). Tiers set on branches; tab `category` sets what each tier needs (`Unit._general_need`). No picker (?208 open item).
- `TreeChoice` + `Unit.pick()` + SkillGrid's "PICK UP TO n" box is the only tree picker; picks saved in `Unit.picked` as "Choice/Tree". The Paladin's and Warlock's "Flex" choices are god slots (other trees of god kinds), not general flex trees.
- Levelling: `Unit.level_up()` (+1 skill point, `leveled_up`), MAX_LEVEL 20; the skills screen's LevelUp button.
- Ranger already has a "Scout" root on its own tab (specialist: Hide, Eyes Forward, Wary, Stamina, capstone Survivalist).
- Roles have no tags; units do (`Unit.tags`, `has_tag()` reads unit, items, learned skills).

## Calls
1. **The offer is one TreeChoice per unit, "Flex Tree"** (`Unit.flex_choice()`, not on the Role), drawn by SkillGrid's existing box on the class's own tab; picking it goes through `Unit.pick()` (key "Flex Tree/<tree>" in `picked`: saved already) and `general_trees()` opens a picked flex tree. Name "Flex Tree", not "Flex", so it never clashes with the Paladin's/Warlock's god-slot "Flex".
2. **Cadence: `Role.flex_every`** (default 10; Rogue, Bard 5; Adventurer 3). Slots = level / flex_every (+ `Unit.flex_extra`). Unspent slots wait. Level 20: most classes 2, Rogue/Bard 4, Adventurer 6.
3. **Which trees: `Role.flex` keys** (Rogue, Paladin: scout). A `jack` unit is offered every grant tree it hasn't natively. A tree the class has natively is never offered.
4. **Prereqs: `SkillTab.needs`, base-stat floors** (a background asks something of who you are). Scout: dexterity 10, wisdom 11 (a starting Paladin, dex 10 wis 11, just meets; made up). **Slackened (`generalist`) = every floor -2** (one mod step). **`jack` = no floors.** Prereq is to take the tree; learning inside still uses the tab's tier gate.
5. **`generalist`, `jack` are tags (mechanic.py, `--human`, kind target), carried by a new `Role.tags`**; `Unit.has_tag()` now reads its role's tags too, so an item or skill carrying `generalist` slackens the same way.
6. **Scout tree**: `Trees/scout.tres` root (name Scout, tag empty so its skills keep their kinds, as Journeyman) in `Trees/general_scout.tres` (kind General, category martial: its tiers need a martial class skill, Rogue's Blade / Paladin's Prowess), grant `scout`. Skills: the Ranger's Scout root minus its capstone (Hide T1, Stamina T1, Eyes Forward T2, Wary T2; tiers made up). Ranger lists `scout` in `general` ("Ranger General"): its Scout skills are already its class's, so the tab duplicates them (shown as GENERAL · SCOUT); the alternative is not listing it.
7. **Student is a Caster/Specialist flex (?199): offered as flex to Wizard, Warlock, Bard** (the user's "Wizards, Warlocks, Bards etc").
8. **Jester hook**: `Unit.flex_needs(t)` (floors after slack: what a page would price), `Unit.flex_extra` (extra slots, saved: what spending stats would buy), `flex_missing(t)`.
9. Tool: `role.py flex` writes the root + tab and wires `--native`/`--offer` classes and GENERAL_TREES; `role.py check` checks every flex key names a grant tab.

## As built
(pending)
