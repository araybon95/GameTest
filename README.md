# GameTest

Godot combat project based on Updated1.zip, preserving its assets, scenes, data, and scripts folders and original combat node names.

Import project.godot in Godot and press F5. The uploaded project declares Godot 4.7; import and headless combat checks also pass with Godot 4.6.3.

## Ashen Expedition

A Slay-the-Spire-style deckbuilder with Darkest Dungeon flavour: a party of
three heroes (Warden, Ranger, Occultist), each with their own deck, HP, Block
and Stress, facing an enemy that telegraphs its intent.

### Combat UI

The saved combat scene supplies the interactive nodes and their signal
connections; `combatscene.gd` lays out the HUD and wires in the artwork. Each
hero has a HealthBar and StressBar (red and purple); the enemy has a HealthBar
and an intent line. Values update after every action.

Heroes start with three cards. Each standing hero keeps unplayed cards and
draws one new card at the start of every subsequent party turn. Played cards go
to the discard pile; an empty draw pile reshuffles the discard pile. Action
points reset to two each round. The card hand scrolls horizontally when it grows.

### Darkest Dungeon mechanics

- **Death's Door** — a hero reduced to 0 HP is not dead yet; they stand at
  Death's Door and the next blow fells them. Healing above 0 clears it.
- **Stress & the resolve test** — Stress builds from enemy hits and from cards
  like the Occultist's *Dark Blast*. At 100 Stress a hero faces a resolve test:
  ~25% they become **Virtuous** (heal, steadied to 45 Stress, +2 damage) or they
  become **Afflicted** (-2 damage and +3 Stress each turn). The result is shown
  beside the hero's name.
- **Enemy intents** — the intent line shows the coming attack and its target;
  every fourth turn the enemy braces for Block instead.

### Artwork

All art lives in `assets/generated/` (transparent PNGs, Darkest Dungeon style):

- `bg_crypt.png` — battle background
- `hero_warden.png`, `hero_ranger.png`, `hero_occultist.png` — party portraits
- `enemy_hollow_villager.png` — the enemy
- `<card_id>.png` for each card (e.g. `wd_slash.png`, `oc_blast.png`)

Any missing file falls back to a text placeholder, so the game always runs.

Scene: scenes/combat/combatscene.tscn
Script: scenes/combat/combatscene.gd
Theme: assets/new_theme.tres

The nested duplicate project and generated .godot cache are excluded. Empty folders use .gitkeep so Git preserves them.

The optional local Ziva editor assistant is excluded from this repository; install it separately if needed.
