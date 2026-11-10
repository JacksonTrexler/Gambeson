# Channels and Jam

Three linked rules, built on branch `v-channel`: helpless ends a channel, a universal channel rule,
and Jam, the first real interrupt.

## 1. Helpless ends a channel

Going Downed and helpless (`Unit.helpless()`: Tenacity) lets go of any channel; a Grudge unit, which
goes on acting, keeps it. Found already wired: `Downed.changed()` calls `Battle.end_channel(u)` on
`&"down"` when the unit is helpless (commit 62eb9a1); the todo note (?85) predates it. What's missing
is a test, so one is added (`downed_test`: Tenacity drops Clairvoyance, Grudge keeps it).

## 2. The channel rule

The user: "channeling has same requirements as resting but units aren't resting when they channel by
default: the benefit of resting is the continuity of the channel instead of its usual benefits. most
units must hold still, but those that can move and rest have a new advantage."

- Rest's requirements (today `Unit.activity() == &"rest"`): no AP spent this turn, no tiles walked
  beyond `Unit.meander()`. Split out as `Unit.idle()`.
- At the end of each of its side's turns after the one it was cast in (`Channel.turns > 0`), a channel
  holds only if that turn was idle; otherwise it ends (`Battle.end_channel()`, so a Rift's count
  starts). The turn it was cast in is exempt: casting is what it did.
- A channeling unit is not resting: `activity()` calls an idle channeler `&"light"` (the channel is its
  work). So instead of rest's benefits it keeps the channel. Rest's benefits it gives up (found by
  grepping `&"rest"`/`rested`): the extra exhaustion recovery (`Exhaustion.recover()`), the rest rate
  of Energy (it gets the light rate, half - judgement call: holding a channel is light work, not none),
  the look-around bonus built by resting turns in a row (`rested_turns`, `Battle.survey()`), Chant
  (`_chant()`), and Hogel's rest_whole devotion.
- Physical or social uses of "rested" stay on idle, not on activity: Flamedance's "only as its turn
  opens" (`Skill.opening`), glass's teeter (`_teeter()`), and a posing traitor giving itself away
  (`_refuse()`): standing still holding a channel is not acting.
- Applies to every channel: Metea (`Skill.channel`), Clairvoyance (`pings`), Rift (`rifts`). Replaces
  "moving doesn't end it" (Clairvoyance) and the like.
- Order at turn end: the channel check runs first, so a Clairvoyance that broke doesn't update or rank
  up.
- Calls:
  - Recasting to stop a channel stays free and isn't activity (Clairvoyance and Rift stop before paying;
    a Metea strike is paid, but it ends the channel anyway). A unit that stopped its channel and was
    otherwise idle rests as usual.
  - Upkeep: no channel has a per-turn upkeep today (each is paid once at its cast). If one gets one, it
    should not count as activity, like the free recast.
  - Reactions on the foe's turn (dodging, Shields Up's standing guard) don't count: activity is
    measured from its own turn's start (`refresh()`) and judged at its own turn's end.
  - Free actions: anything costing 0 AP on its own turn keeps it, as it keeps rest; anything that
    spends AP, a move or a strike ends it at turn's end.
  - The AI: a unit still channeling after `AI._channel()` (it found nothing to strike) holds still for
    the turn rather than walking off and losing it.

## 3. Jam

The user: "rogue, the most offensive prowesses gets Jam: low damage attack that applies an instant
stun, interrupting channeling or any behavior that requires constant attention. Deals damage to focus
as well, same as physical damage received."

- Who: the Rogue (its Blade root, after Wary) and the Slayer Prowess tree (after Jugular). Slayer is
  the most offensive of the Paladin's six Prowess trees: all four of its skills (Jugular, Sundering,
  Silent Strike, Gank) are attacks; Havoc and Fury mix in rallies and self-heals, Brawn, Vanguard and
  Protector lean defensive or support. Slayer is shared with the Fighter and Berserker, who get it too.
- What: a melee (reach 1) physical blunt dex attack, 3 AP, 1 Energy, 1d4 + dex mod (1d6 from rank III):
  low damage. On a hit it interrupts the foe (`Battle.interrupt()`), ending everything that persists
  on attention:
  - its channel (Metea, Clairvoyance, Rift: the Rift's count starts);
  - hiding (timed effects that last until it moves: Hide);
  - Shields Up!'s guard (the facing and its effects);
  - a primed Chant (`chant_up`, `chant_gains`);
  - its watchfulness from resting turns in a row (`rested_turns`, Battle.survey()).
  Not ended: a disguise (Clever Disguise: a trick, not attention), a grapple it holds, a beast shape,
  sleep.
- Instant stun: no stun or daze condition exists (`Effect.gd`, `Effects/`). Reading: the interrupt
  itself, plus Jammed ?? until its next turn is over - it loses its reactions: it can't dodge
  (`Battle.evade()`: all of it lands), can't guard (`Unit.guarding()`), and doesn't obstruct
  (`Battle.obstruction()`). A new status and Effect stat (`jammed`) through `Util/mechanic.py`.
- Focus: no focus or concentration meter exists (`Roles/mage.tres`, Scripts: "focus" is only UI
  focus). Nothing invented; Jam's damage is ordinary physical damage. If a focus meter is built, Jam's
  damage should count against it like physical damage.

## Not changed: rank-up cost

Reported only. `Unit.raise_cost()`: unlocking costs 1, then rank r -> r + 1 costs 1 + r^2 (II 2, III 5,
IV 10, V 17): quadratic per rank, cubic in total. An Affinity bends it (`Unit.worth()`): +1 n log2 n,
+2 linear, -1 and down n^(2 - a). Only Clever Disguise grows exponentially (`rank_cost` 4,
`rank_growth` 2). No cap by default (`max_rank` 0), but 19 skills set one (12 at 1, 5 at 3, one at 5,
one at 8). The user wants exponential growth and no cap: `rank_cost`/`rank_growth` already exist per
skill and could become the default.
