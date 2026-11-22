# w10-boon: show shows_boon, name Restless Dead ??, notice on a walk (?237, ?238)
Built:
- HUD._info (read path): `r.boon` -> note line "Claims to be doing <boon>." (the Bio's note area; shows_tags already shows in the sub line).
- HUD chip `RESTLESS` = "Restless Dead ??" (FOE colour): leader card if u.restless(); read card if r.restless (this observer noticed it) or (known(u) and u.restless()) (own side knows).
- Battle.travel(): one line after `_first_look(u)`: `UNDEAD.settle(self, u)` (Undead.witness runs for a restless walker). w10-opp touches the move path: one-line add, easy to re-seat.
Calls:
- Chip not name: the name stays; "Restless Dead ??" is a chip (as Leader, Asleep). Not shown to a viewer that hasn't noticed it (a foe's card, an unnoticed ally's).
- Boon is a note line, not a chip: it is a sentence.
- Witness fires once per walk (end), not per step.
Tests: undead_test.test_noticing (+card chip), new test_noticing_a_walk, hud_test.test_what_shows (+boon note). Mutation: removing the Battle line fails the walk test.
Visual: shot_w10-boon/01_leader.png checked (chip beside Leader).
