# Approved image preparation

The optimizer is a standalone Python tool outside the Godot project. Run it after visual approval and before adding a generated raster image to the game. It uses Pillow; ImageMagick is not required. `uv` installs the pinned dependency in an isolated script environment on first run.

## Agent workflow

For map areas, use an actual current Godot screenshot as the authoritative camera/layout reference and existing project art as the style reference. Keep map context throughout the iterations. The user may choose one combined transparent 2D painting in a moved/resized lot as an interim implementation before separate models. Standalone polished object concept art requires a separate explicit request; do not substitute it for the map-based workflow. Preserve and document the reference screenshot and the approved version beside the asset.

When extracting an approved area, preserve its composition and object proportions. Do not ask for a new diorama camera or force a differently projected source to fit through large affine stretches. Avoid duplicate paving under an asset whose own ground outline is visible. Calibrate the actual opaque boundary against adjacent roads/rails, then inspect an in-game overview and a close-up of critical joins. For the station market, both through tracks must remain outside the painting; the fenced market edge and platform safety edge share one straight boundary.

1. Generate and save the untouched original under `art/source_images/` (or keep an existing source under `art/concepts/`). Never generate directly into `init/assets/`. Keep the original filename/version and record the prompt in `art/PROMPTS.md`.
2. Review the image against the art brief. Present meaningful new visual directions to the user. Existing approval of a batch or visual direction applies within its agreed scope; do not request repeated approval for routine processing. Do not claim unapproved art has been approved.
3. Run `tools/optimize_asset.py` with the relevant profile and `--approved`. Write the optimized game copy to the asset's intended path under `init/assets/`. This step is required even if dimensions already fit: it normalizes PNG output and records provenance.
4. Read the report and briefly inspect the optimized image for lost detail or damaged transparency. Inspect alpha data when uncertain; a dark preview background is not proof of an opaque PNG. If the budget loses important detail, choose an explicit `--max-edge` with `--reason`; do not resize repeatedly from an optimized copy.
5. Connect the optimized copy in Godot. Run the normal asset import; regenerate sprite anchors for added/redrawn sprites. Inspect one relevant game view where practical. Report material issues without repeating full playtests for each image.

Do not retroactively process all existing assets without a migration task. This workflow applies to new or replaced images. It does not modify Blender models, source `.blend` files, GLB files or their export workflow.

## Commands (from repository root)

```sh
# Read-only plan; approval is not needed to inspect a candidate.
uv run tools/optimize_asset.py art/concepts/example.png --profile sprite --output init/assets/sprites/example.png --dry-run

# After approval: preserve source, write game PNG and report.
uv run tools/optimize_asset.py art/source_images/example.png --profile sprite --output init/assets/sprites/example.png --approved

# Explicit exception for art whose intended map size needs more detail.
uv run tools/optimize_asset.py art/source_images/example.png --profile sprite --max-edge 1536 --reason "Large landmark seen close up" --output init/assets/sprites/example.png --approved
```

The tool refuses to overwrite output/report files unless `--overwrite` is explicit. Sources inside `init/` and in-place edits are rejected. Reports go to `art/optimization_reports/<output filename>.json` by default; use `--report` for assets with the same filename in different directories.

## Processing policy

`tools/asset_profiles.json` defines initial maximum edge lengths: sprites 1024, portraits 1024, scenes 1920, surfaces 1024, facades 2048, UI 1024. These are working budgets, not measured optimal values. Use intended screen size at maximum supported zoom to choose exceptions. Small sprites can use a lower explicit budget.

The tool downsizes only, preserves aspect ratio, canvas margins, RGB/RGBA color and alpha, and applies lossless PNG compression after resizing. It does not crop, quantize colors, create atlases, remove backgrounds, or make textures seamless. Text/EXIF metadata is discarded; an embedded ICC profile is retained to avoid silently changing colors. Source hash, dimensions, file sizes and alpha extrema are recorded. Estimated RGBA bytes are an uncompressed reference, not actual Godot GPU usage. Godot import compression and mipmaps remain a separate configuration step.
