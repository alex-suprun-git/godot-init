# Proportion implementation V3 — 2026-10-31

This pass follows PROPORTION_AUDIT.md. Its raw measurement file remains a before-state diagnostic, not a report of the updated game.

| Element | Before | Implemented |
|---|---|---|
| Adults | Apparent upright height 3.28–3.41 | Approximately 1.72–1.81; per-person canvas widths in `prop_dimensions.gd` |
| Child | Apparent upright height 3.53 | Approximately 1.40 |
| Garage row | One painted row at arbitrary canvas width 27 | Eight 3D bays, each 3.2 × 6 m, wall 2.5, ridge 2.9; new painted material with face UVs |
| Lada / Volga | Old sprites, canvas widths 5 / 5.7, no height normalization | New V3 art; widths 4.3 / 5.0 and vertical factors 0.78 after source-axis calibration |
| Market tent | Canvas width 8 | 5.6; 30 stalls rather than 21, with narrower row/column pitch and shoppers in aisles |
| Bus shelter | Canvas width 10 | 6.5; clearance 3.5 × 7 |
| Station | Canvas width 40 | 22; occupied region 24 × 10 |
| Bus | Canvas width 12, no height normalization | 9.0 and vertical factor 0.78 |
| Tram | Canvas width 14, no height normalization | 10.5 and vertical factor 0.82 |
| Kiosks | Canvas width 5 | 3.5 |
| Executive committee | 32.5 × 11 × 15 m | 45 × 18 × 19 m; flagpole raised with the building |
| Merchant street blocks | 7 m walls, stepped roof placeholders | 9.5 m walls, two generous storeys, actual 3 m pitched roofs |
| Church | Canvas width 24 | 32; clearance enlarged to 20 × 26 |

The garage is a real dimensioned mesh. Cars, the church, and other painted props remain image-based representations; their raw artwork is not claimed to be an exact 3D reconstruction. Car nominal dimensions in the generation prompts are targets, not certified measurements of the PNG.

## Review

- Import new art, regenerate `sprite_anchors.gd` using the existing dev script.
- Run the graphical week autoplay and inspect map close-ups of the square, station/market, garage row and bus stop.
- Open `init/scenes/dev/scale_reference.tscn` with F6 to compare the actual assets on a metre grid. Green pole: 1.8 m. Door reference: 2.2 m.
- The garage material is sampled by face UV landmarks from `garage_single_v3.png`; its source perspective does not set the mesh dimensions.
- Ordinary apartment geometry remains the 3 m floor reference. This pass does not establish a complete physical specification for industrial props, mixed playground illustrations or the picket group.

## Road paint follow-up

Road paint is now generated as individual ground quads in world dimensions rather than scaling entire transparent marking images. Centre dashes: 0.12 m wide, 3 m long, 8 m period. Zebra bars: 0.45 m wide with 0.45 m gaps; crossing depth 3.5 m. Crossing spans follow the actual 10 m / 6.5 m road widths, with edge margins. All four approaches to the main junction receive correctly oriented crossings. Centre lines stop before crossings and secondary junctions. Paint is placed 5 mm above the corresponding road surface instead of at the old fixed 0.62 m elevation. A shared shader adds sparse paint wear. These are visual design dimensions for the prototype, not a claim of jurisdiction-specific road-code compliance.
