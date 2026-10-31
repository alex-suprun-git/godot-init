# Traffic vehicles plan

Status 2026-10-31. Nothing below beyond the Lada is downloaded or integrated.

## Tiers
1. **Ambient traffic** (many cars on the road graph): a handful of cheap, recolourable body types (Zhiguli/Lada sedan done; add hatch/wagon-like, Moskvich, UAZ, bus, truck). Sourced per `.agents/skills/blender-godot-assets/references/asset-sourcing.md` (CC0/CC-BY only, ~2-8k tris, paint material named `*paint*` so `VehicleModels._repaint` tints it).
2. **Key vehicles** (later, high quality, one by one): administration GAZ-24 Volga (`art/models/volga/SOURCING.md`) and the police car. Individual sourcing + adaptation + approval, not part of the ambient pool.

## Done
- Lada v2 GLB with 12 period paints, parked at kerbs, ambient cars (60) and the hero car.

## Blocker
- Blender MCP libraries (Sketchfab, Poly Pizza, Poly Haven) are switched off; tick them in the MCP for Blender sidebar (N in 3D viewport), or provide archives.

## Next
- Search/inspect ~3 candidates per ambient type, extend `VehicleModels.MODELS/LENGTHS` with a weighted pick for ambient cars.
