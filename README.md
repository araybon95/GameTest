# GameTest

Godot combat project based on Updated1.zip, preserving its assets, scenes, data, and scripts folders and original combat node names.

Import project.godot in Godot and press F5. The uploaded project declares Godot 4.7; import and headless combat checks also pass with Godot 4.6.3.

## Combat UI

The saved combat scene drives the UI, with working hero and End Turn signals. Each hero has editable HealthBar and StressBar nodes; the enemy has a HealthBar. Health bars are red and stress bars are purple. Values update after combat actions.

Heroes start with three cards. Each living hero retains unplayed cards and draws one new card at the beginning of every subsequent party turn. Played cards enter the discard pile; an empty draw pile reshuffles the discard pile. Action points reset to two. Scroll the card hand horizontally when it grows.

Scene: scenes/combat/combatscene.tscn
Script: scenes/combat/combatscene.gd
Theme: assets/new_theme.tres

The nested duplicate project and generated .godot cache are excluded. Empty folders use .gitkeep so Git preserves them.
