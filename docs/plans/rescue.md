# Rescue and interrupt: Resuscitate, Intervention, Borrowed Time, friendly fire

Branch `b-rescue`. Baseline suite: 41838 checks, 0 failed (607 tests). The user's texts are in todo.md
under 84 and 85.

## Resuscitate

Readings and calls:
- "adjacent downed unit immediately recovers with rank * 5% hp": it comes back *up* with rank x 5% of
  its max HP, not a heal of that much - a heal is what its HP is below 0 plus the share, so a unit deep
  in the negatives is still saved. One heal, through `Battle.mend()` -> `Unit.heal()` (the
  `being_healed` path every recovery takes, so Molothrus and a-recover's Recovery Endurance join).
- Only on a Downed ally (`hostile = false`: no reviving foes); used on anything else it's refused
  before it's paid for. That needed a target filter: a generic `Behaviour.fits(b, caster, target)`
  hook that `Battle.cast()` asks (every behaviour must allow it), rather than a Skill flag.
- General Specialist tree, tier 4 (its tiers run 1-7; Drone, also "mid", sits at 4 on Caster).
  3 AP, 2 Energy, reach 1, tags physical + specialist (like First Aid).
- The caster gets the rescue XP (`healed_by`, `Battle.rescued()`).
- Not done: the AI doesn't use it (it isn't a `heals()` skill), and the HUD still offers it on any ally
  in reach (the cast is refused).

## Intervention

Readings and calls:
- Placed on **Divinity: Eros** (`Trees/eros.tres`), after Renew - the one divine tree both Cleric and
  Paladin have today. a-gods is restructuring these trees into a god system: move the branch there.
- 3 AP, 2 Energy, an ally (or itself) within rank tiles; Bless lasts rank turns (duration not given).
  Tags magical, wis, bless.
- `bless` is a Glossary term (condition, `--human`) and a tag on the skill; the buff is three of the
  skill's effects, each named "Bless" (shown as one), all data:
  - `regen` 5% x rank tagged `downed`: heals as its side's turn starts only while Downed. `_mend()` now
    asks regen with `Unit.state_tags()` (`downed` while Downed), so any regen tagged downed works so.
    From below 0 it climbs back and is saved once above 0.
  - `hale` (new Effect stat, "Hale ??"): every execute reads `Unit.execute_share()` - HP left / max,
    or 1 while hale. Readers: `Battle.executed()` (the cut on an execute-tagged skill's defensive
    check), `Battle.last_stand()` (Death), Luun's Smite threshold (r x 5% HP: a hale unit is never
    under it - "much less likely" becomes "can't", since it isn't a check).
  - `check` +rank, defensive, tagged `taps`, `execute` (the seam Stun built).
- The seam made sturdier: `last_stand()` against an execute now adds check effects tagged execute;
  the `save` contest (Haluca's kind) now passes the skill's tags to the target's check (it didn't).
- "Any check added later, whether or not the developer is aware": `skill.py check` now fails a skill
  that puts on a helpless/sleep effect (inline, an Effects/ file, or preloaded by its behaviour) without
  the `taps` tag, or that `kills` without `execute`.
- Test proves it with a throwaway `Skill.new()` tagged taps/execute (`intervention_test.test_seam`).

## Borrowed Time

Readings and calls:
- **No time branch exists** on any arcane tree. Placed on the Wizard's own **Arcane** root
  (`Roles/wizard.tres`), after Blink, needing 3 of the root's others (as its capstone Magic Skill Slot
  does) - standing in for "high tier". Passive, data only: Effect stat `defer` +rank (new, generic: an
  item or a later skill giving `defer` works the same).
- Trigger: on its last life (hearts first, as Downed), HP taken to 0. Once a battle (`deferred_once`).
- While deferred (rank of its side's rounds; the round it began in doesn't count if it was its own
  side's turn, as Downed): it can't die; its HP stops at 0 (no negatives); it acts as usual, is
  targeted, healed, executed (an execute can't kill it either). `is_alive()` counts it.
- "Negative effects received": every `Unit.damage()` (hits after mitigation, bleed, poison...) and
  every debuff put on (`afflict()` of an effect with `helps() < 0`), logged with the round, kept for the
  last rank rounds whenever it has `defer` (so the blows that killed it are in it). Replay at each of
  its rounds' end, in order, through `damage()` and `afflict()` (Downed, other passives etc. apply;
  `taking_hit` hooks don't, since the logged number is already after them); replays aren't logged again,
  so each harm is replayed once per round it stays in the window (up to rank times).
- Expiry: `Battle.last_stand(u, rank)` - cut by `execute_share()`, plus check effects tagged execute -
  against d20 + rank, the execute winning ties. At 0 HP the stand is 0: certain death unless healed
  or hale (Bless). Pass: lives, at 1 HP if it had none. Fail: `Unit.fall()` - the death path it put off.
- **Downed / Tenacity**: Borrowed Time goes first; a failed expiry check with a Downed skill puts it
  Downed (as an execute on a standing unit does), then Downed's own rules. A Downed unit dying is not
  deferred (Borrowed Time only catches the 0-HP moment, before Downed).
- HUD: log lines and a float text on going on borrowed time (`Battle.borrowed` signal). No card chip.

## Friendly fire

Readings:
- Before this, `Battle.cast()` decided friend or foe by the truth: a foe-only skill on any ally was
  refused (the HUD said "doesn't take"; a Ctrl-click at its tile, `attempt()`, whiffed as thin air). So
  no friendly fire happened, and the refusal leaked who it was.
- Who can be an ally it can't tell: its own side knows where its teammates hide by their own
  concealment (`Perception._levels()`), so it's an ally in a zone (fog, darkness not its side's own),
  one of an allied but different side hiding, or an ally passing for something else (trickery, a front).

Calls:
- Any foe-only skill (`for_foes()` and not `for_allies()`) cast on a unit friendly to the caster that it
  doesn't read as an ally (`Read.attitude() != ally`). Dual/either skills keep doing by the truth (a
  starter spell on an unseen ally still helps it; `sol_test.test_igna` relies on it).
- Hidden wis check: d20 + wis mod (check bonuses, offensive) against the standard flat DC 12; no
  signal carries the roll, only `held_fire(u, ally)` on a pass (HUD: "X holds its fire: that's Y" and a
  float). Leaders' experience/cha doesn't enter it (the text hints at it; left out).
- Pass: the attacker **spends the skill's AP and cost** (as on a miss), `Battle.interrupt(caster)` -
  Jam's path: its own channel, hiding, guard, primed Chant, watch end - and `used` is emitted with 0
  damage. Recon: its side reads that ally better for the battle by as many levels as the ally hides
  from it (at least 1), through `studied` (`_read()`), which shows its side unless trickery still lies.
- Fail: the attack goes on as on a foe - friendly fire (Conspire's `ally_mitigate` still cuts it).
- Range is checked first (an ally out of reach is refused as before, no check).

## As built

- Skills (`--human`): `resuscitate` (Specialist tier 4), `intervention` (Eros after Renew),
  `borrowed_time` (Wizard Arcane after Blink, needs 3).
- Mechanics: tags/terms `bless` (condition), `execute` (check; the tag Death already carried); Effect
  stats `hale` ("Hale ??") and `defer` ("Borrowed Time").
- Code: `Behaviour.fits()` (cast target filter); `Unit.execute_share()`, `state_tags()`, the deferred
  death state (`defer()`, `harms`, `replay_harms()`, `age_harms()`, `fall()`, `_landed()` split out of
  the hp setter, `is_alive()` counts it); `Battle._borrowed()` (before `Downed.end_round`),
  `_holds_fire()`, signals `borrowed`, `held_fire`; `last_stand()` adds execute-tagged check effects;
  the save contest passes skill tags; regen asked with `state_tags()`; Luun's threshold by
  `execute_share()`. `Effect.marked()` describes hale and defer. HUD log lines for both signals.
- `Util/skill.py check`: `check_check_tags` (tapping effects need `taps`, `kills` needs `execute`).
- Tests (new): `resuscitate_test`, `intervention_test`, `hale_test`, `borrowed_time_test`,
  `friendly_fire_test`. No existing test changed.
- Suite: 41893 checks, 0 failed (619 tests).
- Not done: AI use of Resuscitate / Intervention; HUD offering Resuscitate only on the Downed; a card
  chip for borrowed time; no screenshots (only log lines and float texts were added).
