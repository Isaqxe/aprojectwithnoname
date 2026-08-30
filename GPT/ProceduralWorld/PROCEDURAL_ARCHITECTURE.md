# Procedural World — Architecture Notes

## Current prototype

The current prototype is GPU-first:

```text
GPU shader
  ↓
EnvironmentMap (RGBA)
  ↓
Renderer + cached CPU readback
  ↓
CellSystem / Resources
```

RGBA channels:

- R = macro
- G = temperature
- B = humidity
- A = biome code

The CPU should only consume cached samples, never regenerate the whole world per frame.

## Alternative: hybrid chunk data

A future architecture may be preferable for a large simulation:

```text
World seed + chunk coordinate
        ↓
low-resolution environment data
        ↓
┌───────────────────┬───────────────────┐
│ CPU chunk data    │ GPU visualisation  │
│ biome/climate     │ interpolation      │
│ resource rules    │ borders/details    │
│ gameplay queries  │ surface variation  │
└───────────────────┴───────────────────┘
```

The CPU would generate only a compact low-resolution representation per loaded chunk, not every visible pixel. The GPU would interpolate/upscale that representation and add visual detail.

## Why this may be better

- No per-frame GPU → CPU texture readback.
- Gameplay receives deterministic native CPU data.
- Resources can query exact chunk data without reconstructing noise.
- Natural fit for CellSystem streaming and world chunks.
- Visual detail can remain GPU-only.

## Decision

Do not migrate yet. First validate the current GPU readback prototype and measure whether its cost is acceptable. If the readback or coordinate synchronization becomes a bottleneck, migrate the environment data layer to the hybrid chunk model while preserving the renderer and CellSystem APIs.
