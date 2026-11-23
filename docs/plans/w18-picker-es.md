# w18-picker-es: Elemental Strike on the shared picker
Calls: imbue.choices() = elements capitalized; apply reads c.chose (else AI rule: own element if listed, else first). Battle.cast(.., chose) sets _chosen like cast_at. HUD._pick_choice casts on u at once for non-tile skills; _pick_element + imbue branch deleted (generic: non-tile skill with choices).
Tests: general_test.test_elemental +1 check (pick "Water" via cast chose). No old-path tests changed.
