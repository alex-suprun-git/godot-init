# Traffic vehicles plan

Status 2026-10-31. Nothing here was downloaded: every model is built procedurally in Blender.

## Tiers
1. **Ambient traffic** (many cars on the road graph): a handful of cheap, recolourable body types (Zhiguli/Lada sedan done; add hatch/wagon-like, Moskvich, UAZ, bus, truck). Sourced per `.agents/skills/blender-godot-assets/references/asset-sourcing.md` (CC0/CC-BY only, ~2-8k tris, paint material named `*paint*` so `VehicleModels._repaint` tints it).
2. **Key vehicles** (later, high quality, one by one): administration GAZ-24 Volga (`art/models/volga/SOURCING.md`) and the police car. Individual sourcing + adaptation + approval, not part of the ambient pool.

## Done
- Lada v2 GLB with 12 period paints, parked at kerbs, ambient cars (60) and the hero car; Lada wagon variant (`art/models/lada/`).
- Current reference-led ZIL food/coal and container KamAZ family: see `README.md` for source, exports and review. Old rough truck geometry has been deleted. The independent 20 ft container is preserved with `build_container.py` / `container.blend`.
- Placed in the truck stop, checkpoint queue and port (building_catalog.gd, `model` dressing entries). Verified in Godot frames only, no turntable previews saved.

## Blocker
- Blender MCP libraries (Sketchfab, Poly Pizza, Poly Haven) were switched off when last checked; original models are fine meanwhile.

## Next
- Search/inspect ~3 candidates per ambient type, extend `VehicleModels.MODELS/LENGTHS` with a weighted pick for ambient cars.
