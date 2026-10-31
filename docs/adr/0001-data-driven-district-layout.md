# ADR 0001: Data-driven district layout on a lot grid

Status: accepted, 2026-10-31

## Context

The map is a 3D scene built in code. Building positions were hand-placed `Rect2` values copied from an SVG schematic and spread across about ten `_build_*` functions in `city_map.gd`. Game locations kept their own positions in `week1.gd`.

Moving one building meant editing it in two places and then re-checking hand-placed trees, cars, and props around it. Markers drifted away from their buildings.

The starting district is being redesigned as an outskirts district (see README, "Starting District Layout"). Unique buildings such as a school, kindergarten, or police station will be added gradually over many iterations.

## Decision

- The layout is data: `district_layout.gd` holds typed lots (W housing, K core, G street, X large, D village, R reserve) with rectangles in metres, plus roads, rails, and water.
- What stands on a lot is a content key resolved by `building_catalog.gd`: geometry, textures, placeholder, and lot-local dressing. Missing art renders as a placeholder box.
- Game locations reference lot ids. Their map position is derived from the lot, never stored twice.
- Startup validation checks that every referenced lot and content key exists.

## Alternatives considered

- **Keep hand-placed code, just tidy it.** Cheapest now, but every later change stays a multi-place edit, and it keeps the class of bug where markers drift from buildings.
- **Godot scenes per building, placed in the editor.** Visual editing is nice, but placement would live in `.tscn` files that are hard to diff and review, and the layout would still not be one readable table. It may still be used later for individual detailed buildings.
- **Free placement without a grid.** Most flexible, but swapping a panel block for a school would mean re-planning neighbours each time. A grid with reserved core lots matches how Soviet micro-districts were actually planned.

## Consequences

- Swapping content on a lot is a one-line change, and moving a lot moves its marker, travel time, and dressing with it.
- A one-time refactor of the map builder is required.
- Mistakes such as a mistyped lot id show up at runtime, not in code. Startup validation mitigates this.
- Grids look repetitive. This is countered by the irregular village, per-lot variation (floors, tint, condition), and dressing.
- Travel time is derived from lot distance, so map scale directly sets game pace. Speeds in `week1.gd` stay the tuning knob.
