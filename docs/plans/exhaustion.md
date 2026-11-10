# Exhaustion

Repeating a skill costs more each time, so spamming one skill stops paying and ranks are worth buying.
Code: `Scripts/Exhaustion.gd` (state and arithmetic, one per unit as `Unit.exhaustion`), read by
`Unit.price()`, `Unit.ap_cost()`, `Unit.strike_ap()` and `Unit.strike_cost()`. Tests: `Tests/exhaustion_test.gd`.

## The rules as built

- Each unit counts its uses of each skill. What weighs on a skill is its own uses, plus half
  (`KIND` 0.5) of the uses of the unit's other skills of the same broad kind.
- Each use weighing on a skill adds half (`STEP` 0.5) of its AP and of its resource cost:
  cost x (1 + 0.5 x uses). AP stays fractional; the resource cost rounds up. A cost of 0 stays 0.
  Strike: 3, 4.5, 6, 7.5 AP. Hex: 4 AP / 2 Energy, then 6 / 3, then 8 / 4.
- A use is one payment (`Unit.pay_for()`). Strike III's three hits are one use (3 AP, against 13.5 AP
  for three Strikes at rank I). A skill landing on several (Sing) is one. A free recast (Jugular's
  natural 20, Strike!'s restrike) is none. Changing a persona (Personify) is paid, so it is one.
  Toggles, items and Discipline's burned AP are not uses.
- A channeled skill is one use from channel to strike. The strike is paid at the rate the channel
  was paid at: a fresh Metea strikes for its plain 2 AP / 1 Energy, a second one for 3 AP / 2.
- As each of its side's turns ends (`Battle.end_turn()`), every count falls by 1 (`RECOVERY`).
  If the unit rested that turn (`Unit.activity() == &"rest"`: no move, no AP spent, the same test
  Energy recovery uses), it falls further by its con mod; with a mod below 1, by 1 / (1 - mod):
  0 -> 1, -1 -> 1/2, -3 -> 1/4, so at -3 one extra use comes back every 4 turns rested.
- The player sees it on the slot's tooltip ("Exhausted x2: 6 AP now") and on the cost forecast
  ("6 AP (exhausted x2)"); the Glossary has the term and the Guide's Skills page a section.

## Calls made on judgement (question 87)

1. Step 0.5 of base cost per use, linear. Tunable in the three constants.
2. Broad kinds are the category tags (martial, specialist, magical). 20 of the 65 active skills
   carry none (Smite, Solar, Renew, Sing, Drown, Rake, Energy Missile, Flamecharm...): they wear
   on themselves only. A skill with two kinds would share with both, half once.
3. The half share is derived from the other skills' own counts, not stored: it recovers as they do.
   Five martial skills used once each weigh 3 on each, and nothing after one turn.
4. Counts fall at the end of the unit's own side's turn, so one use a turn is free for ever and
   two a turn build up (Strike twice a turn: 7.5 AP, then 10.5, then out of reach).
5. Fractions are continuous: at con mod -3 a rested turn takes off 1.25, not 1 until the fourth.
6. Con mod 0 rests like +1 (one extra use), as Energy recovery does. Read literally ("adds con
   mod") it would add nothing.
7. Light activity gets no resting bonus (Energy recovery gives it half).
8. A reserve that pays whole costs (a Sweet Nothing) still pays its 1 point; the AP still rises.
9. The AI does nothing new: it still picks by score and stops when `can_afford()` says no.
10. Staged tests run with exhaustion off (`Exhaustion.on`, set by `Test.calm()`); `combat_test`
    turns it on for its whole battles.

## What it did to the museum battles

30 seeded AI battles went from Lancin 8, Nemes 22 (3-14 turns) to Lancin 29, Nemes 1 (8-20 turns).
Nemes won by casting Hex over and over (437 casts to 293); at a step of 0.25 it is still 25 to 5.

## Left to do

- Decide the open calls above, most of all the 20 skills with no kind and con mod 0.
- Rebalance the museum (Nemes leans on Hex), or teach the AI to weigh a raised cost and vary.
- Nothing on the hotbar itself shows a worn skill until hovered; a mark on the slot may be wanted.
- Static skill descriptions (skills screen, spellbook) show base costs only.
