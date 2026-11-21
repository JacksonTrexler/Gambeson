# w8-misc: five follow-ups (builder notes)

## 1. Preparation tests the plan left out
`Tests/prep_test.gd` `test_doubt_sides`: a trickster's 30-point `inquire` check bonus does not reach its side of `doubt()` (`their_tags = []`);
an Inquisition use via `prepare()` wins about 264/400 against 210/400 for a plain doubt (leader far from the siren, so no "close" edge).
Mutations: dropping `their_tags = []` fails it; `prepare` passing edge 0 fails it (gap 8 vs 54). Margin chosen: +30. No rules change.
