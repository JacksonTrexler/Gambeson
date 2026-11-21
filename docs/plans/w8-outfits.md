# Party members' outfits between battles (w8-outfits, ?216, 2026-11-21)

Card: "Party members' outfits and the stash": the stash screen was the leader's (in battle, or once it is over); let the player open any roster member's outfit (and bar) between battles, saved through the roster entry. No new rules: the screen reads `Game.roster`.

## Readings and calls
1. **Where.** The Party panel (Entry) gets an "Outfit" button beside each member's box (grid now 4 columns, two members to a row, so ten classes still fit the screen). It opens the existing `CharacterSheet` over the panel, on a unit made from the roster entry.
2. **The unit stands in for the entry.** `PartyPanel.outfit(i)` builds a unit of the entry's class (the same few lines as `Battle.from_role()`, copied: Battle.gd is w8-fc's; make it static and share later), `from_dict()`s it, adds it (hidden) to the panel so its `ready` runs and the bar follows what its items lend (`refit()` -> `_sync_granted()`), and frees it when the sheet closes. The bar (and learned skills) round-trip through `to_dict()`; there's no bar editor, only items changing it as they do in battle.
3. **Saving.** Each change (equip, take off, use a Heart) writes `Game.roster[i] = unit.to_dict()` and `Save.save()`.
4. **The leader (entry 0)** is built as `Battle.starter()` does (its own `Game.level/xp/outfit/hearts/equipped/lapses` win over its entry) and each change also writes `Game.outfit` and `Game.equipped`; a Heart adds to `Game.hearts` as in battle. Call: the leader is pickable too, so the panel is one list.
5. **Items conserve.** Equip: stash loses the item, gains what it replaced; take off: stash gains it. Nothing else touches the stash. A bound (Shackles) item can't be removed here, as in battle.
6. **Free between battles.** No AP is charged (no battle: `ap_of` gives 0). Calls: a potion in a trinket slot can't be used here (nothing to restore; `CharacterSheet.between` hides its Use); a stash consumable offers Use only if it gives hearts. Members' hearts live in their own entry (`hearts`), the leader's in `Game.hearts`.
7. **Not done:** the button shows only while the roster has more than the leader (the Party button's existing rule), so a solo new game has no between-battle stash screen; the in-battle sheet is unchanged (it already outfits fielded members; `Game.keep()` writes them back).

## Tests
`Tests/save_test.gd` `test_member_outfit`: the button opens the sheet on that member; equip puts the stash item on and the replaced one in the stash; roster entry updated, others' and the leader's untouched; reopened it's still worn (round trip through `Game.roster`); take off returns it; a Heart is the member's own life; the leader's change reaches `Game.outfit` and its entry; the save round trip; `_owned()` (stash plus everything worn) is conserved throughout.
Mutation spot-checks (each failed the test, then reverted): dropping `stash.append(old)` (3 fail); dropping `stash.erase(it)` (4 fail); not writing the leader's `Game.outfit` (1 fail).
Visual: `S/shot_w8-outfits/` (driver `S/driver_w8outfits.gd`): the Party panel at level 8 and a Paladin's stash screen.

## As built
Scripts/PartyPanel.gd (Outfit buttons, `outfit()`, handlers), Scripts/CharacterSheet.gd (`between`), Tests/save_test.gd. Entry.gd unchanged (its `open_party()` already does it).
