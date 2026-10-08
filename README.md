# Ashen Expedition

A Godot 4 combat prototype with three hero decks, party turns, and a dark card battle interface.

Open `project.godot` in Godot 4.6 or later and press F6 on `battle.tscn`, or F5 to run the project. The original `Scripts` file is now `battle.gd`.

Select a living hero, play cards using their action points, and end the party turn to resolve enemy intent. Restart Battle resets the encounter. Health and stress meters, block values, and action points update with combat. Cards highlight and enlarge on hover or keyboard focus. The hand scrolls horizontally when needed.

Artwork is optional. Add transparent PNGs at:

- `assets/characters/warden.png`, `ranger.png`, and `occultist.png`
- `assets/enemies/hollow_villager.png`
- `assets/cards/<card_id>.png` (IDs are listed in `CARD_DATA` in `battle.gd`)

Missing artwork uses text placeholders. No artwork from the reference games is included.

For cloud/headless validation, use writable XDG directories:

```sh
export XDG_CACHE_HOME=/workspace/.cache
export XDG_DATA_HOME=/workspace/.local/share
export XDG_CONFIG_HOME=/workspace/.config
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
godot --headless --path /workspace/GameTest --editor --import --quit
godot --headless --path /workspace/GameTest --quit-after 10
```
