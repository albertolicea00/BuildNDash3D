# AGENTS.md — BuildNDash3D (3D POV Runner)

3D asymmetric co-op game, Subway Surfers / Temple Run / Minion Rush / POV runner style.

> All code, comments, and docs in English, with good meaningful comments.

## Players
- **Player A (Track Builder):** places lanes, obstacles, trains, ramps, power-ups. Top-down view or free camera.
- **Player B (Runner 3D):** runs on 3 lanes, dodges, slides, jumps.

## Modes
1. **Local (same device):** split screen or overlaid interface.
2. **Offline LAN (no internet):** host + client over local IP (`ENetMultiplayerPeer`).
3. **Local Server:** host runs an authoritative internal server that controls:
   - procedural track generation
   - speed
   - obstacles
   - lane synchronization
   - collisions

## Technical requirements
- Godot 4.x (GDScript)
- Android + Web (WebGL) export
- 3D lane-based movement (3 lanes, lateral switch, jump, slide)
- Low-poly art
- Builder with top-down view or free camera
- **No third-party copyrighted assets** — only CC0 or original art
- Modular code (logic / networking / UI separated)
- Independent project: do NOT share anything with the other games in the monorepo

## Art style
Low poly runner, Subway Surfers style but original. Flat colors, no textures, mobile optimized.

---

## 🟩 FREE copyright-free assets (CC0)

### 🧱 3D Low Poly
- Kenney 3D → https://kenney.nl/assets
- Poly Pizza (CC0) → https://poly.pizza
- Quaternius (rigs, characters, low poly) → https://quaternius.com
- Itch.io 3D CC0 → https://itch.io/game-assets/free/tag-cc0

### 🔊 Sound and music
- Kenney Audio
- Freesound.org (filter CC0)
- Mixkit
- OpenGameArt Audio

## 🟦 AI-generated assets
- Leonardo.ai (great for 3D low poly), Flux/Midjourney, Stable Diffusion (local)

### Base prompt
> "low poly 3D models, mobile optimized, no textures, only flat colors, CC0 style, clean geometry, for a runner game"

---

## Wishlist (not implemented yet)

- **Online multiplayer:** current netcode is LAN-only (ENet over local IP, manual IP entry). Future: dedicated server reachable over the internet + matchmaking/relay. The authority model is already server-side (host validates everything in "Local Server" mode), so the migration path is extracting the host logic into a headless Godot server.
