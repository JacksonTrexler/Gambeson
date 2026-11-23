# w18-jester: Jester class, its inverted page (flex trees bought with base stats), patron Jovia

User: "Jester is a new class. jesters have a class skill page and an inverted class skill page. They may unlock flex trees through their inverted page by spending *base stats instead of skill points*. martial: costs a chosen mental stat. specialist: costs str or int. caster: costs a chosen physical stat. New warlock patron: Jovia, allows warlocks to use the inverted Jester tree." Adventurers and jesters have no flex prereqs (`jack`).

## Readings (follow-up.md, no Answer lines filled: best guesses used)
- F13: Scout martial, Journeyman specialist, Student caster. Data: `SkillTab.flex_kind` (empty: its category). Journeyman's category stays "" (its tier gating unchanged); flex_kind = specialist.
- F14: 1 point of the chosen stat per tree, permanent (base stat lowered, saved), floor 6 (a stat at 6 can't pay). The inverted page is its own tab beside the class's.
- F15: Jovia pays the same stat costs; picked as a patron like Hogel/Elmon (Flex burns work as for any patron). Her tree is the Jester's Inverted root itself. Tag `jest` NOT built: no rule would read it (a hoagie token); the page lives on the root (call 1). Suit not built (no suit system in code yet).

## Calls
1. Inverted page = `SkillRoot.inverted` on a root (`Trees/inverted.tres`, "Inverted"); any open tab holding such a root sells flex trees for stats (`Unit.inverted()`). The Jester's "Inverted" tab (Role.tabs) and Jovia's own tree share that one root, so the warlock gets the very same page.
2. Buying: `Unit.buy_flex(t, stat)`: price `FLEX_PRICE` 1, floor `FLEX_FLOOR` 6, stat must be in `FLEX_PAY[kind]` (martial: int/wis/cha; specialist: str/int; magical: str/dex/con); lowers the base stat, `flex_extra += 1`, picks "Flex Tree/<t>" (opens like a levelled one; saved).
3. Offer on the inverted page = every grant tree not native/taken (wider than Role.flex); prereqs (SkillTab.needs) still apply unless `jack` (a Jovia warlock must meet Scout's floors; checked before paying only).
4. Stat choice in the UI: the inverted page's box ("INVERTED · PAY 1 BASE STAT") shows the trees; clicking one shows a button per paying stat in the footer ("Dex 13>12"), greyed with the reason when it can't (SkillDetail.paid -> SkillTree._pay -> Unit.buy_flex).
5. Jester: focus specialist (stats str 9 dex 13 con 10 int 11 wis 11 cha 14), noun "Performer", tends pragmatic, gambeson + dagger, flex_every 10 (default; stats are its route), tags jack. Levelled flex slots still come on the General tab (F14 "normal cadence").
6. "Inverted" is a tab kind (SkillTab.KINDS colour) and the root's name (user's word, no ??). Jovia colour #e08fc4 (PATRONS).
7. Skills (all ??, data only, no behaviours): Jester root: Jape (cha vs wis save, Jeered: Defense -1/rank, 2 turns), Heckle (after Jape; Heckled: luck -1/rank), Tumble (passive Defense +1/rank), Juggle (dex pierce 1d4, range 4, roll +rank), Read the Room (capstone, needs 3: insight +1/rank). Inverted root: Fool's Luck (passive luck +1/rank), Pratfall (adjacent, dex save, Off Balance). skill.py wrote `intensity = &"faint"` on Juggle (no other skill has the field; skills_test flagged it undescribed): removed by hand.

## As built
Suite: after the data-only class commit 11191 checks, 4 failed (1052 tests) (entry list, Jovia in patron list, Juggle intensity); final 11215, 0 failed (1054 tests).
Files: Roles/jester.tres, Trees/jester.tres, Trees/inverted.tres (inverted = true), Gods/jovia.tres, Units/Jester.png, Skills + Icons x7, Scenes/entry.tscn, Trees/general_journeyman.tres (flex_kind), Scripts/SkillRoot.gd (`inverted`), SkillTab.gd (`flex_kind`, `flex_type()`, colours), Unit.gd (INVERTED, FLEX_PAY, FLEX_PRICE, FLEX_FLOOR, `inverted()`, `invert_options/choice()`, `flex_payers()`, `buy_missing()`, `buy_flex()`, pick_missing branch), SkillGrid.gd (box on an inverted tab), SkillDetail.gd (stat buttons, `paid`), SkillTree.gd (`_pay`).
Tests: general_test `test_flex_by_stats` (types; 10-row cost table; buy at L1, stat spent, tab open, saved, once only, floor 6, all-at-floor; fighter has no page), `test_jovia` (Jovia's tree = Inverted root; no page before picking her; prereqs asked; buys Journeyman with int). Changed: champions_test test_entry (+Jester), warlock_test test_one_patron (+Jovia).
Mutations (general_test): martial pays str: 8 fail; no floor: 3; page for all: 2; no prereq check: 1.
Visual: S/shot_w18-jester (Jester Inverted tab: FL, Pr, box St Jo Sc; Student chosen -> Str/Dex/Con buttons; paid Dex 13>12 -> GENERAL · STUDENT tab opens).
Undone: AI never buys flex trees; no Jester-specific test file (lean: entry + general tests cover it); Monster class-with-paths not built (the Inverted root shows a root can be shared by a class tab and a god's own tree).
