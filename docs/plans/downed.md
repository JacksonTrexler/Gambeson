# Downed (down but not out): plan and progress

Branch `r-downed`. One mechanism any skill configures by data; Tenacity and Grudge are its first users.

## The rules

- A skill may carry a Downed rule (`Skill.downed`, a `Downed` resource): rounds per rank, negative-HP limit per rank (share of max HP), whether the unit keeps acting, an action budget per rank, a must-melee-each-round flag.
- A unit with such a passive, on its last life, taken to 0 HP doesn't die: it is Downed (`Unit.dbno`, a `Downed.State`). The blow that downs it leaves it at 0; later blows take it below 0.
- Limit: `round(share x rank x max HP)` below 0. At exactly the limit it lives; past it, it dies at once.
- Rounds: one of its own side's turns ending. The turn it went down in doesn't count if that was its own side's turn. Its last round ending at 0 HP or below, it dies.
- Healed above 0 by anything: no longer Downed, and saved: `Battle.rescued(u, healer)` pays the rescue XP once (`paid_rise`).
- Tenacity (Adventurer, Fighter; passive): rank rounds, 20% x rank limit, helpless.
- Grudge (Berserker class skill, low tier; passive): rank rounds, 20% x rank limit, keeps acting; more than rank skill uses in all and it dies; a round ending without a melee attack and it dies.

## Judgement calls (question 85 for the designer)

- Round = one of the unit's own side's turns after it went down (own-turn downs get the rest of that turn free).
- Action (Grudge) = each skill use it pays for (Strike counts once however many hits). Walking, toggles and items don't count. The use that goes over the budget still resolves; then it dies.
- Melee attack = an attack (hit or miss) on a foe touching it, as Starblade's "melee hit" already reads.
- Hearts first: hearts and a Red Spinel Ring are spent before a Downed skill does anything; Downed only on the last life.
- XP: fall XP paid when it actually dies (not when it goes down), once. Rescue XP when its HP rises above 0, two shares to whoever healed it last (if another unit), once. Downing gives no kill credit; the death does.
- Helpless (Tenacity): can't act, move, use items or take orders. It still holds its tile, can be targeted, hit, healed; its effects tick, it still sees, its passives stay on, its side isn't beaten while it lingers. A helpless leader can still give orders.
- Overkill isn't carried into the negatives; a multi-hit Strike's later hits do land on the Downed unit.
- Executes (Death, Luun's Smite): a standing unit goes Downed as with a heart; one already Downed dies.
- Several Downed skills on one unit: the highest rank, first listed on a tie. Rank and limit are fixed as it goes down.
- Placement: Tenacity beside Wary (Adventurer's Martial root, open from the start; Fighter's options). Grudge on `Trees/fury.tres`, open from the start, `classes = [berserker]` (a Paladin borrowing Fury sees it locked).

## Where the hooks go

- `Scripts/Downed.gd` (new): the rule resource, `State`, and the static rules: `slot_of`, `floor_hp`, `takes`, `succumb`, `finish`, `acted`, `end_round`, `changed`, `markup`.
- `Unit.gd`: `dbno`, `healed_by`, `signal dbno_changed(u, how)`, `helpless()`; hp setter (floor, `Downed.takes` branch); `is_alive()` counts the Downed; `pay_for`/`pay_strike` count an action.
- `Battle.gd`: `signal dbno_changed`; connect in `_ready` and `summon`; `_on_dbno`; `used` -> `Downed.acted`; `end_turn` -> `Downed.end_round` before `_revive()`; `_acting` not helpless; `healed_by` set where a caster heals; Sickness never lifts a Downed unit; executes use `Downed.finish`; kill credit on the death.
- `Skill.gd`: `@export var downed: Downed`, one line in `markup()`. `Glossary.gd`: the "downed" term.
- `Command.gd` `can_order`, `AI.gd` (`act` gate, Grudge's last blows, finishing a helpless foe last), `HUD.gd` (chip, log lines, reason texts).
- Data: `Skills/tenacity.tres`, `Skills/grudge.tres`, `Roles/adventurer.tres`, `Roles/fighter.tres`, `Trees/fury.tres`.
- Tests: `Tests/downed_test.gd`.

## Places touched to add one skill (for the skill tooling)

1. `Skills/<name>.tres` (the skill).
2. Where it's offered: a tree (`Trees/*.tres`: ext_resource + Branch sub_resource + `branches`), a role's inline root (`Roles/*.tres`, same three places) or a role's `options` (ext_resource + array).
3. A new mechanic only: a field on `Skill.gd` + its line in `markup()`, the rule's own script, and a `Glossary.gd` term.
4. `godot --headless --path . --import` for new `.uid` files.
5. Tests that count or list a class's offers (`hud_test.test_adventurer_skills_screen` counts the wheel: 36 -> 37; `fighter_test`, `adventurer_test`, `progress_test` list some), and the skill's own test.

## Left to do

- [x] `Scripts/Downed.gd` + Unit/Battle/Skill/Glossary/Command hooks (and the AI's gate: a helpless unit takes no turn)
- [x] `Skills/tenacity.tres`, `Skills/grudge.tres`, wired into the roles and Fury
- [x] `Tests/downed_test.gd` (10 tests); full suite green (454 tests); first commit. `hud_test`'s Adventurer wheel count went 36 -> 37
- [ ] HUD (chip, log lines, reasons) and AI (helpless gate, Grudge melee, finishing last); second commit
