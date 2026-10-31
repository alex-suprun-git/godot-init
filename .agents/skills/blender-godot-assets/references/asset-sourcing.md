# Reusable model sourcing

Use this workflow when asked to source a model, or when reuse could save substantial modeling work. The agent performs research and technical selection; the user sets the creative direction.

## Brief and search

1. Read the asset prompt and current game implementation. Identify the exact subject/variant, mood, intended camera and closest approved asset. Distinguish required fidelity from details invisible in play. Propose geometry/material/texture budgets for that use; do not treat a triangle count alone as quality.
2. Search by the exact subject, aliases and game-friendly terms such as `low poly`, `game ready`, `glTF`, `Blender`. Start with a small search pass and keep roughly three credible candidates. Expand only if a specific missing requirement warrants it; stop when a suitable candidate can proceed to inspection or the searched sources yield no suitable candidate. Report "not found in this search", never "does not exist".
3. For specific real-world vehicles, search author listings on Sketchfab and, if needed, Fab/CGTrader/TurboSquid. For general props, vegetation or materials, consider Poly Haven, Kenney, Poly Pizza and OpenGameArt. These are search routes, not blanket endorsements or guarantees of matching assets. GitHub is useful for author-maintained asset packs and pipeline tools; check the license covering the actual models and textures, separately from code.
4. Follow aggregators to the original author/listing. Record URL, creator, date checked, displayed license and evidence, price, advertised formats and geometry, and unresolved questions. Recheck current listings; search snippets are leads and must be identified as such if direct access fails.

## Selection

- Prefer clear permission for intended game use and modification. CC0 or CC BY are useful starting points; retain the exact license version and required attribution from the actual download. Unknown, personal-use, NC or ND terms do not qualify for the default reusable game asset path. A paid listing can qualify if its terms and budget fit.
- Check whether source files may be stored in this repository as well as distributed inside a built game. Do not assume a marketplace license permits publishing the raw asset in Git. Keep restricted source files out of the repository.
- Prefer GLB/glTF or Blender sources; FBX/OBJ can be converted. A `.max`-only asset is a poor fit for our Blender workflow unless a supported export is available. STL printable models usually lack the surfaces/materials needed for the game.
- Compare silhouette, era/variant, materials, UVs, wheels and visible detail with the brief. Estimate adaptation effort versus rebuilding. Do not declare visual acceptance from listing metadata or a thumbnail.
- Return one recommendation with reasons: **adapt candidate**, **build original**, or **unresolved acquisition/terms**. Separate a metadata shortlist from a downloaded inspection and an in-game approval.

## Acquisition and technical inspection

When implementation is authorized, download from the legitimate source into an asset-specific staging directory. Use a supported connector, public API or the normal download flow. If acquisition needs a login or purchase, identify the exact remaining step; do not invent a download URL or bypass access controls. Do not purchase without an authorized budget.

Keep the original archive and license evidence where their terms permit. Treat downloaded scripts as untrusted and do not enable Blender auto-run for them. Record a SHA-256 hash and the attribution text before adaptation.

Inspect the file in Blender: dimensions/axes, actual mesh/triangle/material counts, UVs and missing textures, separate movable parts and render appearance. Produce front, side and three-quarter previews. Adapt the game copy, export GLB using this skill, and inspect it beside the approved Lada under the actual map camera before final acceptance. Preserve the original source and list modifications.

## Automation boundary

The reusable skill directs the agent's search, evidence recording and decision; it is not a background crawler. Use available web tools for discovery, supported provider APIs where practical, and Blender MCP/scripts for inspection, conversion, optimization and previews. Do not promise universal unattended downloads: providers differ in authentication, purchase and API availability.

## Working agreement: downloaded model to game asset

When the user requests implementation, Codex first attempts legitimate acquisition independently. Do not send the user to download the file before trying an available normal download route. If login, purchase or inaccessible download controls prevent acquisition, identify the exact model and remaining step; the user can complete the login/download or provide the archive. A purchase still needs an authorized budget. A sourcing discussion does not itself mean implementation has been requested.

Codex handles technical preparation, initial inspection, previews and routine corrections without asking the user to approve each operation. Ask the user about meaningful creative choices, such as paint colour, condition, tint or a change of vehicle variant, when the brief does not already answer them. First prepare concrete comparable previews where possible, and continue independent work while a preference is pending. Reuse approved style decisions instead of asking the same questions again.

Use the following stages, saving outputs as work progresses:

1. **Inspect:** use Blender MCP/Python to collect object names and hierarchy, evaluated triangle counts, material and texture inventory, missing resources, dimensions, transforms/axes, UV availability and whether wheels/windows/body are separate. Save a machine-readable report beside the asset. A valid import is not visual approval.
2. **Preview and review:** create consistent front, side, rear and three-quarter renders plus a view matching the game camera. Codex inspects the images for silhouette, shading defects, missing textures and transparency issues. Surface counts alone cannot detect these problems.
3. **Adapt:** preserve the original and edit an independent game copy. Typical changes include paint colour/roughness, dirt/wear, glass tint/opacity/reflections, wheels/lights/bumpers and removal of hidden geometry. If transparent windows expose an empty shell, add a simple interior or use suitable tint; do not blindly lower opacity. If parts/materials are merged or colour is baked into one atlas, inspect and separate/repaint as needed before promising an easy edit.
4. **Optimize:** reduce geometry, material slots or texture sizes where they materially help. Preserve the body silhouette, visible wheel arches and details that survive the intended map zoom. Compare before/after previews; do not pursue a triangle target at the expense of the approved appearance.
5. **Integrate:** export a portable GLB, import into Godot and inspect at real scale under the map's camera/light beside existing vehicles. Follow the main skill's export and grounding instructions. Report the visible result and any unresolved limitation.

Inspection reports, preview cameras/renders and export can be scripted. Visual judgement and unusual repairs still require agent inspection and asset-specific edits. Save reusable inspection/adaptation/export scripts beside the asset when created; make their paths and prerequisites explicit. After the first pass, use these scripts for recolours and re-exports rather than rebuilding the workflow manually. Do not describe a generic inspector or one-click pipeline as available until it has actually been implemented and run.

## Resume across chats

Before handing off, update the asset record with its current stage, original/download and working-copy paths (where terms permit), implemented script paths and commands, report/preview/export paths, approved choices, unresolved decisions, blockers and the next concrete action. On continuation, read that record and inspect existing files before downloading, rebuilding or asking again. Preserve completed work and check long-job status before rerunning it.

Poly Haven has an official API and CC0 assets; API-specific terms are separate from the asset license. See https://github.com/Poly-Haven/Public-API and https://polyhaven.com/license. Kenney's asset terms are documented at https://kenney.nl/support. Verify other providers' current per-asset terms.

## Research record

In `art/models/<asset>/SOURCING.md`, keep:

- Brief and proposed budgets, including which choices remain provisional.
- Checked date, searched sources and any access limitations.
- Candidate table with author/source, license evidence, cost, formats/counts, concerns and disposition. Use "unknown" instead of filling gaps with guesses.
- Decision and remaining verification steps. State explicitly whether anything was downloaded or integrated.
- After acquisition: hash, exact license/attribution, inspection results, modifications and in-game preview paths. Add third-party credits when a model is actually included, not merely shortlisted.
