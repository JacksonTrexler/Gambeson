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

## Done
## Next
