# w16-tempers
Goal: tempers `vindictive` (grudges) and `flirty` (affinity); first-time behaviour pop-ups; longer holds for interesting AI turns; `Command.skilled()` shared skilled-leader test.
Files: Scripts/Bio.gd, Unit.gd, AI.gd, Command.gd, Battle.gd, HUD.gd, Util/unit.py, Tests/bio_test.gd, Tests/command_test.gd (or ai_tactics), Tests/sims/busy_fight.gd (comment).

## Readings
- Temper = `Bio.behaviour` (Bio.BEHAVIOURS + TEMPERS, Unit.temper()); AI._full branches on it; `Util/unit.py` BEHAVIOURS mirrors it (check).
- "Persona" in the user's words = the unit's Bio (who it is, past stats). Code's Persona export group is the deception system; not used here.
- Target bonus seam: `AI._hunted()` (HUNT for a hunted side) feeds both `_strike` and `_targeting`. Grudge joins it there.
- Pop-up seam: `Battle.passive(u, null, 0, stat)` -> HUD._on_passive floats "Stat" (seen units only).
- Pacing: HUD._act_alone, `pace` 0.45 s between units (together: a frame per unit).

## Calls
- Grudge memory: `Unit.wrongs: Dictionary[Faction, int]` = blows that unit LANDED (hit() damage > 0, not itself) on each side this fight; cleared in Battle._listen. Kept on the striker so a dead victim's blows still count. Every unit records (shared: later skills may read it); only vindictive weighs it.
- Ally hit = victim's side is friends with the vindictive unit (Faction.friends); its own hits count the same. Word travels: it knows of every landed blow on its side (no sight check).
- Grudge weight: GRUDGE 2.0 per blow, at most 3 blows (6.0) - in tiles of walking in _targeting, in HP-worth in _strike. Bio.grudges (words) naming the target (name word, identity tag, class, race, looks word, as read) = HUNT (10).
- Affinity: Bio.fancies words name it; none listed: its charisma as read >= Difficulty.stat_at("high") (14), or, with no stats read, looks with a benevolent aura (Beautiful, Radiant).
- Flirty: support skills go to fancied allies first; on a fancied foe a soft skill (no damage tiers, or love-tagged) +SMITTEN 2.0, a damaging one worth half.
- Pop-ups (Battle.first_time(u, what), once per unit per fight): "Grudge" when a vindictive unit strikes or heads for a target its grudge (blows or Bio) adds to; "Smitten" when a flirty unit supports or soft-strikes a fancied unit. "Grudge" shares its word with the Grudge skill (Downed fighting on) - flagged.
- Pacing: HUD holds SIGN_HOLD 0.3 s per sign shown during a unit's AI act, at most 3 (0.9 s); a plain turn (no sign) unchanged.
- Skilled leader: `Command.skilled(l)` = has_tag(leader) or cha_of(l) >= mod of Difficulty.stat_at("high") (14 -> +2). Band: difficult/"high" in Difficulty.STAT_SCORE. AI._calm uses it (was cha_of > 0, i.e. +1). Command's rank rules (slots, caps, reach) unchanged.

- Smitten fires only with a skill (support given, or a soft hostile one); a plain approach to a fancied foe is quiet. Grudge fires on a strike or the main approach (_full) at a grudged target.
- No `leader` Glossary tag added (no unit carries one yet; has_tag reads it wherever it comes from: unit tags, gear, skills). Flag: add via mechanic.py when one is wanted.
- Every visible passive sign counts toward the hold (luck glints, skill activations too), not only temper signs: "skill activations" read as interesting.

## As built (2ef04eb)
- Bio: BEHAVIOURS/TEMPERS + vindictive, flirty; `grudges`, `fancies` word lists; `Bio.names(words, r)` (name/looks word, tags incl. race+role, class). Util/unit.py BEHAVIOURS mirrored.
- Unit.wrongs + hit() records; Battle._listen clears; `Battle.first_time(u, what)` (+ `_firsts`).
- AI: `_hunted(u, t, r)` += `_grudge()`; `_fancies()`, `_soft()`, `_smitten()` in _strike; _support orders fancied first; `_notable()` signs. `_calm` uses `Command.skilled()`.
- HUD: SIGN_TINT grudge/smitten; `_signs` counter; SIGN_HOLD in _act_alone.
- Tests: bio_test.test_vindictive_grudge (grudge focus, Bio names, popup once), test_flirty_supports_fancied (fancies, Smitten, high cha default); ai_tactics_test.test_calm_followers_drill updated (cha +1 now unskilled; tag leader skilled).
- Mutations (all failed as expected): _grudge 0; flirty ordering off; skilled without tag; skilled as cha_of > 0; first_time without the once guard.
- busy_fight 30 (target): unit turn mean 104 / p95 230 ms (main 110 / 249; p95 OVER budget on both, pre-existing); frame-per-unit stare p95 743 ms (main 764), under 1000; OUTCOME ok. Sim units have no tempers and HUD holds aren't in it (compute only).
- Suite 11065 checks, 0 failed (1045 tests; was 11057/1043). unit.py, skill.py check ok; launch log clean.
## Undone
- No soft-strike test for flirty on a fancied foe (_smitten), no visual frames of the signs (reuses passive sign path), no Glossary `leader` tag, unit.py new has no --grudges/--fancies flags.
