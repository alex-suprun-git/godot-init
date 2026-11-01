# Bridge material originals

Built-in ImageGen sources generated 2026-11-01. Each untouched PNG has an adjacent exact `.prompt.md` file. The user approved the concrete/ballast/painted-steel direction and requested implementation. Sources are preserved; game copies were prepared separately with `tools/optimize_asset.py --profile surface --approved`.

- `bridge-concrete-v1.png`: warm-grey structural concrete, subtle pores/formwork and tie impressions.
- `bridge-ballast-v1.png`: angular grey-brown crushed stone, no rails or sleepers.
- `bridge-steel-v1.png`: matte grey-blue painted steel with restrained wear, no baked rivets or joints.

All images were visually inspected. Requested four-way seamlessness was checked through repeated actual Godot materials; no conspicuous boundary was found at the inspected scale, but exact edge-pixel matching is not claimed. Grain/tie details soften under map-distance mip filtering. Do not enlarge ballast stones merely to retain full-resolution detail in a district overview.

Game texture paths, provenance reports, actual sampling sizes/tints, captures and remaining visual review are recorded in `../../bridges/README.md`. No original was overwritten or edited by the optimizer.
