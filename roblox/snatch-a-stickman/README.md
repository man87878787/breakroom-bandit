# Snatch a Stickman

A Roblox prototype built around a simple social loop:

1. Stickmen spawn in the central market.
2. Players recruit them with coins.
3. Owned stickmen generate passive income.
4. Rival players can snatch unshielded stickmen.
5. Each base has a short shield with a cooldown.
6. Higher rarities cost more and generate more income.

The goal is a very readable, viral-friendly premise without copying another Roblox game's private code or assets.

## Current prototype

- Runtime-generated map; no external models required
- 6 player plots
- 5 rarity tiers
- Passive coin economy
- Recruit / steal interactions using ProximityPrompt
- Base shield with cooldown
- Server-authoritative coin and ownership logic
- Simple custom HUD
- No paid assets
- Session-only progress for the first playtest

## Open in Roblox Studio

This project is arranged for **Rojo**.

1. Install Rojo and the Rojo Roblox Studio plugin.
2. In this folder, run:
   ```bash
   rojo serve
   ```
3. Open a new Baseplate in Roblox Studio.
4. Connect the Rojo plugin to the running project.
5. Press **Play** or use a local multi-player test with 2-6 players.

The world builds itself when the server starts.

## First playtest questions

- Is recruiting understandable within 10 seconds?
- Do players care when a higher-rarity stickman appears?
- Is stealing exciting or just annoying?
- Is 10 seconds of shield protection enough?
- Is the first useful purchase too slow or too fast?
- Do players have a reason to move through the middle of the map?

## Next build if the loop is fun

- Carry animation instead of instant transfer
- DataStore persistence
- Stickman mutations / traits
- Rebirths
- Daily streak
- Better base art and map theme
- Sound and juice
- Mobile-first buttons and haptics
- Server analytics for retention and economy tuning
