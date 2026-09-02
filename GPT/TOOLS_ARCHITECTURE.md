# Alive Cells — Experimental Tools Architecture

This document reserves a separate layer for simulation-control tools. The NEO genetic system remains unchanged while tools are developed.

## Baseline

NEO baseline commit: `7756af0408c33d434f382b07c034570405937ecb`

## Goals

Provide developer-facing simulation controls for spawning cells and resources, applying mutations, controlling simulation time, and temporarily influencing environmental conditions.

## Rules

- Tools must not modify NEO definitions or formulas.
- Tools act on the running simulation through existing simulation interfaces.
- Tool state is separate from scientific simulation state whenever possible.
- Normal simulation remains usable without opening the tools UI.
- Every tool should be safe to use repeatedly and should fail gracefully when a target is unavailable.

## Planned groups

### Population
- Spawn cell at mouse position.
- Spawn resource at mouse position.
- Optional burst/count controls.
- Optional species selection for cells.

### Genetics
- Mutate selected cell.
- Repeat mutation passes for controlled experiments.
- Mutation result feedback.
- No direct genotype editing in v1.

### Time
- Pause/resume.
- Simulation speed presets.
- One Tick is defined as `0.1` simulation seconds in the tools layer.
- Existing elapsed simulation time remains the source clock; the debug display exposes it as integer Ticks.
- Step-one-Tick is reserved for a later deterministic clock implementation.

### Environment
- Temperature control.
- Humidity control.
- Food density control.
- Changes affect the current laboratory domain only.
- Reset to baseline environment values.

## Architecture

The tools layer is an independent controller/UI scene that requests actions from existing systems rather than owning biology.

Preferred dependency direction:

`Tools Scene/UI -> SimulationTools -> CellManager / WorldResourceSpawner / ExperimentalDomain / simulation clock`

The NEO system remains:

`CellManager -> CellFactory -> Cell -> CellGenetics -> GeneData / GeneFormulas`

Tools must not rewrite NEO definitions or formulas. A mutation tool may request mutation from the selected cell's existing `CellGenetics`, then request the existing biology application path.

The `CellInspector` remains the authoritative owner of cell selection. Tools obtain the selected cell through the Inspector's public `get_selected_cell()` method instead of reading its private state.

Spawn interaction is explicitly modal:

`Normal -> Spawn Cell` or `Spawn Resource -> click world -> perform spawn`

While a spawn mode is active, the Tools controller consumes left-clicks in the world before the camera can interpret them as pan input. Clicking the active spawn button again returns to Normal mode. Hiding Tools also exits spawn mode.

## First implementation slice

1. `SimulationTools` controller with a separate reusable `SimulationTools.tscn` scene and a toggleable panel (`F4`).
2. Spawn-cell and spawn-resource controls with explicit world-click modes.
3. Mutate-selected-cell control using `CellInspector.get_selected_cell()`.
4. Pause/resume and 1×/2×/4×/8× time-scale controls.
5. Temperature/humidity/food-density sliders and environment reset.
6. Lightweight feedback and selected-target display.
7. Replace the CellSystemTest elapsed-time display with integer Ticks.

## Non-goals for v1

- Direct genotype editing.
- Sexual reproduction.
- New genetic categories.
- Reworking NEO inheritance or mutation formulas.
- Replacing CellManager or the existing resource spawner.
- Full deterministic single-Tick stepping.
