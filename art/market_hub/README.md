# Market, bus station and railway station — combined 2D site

## Current state

The user approved the map-based concept v3 and explicitly requested one combined 2D painting in the moved market slot as an interim implementation. Separate 3D stalls are deferred. The current integrated source is **asset v7**, incorporating the user's subsequent corrections; the final in-game result awaits user review.

- Source: `art/source_images/market_hub/market_hub_v7.png` (untouched generated original, 1605 x 980 RGBA).
- Game copy: `init/assets/sprites/market_hub_v7.png`.
- Provenance: `art/optimization_reports/market_hub_v7.png.json`.
- Initial prompt: `asset-v1.prompt.md`; exact revision prompts: `REVISIONS.md`.
- Map basis: `art/concepts/market-direction-v2.map-reference.png`; approved composition: `art/concepts/market-direction-v3.png`.

## User-directed corrections

- The freight wagon is removed from the passenger railway; both parallel through tracks remain clear and unchanged.
- The station is on the railway side, the bus bays form one straight row on the road side, and the dense colourful market adjoins the station.
- The market-side railway boundary has a plain metal mesh fence. No platform furniture, lamps or decorative plants sit along that boundary. Planting on the back/street side remains in the painting.
- Only the station-front part is a passenger platform. The ambiguous dark structure formerly in front of the building is removed.
- The user requested a 10% larger station, 10% smaller stalls and about five metres clear between stalls/fence and station. These are depicted generative targets, not surveyed measurements of individual painted objects.
- The station stays fixed while its platform widens to create one straight railway-facing boundary, continuous with the market concrete edge. Yellow paint occurs only at the station platform and immediately adjoins the transparent exterior; no extra foreground paving strip covers the railway.

## Integration and calibration

- `district_layout.gd`: `market` is now the combined site, `Rect2(-20, 315, 250, 78)`. The old market becomes a grass lot `former_market`, `Rect2(-215, 315, 185, 70)`. There is no separately rendered station lot.
- The `market` event location ID is preserved. South-hub subzones follow the new market and station areas, with reduced activity on the former market field.
- `building_catalog.gd` uses `painted_lot`, the v7 sprite and grass beneath it, avoiding the old duplicate paving slab. The picture reserves the site against additional random dressing.
- Grounded strips use canvas width 222.1 map units, footprint 244 x 70 m, anchor `(0.7913, 0.9867)`, source axes `(+0.583, -0.600)` and local offset `(0, 1.7)`. The source already nearly matches the fixed isometric camera; affine vertical correction is about 0.976, avoiding v1's heavy stretch.
- The anchor is at world `(227, 390.7)`. Measuring the same opaque bottom envelope used by the renderer gives maximum ground z about 392.807, leaving about 0.293 m to the first track's ballast boundary at z=393.1. Track centres remain z=395 and 405. The image contains no rails of its own.
- The static passenger-line wagon is no longer created. Port-siding wagons are unchanged.
- Optimizer: sprite profile, explicit 2048px limit for the whole site. Size remains 1605 x 980; PNG drops from 1,254,991 to 1,212,233 bytes; alpha extrema remain 0–255. No cropping or palette quantization.
- Godot import and the required sprite-anchor refresh were run. This painted lot uses its explicit calibrated corner instead of the automatic average edge anchor.

## Visual verification

- Inspected actual Godot frames `in-game-v7.png` (whole site) and `platform-v7.png` (station, straight boundary and both clear tracks). No duplicate station, old market stalls, old paving slab or passenger wagon is present. No script errors occurred during the focused captures.
- Earlier v1 autoplay produced overview and hub frames, then ended after the day-card frame; a completed first-week playthrough is **not** claimed. It reported the already recorded shutdown warnings about four ObjectDB instances/two resources still in use. The final v7 was checked with focused graphical captures rather than automated tests.
- `autoplay.gd` now includes `0_market_hub` for repeatable visual review.
- This is one static late-summer painting for the fixed isometric camera. Painted shoppers, buses and stalls do not independently animate or simulate internal aisle movement; separate seasonal/event art and 3D models are future work.

## Next action

User review of the final in-game framing. Keep subsequent revisions on this real-map basis; request separate polished object concepts only when explicitly instructed. Do not resume 3D production without the separate discussion the user requested.
