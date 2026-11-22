# Cost identity: cost profiles over the computed price (w2-cost, 2026-11-18)

The user (?131): "skill cost is part of its identity (ap heavy / resource heavy / specific resource needed or
preferred). Skills *should* have an algorithm they can use looking at which tags are included, which
parameters are scaled how far (rank may scale cost, potentially a lot) as a baseline. Consider expanding
how skill costs can be configured. a natural language description: "high mana cost, low ap cost" should be
trivial for a sonnet or haiku model to implement via skill".
Read: skill-modifiers.md, param.md, param-rest.md, ai-prices.md, Pricing.gd, SkillTerms.gd, Util/skill.py.

## Readings and calls (for review)

1. **Baseline = Pricing's points.** The computed price (Pricing.points(): intensity, tags/terms, rank
   and stat scaling, contingencies) stays every skill's budget. A profile only skews how that budget is
   spent: AP against the resource cost, which resource, and how steeply rank grows it. No TABLE number
   changes, so no balancing.
2. **Stored as words, in place of `priced`.** `Skill.priced: bool` becomes `Skill.costs: String`, the
   profile as written ("high mana, low ap"); "" = hand-priced (ap/cost as set), as `priced = false` was.
   `Skill.priced()` is now a func. Field count unchanged (103); FLAG_CEILING 104 -> 103, the true count
   (the `inherent` field already went). A declarative field every skill shares, replacing one: no net flag.
   The three priced skills (poach, skeleton, warcry) become `costs = "even"` (the baseline), priced exactly as before.
3. **Vocabulary** (Pricing.TABLE `levels`, `dims`, `rank`; mirrored in skill.py, which checks them):
   - clauses split on commas, ";" and "and": each is `[level] [only|needs|prefers] <dimension>`, or
     `<flat|scaled|steep> rank`, or `even`. Filler words "cost", "costs" after a dimension are ignored
     ("high mana cost, low ap cost" reads as "high mana, low ap").
   - levels: none / no / free 0; low / light / cheap 0.5; moderate / medium / normal / even 1 (also the
     default with no level); high / heavy 1.5; very high / very heavy 2.
   - dimensions: `ap`; the resource cost: `cost` / `energy` / `resource` (whatever pays, by its tags), or a
     reserve by id: `mana`, `stamina`, `focus`, `sweet_nothings` ("sweet nothings" too).
   - a reserve named plainly or with `prefers`: **preferred**: `Unit._funding()` tries it first (after a
     needed one) when its holder has it and it can pay (a generic hook: the skill's identity, read off
     the profile). `only` / `needs`: **needed**: written as the existing `Skill.needs` field by the tool
     (one source at run time; check keeps them in step).
   - at most one resource (a skill has one cost); `health` / `hp` / `life` are refused: no HP costs exist yet
     (a mechanic for new-mechanic first).
   - unstated dimensions are moderate (absolute, not complementary: "high mana" alone is dearer overall;
     "high mana, low ap" spends the same budget differently). Call: absolute words, so a model writes what it reads.
4. **Weights to costs.** With p(r) = points at rank r under its modifiers, rank growth g (flat 0, scaled 1,
   steep 2): q = p(1) + g x (p(r) - p(1)); **AP = clamp(round(ap_base + q x ap_per x w_ap), 1, ap_max)**,
   **cost = round(q x energy_per x w_cost)** (round half away from zero, as before). "even" reproduces the old
   priced rule exactly. "none ap" still costs ap_base (1 AP, the floor for an active).
5. **Rank.** Rank already scales the baseline where a skill's terms scale (dice by rank, per-rank hit and
   damage, other per-rank terms). `steep rank` doubles that growth past rank I; `flat rank` prices every rank
   as rank I (what a flat hand cost is). Call: a rank word on the whole price, not per dimension (small).
6. **Migration (mechanical, no balancing).** `godot -s Util/terms.gd -- infer` tries every hand-priced active
   (not cost_per_rank, not hybrid) against every level pair (and a `flat rank` where its points grow with
   rank), keeping a profile only if it reproduces the hand AP and cost **exactly at every rank 1..max (5 if
   uncapped)**; `skill.py migrate` writes those with `skill.py cost`. Anything else stays hand-set (listed below).
   Resource word: `only <reserve>` where it has `needs`; otherwise the generic `cost` (no preference written,
   so funding order is unchanged). Under emblems a migrated skill now prices via the profile instead of
   hand x points ratio: small differences, only with emblems on (call: accepted as rounding).
7. **Tool.** `skill.py new --cost "high mana, low ap"` (default "even"; `--hand-priced --ap 4 --cost 2`
   still sets a hand price: with --hand-priced, --cost is a number) and `skill.py cost <id> "<profile>"` (or
   `skill.py cost <id> hand --ap 4 --points 2` to go back): writes
   `costs`, drops the hand ap/cost lines, sets or clears `needs` to match `only`, prints AP and cost at ranks I-III.
   `check` parses every profile and checks `only X` against `needs`.

## Tests (one per seam)
- `modifiers_test.test_priced` updated: `s.costs = "even"` for `s.priced = true`.
- New `Tests/costs_test.gd`: profile -> cost table test (words to weights, AP/cost at ranks, steep/flat,
  synonyms, refusals); every skill's profile parses and its named reserve can pay it; preference in funding.
- skill.py check: profile parse + only/needs (tool check).
- Mutations: listed in "As built".

## As built
- `Scripts/Skill.gd`: `costs` (String) replaces `priced`; `priced()` a func. `Util/skill.py` FLAG_CEILING 104 -> 103 (the true count).
- `Scripts/Pricing.gd`: TABLE `levels`, `rank`, `generic`, `reserves`; `profile(text)` (cached parse, `error` on a bad
  word), `profile_of(s)`, `budget(s, r, m)` (rank growth), `ap()`/`energy()` by the weights, `reserve_of(s)`.
- `Scripts/Unit.gd` `_funding()`: a preferred reserve pays first (after a needed one).
- `Util/skill.py`: `profile()` (mirror of Pricing's), `check_costs` (parses, active only, "X only" <-> `needs`),
  `new --cost "<profile>"` (default "even"; `--hand-priced --ap N --cost N` still hand), `cost <id> "<profile>"`
  / `cost <id> hand --ap --points`, `migrate`. `Util/terms.gd`: `infer` mode; `terms` prints the profile and AP/cost at I-III.
- `.claude/skills/new-skill/SKILL.md`: the vocabulary, examples, `skill.py cost`.
- Migrated (exact at every rank, so play unchanged without emblems): 48 + the 3 already priced (now "even").
  Writing a profile drops the hand `ap`/`cost` lines.
- **Kept hand-priced (no profile reproduces them at every rank; 38):** burning_bag, cindering, clairvoyance,
  coordinate, darkstone, death, elemental_strike, flamecharm, flamedance, flamewall, gank, heal, hitch,
  invisibility, judgement, jugular, level_up, meditate, megaheal, metea, mirror_image, pray, rake, ramuts_ire
  (0 AP), rejuvinate, resuscitate, savage_swing, send_off, slam_jam, smite, snare, solar, spike, stonegift, strike,
  stun, well_up, wildfire; and the 7 cost-x-rank starter spells (aetha, astera, hydera, igna, nadira, sola,
  terestera: a profile has no "x rank" word; their rank I hand price matches "even"). For the next card: set one
  with `python3 Util/skill.py cost <id> "<profile>"` once a skill's terms are parameterized (it prints the price
  at I-III to compare), or leave it hand-set.
- Tests: new `Tests/costs_test.gd` (test_profiles: words -> weights table, refusals, AP/cost at ranks for
  even/skewed/flat/steep/no-ap; test_every_profile; test_prefers). Changed to the new rule: `modifiers_test.test_priced`
  (`costs = "even"`), `energize_test` (reads Pricing, not the removed fields), `route_test.test_missed` (reads
  `v(3).price(h)`), `route_test.test_requirement_paths` (its Haluca copy hand-priced 4/2 as before: the payoff it
  adds would price a priced copy past v(3)'s AP).
- Mutations (each failed its test, reverted): energy ignoring w_cost; budget ignoring the rank word; funding
  ignoring the preference; `only` never set. Tool: a "high health" profile and a "mana only" without `needs`
  each give a `skill.py check` problem.
- Suite: 9522 checks, 0 failed (931 tests) -> 9702 checks, 0 failed (934 tests).

## Calls to review
- `priced` -> `costs` (a string of words, not new fields per dimension); "even" the baseline.
- Absolute words, unstated = moderate; levels 0 / 0.5 / 1 / 1.5 / 2.
- A plainly named reserve is a preference with teeth (paid first), not only a label; "only" compiles to `needs`.
- Rank word on the whole price (flat 0, scaled 1, steep 2), not per dimension.
- Migration exact at every rank 1..max (5 uncapped), no emblems: with emblems on, a migrated skill now prices by
  its profile under modifiers rather than hand x points ratio (small differences).
- 26 of the 48 migrated profiles carry "flat rank" (their terms grow with rank but their hand price didn't):
  the user may want those to scale; that would be balancing, so not done.
- `skill.py cost` refuses to drop an existing `needs` silently (say "X only" or remove it first).
