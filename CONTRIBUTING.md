# Contributing to BuildNDash3D

Thanks for your interest in contributing! Please follow these guidelines.

## Ground rules

- **English only:** all code, comments, identifiers, docs, and commit messages must be in English.
- **Good comments:** explain *why*, not just *what*. Every non-obvious block of GDScript should have a meaningful comment.
- **No copyrighted material:** only original art or CC0 assets. Never commit copyrighted art, music, or names.
- **Read the spec first:** read `AGENTS.md` for the game specification. Changes must respect it.

## Development setup

1. Install [Godot 4.x](https://godotengine.org/download).
2. Open this folder as a Godot project in Godot.
3. Make sure the project still exports to Web, Android, and iOS after your changes.

## Code style (GDScript)

- `snake_case` for variables, functions, signals; `PascalCase` for classes and node names.
- One script per responsibility — avoid god scripts.
- Keep game logic, networking, and UI in separate modules.
- Use typed GDScript where possible (`var speed: float = 200.0`).

## Workflow

1. Fork the repo and create a branch from `main`:
   `git checkout -b feat/<short-description>` (e.g., `feat/mechanic-update`).
2. Make your changes with clear, focused commits.
3. Test all three modes if your change touches gameplay or networking: Local, Offline LAN, Local Server.
4. Open a Pull Request using the PR template.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add role-specific functionality
fix: prevent synchronization offsets during LAN play
docs: update building constraints in AGENTS.md
```

## Reporting bugs / requesting features

Use the GitHub issue templates. Include the mode (Local / LAN / Local Server) and reproduction steps.
