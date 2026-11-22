# Passive signage (w7-passives, 2026-11-20)

The user's words (docs/agents/answers-2026-11-20b.md, UX nits): passives muted on name and number, unmuting or flashing as they
act; plumbing so a passive acting on a unit can show it, a non-viewed unit getting "<icon> Name amount" above it in the tag
colour ("<3 Regen +4 hp" in green); Luck "+1" with a sparkle, only when an action really needed it; amounts italic when rounded
down, bold when rounded up; "hold implementation of these when it cannot be done efficiently / without major performance
degradation: there should be no noticable impact". Spellbook: traits and armor passives muted.
Baseline suite: 10457 checks, 0 failed (989 tests).

## Readings and calls

1. **One signal.** `Battle.passive_fired(u, skill, amount, stat, rounded)`, emitted only through `Battle.passive()`. skill null
   means the stat acted by itself (Luck); `stat` names what moved (`&"hp"`, `&"luck"`, `&"regen"`), `rounded` is -1 down / 1 up /
   0 exact (`Luck.rounded(x, n)`, beside `Luck.settle()`, the one place rounding happens). The HUD (`_on_passive`) is the only
   listener. It is only called from real moments, never from previews, `walk(expected)` or the AI's weighing. No listener guard:
   an emit with no listener is a lookup, and the call sites fire a few times a turn at most.
2. **Call sites.** Regen (`_mend`: signed by the skill that put it on, read from `Applied.skill`, or by an own passive that regens;
   with neither it's "Regen"). Luck: a step only luck squeezed in (`walk()` returns `squeezed`, `travel()` signs it if the unit got
   that far), a use from the clover slot, or a target only luck's rounding put in reach (`_lucky_use()`, once the use is paid for).
   The hurt and healing hooks (`_on_taking_hit`, `_on_being_healed`) now loop `on_passives` themselves rather than `hooks()`, so
   they know the skill: one that spares its holder hp, or siphons a heal, signs it (Molothrus). Every reaction (`react_with`) also
   signs, with no amount. Call: the existing `reacted` floater (the skill's name in gold) became this sign, in the skill's tag colour;
   the log line stays.
3. **Shown how.** Viewed unit (selected, bar showing) with the skill on its hotbar or trait bar: the slot lights (`SkillSlot.flash()`:
   unmuted, gold rim fading over 0.8 s); acting again within 4 s it only unmutes, no rim (the user's "just unmute briefly if it
   activates often"; call: "often" = within 4 s). Otherwise a floater: icon, "Name +amount stat" (stat word only for a skill's sign:
   "Rejuvinate +4 hp", "Luck +1"), in `SkillSlot.tint()` (the tag colour the hotbar stripe uses) lightened; a stat's own sign takes
   `HUD.SIGN_TINT` (luck clover green, regen heal green) and a small four-point glint. Calls: the glint marks every stat-only sign
   (only Luck today), not Luck by name; a regen floater appears beside the existing "+4" hp number (both stack), not instead of it.
4. **What the player may see.** Own side: always, with amounts. Another side's unit: only if the player's read places it there, and
   only as much as `skill_sense()` allows (0 none, 1 name only, 2 with amount). One read per sign.
5. **Muted.** `SkillSlot.muted(s)`: an always-on passive (not a toggle, not a hybrid: those are clicked). Hotbar and trait slots draw
   its name and numeral in `MUTED_TEXT` / `MUTED_GOLD`; the spellbook (`SkillEntry`) does the same, so traits and innate armor
   passives are muted there, and their tooltip says they take no slot. Call: one rule for every always-on passive rather than traits
   and innate links only (they are always-on passives too). Not done: the class skills screen (it's a shop, not a list to select from).
6. **Rounding faces.** `Overlay._face()`: a `FontVariation` made once from the floaters' font per direction, slanted (rounded down) or
   emboldened (rounded up). Built for passive signs and for damage numbers: `Unit.hit()` adds `rounded` to the blow it already
   passes through `taking_hit`; the HUD keeps the blow (it kept the tags) and styles the number if it all came from that blow.
   **Held (not perf):** heals other than regen (potions, Heal: the amount is rounded upstream and reaches the HUD only as an hp change;
   threading it means a parameter on every heal path), the log (its RichTextLabel has no italic/bold faces set up, and its amounts
   aren't per blow), and previews (they show a range over rolls, each end rounded its own way: there's no one rounding to mark).
   All three are cheap at run time; they're held for scope, a question for the user.
7. **Names.** No new player-facing names: the signs use skill names and the existing words Luck and Regen.

## Performance

`Tests/sims/busy_fight.gd -- 15 20 n=3`, two runs each, headless (Battle side; ms on the M3):

| | before | after |
|---|---|---|
| 15v15 unit turn mean | 64.1 / 63.0 | 64.3 / 64.0 |
| 15v15 side end_turn mean | 234.3 / 230.1 | 234.5 / 232.8 |
| 20v20 unit turn mean | 76.1 / 74.8 | 75.9 / 75.7 |
| 20v20 side end_turn mean | 461.4 / 453.8 | 459.2 / 457.8 |

Within run-to-run noise (about 1-2%), and the fight digests match (2121111823, 129203950): no rule changed. The HUD side, timed
in a throwaway test: a sign on another side's unit 0.24 ms (one read), on an own unit 0.05 ms, against 0.30 ms for the existing hp
number on a foe. A slot's flash runs `_process` only while lit. Floaters with no rounding allocate nothing new.

## As built

- `Scripts/Battle.gd`: `passive_fired`, `passive()`, `_regen_source()`, `_lucky_use()`, `walk()`'s `squeezed`, hooks loops.
- `Scripts/Luck.gd`: `rounded()`. `Scripts/Unit.gd`: the blow's `rounded`.
- `Scripts/HUD.gd`: `_on_passive()`, `SIGN_TINT`, blow kept for the damage number's face; the reacted floater moved into the sign.
- `Scripts/Overlay.gd`: `float_sign()`, `_face()`, `float_text(..., rounded)`.
- `Scripts/SkillSlot.gd`: `muted()`, `flash()`, muted colours (style only; no layout). `Scripts/SkillEntry.gd`: muted entries.
- Tests: `Tests/passive_signs_test.gd` (two tests, by seam: Battle's call sites incl. "a plan signs nothing", the HUD's slot vs floater,
  glint, faces, spellbook). Mutation spot-checks, each failing the file: no regen emit; a sign from `walk()` itself (planned walks
  sign); `_face()` a no-op; slot flash skipped (floats instead); the hurt hook's sign dropped.
- Screenshots: `S/shot_w7-passives/` (01 muted bar, 02 signs + lit Favour slot + faces, 04 spellbook).
- Suite: 10472 checks, 0 failed (991 tests).
