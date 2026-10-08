# GameTest

Project imported from Updated1.zip. The outer project is the source; the nested duplicate and generated Godot cache are excluded.

Import project.godot into Godot 4.7 (the version declared by the uploaded project). The combat scene is scenes/combat/combatscene.tscn. Existing scene nodes, signal connections, theme, and assets/scenes/data/scripts folder layout are preserved. Empty folders contain .gitkeep files so Git retains them.

Validation: imported and started with Godot 4.6.3 in headless mode. The uploaded script still generates a separate UI at runtime. Saved scene signals reference `_on_warden_pressed`, `_on_ranger_pressed`, `_on_occultist_pressed`, and `_on_end_turn_button_pressed`, which are not implemented in that script. These pre-existing issues are preserved for a separate integration fix.
