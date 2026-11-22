# w5-burn: ?195, Burnout is Exhaustion (branch w5-burn)

The user: "Burnout *is* RecoveryEndurance / Exhaustion functionally (effects that increase Burnout increase Exhaustion the same amount); it builds when casting and using int mod, and it decays slowly."

## Readings

- Burnout (`Scripts/Burnout.gd`) holds no state: it is a penalty multiplier (`Burnout.penalty()`) on `Exhaustion`'s one count (`Exhaustion.uses`). Anything that adds a use or relieves one (`used()`, `relieve()`, `recover()`, Deathlust's `relieve_share()`, Battle's Wear) moves Burnout and Exhaustion the same amount, because there is one count. Clause 1 met, no code change.
- "Builds when casting and using int mod": every cast adds a use (`Unit.pay_for` -> `Exhaustion.used`); an int-tagged skill (`Burnout.of`) is the "uses int mod" case and wears 1.25x harder (more on Mana). Met.
- "Decays slowly": 1 use per side-turn (`RECOVERY`), con mod more when resting. Met.
- RecoveryEndurance is a different thing and stays separate: a con-mod budget that counts down on recoveries and refills only on a rest at full, with con checks and permanent max loss. It shares no state or logic with Exhaustion (nothing duplicated to fold), and folding would drop the user's own recovery design (recovery.md). I read the "/" as two names for the skill-use wear (Burnout, Exhaustion), which is already one rule.

## Calls (for the coordinator to number)

1. No fold: Exhaustion and Burnout already share one counter, one decay, one hook; RecoveryEndurance is a distinct budget (above). If the user means RE should also feed Exhaustion (a recovery adding uses), that is a new rule, not done.

## As built

- Code: none. Test: one line added to `exhaustion_test.test_burnout` (int and non-int skill share one count; a turn's end takes 1 use off each). Mutation: RECOVERY 2.0 fails it, reverted.
- Glossary left as is (`burnout`: "Exhaustion on int skills", consistent).
