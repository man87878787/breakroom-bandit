# Snatch a Stickman

An original Roblox social-collection game prototype built around an instantly readable loop:

1. Stickmen spawn in the central market.
2. Players recruit them with coins.
3. Secured stickmen generate passive income.
4. Rival players can grab an unshielded stickman.
5. A steal is **not instant anymore**: the thief has to physically escape across the map.
6. The owner can catch up and recover the stickman before it is secured.
7. The thief only becomes the new owner after reaching their glowing green **SECURE** pad.
8. Each base has a timed shield with a cooldown.
9. Higher rarities cost more, generate more income, and create higher-stakes escape moments.

The goal is a simple, clip-friendly premise with social tension and visible progression, without copying another Roblox game's private code or assets.

## Current build

- Runtime-generated map; no external models required
- 6 player bases
- Central stickman market
- 5 rarity tiers
- Passive coin economy
- Recruit interactions using ProximityPrompt
- **Carry-and-escape stealing system**
- **Owner recovery interaction during an escape**
- **Movement penalty while carrying**
- **Green secure zone at every base**
- **Escape bonus for successful steals**
- Base shield with cooldown
- Server-authoritative coin, carry, and ownership logic
- Responsive custom HUD with escape-state banner
- Death / disconnect recovery handling
- No paid assets
- Session-only progress for the current playtest

## Open in Roblox Studio

This project is arranged for **Rojo**.

1. Install Rojo and the Rojo Roblox Studio plugin.
2. In this folder, run:
   \`\`\`bash
   rojo serve
   \`\`\`
3. Open a new Baseplate in Roblox Studio.
4. Connect the Rojo plugin to the running project.
5. Press **Play** or use a local multi-player test with 2-6 players.

The world builds itself when the server starts.

## Core playtest

Test with at least two players:

- Recruit a stickman.
- Wait for its short steal protection to expire.
- Have the rival grab it.
- The rival should move more slowly while carrying it.
- The original owner can run close and hold **Recover** on the carried stickman.
- If the thief reaches their own green **SECURE** pad first, ownership transfers and the thief gets an escape bonus.
- Dying before securing should return the stickman to its prior owner.

## What the next major updates should target

1. Persistence and session recovery
2. Mutations / visual traits that create jackpot moments
3. Rebirth and long-term progression
4. Better map art, movement juice, sound, VFX, and animation
5. First-session quests and rewards
6. Mobile-first interaction polish
7. Economy / retention analytics hooks
8. Private-server and friend-group social features
