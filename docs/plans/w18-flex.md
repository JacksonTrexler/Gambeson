# w18-flex: flex trees offered while levelling; Scout (martial)

User: "Ranger General, Scout Martial: Rogues, Paladins have access to Scout Martial as a flex option. Flex trees reflect backgrounds, professions, hobbies etc that aren't full fledged classes. exclusive flex tree users may make for interesting NPCs or hirelings but generally flex trees are bonuses offered as part of leveling a class. Most classes get one flex tree per 10 levels. Rogues and Bards get one every 5, Adventurers get one every 3. flex trees have prereqs, they are slackened for Rogues and Bards (`generalist`), adventurers and jesters don't have requirements (`jack`)."

## Readings (existing machinery)
- Flex trees today = general tabs with a `SkillTab.grant` key (Student, Journeyman: w5-tree). Opened by `Role.general` (native) or `Unit.grant_tree(key)` (run time, `trees_granted`, saved). Tiers set on branches; tab `category` sets what each tier needs (`Unit._general_need`). No picker (?208 open item).
- `TreeChoice` + `Unit.pick()` + SkillGrid's "PICK UP TO n" box is the only tree picker; picks saved in `Unit.picked` as "Choice/Tree". The Paladin's and Warlock's "Flex" choices are god slots (other trees of god kinds), not general flex trees.
- Levelling: `Unit.level_up()` (+1 skill point, `leveled_up`), MAX_LEVEL 20; the skills screen's LevelUp button.
- Ranger already has a "Scout" root on its own tab (specialist: Hide, Eyes Forward, Wary, Stamina, capstone Survivalist).
- Roles have no tags; units do (`Unit.tags`, `has_tag()` reads unit, items, learned skills).

## Calls
1. **The offer is one TreeChoice per unit, "Flex Tree"** (`Unit.flex_choice()`, not on the Role), drawn by SkillGrid's existing box on the **base General tab** (not the class's own: the Adventurer's own tab is a wheel with no boxes; flex trees are general trees); before a slot it reads "AT LEVEL n"; picking it goes through `Unit.pick()` (key "Flex Tree/<tree>" in `picked`: saved already) and `general_trees()` opens a picked flex tree. Name "Flex Tree", not "Flex", so it never clashes with the Paladin's/Warlock's god-slot "Flex".
2. **Cadence: `Role.flex_every`** (default 10; Rogue, Bard 5; Adventurer 3). Slots = level / flex_every (+ `Unit.flex_extra`). Unspent slots wait. Level 20: most classes 2, Rogue/Bard 4, Adventurer 6.
3. **Which trees: `Role.flex` keys** (Rogue, Paladin: scout). A `jack` unit is offered every grant tree it hasn't natively. A tree the class has natively is never offered.
4. **Prereqs: `SkillTab.needs`, base-stat floors** (a background asks something of who you are). Scout: dexterity 10, wisdom 11 (a starting Paladin, dex 10 wis 11, just meets; made up). **Slackened (`generalist`) = every floor -2** (one mod step). **`jack` = no floors.** Prereq is to take the tree; learning inside still uses the tab's tier gate.
5. **`generalist`, `jack` are tags (mechanic.py, `--human`, kind target), carried by a new `Role.tags`**; `Unit.has_tag()` now reads its role's tags too, so an item or skill carrying `generalist` slackens the same way.
6. **Scout tree**: `Trees/scout.tres` root (name Scout, tag empty so its skills keep their kinds, as Journeyman) in `Trees/general_scout.tres` (kind General, category martial: its tiers need a martial class skill, Rogue's Blade / Paladin's Prowess), grant `scout`. Skills: the Ranger's Scout root minus its capstone (Hide T1, Stamina T1, Eyes Forward T2, Wary T2; tiers made up). Ranger lists `scout` in `general` ("Ranger General"): its Scout skills are already its class's, so the tab duplicates them (shown as GENERAL · SCOUT); the alternative is not listing it.
7. **Student is a Caster/Specialist flex (?199): offered as flex to Wizard, Warlock, Bard** (the user's "Wizards, Warlocks, Bards etc").
8. **Jester hook**: `Unit.flex_needs(t)` (floors after slack: what a page would price), `Unit.flex_extra` (extra slots, saved: what spending stats would buy), `flex_missing(t)`.
9. The Skills icon's badge also lights for a flex tree to take up (`Unit.flex_due()`; one HUD line).
10. Student has no `needs` (none asked).
11. Tool: `role.py flex` writes the root + tab and wires `--native`/`--offer` classes and GENERAL_TREES; `role.py check` checks every flex key names a grant tab.

## As built
Baseline 11088 checks, 0 failed (1047 tests); after 11115, 0 failed (1049 tests).

Files: Scripts/Role.gd (`tags`, `flex`, `flex_every`), SkillTab.gd (`needs`), Unit.gd (FLEX, FLEX_SLACK, `flex_extra` saved, `flex_slots/options/choice/next/due/needs/missing`, `has_tag` reads role tags, `general_trees` opens a flex pick, `pick_missing` flex branch, GENERAL_TREES + Scout), SkillGrid.gd (flex box on base General tab, heading), HUD.gd (badge line), Tags.gd + Glossary.gd (`generalist`, `jack` via mechanic.py), Trees/scout.tres + general_scout.tres (role.py flex), Roles: ranger (general scout), rogue/paladin (flex scout), wizard/warlock/bard (flex student), rogue/bard (generalist, every 5), adventurer (jack, every 3), Util/role.py (`flex` subcommand; check: every General tab in GENERAL_TREES, every Role.flex key names a grant).

Tests: general_test `test_flex_cadence` (11-row table + level_up -> pick -> saved), `test_flex_prereqs` (9-row slack table + pick refused). No existing test changed. Mutations: cadence ignoring flex_every fails 5; FLEX_SLACK 0 fails 4; has_tag without role tags fails 6.
Visual: S/shot_w18-flex (Rogue L5: "FLEX TREE · PICK UP TO 1" box with Sc on General; picked -> GENERAL · SCOUT tab).

**Jester hook (w18-jester):** a page spending base stats calls `flex_needs(t)` to price, lowers stats, then `flex_extra += 1` (saved) and `pick(flex_choice(), t)`; `jack` already waives needs and offers every tree, so a jester page may price by `t.needs` directly.

Note for hosts: `git stash` is repo-wide across worktrees; a sibling's stash was popped into this tree once (reset, nothing lost). Don't stash.

Undone: NPC/hireling exclusive flex users; AI never picks flex trees (authored units can list "Flex Tree/<name>" in picked); the Paladin/Warlock god-slot "Flex" naming vs flex trees is the user's to reconcile.
