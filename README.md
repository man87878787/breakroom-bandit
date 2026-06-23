# Breakroom Bandit

A top-down **stealth arcade game** built with [Pygame](https://www.pygame.org/).
You play an office worker pulling off the ultimate snack heist: collect coins,
raid the vending machines, and stay one step ahead of the Boss — who unlocks a
brand-new superhuman sense **every time you secure a snack**.

The tone is deliberately silly. Nobody is scary, the Boss has angry little
eyebrows, and the worst that happens is a mandatory team-building chat.

## How it plays

1. Wander the office picking up **coins** (gold circles).
2. Step onto a **vending machine** (`$`, green) with enough coins to auto-buy a
   snack. Each snack secured is a point — and an upgrade to the Boss's AI.
3. Keep your **sleepiness meter** topped up at a **coffee station** (`C`, brown).
   If it empties, you doze off at your desk. Game over.
4. Secure **5 snacks** to clock out a legend.

## The Boss's escalating senses

The Boss starts out wandering blindly. Each snack you secure makes him smarter:

| Snacks secured | New sense | How to beat it |
| -------------- | --------- | -------------- |
| 0 | None — aimless wandering | Just don't bump into him |
| 1 | **Hearing** — detects running footsteps nearby | Hold **Shift** to sneak slowly and quietly |
| 2 | **Scent** — tracks the trail you leave behind | Press **Space** to spill coffee and break the trail |
| 3 | **Sight** — line-of-sight vision in lit corridors | Stand **completely still** to hide under a cardboard box |

The HUD always shows which senses are currently active and flashes a big alert
(`BOSS HEARS YOU!`, `BOSS NOSES YOU!`, `BOSS EYES YOU!`) the moment one of them
locks onto you.

## Controls

| Key | Action |
| --- | ------ |
| `W` `A` `S` `D` / arrow keys | Move |
| `Shift` (hold) | Sneak slowly (silent footsteps) |
| `Space` | Spill coffee (breaks the scent trail) |
| *(stop moving)* | Hide under a cardboard box (invisible to sight) |
| `Enter` | Start / restart |
| `Esc` | Quit |

## Running it

```bash
pip install -r requirements.txt
python main.py
```

## Project layout

```
breakroom_bandit/
  settings.py   # constants, colors, the office map, sense schedule
  level.py      # map parsing, collision, line-of-sight
  pathing.py    # BFS the Boss uses to chase
  entities.py   # Player, Boss, Coin, ScentMarker, Spill
  game.py       # main loop, state machine, HUD, rendering
main.py         # launcher
tests/          # headless smoke tests (SDL dummy driver)
```

## Tests

```bash
SDL_VIDEODRIVER=dummy python tests/test_smoke.py
```
