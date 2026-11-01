# City park — first 2D integration

## Decision and files

- On 2026-11-01 the user chose the first park concept over the newly planted 1980s comparison and requested its integration on a separate branch: `codex/city-park-2d`.
- Direction: a pleasant, modest, moderately maintained Soviet/post-Soviet neighbourhood park, without pomp.
- Untouched source: `art/concepts/city-park-v1.png`; exact prompt: `art/concepts/city-park-v1.prompt.md`.
- Game copy: `init/assets/sprites/city_park_v1.png`.
- Preparation: `uv run --offline tools/optimize_asset.py art/concepts/city-park-v1.png --profile sprite --max-edge 1536 --reason "Whole 54 by 84 metre park with benches, flowers and foliage visible at maximum map zoom" --output init/assets/sprites/city_park_v1.png --approved`.
- Report: `art/optimization_reports/city_park_v1.png.json`. The separate optimizer preserved the 1536 x 1024 RGBA image and reduced PNG size from 2,667,760 to 2,516,347 bytes. Source and output alpha extrema are 0–254; the dark exterior in the image preview is transparent in the game.

## Integration

- `district_layout.gd` retains the existing `city_park` lot, `Rect2(82, -72, 54, 84)`, and the `admin_park` ambient pedestrian subzone.
- `building_catalog.gd` replaces the two placeholder paths, two placeholder benches and four standalone birches with one `painted_lot` recipe. All furniture, paths and trees are already in the painting.
- `district_builder.gd` reuses `grounded_props.gd`'s vertical mesh strips and alpha scissor. The bottom contour sits on the ground; the upper painting remains upright. This avoids flattening tree crowns onto a ground decal. The whole lot is reserved against additional randomly scattered trees.
- Calibration in the unchanged source: near corner about (628, 1016), left corner (34, 662), right corner (1514, 384). Positive/negative ground slopes are 0.596/-0.712. Canvas width 95.08 map units and near-corner anchor (0.409, 0.992) produce an approximately 52 x 77.6 m painted footprint centred inside the 54 x 84 m lot. Deliberate grass margins keep the painting clear of adjacent pavements.
- The general sprite anchor table was refreshed with `measure_sprite_anchors.gd`. This whole-lot recipe uses the explicitly calibrated near corner, because the automatic average ground-edge anchor is appropriate for compact props rather than the park's two-sided footprint.
- The painting is calibrated for the default fixed isometric camera. It is one late-summer illustration; season-specific park paintings and separate moving/shadow-casting trees are not implemented.

## Visual review

- Godot 4.7.1 imported the asset. A graphical dev-autoplay run rendered the map successfully.
- Inspected `0_city_park.png` and `0_administration.png`: the park occupies its intended site, paths follow the map axes, no old placeholder cross or duplicate park birches remain, and no dark exterior halo covers the adjacent ground or roads.
- Actual game frame: `art/city_park/in-game-v1.png`.
- `autoplay.gd` now captures `0_city_park.png` after the administrative-centre frame, so this view can be reviewed again with the normal dev-autoplay command. Create the output directory before launching.

## Follow-up

The first in-game integration is ready for the user's visual review. Any later art revision should preserve the source outside `init/`, go through the optimizer separately, and refresh the calibration and sprite anchors if the footprint changes.
