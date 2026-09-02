# Alive Cells — Experimental Tools Architecture

This document reserves a separate layer for simulation-control tools. The NEO genetic system remains unchanged while tools are developed.

## Baseline

NEO baseline commit: `7756af0408c33d434f382b07c034570405937ecb`

## Goals

Provide developer-facing simulation controls for spawning cells and resources, applying mutations, controlling simulation time, and temporarily influencing environmental conditions.

## Rules

- Tools must not modify NEO definitions or formulas.
- Tools act on the running simulation through public APIs.
- Tool state is separate from scientific simulation state whenever possible.
- Normal simulation remains playable without opening the tools UI.
- Every tool should be safe to use repeatedly and should fail gracefully when a target is unavailable.

## Planned groups

### Population
- Spawn cell
- Spawn resource
- Optional burst/count controls
- Position mode: mouse position or random valid position
- Optional species selection for cells

### Genetics
- Mutate selected cell
- Mutate selected cell multiple times
- Mutation result feedback
- No direct editing of genotype in the first version

### Time
- Pause/resume
- Simulation speed presets
- Step one simulation tick
- Reset elapsed simulation time
- Optional time skip

### Environment
- Temperature control
- Humidity control
- Food density control
- Biome selection or override, if supported by the current environment system
- Apply to current simulation only; preserve scenario configuration separately

## Architecture

The tools layer should be an independent controller/UI that requests actions from existing managers rather than owning biology itself.

Preferred dependency direction:

`Tools UI -> Tools Controller -> CellManager / WorldResourceSpawner / Environment system / simulation clock`

The NEO system remains:

`CellManager -> CellFactory -> Cell -> CellGenetics -> GeneData / GeneFormulas`

Tools should call the CellManager and other existing public interfaces, never reach into GeneData internals to change biology directly.

## First implementation slice

1. Create a `SimulationTools` controller.
2. Add a togglable tools panel/hotkey.
3. Implement spawn-cell and spawn-resource actions.
4. Implement mutate-selected-cell action.
5. Add pause/speed/step controls.
6. Add temperature/humidity/food-density controls.
7. Add lightweight on-screen feedback for each action.

## Non-goals for v1

- Direct genotype editing.
- Sexual reproduction.
- New genetic categories.
- Reworking NEO inheritance or mutation formulas.
- Replacing CellManager or the existing resource spawner.
