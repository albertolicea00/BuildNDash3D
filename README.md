# 🛹 BuildNDash3D

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![License: Source-Available](https://img.shields.io/badge/License-Source--Available-red.svg)](LICENSE)
[![Platform: Web | Android | iOS](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS-orange)](https://godotengine.org)
[![Genre: Asymmetric Co-op](https://img.shields.io/badge/Genre-Asymmetric%20Co--op-purple)](#asymmetric-co-op-roles)

A POV 3D asymmetric co-op runner. The **Runner 3D** navigates three lanes by switching, jumping, and sliding to avoid oncoming trains and barriers, while the **Track Builder** uses a top-down tactical overview or free camera to construct the track by placing lanes, obstacles, and power-ups.

---

## 🎮 Asymmetric Co-op Roles

This game requires **two players** working together with entirely different controls and perspectives:

*   **Player A (Track Builder) 🛹**: Controls track generation in real-time, placing lanes, ramps, obstacles, oncoming trains, and power-ups from a tactical overhead view or free camera.
*   **Player B (Runner 3D) 🏃**: Dashes down the 3 lanes, switching lanes laterally, jumping over obstacles, and sliding under barriers in first-person or third-person POV.

---

## 📡 Game Modes

You can play BuildNDash3D in three different ways:

1.  **Local (Single Device) 📱**: Screen-divided controls or split-screen interface on a single device (great for tablets or phones).
2.  **Offline LAN 📶**: Connect with another player on the same local Wi-Fi network. One player acts as host, and the other joins via local IP.
3.  **Local Server 🖥️**: Host starts an authoritative local server. The server manages all game logic (collisions, speeds, state validations), ensuring high integrity and synchrony.

---

## 🛠️ Tech Stack & Requirements

*   **Game Engine:** [Godot 4.x](https://godotengine.org/)
*   **Scripting Language:** GDScript (fully typed, clean code architecture)
*   **Networking Protocol:** ENet via Godot's High-Level Multiplayer API
*   **Export Profiles:** HTML5 (WebGL) for web browser play & Android (APK/AAB) + iOS (IPA) for mobile devices
*   **Assets:** CC0 (Public Domain) or original custom assets

### Feature Specs:
- **3D Lane-based Movement:** Smooth lateral lane switching (3 lanes), jumping, and sliding mechanics.
- **Procedural Synchronization:** Syncs obstacles and lane modifications in real-time between players.

---

## 🚀 Getting Started

### Prerequisites
- [Godot Engine 4.x](https://godotengine.org/download) installed on your system.

### Running the Project
1.  Clone this repository (or download the game folder).
2.  Open **Godot Engine** and select **Import**.
3.  Navigate to this folder and select `project.godot`.
4.  Run the project by pressing `F5` or clicking the **Play** button.

### Building / Exporting
To export to **Web**, **Android**, or **iOS**:
1.  Go to `Project` -> `Export...` in the Godot Editor.
2.  Select your target profile (**Web**, **Android**, or **iOS**).
3.  Set up the export paths and click **Export Project**.

---

## 🤝 Contributing & Legal

*   **Code of Conduct:** Adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).
*   **Contributing Guidelines:** Check [Contributing Guidelines](CONTRIBUTING.md).
*   **Security Policy:** Report vulnerabilities via our [Security Policy](SECURITY.md).
*   **End User License Agreement:** Play and distribute according to the [EULA](EULA.md).
*   **Privacy Policy:** Read how we treat your data in the [Privacy Policy](PRIVACY_POLICY.md).

---

## 📄 License

This repository is licensed under a custom **Source-Available License** for educational and reference purposes only. See the [LICENSE](LICENSE) file for the full terms.

*Note: Third-party assets used in this project remain subject to their respective CC0 (Public Domain) or other original licenses.*
