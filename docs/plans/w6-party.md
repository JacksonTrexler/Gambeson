# Persistent units and a configurable Party (w6-party, ?206, 2026-11-20)

The user (?206, verbatim): "Go ahead and set up persistent units to keep track of saved skills / a configurable 'Party'. Party size is
level / 4, + base cha mod if positive. at least 2."
Built by two builders (the first was interrupted after f743b3f, bbb99d7, 0c72048; the second finished). Final suite: 10304 checks,
0 failed (976 tests); adventurer-skills' baseline before it (w6-link) was 10265 checks (972 tests).

## Readings and calls

1. **The roster.** `Game.roster`: the player's persistent units, each a `Unit.to_dict()` (side, class, name, level, XP, hearts,
   learned skills with rank/points/on, purchases, trees opened and picked, the equipped bar by skill id, what it wears by
   `Save.item_out()`, `lapses_out()`). `Unit.from_dict()` puts it back on a fresh unit of its class (`Battle.from_role()`); a gone
   skill or item is left out. Unspent skill points aren't stored: level - 1 less what `purchases` spent.
2. **"Level" is the leader's.** Party size reads `Game.level` (the hero / leader, roster entry 0) and the leader's class's base
   charisma (`Role.stats`), not effects in play: `Game.party_size(lvl, cha) = max(lvl / 4 + max(cha mod, 0), 2)`. The leader counts
   toward the size.
3. **Game.hero stays the leader's record** (side, class file, name), and is roster entry 0; `Game.level/xp/hearts/outfit/equipped/
   lapses` stay the leader's live fields as before and win over its roster entry where both speak (its learned skills, trees and
   picks come from the entry). Its hearts are its class's plus `Game.hearts`, not the entry's (which already included them).
4. **Who is on the roster.** A new game (Entry `_play`) makes the leader plus one recruit of each other starting class, as new as it
   (the level picked, its class's outfit), named by its class. The party starts as the first that fit. Call: a stand-in until
   recruiting exists; no made-up names (class names are the user's).
5. **The Party screen** (`Scripts/PartyPanel.gd`), a "Party: n of m" button on Entry (shown when the roster has more than the
   leader): a box per roster member, the leader always ticked, others tickable while there's room; Done saves. Full-screen dim over
   Entry.
6. **A battle fields the party.** `Battle._field_party()`: each picked member, as a unit of its class on the player's side, on the free
   tiles nearest the leader, `follows` the leader (Command puts it in the leader's party from the start). Command's in-battle
   `party_size()` never drops below what was brought (`Command.brought`). Only roster entries persist: NPC and companion class units
   (`_join_companions`, scenario units) stay fresh.
7. **Keeping.** `Game.keep()` reads each fielded unit back into its roster entry, and the leader's `lapses_out()` into `Game.lapses`
   (the lapses plumbing, previously never filled); it runs as the battle leaves the tree and inside `Save.pack()` (the battle's end
   saves). Every battle with a player connects it, roster or not.
8. **Save version 2.** Adds `roster` and `party`; a version 1 file still loads (`Save.migrate()`: its hero, level, XP, hearts, outfit,
   bar and lapses become the roster's one entry) and writes back as version 2. Other versions are set aside as before.
9. **Bar with null slots** (merged adventurer-skills: item links, `slot_cost()`): `to_dict` writes "" for an empty slot or a skill
   with no `Skills/` file, `from_dict` sets it after `ready` through `set_equipped()`; the round trip is tested.

## Tests

`Tests/save_test.gd`: `test_roster` (learned skill + rank, purchases and points left, bar slot by slot, item worn, level/XP, lapses,
the party fielded on the player's side and in Command's party, `keep()` into roster and `Game.lapses`, the save reading fielded units,
the leader's hearts not doubled), `test_migrate` (a version 1 file), `test_party_size` (a table, plus `party_now()` ordering and cap).
`Tests/run.gd` resets roster/party/fielded between files.
Mutation spot-checks (each failed save_test, then reverted): leader hearts not restored; `keep()` not filling `Game.lapses`;
negative cha mod counted; `from_dict` dropping learned skills (4 fail); no migration (2 fail).
Visual: `S/shot_w6-party/` (driver `S/driver_party.gd`): the Party screen at level 8 Adventurer (5 of 5), then the battle with the
leader and four members fielded.

## As built

Scripts/Unit.gd (`to_dict`, `from_dict`), Game.gd (`roster`, `party`, `fielded`, `party_size`, `leader_party_size`, `party_now`,
`keep`, `reset`), Save.gd (v2, `migrate`), Battle.gd (`starter` from the leader's entry, `_field_party`), Command.gd (`brought`),
Entry.gd + Scenes/entry.tscn (Party button, recruits), PartyPanel.gd (new), Tests/save_test.gd, Tests/run.gd.
Not done: recruiting/dismissing roster members in play; party members' outfits can't be changed between battles outside a battle
(the stash screen is the leader's); a fallen party member isn't removed from the roster (permadeath is a design call).
