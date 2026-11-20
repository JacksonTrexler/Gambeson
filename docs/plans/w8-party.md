# Party size without the floor (w8-party, ?216, 2026-11-20)

The user (?216, verbatim): "base cha mod increases party size (at least +0) + level/4 (at least +1); unit can't market themselves / has nothing to market? they'll have to go solo."

## Readings and calls
1. **The rule:** `Game.party_size(lvl, cha) = max(cha mod, 0) + max(lvl / 4, 1)`, level and base charisma the leader's (roster entry 0), as before. The old "at least 2" floor is gone. Note the two floors: level 1, cha 10 is now 1 (was 2); level 1, cha 16 is 4 (was 3), since the +1 is now on top of the mod.
2. **Size 1 is solo:** the leader alone, no one to bring. `party_now()` already returns `[0]` at cap 1 (picked recruits are cut), so no logic changed there; a battle's `_field_party()` skips entry 0 and fields no one.
3. **Wording:** Entry's button reads "Party: solo" at size 1 (else "Party: n of m"); the Party panel's count line reads "Going solo: no one to bring yet" (all other boxes stay greyed by the existing cap rule). The button stays visible while the roster has more than the leader, so the panel still shows who waits.
4. **Left alone:** `Command.party_size()` (in-battle allies who hear orders: cha mod, at least 1) is a different number and its comment doesn't quote the floor. `requirements.md` line 74 and `docs/done/rules.md`, `docs/todo/systems.md` (lines ~169, ~1210) still quote "at least 2": I may only write my plan, so the coordinator should update them. No Guide text mentions the floor.
5. A new game now starts solo for most classes at level 1 (the default Adventurer, cha 16, still brings 3 stand-ins).

## As built
Scripts/Game.gd (`party_size`), Scripts/Entry.gd (button text), Scripts/PartyPanel.gd (count text), Tests/save_test.gd (`test_party_size`: table updated to the new rule, party_now case now level 1 / cap 4, plus a Fighter (cha 9) solo case and the Entry text). Mutation: dropping the `max(.., 1)` failed 5 checks; reverted.
