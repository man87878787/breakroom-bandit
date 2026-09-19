# Snatch the Stickman

**Snatch the Stickman** is an original Roblox social-collection game built around a readable risk/reward loop:

1. Recruit stickmen from the central market.
2. Grow passive income and upgrade your base.
3. Raid an unshielded rival and grab one of their stickmen.
4. Escape across the map while moving more slowly.
5. Reach your green **SECURE** pad before the owner recovers the stickman.
6. Build a better collection, complete session missions, and push a longer snatch streak.

The project uses original code and runtime-generated geometry; it does not copy proprietary code or assets from other Roblox experiences.

## 50-point improvement pass

This branch includes a cohesive launch-readiness pass with exactly 50 concrete improvements:

1. Renamed the player-facing game identity to **Snatch the Stickman**.
2. Renamed the Rojo project to `SnatchTheStickman`.
3. Renamed the runtime world folder to `SnatchTheStickmanWorld`.
4. Added persistent stickman collection data.
5. Added safe restoration of saved collections on join.
6. Added rarity validation while restoring saved collections.
7. Added a hard collection-data size limit before saving.
8. Added persistent income-upgrade levels.
9. Added persistent capacity-upgrade levels.
10. Added persistent shield-upgrade levels.
11. Added persistent lifetime recruit totals.
12. Added persistent lifetime successful-snatch totals.
13. Added persistent best-snatch-streak tracking.
14. Added persistent lifetime coins-earned tracking.
15. Kept the existing DataStore name so older saved coins migrate forward.
16. Added a profile-ready interaction gate so purchases/raids cannot race a load.
17. Added fail-open playability when DataStore reads fail.
18. Prevented failed initial loads from overwriting valid saved data.
19. Added retry/backoff for DataStore reads and writes.
20. Increased autosave frequency to 45 seconds.
21. Kept forced saves on player exit and server shutdown.
22. Added replicated save-state feedback for the HUD.
23. Added rejoin steal protection for restored stickmen.
24. Added temporary base protection when a player first joins.
25. Added capacity progression from 8 to 10 to 12 crew slots.
26. Added permanent passive-income multipliers.
27. Added shield-duration progression.
28. Added shield-cooldown progression.
29. Added three physical upgrade stations at every owned base.
30. Added owner-only validation for upgrade purchases.
31. Added price and max-level feedback on upgrade pads.
32. Added a recruit session mission.
33. Added an earn-coins session mission.
34. Added a successful-snatch session mission.
35. Added one-time session mission rewards.
36. Added duplicate-claim protection for mission rewards.
37. Added a successful-snatch streak system.
38. Added scaling escape bonuses for longer streaks.
39. Added streak reset when a steal is recovered or otherwise fails.
40. Added a hard cap on unowned market stock.
41. Increased and stabilized initial market stock.
42. Added periodic forced affordable Common spawns.
43. Added server-wide announcements for Legendary and Glitched market spawns.
44. Added glow treatment to Epic, Legendary, and Glitched stickmen.
45. Improved stickman info billboards with cleaner income timing text.
46. Added dynamic base signs showing crew capacity and income rate.
47. Rebuilt the HUD with live coins, income, crew, streak, missions, and save status.
48. Added live shield/join-protection countdowns and distance-to-SECURE feedback.
49. Added mobile/small-screen HUD adaptation and coin-gain animation.
50. Added a launch-polish world pass: evening lighting, atmosphere, bloom, rails, market outline, title board, lit routes, lamps, and a center beacon.

## Current gameplay systems

- Six player bases
- Central rarity-based stickman market
- Five rarity tiers: Common, Rare, Epic, Legendary, and Glitched
- Persistent coins, collections, upgrades, and lifetime stats
- Passive coin economy with permanent income upgrades
- Expandable crew capacity
- Carry-and-escape stealing
- Owner recovery during an escape
- Movement penalty while carrying
- Green SECURE zones
- Streak-scaled escape bonuses
- Timed base shield with permanent upgrades
- Join and rejoin protection windows
- Three session missions with coin rewards
- Market stock pacing and affordable-spawn protection
- Responsive custom HUD
- Runtime-generated world polish
- Death/disconnect carry recovery
- Server-authoritative gameplay state
- No paid or copied assets

## Open in Roblox Studio

This project is arranged for **Rojo**.

```bash
rojo serve
```

Open a Baseplate in Roblox Studio, connect the Rojo plugin, and start a local multiplayer test with 2–6 players. The world builds itself when the server starts.

For persistence testing in Studio, publish the experience and enable Studio access to API Services.

## Core multiplayer verification

Test these flows with at least two players:

- Join and confirm the profile reaches a ready/saved state.
- Recruit multiple rarities and confirm they reappear after rejoining.
- Buy all three upgrade types and confirm they persist.
- Confirm capacity upgrades allow 10 and then 12 stickmen.
- Confirm income upgrades increase the HUD income rate and actual payouts.
- Confirm shield upgrades improve duration/cooldown.
- Confirm join protection blocks immediate raids.
- Let steal protection expire, grab a rival stickman, and verify the carry slowdown.
- Recover a carried stickman and confirm the thief's streak resets.
- Secure a stolen stickman and confirm ownership, bonus coins, mission progress, and streak update.
- Complete all three session missions and confirm each reward only pays once.
- Verify market stock remains bounded over a long server session.
- Rejoin and confirm coins, crew, upgrade levels, and lifetime stats survive.

## Next highest-impact targets

The strongest next step is a **collection-book + rebirth/prestige layer**: a proper rarity catalog, discovery completion, duplicate value, prestige resets with permanent multipliers, and analytics around first-session completion. After that, animation/audio/VFX and a custom authored map would provide the biggest presentation lift.
