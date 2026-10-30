# Map proportion audit — 2026-10-31

Scope: current `city_map.gd`, `grounded_props.gd`, alpha bounds of 30 sprite assets, source artwork, and the graphical close-ups from the current map. This is an analysis; gameplay rendering and scale constants were not changed during this audit.

## Finding

The map has no consistent scale contract between geometry, sprite canvases, individual features inside artwork, and groups of objects. Apartment geometry supplies a usable reference, but most props were sized by the horizontal size of the full PNG. That number is neither physical length nor height. The recent projection correction also changes vertical scale without subsequently normalizing object dimensions.

Assume one world unit represents one metre for this audit. Proposed reference dimensions below are design calibration targets, not researched specifications for individual vehicle or building models.

## Reliable references

- Apartment floors: 3 units. Five-storey block: 35 × 11 × 15; nine-storey block: about 25.2 × 11 × 27. These proportions are internally consistent.
- Merchant houses: wall height 7, two storeys in the texture. The door drawn at roughly 300 pixels of the 887-pixel texture reads about 2.4 units high. This provides a second independent reference.
- Roads: main road 10 wide; cross street 6.5; local streets 4.5. Railway surface is 3 wide. These are not the first things to rescale globally.
- Trees: birch canvas height 9–13, poplar 13–18, with fixed-Y billboards. Their relationship to 15-unit apartment blocks is broadly coherent. Keep this reference while calibrating props.

## Highest-priority mismatches

| Priority | Evidence | Consequence / proposed treatment |
|---|---|---|
| P1 | Adult pedestrian silhouettes correspond to 3.28–3.41 units of apparent upright height relative to 3D floors. | People read close to an entire storey. Calibrate to an apparent upright reference of approximately 1.7–1.85; initial uniform factor about 0.52–0.56. Check anatomical head-to-foot landmarks because pose and source viewing angle affect the silhouette. |
| P1 | Child silhouette corresponds to 3.53 units, higher than every adult preset. | The intended age relationship is reversed. Calibrate separately to a proposed 1.25–1.5 reference; initial factor about 0.35–0.43, not the same factor as adults. |
| P1 | Station door is approximately 130 source pixels high. At canvas width 40 and current correction this reads about 4.5 units, versus about 2.4 for merchant-house doors. | Station is oversized relative to the architecture around it. A width near 20–22 is a useful first candidate, subject to checking door, roof and platform together. Its antenna-inclusive silhouette diagnostic must not be treated as main roof height. |
| P1 | Bus shelter's nearest vertical support is roughly 400 pixels high. At width 10 this reads about 4 units before roof thickness. | The shelter looks monumental next to people and small buildings. A first candidate around 6–7 canvas units should be checked against a 2.5–3-unit support reference and the bus's doors. |
| P1 | Market tent uses width 8; its front vertical post reads roughly 3.5–3.8 units. Slots are 34 SVG pixels = 8.5 world units apart. | Stalls and aisles need a coordinated adjustment. A first tent width near 5.5–6 would bring posts toward 2.5 units. Shrinking stalls alone leaves excessive gaps: then review row spacing and stall count. |
| P1 | Garage row uses width 27 for eight bays; the nearest door in the artwork reads roughly 4–5 units high. | Individual bay width, door height and overall row length must be checked independently. A uniform shrink that fixes door height may make eight bays too narrow for the cars. This asset may require a correction of its internal proportions or separate bay geometry. |
| P1 | All long-prop calibrations currently inherit one inferred second axis. Their vertical factors range from about 1.02 to 1.30. | Fixing the footprint does not preserve object scale. Normalize dimensions after projection calibration. Source-specific structural landmarks are needed, especially for vehicles. |

Feature-based estimates above are approximate measurements from the current artwork, not automatic semantic detection. They are more useful than treating a whole image's height as a wall height.

## Other groups requiring calibration

- **Cars and vans:** widths 5.0, 5.7 and 5.2 are PNG widths. Current projection correction stretches them vertically by about 26–30%. The original Lada request gives 4.1 × 1.7 as the reference footprint, but no implementation checks those two dimensions. Use wheelbase, wheel diameter and roof-to-wheel height together with that footprint. Reducing only their height would leave their footprint unverified.
- **Bus and tram:** widths 12 and 14 receive about 22–23% vertical stretching. Compare door heights to a calibrated adult, and wheels and vehicle body width to the road. Their overall opaque image height includes roof depth and is not vehicle height.
- **Freight wagons:** width 28 covers three wagons. Comparing the number 28 directly to bus width 12 is invalid. Check the length of each wagon, wheel diameter, rail contact and loading-gauge appearance. The clipping fix is verified; the physical proportions are not yet calibrated.
- **Private houses and kiosks:** widths 13 and 5 have no door-height contract. Their complete silhouettes include roofs, porches, fences and gardens. Calibrate the building door and eaves rather than the whole compound image.
- **Bench/playground sprite:** width 11 refers to a multi-object group. Its bench, swing and slide may need different corrections; whole-group bounds cannot establish bench size.
- **Industrial structures:** chimney width 22.7 is described in code as implying height 34, but its camera-facing silhouette reads about 40.3 upright-equivalent units. This is a mismatch between the comment and the rendering convention, not proof a 40-unit chimney is inherently implausible. Water tower, church and tanks likewise need component landmarks before changing them.
- **Picket group:** width 12 covers multiple people and placards. Use individual heads and bodies, not group height. Placards make the silhouette-height diagnostic misleading.
- **Heat pipes:** two square 0.7 × 0.7 sections at height 2.6, supported by 0.4-wide posts every 8 units. Their mass and height strongly compete with houses and pedestrians. Review after the person reference is fixed; they also currently occupy the same vertical band as a shelter roof.

## Placement and occupancy also affect perceived scale

- Station renders at canvas width 40 while its occupied rectangle is 30 × 12. These numbers describe different things; the occupied rectangle is not derived from the corrected footprint.
- Market tents do not register their individual footprints in `_occupied`; shoppers are placed randomly along aisles without checking them. Intersections can look like scale errors.
- A private-house sprite includes fence and garden but reserves only 8 × 7. Check the entire compound footprint.
- Tree avoidance margins and vehicle parking need to be recalculated when object dimensions change. Repeated manual position nudges will not provide a stable layout.

## Why blanket scaling will fail

1. Transparent padding differs drastically: visible width is 55% of the tank-farm canvas, 35% of the chimney canvas, and 93% of the Lada canvas. The same input `width` has different meanings.
2. Alpha silhouette bounds include depth, rooftops, antennas, signs, gardens and multiple objects. They are useful diagnostics, not physical dimensions.
3. Camera-facing sprites and the new grounded strip renderer interpret height differently. The strip renderer maps the lower contour onto the terrain but still has no semantic knowledge of which pixels are a roof, a far wall or a wheel. It is not a true 3D reconstruction.
4. Source artwork contains inconsistent proportions and views. A single affine projection correction cannot repair every internal dimension.
5. Small physical objects may become hard to read after correction. UI portraits/markers are intentionally screen-sized and should remain a separate presentation system; do not distort all world objects to match marker size.

## Recommended implementation order

1. Establish world references: 3-unit floor, approximately 1.8-unit adult, approximately 1.4-unit child, approximately 2.2-unit ordinary door; retain current coherent building geometry.
2. Create explicit per-asset dimensions and measured semantic landmarks: long/short footprint edges, door or eave height, wheel centres/diameter, separate visual footprint and clearance footprint. Derive image size after projection correction.
3. Calibrate people, Lada, one garage bay, one tent and one shelter together in a dedicated graphical comparison scene containing a floor/door ruler. Then calibrate buses, station and industrial props against these references.
4. Recalculate occupancy and spacing from the resulting footprint, then inspect the same map locations at near and overview zoom. Choose readability aids separately if real-scale people become difficult to see.

The raw measurements are in `proportion_measurements.json`. `height_equivalent` is explicitly a screen/rendering diagnostic and must not be interpreted as the object's anatomical or structural height. Proposed values are starting points for graphical calibration. This audit leaves gameplay rendering and scale constants unchanged.
