# w2-striking: Striking Features, Striking Intellect

The user's words (2026-11-18, verbatim): "2 skills: Specialist/Caster general Striking Features/Intellect: Unit may use `cha/int` for their strike attack mod, if it's higher."

## Readings and calls (for review)

1. One generic hook: Effect stat `attack_stat` (title "Attack stat ??"). `checks` names the stats offered, `skills` (and/or `tags`) say which attacks; `Unit.attack_stat(skill)` returns the highest-mod of the skill's own stat, a weapon's (`wielded()`) and every offered one. `Unit.attack_mod()` reads it, and so do the three `check_bonus(..., &"offensive")` sites (cast, `_chain`, `attack_odds`), so Bracing on cha/int checks follows the stat used. Forecast, hit chance and the AI share `attack_odds`, so they see it. Another skill can offer another stat or name other skills/tags: data only.
2. "Strike" = `skills = [Skills/strike.tres]` (the one chain skill; Strike forms are effects on passives, not skills). No new tag: Strike's tags (physical, str, martial) are shared by other skills. `Effect.skills` already existed (read through `Unit.stat(..., of)`), unused in data until now.
3. Striking Features already existed on the Specialist general tree (tier 4) with the `featured` effect (first hits add cha mod damage). Call: kept it and added the `attack_stat` effect to it rather than replacing it or making a duplicate id. Its name is the user's, so no `??`.
4. Striking Intellect: new via `skill.py new --human`, passive, tag magical, general_caster tier 4 after Record Striker (beside Striking Features' tier 4). Placement and tier are calls.
5. Not balanced; prices are the calculator's (w2-cost's area).

## As built

- `Scripts/Effect.gd` (stat, title, describe), `Scripts/Unit.gd` (`attack_stat`, `attack_mod`), `Scripts/Battle.gd` (three `check_bonus` sites), `Skills/striking_features.tres`, `Skills/striking_intellect.tres`, `Trees/general_caster.tres`, icon.
- Test: `general_test.test_attack_stat`, a table row per stat (higher uses it, forecast rises, lower unchanged, unequipped unchanged, non-Strike untouched). No file of its own.
- Mutation spot-checks (failed, reverted): comparison flipped; `skills` filter ignored.
