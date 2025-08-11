# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

This is a Godot 4 game project called "Serein" - a third-person action game built with GDScript. The project uses the Jolt Physics engine and features a character controller named "Timmy" with a third-person camera system.

## Build and Export Commands

The project uses Godot's built-in export system. Export presets are configured in `export_presets.cfg`:

- **Web Build**: Exports to `../../../Builds/ElijahFarhaad/Web/index.html`
- **Windows Build**: Exports to `../../../Builds/ElijahFarhaad/Serein.exe`

To export from command line:
```bash
# Export for Web
godot --headless --export-release "Web" path/to/output/index.html

# Export for Windows
godot --headless --export-release "Windows Desktop" path/to/output/Serein.exe
```

## Architecture and Code Structure

### Core Systems

- **Global State Management**: `Scripts/globals.gd` contains scene paths and global flags
- **Character Controller**: `Scripts/timmy.gd` handles player movement, animation, and input
- **Camera System**: `Scripts/TPSCamera.gd` implements third-person camera with dynamic FOV and positioning
- **UI Systems**: Settings, pause menu, and main menu controllers in `Scenes/UI/`

### Scene Organization

- `Scenes/Levels/` - Game levels (main level is O-Block.tscn)
- `Scenes/UI/` - User interface scenes (main menu, settings, pause)
- `Scenes/Timmy/` - Character assets and setup
- `Scenes/Loading Screen/` - 3D loading screen implementation

### Input System

Custom input actions defined in `project.godot`:
- Movement: WASD (forward/backward/left/right)
- Jump: Space
- Sprint: Left Shift
- Vault/Interact: E
- Pause: Escape

### Animation System

- Uses AnimationTree and AnimationPlayer for character animations
- Character resources stored in `Resources/` directory
- Animation states managed through `Scripts/timmy.gd`

### Audio System

- Background music and sound effects in `Audio/` directory
- Footstep audio system integrated with character movement
- Voice lines and ambient sounds for game atmosphere

## Development Notes

- Main scene is set via UID reference in project.godot
- Auto-load singleton: `Globals` script for cross-scene data
- Physics engine: Jolt Physics for 3D physics simulation
- Target resolution: 1920x1080 with viewport stretching
- Animation FPS: 60 fps for smooth character animations

## Key Gameplay Features

- Third-person character movement with sprinting
- Dynamic camera system with FOV changes based on movement state
- Vaulting/interaction system
- Loading screen with 3D scene preview
- Pause/settings menu system with audio controls

## Important Notes

- Never create TSCN or TRES files. 
- Never modify them either
- Always provide instruction to the user to create scenes or resources