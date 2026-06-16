# Tower

Physics-based iOS tower building game built with **SpriteKit** and **SwiftUI**.

Stack blocks of different shapes and materials, survive tilt gravity and wind, and reach the target height to clear each level.

## Requirements

- Xcode 15+ (iOS 17 deployment target)
- iPhone or iPad simulator / device
- Physical device recommended for **tilt gravity** (CoreMotion)

## Open and run

```bash
open Tower.xcodeproj
```

1. Select the **Tower** scheme
2. Choose an iOS Simulator or connected device
3. Press **Run** (⌘R)

### Simulator tilt controls

On the simulator, enable **Sim Tilt** in the debug panel (bottom-left during gameplay) and use the Roll/Pitch sliders to steer gravity.

### Device tilt

Hold the phone naturally; gravity follows device pitch and roll. Neutral pose is calibrated when a level starts.

## Gameplay

- **Drag** on the playfield to position a block, **release** to place
- Tap **Rotate** to turn the selected queue block 90°
- Reach the dashed **TARGET** line and hold steady for 2 seconds to win
- If a block falls off the platform → level failed

### Materials

| Material | Feel |
|----------|------|
| Wood | Balanced baseline |
| Ice | Slippery, drifts easily |
| Rubber | Grippy and bouncy |
| Metal | Heavy, stabilizes the base |

### Stars

- 1★ — Complete the level
- 2★ — Use ≤ par blocks
- 3★ — No block crossed the fail line

Progress is saved locally on device (`UserDefaults`).

## Project structure

```
Tower/
├── App/           # SwiftUI app entry, navigation
├── Game/          # SpriteKit scene, physics, models
├── UI/            # Menus, HUD, level select
├── Data/Levels/   # world1.json … world6.json (30 levels)
├── Audio/         # Sound manager
└── Resources/     # Assets
```

## Level data format

Levels live in `Tower/Data/Levels/worldN.json`:

```json
{
  "world": 1,
  "title": "Foundations",
  "levels": [{
    "levelId": 1,
    "name": "First Steps",
    "targetHeight": 80,
    "holdDuration": 2.0,
    "maxBlocks": 12,
    "blockQueue": ["wood_rectangle", "wood_square"],
    "wind": { "baseStrength": 0, "gustFrequency": 0, "direction": "right" },
    "tiltSensitivity": 1.0,
    "platformWidth": 6.0,
    "parBlocks": 6
  }]
}
```

Block tokens: `{material}_{shape}` — e.g. `metal_plank`, `ice_triangle`.

## Regenerate Xcode project

This repo uses [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
```

## Spec

See [SPEC.md](SPEC.md) for full game design documentation.
