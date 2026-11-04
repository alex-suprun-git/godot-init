# Vehicle trio: modeling reference proposals

Latest SUV reference is `luxury-suv-v3.png`, a fresh built-in ImageGen generation explicitly requested on 2026-11-04, without input images. Exact prompt: `luxury-suv-v3.prompt.md`. It guided model v6; the user then chose to retain the current model and focus on failure analysis. The sheet is not a measured blueprint, and its white-background presentation does not match the existing neutral-grid RAF/PAZ/UAZ reference family. Current model state and known attachment gaps: `../../models/vehicle_trio/README.md`. The older v1/v2 records below describe earlier stages.

User requested two wealthy-owner vehicles plus a rural Niva-like compact 4x4, starting with 2D projections. Built-in ImageGen produced three untouched reference sheets on 2026-11-04; exact prompts are in adjacent files.

- `luxury-suv-v2.png`: current black five-door SUV proposal, mid-1990s G-class proportion reference. User flagged three passenger doors per side in v1; v2 corrects this to two per side plus a rear tailgate and shortens the body. Visually checked side, overhead and three-quarter views for two side handles. The original v1 is preserved as superseded.
- `luxury-sedan-v1.png`: large charcoal luxury sedan, W140 proportion reference.
- `rural-4x4-v1.png`: short olive three-door rural 4x4, classic Niva proportion reference.

Each sheet contains side, front, rear, overhead and a small three-quarter appearance view. Visually inspected all three outputs. The short rural body is distinct from the long luxury SUV. These remain strongly recognizable real-vehicle references despite the omitted logos; independent final styling and in-game names are unresolved. No legal clearance is implied.

The user accepted corrected SUV v2 sufficiently to continue on 2026-11-04. These remain generated visual guides, not dimensionally validated blueprints: view scales, axle alignment and panel consistency must be reconciled during modeling. Target dimensions in prompts are design guidance only. First Blender shape studies, measured GLB exports, actual Godot comparison and current review status now live in `../../models/vehicle_trio/README.md`. These reference images remain outside the game; no raster optimization is needed for modeling-only references.
