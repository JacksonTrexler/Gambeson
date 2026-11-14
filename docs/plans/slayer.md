# Slayer: martial skills (Gank, Peel, Poach, Sutemi, Spike, Hitch, Bludgeon, Slam Jam)

Branch `m-slayer`, 2026-11-14. The user's request is in the coordinator's `answers-2026-11-14.md`
("martial / slayer"). Names the user gave go in as they are (`--human`): the eight skills, Off Balance,
Winded, neutralized, ambush. Anything else I name gets ` ??`.

## Generic hooks (each one place later content can join)

All new skill verbs are `Behaviours/*.gd`; Skill.gd gets no new flags. New hooks on `Scripts/Behaviour.gd`:

- **Cast, earlier.** Battle.cast() builds the `Behaviour.Cast` once the skill is paid for (not only as
  it lands), so behaviours can weigh in on the roll. It carries `tags` (the hit's tags, `ambush` among
  them) and `hit` (it landed).
- `aim(c)`: once paid, before any roll - side effects that come first (Sutemi's lunge, Poach's discount).
- `edge(c) -> int`: advantage (+1) / disadvantage (-1) it adds to the attack roll. Summed with the
  skill's own flags, clamped to -1..+1. Pure: the HUD's hit chance asks it too.
- `guard(c) -> int`: Defense the target adds against this attack (Spike). Pure, read by the HUD too.
- `bonus(c) -> int`: damage added to each hit that lands (Spike +rank, Bludgeon's blunt die).
- `felled(c, how)`: the cast's own target was neutralized while it resolved (Poach's regain).
- `step_cost(b, holder, rank, from, to, cost, bag) -> float` (passive): what a step costs its holder;
  `bag` is shared across one walk's steps (Peel's cap). Read by `Battle.walk()`, which both the move and
  the HUD's reach and "will consume" preview use, so the discount shows while planning.
- **neutralized**: `Battle.neutralized(u, by, how)` signal and `Battle.neutralize(u, how)`, the one
  call for "taken out of the fight". `how`: &"downed" (a heart spent, it gets up at turn's end),
  &"down" (Downed, down but not out), &"killed". A later forced unshape / polymorph break calls
  `neutralize(u, &"unshaped")`; none exists today (Beastshape only ends by choice or time). *Call:* a
  Downed unit then killed is neutralized twice (each a transition), so a Poach that downs and a later
  one that kills both regain.
- **Targeting memory**: `Battle.aimed(o, t) -> int` (times o has used a skill on t this battle, itself
  excluded), recorded in cast() after `aim()`, so a skill asks "before this one". Every unit-targeted
  cast counts, ally or foe, hit or miss.
- **Low health** = *bloodied*, the existing measure (`Read.healthy`: at or below half HP), read through
  `Unit.execute_share() <= 0.5` (the execute measure, so Bless's hale makes it count as whole).
  `Unit.bloodied()` added as the one query.
- **ambush**: `Battle.ambushes(caster, target)`: the target can't locate the caster, or the caster is
  concealed from it or unseen (Read: `located()`, `concealed`, `seen`), read as the attack is made,
  before the attack exposes it. An ambushing attack's hit tags gain `ambush` (tag via mechanic.py,
  `--human`), so an Effect tagged ambush (damage, defense, mitigate...) or any rule asking for the tag
  reads it with no new code.
- **Unspent AP**: `Unit.unspent`: AP it had left as its side's last turn ended (`Battle.end_turn()`).
- **Refund**: `Unit.refund(share)`: gives back that share of its last payment (AP to its general pool,
  cost to the fund it came from). *Call:* a refund is not a recovery - it doesn't spend RE (Burnout).
  Poach's discount and Slam Jam's are refunds, so the HUD shows the full price beforehand; m-core's cost
  calculator may fold them in.
- **Regain** (Poach): Energy through `Unit.grant_energy()`; Focus and Stamina reserves through
  `set_store` + `note_recovery()` - so RE and burnout apply to each (each is one recovery).
- **Tow**: a new Effect stat `tow` (mechanic.py): a grip with it drags the unit it holds along its
  holder's next move, up to that many tiles, same direction (`Battle.travel()`). *Call:* a towing grip
  ends as its holder's side's turn ends ("grapple ends end of turn"), read off the stat, so any grip
  carrying tow is brief.
- **Winded** (status, `--human`) with new Effect stat `winded` ??: AP it loses at once, or as its next
  turn opens if it isn't acting now (`Unit.refresh()`).
- **Off Balance** (status, `--human`): Defense -1 per rank, put on the caster at rank = tiles travelled.

## The skills (Trees/slayer.tres)

Sizes against today's martial attacks: low 1d4 (Jam 3 AP/1 EN), moderate low 1d6 (Stun 4/2), moderate
1d8, high 1d10 (Crushing Blow 4/2), very high 2d6 (Savage Swing 5/3). Hand-set costs; the cost
vocabulary is for m-core's calculator.

| Skill | Design (rank r) | Cost | Cost vocabulary |
|---|---|---|---|
| Gank | 1d10 + str, reach 1, weapon blow; only with an ally within r tiles of the target; disadvantage unless it ambushes | 4 AP, 2 EN | high damage; adjacent; requirement difficult (ally near target); penalty: disadvantage unless ambush |
| Peel (passive) | ally within r + wis mod, a foe within r of that ally: each step toward that foe costs (tiles closer)/2 less, at most half the step, for r steps a turn | - | unique effect tame; requirement easy-moderate; rank range |
| Poach | 1d6 + dex, reach 1; vs a bloodied target it has never aimed at: advantage and half its AP and Energy back; its target neutralized by it: 5% x r of max Energy back, 10% x r of Focus and Stamina | 3 AP, 2 EN | moderate low damage; adjacent; unique effect impactful (regain); requirement difficult (bloodied + new target) |
| Sutemi | lunges up to r tiles to beside a target within r + 1, then 1d10 + str; Off Balance: -1 Defense a tile lunged | 5 AP, 2 EN | high damage; rank range; unique effect impactful (free move); penalty (Off Balance) |
| Spike | 1d10 + str; target adds its unspent AP to Defense; a hit +r damage | 6 AP, 2 EN | high damage; +rank damage; penalty (target's Defense); adjacent; high AP |
| Hitch | 1d4 + str; a hit: str contest + r; won, grappled with tow r (next move drags it r tiles), till its turn ends | 3 AP, 1 EN | low damage; +rank hit (on the grapple); unique effect impactful (tow); adjacent |
| Bludgeon | blunt, 1d8 + str (+1d4 more wielding blunt); a hit: Winded, r AP | 5 AP, 2 EN | moderate (high when blunt) damage; requirement easy (blunt weapon) for the extra; unique effect tame (Winded); adjacent |
| Slam Jam | after Jam. 1d10 + str; a hit: a contest (str + r vs con save) to interrupt as Jam does (Jammed); a hit refunds 1/(r+2) of its cost | 6 AP, 3 EN | high damage; unique effect impactful (interrupt); high cost; refund on hit |

## Calls (judgement, for the user)

1. Gank's "within rank tiles of an ally": an ally (not the caster) within r tiles of the target.
   Disadvantage unless the attack ambushes. Uses its weapon's blow tag (Strike's rule).
2. Peel: "X AP cheaper, X = tiles closer to the enemy / 2" per step (Euclidean, the game's distance),
   capped at half that step's cost; "no more than rank tiles": r discounted steps a turn (Unit.tally,
   per-turn, cleared at refresh). Only foes the walker can locate count (the preview and the walk agree).
3. Poach's "low health" = bloodied (half HP or below). "hasn't targeted in the past": never this battle.
   Cost reduction = half AP and Energy back, as a refund after paying. "Double regain for focus and
   stamina": 10% x r of each reserve's max. Regain only when its own blow neutralizes its target.
   Rangers: Slayer is a Ranger tab already (Roles/ranger.tres) - checked by test.
4. Sutemi: target within r + 1 (so it moves up to r tiles to stand beside it). The lunge is a forced
   step-by-step move like Sing's pull: no movement spent, ground underfoot does nothing. Off Balance
   lasts through the caster's next turn (the tick system ends effects as a turn ends, not as it starts).
   It can't be used if the lunge can't end beside the target.
5. Spike: "unspent AP from last turn" = what it had left as its side's last turn ended, rounded down.
6. Hitch: contest d20 + str check mod + r against the target's str or dex check mod (its better).
   Tow keeps the direction of the caster's move; stops at anything in the way.
7. Bludgeon: "already bludgeoning" = its weapon deals blunt (or it's bare-handed, blunt by Strike's
   rule). Moderate 1d8, + 1d4 when bludgeoning.
8. Winded (the user's sentence breaks off at "enemy loses"): loses r AP at once if acting, else off
   its next turn. **Open question.**
9. Slam Jam: "divide cost by rank + 1 / (rank + 2) on a hit" read as: a hit makes it cost
   (r + 1)/(r + 2) of the price, i.e. 1/(r + 2) of the AP and Energy back. "chance to interrupt": a
   contest, d20 + str check mod + r vs d20 + con save. Jam's interrupt and Jammed on success. Not its
   Focus drain (that's Jam's own).
10. Tiers: Gank, Poach, Hitch, Peel beside Jugular/Jam at the root level; Sutemi and Spike after
    Jugular; Bludgeon after Hitch; Slam Jam after Jam.

## As built

As planned, plus:

- **Hooks** (`Scripts/Behaviour.gd`): `aim`, `edge`, `guard`, `bonus`, `felled` on a cast; `step_cost`
  for passives. `Battle.cast()` is now a wrapper over `_cast()` that keeps `_resolving` (casts under way)
  for `felled()`; `Battle.cast_of()` builds the shared Cast (also for the HUD's `hit_chance(u, s, t, b)`),
  `edge_of()`, `guard_of()`, `aimed()`, `ambushes()`, `neutralize()` + signal `neutralized`. `hit_tags()`
  takes an optional foe and battle (ambush). `walk()` returns its hooks' `bag`; `travel()` adds it to
  `Unit.tally` and tows (`_tow()`); `end_turn()` records `Unit.unspent` and lets towing grips go
  (`_release_tows()`). `_let_go()` also ends grips a behaviour put on (Applied.skill, lasting).
- **Unit**: `unspent`, `tally`, `paid_ap`, `refund()`, `bloodied()`, `winded()` (called by `refresh()`).
- **Mechanics** (mechanic.py): tag `ambush` (`--human`, kind check); Effect stats `tow`, `winded`;
  effects `Effects/winded.tres` (Winded), `Effects/off_balance.tres` (Off Balance), and
  `Effects/hitched.tres`, named **Hitched ??** (my name: the held-and-towed status).
- **Skills**: all eight `--human` via skill.py, on `Trees/slayer.tres`: Gank (the stub replaced: removed
  and rewritten through the tool, same place, after Jugular), Poach (beside Gank), Sutemi and Spike
  (after Jugular), Peel and Hitch (beside Jam, no prerequisite), Bludgeon (after Hitch), Slam Jam (after
  Jam). Poach reaches Rangers through their Prowess choice (opened by Quarry), whose Slayer tab is this tree.
- `Util/skill.py`: the new hooks join its HOOKS list (so check doesn't call such behaviours empty).
- **AI**: `AI._strike()` skips a skill whose behaviours' `fits()` refuse the target (Gank with no ally
  near, Sutemi blocked), so it picks something else rather than failing the cast. Otherwise the AI
  uses all seven actives as ordinary attacks (scored by damage; it doesn't weigh Gank's ambush, Poach's
  advantage, Spike's Defense or Sutemi's Off Balance). Peel works for AI walkers for free (walk()).
- More calls made while building: Hitch's tow applies to every move the caster makes that turn, not
  only the next; Sutemi's lunge emits no `traveled` (it's a forced move, like pull); Poach's regain
  fires once per cast; an ambush is judged as the cast is paid for, before Sutemi's lunge.
- Tests: `Tests/slayer_test.gd` (neutralized, targeting memory, ambush tag, refund, tow on any grip),
  and one per skill: `gank_test` (incl. the AI), `poach_test` (incl. Rangers, RE), `peel_test` (walk
  preview = real walk), `sutemi_test`, `spike_test`, `hitch_test`, `bludgeon_test`, `slam_jam_test`.
  No existing test changed.

## Left open

- Winded's meaning (the user's sentence breaks off).
- A forced unshape / polymorph break doesn't exist yet; it should call `Battle.neutralize(u, &"unshaped")`.
- Poach's and Slam Jam's discounts are refunds after paying: the HUD shows the full price beforehand.
  m-core's cost calculator could fold them in.
- New tag `ambush` needs a colour (Tags.COLOR) at merge.
- todo.md / docs/todo not updated (out of bounds): the calls above and Hitched ?? want question numbers.
