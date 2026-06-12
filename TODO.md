# TODO — BuildNDash3D

Living checklist. Items are checked (`[x]`) when done — never deleted.

## Project setup

- [x] Godot 4.x project (`project.godot`, GL Compatibility renderer for Web + Android + iOS)
- [x] Entry scene `scenes/main.tscn` + code-built UI
- [x] `Net` autoload (`scripts/net.gd`) — LOCAL / HOST / CLIENT, port 7804
- [x] Repo files: README, LICENSE, EULA, PRIVACY_POLICY, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, AGENTS.md, TODO.md, .github templates, .gitignore

## Core gameplay

- [x] Runner 3D: 3 lanes, lane switch, jump, slide; manual kinematics (`scripts/runner_3d.gd`)
- [x] Server timeline: speed ramps 10 → 22 m/s
- [x] Procedural track: floor segments generated ahead, freed behind
- [x] Ambient obstacle rows every 14 m, always ≥1 free lane
- [x] Obstacle kinds: low barrier (jump), high barrier (slide), train (switch lane), ramp (launch), shield power-up
- [x] Track Builder: type selector + Drop LEFT/CENTER/RIGHT buttons (2.5s cooldown), drop 35 m ahead
- [x] Distance-based collision resolution (no physics bodies, platform-stable)
- [x] Runner POV chase camera; aerial top-down camera for the remote Track Builder
- [x] Distance score HUD + cooldown bar + shield indicator
- [x] Game over panel + restart + back to menu

## Modes

- [x] Local (same device): Runner gestures/keys + Track Builder HUD overlay buttons
- [x] Offline LAN: host + client by IP (`ENetMultiplayerPeer`)
- [x] Local Server: strict host-side validation (cooldown, lane, kind)
- [x] State sync: unreliable snapshot (runner transform, lane, slide, score, shield) + reliable spawn/free/restart RPCs

## Polish / pending

- [ ] Manual playtest: balance speed ramp, drop distance, hit windows
- [ ] LAN playtest on two devices
- [ ] Split-screen local option (SubViewports) — spec allows overlay OR split screen
- [ ] Runner animations (lean on lane switch, jump squash/stretch)
- [ ] Coins / collectible trail between obstacles
- [ ] More power-ups (magnet, multiplier)
- [ ] Scenery props alongside track (low-poly buildings, trees)
- [ ] Sound effects (whoosh, hit, pickup) — CC0 or original
- [ ] Background music — CC0 or original
- [ ] Pause menu
- [ ] High score persistence (local save)
- [ ] Web export preset + test in browser (WebGL performance check)
- [ ] Android + iOS export presets + test on device
- [ ] App icon final art + splash screen

## Wishlist

- [ ] Online multiplayer: dedicated headless server + matchmaking/relay
- [ ] Curved/branching track sections
- [ ] Role swap option
