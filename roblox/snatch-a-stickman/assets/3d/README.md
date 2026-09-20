# Snatch the Stickman — 3D Source Assets

This folder contains original source assets created specifically for Snatch the Stickman.

## snatch-world-props-v1

- `snatch-world-props-v1.blend` — editable Blender source.
- `snatch-world-props-v1.glb` — portable export for review/import.
- Created as a low-poly Roblox-friendly prop kit.
- No third-party meshes, textures, logos, characters, or proprietary game assets are included.

### Included prop concepts

1. **Rarity Vault Pod** — presentation pedestal/cage for high-value stickmen.
2. **Transit Terminal** — compact city fast-travel kiosk concept.
3. **Bounty Board** — physical contract/bounty presentation prop.
4. **Freight Rare Cargo** — beacon crate for Scrapline Freight events.

These source assets are intentionally separate from runtime collision/gameplay geometry. Gameplay-critical collision, prompts, rewards, and server authority remain implemented in Luau so the game does not depend on imported mesh behavior.

Before publishing a mesh version to Roblox, import the GLB into Studio, verify scale/orientation/materials, generate simple collision, and replace only the matching presentation geometry. Do not replace server-authoritative interaction logic with mesh-local behavior.
