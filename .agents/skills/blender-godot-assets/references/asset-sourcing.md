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

Poly Haven has an official API and CC0 assets; API-specific terms are separate from the asset license. See https://github.com/Poly-Haven/Public-API and https://polyhaven.com/license. Kenney's asset terms are documented at https://kenney.nl/support. Verify other providers' current per-asset terms.

## Research record

In `art/models/<asset>/SOURCING.md`, keep:

- Brief and proposed budgets, including which choices remain provisional.
- Checked date, searched sources and any access limitations.
- Candidate table with author/source, license evidence, cost, formats/counts, concerns and disposition. Use "unknown" instead of filling gaps with guesses.
- Decision and remaining verification steps. State explicitly whether anything was downloaded or integrated.
- After acquisition: hash, exact license/attribution, inspection results, modifications and in-game preview paths. Add third-party credits when a model is actually included, not merely shortlisted.
