# Steal a Tower of Hell

Original Roblox tower-heist game foundation.

## Core loop
1. Claim a tower plot.
2. Climb and improve your tower.
3. Raid another player's tower.
4. Reach the steal objective and escape.
5. Bank rewards and upgrade your tower, movement, and defenses.

## Architecture
- `src/shared`: configuration and network contracts.
- `src/server`: authoritative gameplay services.
- `src/client`: presentation/input only.
- Server owns economy, tower ownership, stealing, rewards, and persistence.

## Tooling
The only required project dependency is Rojo 7.7.0 through Rokit.

Build:
`rojo build default.project.json -o StealATowerOfHell.rbxlx`

The project intentionally starts without external gameplay packages so core systems remain auditable and lightweight.
