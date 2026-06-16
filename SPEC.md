# Tower — Physics-Based iOS Tower Building Game

## 1. Overview

**Tower** is a physics-based puzzle game for iOS where players stack blocks of different shapes and materials to reach a target height. The tower must survive real-time forces: device tilt (gravity), wind, and material interactions. Success requires both structural planning and active balance.

**Platform:** iOS (iPhone; iPad optional)  
**Genre:** Physics puzzle / casual builder  
**Session length:** 1–3 minutes per level  
**Core loop:** Select block → place on tower → survive physics → reach height goal

---

## 2. Design Pillars

| Pillar | Description |
|--------|-------------|
| **Tactile physics** | Every block feels distinct; failures are readable and fair |
| **Active play** | Tilt and wind mean the tower is never truly “finished” until the goal is met |
| **Expressive materials** | Material choice matters as much as shape |
| **Juicy feedback** | Placement, stress, wobble, collapse, and victory all feel animated and satisfying |

---

## 3. Core Gameplay

### 3.1 Objective

Each level defines a **target height** (measured from the ground plane to the highest stable point of the tower). The player wins when:

1. The tower reaches or exceeds the target height, **and**
2. The structure remains stable for a **hold duration** (e.g. 2 seconds) without any block falling below a fail line.

### 3.2 Building Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│ Block queue │ ──► │ Select/rotate│ ──► │ Place block │ ──► │ Physics sim  │
│  (3–5 next) │     │   preview    │     │  (tap/drag) │     │  + survive   │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                                                                      │
                                      ┌───────────────────────────────┘
                                      ▼
                            ┌──────────────────┐
                            │ Height check +   │
                            │ stability hold   │
                            └──────────────────┘
```

1. Player sees a **block queue** (next 3–5 pieces).
2. Player selects a block, optionally **rotates** it (90° steps).
3. Player **places** the block on the tower or ground via drag-and-drop or tap-to-drop.
4. Physics runs continuously; tilt and wind apply.
5. On reaching target height + hold time → **level complete**.
6. If any block crosses the **fail line** (falls off platform) → **level failed** (retry).

### 3.3 Placement Rules

- Blocks snap to a coarse grid only if **optional assist mode** is enabled; default is free placement with soft magnetic snap near edges.
- Overlap at placement time is rejected (block returns to queue).
- Maximum **active blocks** per level may be capped (e.g. 20) to encourage efficient design.
- A brief **placement cooldown** (0.3s) prevents spam placement during collapse.

---

## 4. Block Shapes

Blocks are 2D physics bodies (side-view tower). Shapes affect center of mass, contact points, and stacking difficulty.

| Shape | Description | Gameplay role |
|-------|-------------|---------------|
| **Rectangle** | Standard brick | Stable, beginner-friendly |
| **Square** | Equal sides | Good pillar block |
| **Triangle** | Ramp / wedge | Deflects wind, tricky base |
| **L-shape** | Tetromino-L | Hooks over edges, high skill |
| **T-shape** | Tetromino-T | Wide top, unstable on narrow bases |
| **Circle / cylinder** | Rolling profile | High roll risk; rubber helps |
| **Thin plank** | Low height, long span | Bridges gaps; bends under load |
| **Arc / half-circle** | Curved top | Blocks slide off easily |

Each shape has a fixed **collision hull** and **density** baseline; material modifiers apply on top.

---

## 5. Materials

Materials modify friction, restitution, density, damping, and optional special behaviors.

| Material | Density | Friction | Restitution | Special |
|----------|---------|----------|-------------|---------|
| **Wood** | Medium | Medium-high | Low | Baseline; slight vibration damping |
| **Ice** | Low-medium | Very low | Low | Slippery; blocks slide on contact |
| **Rubber** | Low | Very high | High | Grippy; absorbs impact, bouncy |
| **Metal** | High | Medium | Low | Heavy; high inertia, stabilizes base |

### 5.1 Material Interactions

- **Ice on ice:** Extra-low friction (super-slip).
- **Rubber on any:** +friction bonus at contact; reduces slide.
- **Metal on wood:** Wood compresses slightly (visual only + tiny sink).
- **Ice + wind:** Higher lateral drift than other materials.
- **Rubber + tilt:** Reduces micro-sliding during gravity shifts.

### 5.2 Material Availability by Level

Early levels introduce one material at a time. Later levels mix materials in the queue and allow **material hints** in the UI (color + icon).

---

## 6. Physics Systems

### 6.1 Engine

Use a 2D rigid-body engine (recommended: **SpriteKit** with `SKPhysicsBody`, or **Unity 2D** / **Box2D** if cross-platform is planned).

Fixed timestep simulation: **60 Hz** physics, interpolated rendering.

### 6.2 Gravity via Device Tilt

| Input | Mapping |
|-------|---------|
| `CMMotionManager` device attitude | Gravity vector in world space |
| Pitch / roll | Rotate gravity direction (magnitude fixed at ~9.81 m/s²) |
| Flat phone | Gravity points straight down |

**Tuning:**
- Max tilt angle clamped to ±30° from vertical for playability.
- Gravity direction **smooths** over 100–150ms to avoid jitter from noisy sensors.
- Optional **calibration** on level start (set current pose as “neutral”).

**Gameplay effect:** Players actively counter lean by choosing wide bases, heavy metal anchors, and rubber grip layers.

### 6.3 Wind

Wind is a horizontal force field applied to all non-kinematic blocks.

| Parameter | Behavior |
|-----------|----------|
| **Base strength** | Scales per level (0 → strong) |
| **Direction** | Left or right; occasional gusts |
| **Variation** | Perlin / sine noise over time |
| **Gust events** | Random spikes (1–2s) with telegraph |

**Telegraph (fairness):**
- 0.5s before a gust: leaves/particles blow, flag icon pulses, subtle whoosh SFX.
- UI **wind meter** shows direction and approximate strength.

**Force model:**
```
F_wind = wind_strength(t) * exposed_area(block) * drag_coeff(material)
```
Tall stacks and light materials (ice, rubber) feel wind more; metal resists via mass.

### 6.4 Structural Stability

- Joint breaking is **not** used initially; pure rigid-body friction/stacking.
- Optional later feature: **stress cracks** on wood when shear exceeds threshold.
- **Sleeping bodies** wake on wind gust or gravity shift beyond ε.

### 6.5 Failure Conditions

| Condition | Result |
|-----------|--------|
| Any block falls below fail Y | Immediate fail |
| Tower height drops below target for > 1s after reaching it | Fail (anti-luck) |
| Block comes to rest outside platform bounds | Fail |

---

## 7. Level Design

### 7.1 Level Parameters

Each level JSON / config defines:

```yaml
level_id: 12
target_height: 18.0        # meters (world units)
hold_duration: 2.0         # seconds
max_blocks: 15
block_queue: [wood_rect, ice_square, rubber_triangle, ...]
wind:
  base_strength: 0.4
  gust_frequency: 0.2
  direction: random
tilt_sensitivity: 1.0
platform_width: 6.0
par_blocks: 10             # optional 3-star threshold
```

### 7.2 Progression Curve

| World | Theme | New mechanic |
|-------|-------|--------------|
| 1 | Foundations | Wood, basic shapes, no wind |
| 2 | Slippery slopes | Ice, low friction |
| 3 | Grip & bounce | Rubber |
| 4 | Heavy metal | Metal, weight puzzles |
| 5 | Sky high | Wind + mixed materials |
| 6 | Storm | Strong wind + full tilt |

### 7.3 Scoring (Optional)

- ★ **Reach height** — complete the level
- ★★ **Par blocks** — use ≤ par block count
- ★★★ **No drops** — no block hit fail line during run

---

## 8. Controls & UI

### 8.1 Input

| Gesture | Action |
|---------|--------|
| Drag block from queue | Position over tower |
| Release | Drop / place |
| Two-finger rotate (or tap rotate button) | Rotate 90° |
| Pause button | Pause sim; tilt ignored while paused |

### 8.2 HUD

- **Height meter** — current vs target (vertical bar beside tower)
- **Wind indicator** — arrow + strength bars
- **Block queue** — bottom tray with material color coding
- **Tilt hint** — subtle bubble level overlay (optional, tutorial only)

### 8.3 Visual Language

| Material | Color | Surface |
|----------|-------|---------|
| Wood | Warm brown | Grain texture |
| Ice | Cyan / white | Gloss, specular highlight |
| Rubber | Red or dark gray | Matte, slight squash on impact |
| Metal | Silver / steel blue | Brushed metal, sharp highlights |

---

## 9. Animation & Juice

### 9.1 Principles

Animations sell **weight**, **contact**, and **danger** without obscuring physics.

### 9.2 Placement

- **Ghost preview** — semi-transparent block with green/red validity
- **Drop** — 80ms ease-in; tiny squash on landing (scale Y 0.92 → 1.0)
- **Invalid** — shake + red flash

### 9.3 Ambient & Reactive

- Tower **wobble** sprite offset proportional to center-of-mass sway (not affecting physics)
- **Wind particles** — leaves, dust streaks matching wind vector
- **Stress shake** — blocks tremble when friction is near slip threshold
- Camera **subtle parallax** on tilt (2–5% offset)

### 9.4 Events

| Event | Animation |
|-------|-----------|
| Gust warning | Flag whip, UI pulse, particle surge |
| Near fail | Screen edge red vignette, heartbeat haptic |
| Block slip | Brief spark/dust at contact point |
| Level complete | Confetti, height banner slam, star burst |
| Collapse | Brief slow-mo (0.3s at 50% speed), then fail banner |

### 9.5 Haptics (`UIImpactFeedbackGenerator`)

- Light impact on place
- Medium on gust
- Heavy rumble during collapse
- Success pattern on win

---

## 10. Audio

| Category | Examples |
|----------|----------|
| **Impacts** | Material-specific (wood thud, metal clang, rubber squeak, ice tick) |
| **Wind** | Looping airy bed + gust whoosh one-shots |
| **UI** | Soft clicks, queue shuffle |
| **Music** | Light acoustic / playful; intensity rises with tower height |
| **Fail / win** | Sting + resolve chord |

Use **pitch variation** on repeated impacts to avoid fatigue.

---

## 11. Technical Architecture (iOS)

### 11.1 Recommended Stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI (menus) + SpriteKit (game scene) |
| Physics | SpriteKit physics or Box2D via bridge |
| Sensors | CoreMotion (`CMMotionManager`) |
| Persistence | SwiftData or JSON for level progress |
| Haptics | `CoreHaptics` |

### 11.2 Scene Graph

```
GameViewController
├── HUD (SwiftUI overlay)
└── SKScene (TowerScene)
    ├── CameraNode (follow + parallax)
    ├── PlatformNode (static)
    ├── BlockNodes[] (dynamic physics bodies)
    ├── WindParticleEmitter
    └── Background layers
```

### 11.3 Performance Targets

- 60 FPS on iPhone 12 and newer
- Max ~40 active rigid bodies per scene
- Sleep inactive bodies; joint-less design preferred

### 11.4 Testing Hooks

- Debug overlay: gravity vector, wind force, friction at contacts
- **Simulated tilt** slider (Simulator)
- **Wind override** for reproducible QA

---

## 12. Monetization (Optional)

- Premium: one-time purchase, all worlds
- Or: free first world + IAP for worlds 2–6
- No pay-to-skip physics; cosmetic block skins only

---

## 13. MVP Scope

### Phase 1 — Vertical Slice
- [ ] 1 platform, 4 materials, 4 shapes
- [ ] Tilt gravity + basic wind
- [ ] 5 tutorial levels
- [ ] Place, fail, win flow
- [ ] Core animations (place squash, wind particles, win confetti)

### Phase 2 — Content
- [ ] 30 levels across 3 worlds
- [ ] Star scoring
- [ ] Level select map

### Phase 3 — Polish
- [ ] Full audio suite
- [ ] Haptics
- [ ] iCloud save
- [ ] iPad layout

---

## 14. Open Questions

1. **2D side view vs. isometric?** Spec assumes 2D side view; isometric changes placement UX.
2. **Real-time vs. turn-based placement?** Spec assumes real-time physics during building.
3. **Multiplayer?** Not in scope; async “ghost tower” leaderboards possible later.
4. **Block crafting?** Queue is level-authored; no crafting in MVP.

---

## 15. Glossary

| Term | Definition |
|------|------------|
| **Hold duration** | Time tower must stay at target height before win |
| **Fail line** | Y-coordinate below which a fallen block triggers failure |
| **Block queue** | Ordered list of upcoming pieces |
| **Gust** | Short wind intensity spike |
| **Par** | Target block count for 2-star rating |
