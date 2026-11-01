# Pull request workflow and screenshots

Branch and scope rules live in `AGENTS.md`. Review screenshots are GitHub attachments, not Git content.

## Prepare and attach screenshots

1. Capture only the relevant autoplay scenario into a scratch directory, or reuse existing frames. Select a few clear views, normally one per visible feature; before-and-after pairs are useful when the camera matches.
2. Prepare JPEGs (quality 80, maximum edge 1600 px) with the helper:

   ```bash
   tools/pr_screenshots.sh <feature-slug> --from /absolute/capture/directory --pick overview detail
   ```

   Output stays in ignored `.local/pr-assets/<feature-slug>/`. Without `--from`, the helper runs autoplay; without `--pick`, it lists available frames. Inspect the selected images and keep each below about 1 MB, with at most six images per PR.
3. Use GitHub CLI 2.99.0 or newer. Write the PR body to a file, placing local image references in the Screenshots table, then attach those same files:

   ```bash
   gh pr edit <number> --body-file /absolute/pr-body.md \
     --attach "$PWD/.local/pr-assets/<feature-slug>/overview.jpg" \
     --attach "$PWD/.local/pr-assets/<feature-slug>/detail.jpg"
   ```

   For example, a table cell can contain `![Field overview](/absolute/path/to/overview.jpg)`. `gh` uploads the file and rewrites its reference to a GitHub attachment URL. Relative references resolve from the body file's directory, then the working directory. The same `--attach` flags work with `gh pr create`.
4. Read the saved PR body back with `gh pr view <number> --json body --jq .body`. Confirm every selected image became an attachment URL and no local paths remain. A partially failed upload can still update the PR: inspect the saved body before retrying. If the installed CLI lacks `--attach`, update it or use GitHub's web attachment control; do not commit images as a fallback.

Do not add review captures or optimizer reports to Git. Generated asset originals and game-ready assets continue to follow `art/ASSET_PIPELINE.md`.

## Existing screenshot archive

Existing tracked images in `docs/pr-assets/` remain untouched during this migration. The user deferred cleanup for one to two months from 2026-11-01 (December 2026–January 2027). Do not migrate or delete other PRs' images now. A later, separately authorized cleanup must preserve the affected PR illustrations; deleting files in a new commit alone does not remove their blobs from Git history.
