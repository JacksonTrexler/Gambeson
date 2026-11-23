# w18-jester: Jester class, its inverted page (flex trees bought with base stats), patron Jovia

User: "Jester is a new class. jesters have a class skill page and an inverted class skill page. They may unlock flex trees through their inverted page by spending *base stats instead of skill points*. martial: costs a chosen mental stat. specialist: costs str or int. caster: costs a chosen physical stat. New warlock patron: Jovia, allows warlocks to use the inverted Jester tree." Adventurers and jesters have no flex prereqs (`jack`).

## Readings (follow-up.md, no Answer lines filled: best guesses used)
- F13: Scout martial, Journeyman specialist, Student caster. Data: `SkillTab.flex_kind` (empty: its category). Journeyman's category stays "" (its tier gating unchanged); flex_kind = specialist.
- F14: 1 point of the chosen stat per tree, permanent (base stat lowered, saved), floor 6 (a stat at 6 can't pay). The inverted page is its own tab beside the class's.
- F15: Jovia pays the same stat costs; trickster patron, tag `jest`; picked as a patron like Hogel/Elmon (Flex burns work as for any patron).

## Calls
1. Inverted page = `SkillRoot.inverted` on a root (`Trees/inverted.tres`, "Inverted"); any open tab holding such a root sells flex trees for stats (`Unit.inverted()`). The Jester's "Inverted" tab (Role.tabs) and Jovia's own tree share that one root, so the warlock gets the very same page.
2. Buying: `Unit.buy_flex(t, stat)`: price `FLEX_PRICE` 1, floor `FLEX_FLOOR` 6, stat must be in `FLEX_PAY[kind]` (martial: int/wis/cha; specialist: str/int; magical: str/dex/con); lowers the base stat, `flex_extra += 1`, picks "Flex Tree/<t>" (opens like a levelled one; saved).
3. Offer on the inverted page = every grant tree not native/taken (wider than Role.flex); prereqs still apply unless `jack` (a Jovia warlock must meet Scout's floors; the stat paid can't take it below them either? no: checked before paying only).
4. Stat choice in the UI: the inverted page's box shows the trees; clicking one pops a menu of payable stats ("Wisdom 11 -> 10").
5. Jester: focus specialist, noun "Performer", flex_every 10 (default; stats are its route), tags jack, jest.
6. `jest` tag (mechanic.py, --human from F15): carried by Jester role; Jovia's tag.

## Done
## Next
