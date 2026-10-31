# Pull request workflow and screenshots

Rules for branches live in `AGENTS.md` ("Git and Pull Requests"). This file holds the procedure for screenshots so every PR looks the same between "releases".

## Principle

One feature or one coherent update per PR. Each visible feature gets at least one screenshot with a caption that says what to look at. Before-and-after pairs are best for changes to existing visuals.

## Taking the screenshots

1. Run the dev autoplay (it plays the first week and saves a picture of each phase), or open the game and use the dev camera, then pick the frames that show the feature:

   ```bash
   tools/pr_screenshots.sh <feature-slug>
   ```

   The script runs the autoplay into a temporary folder, converts frames to JPEG (quality 80) at most 1600 px on the long side and copies those you name into `docs/pr-assets/<feature-slug>/`. Name frames with `--pick <shot1> <shot2>`; without `--pick` it lists the available shots and exits.
2. Read the images yourself and check them before attaching: the feature is visible, nothing is cut off, no debug overlay is left on. For a before-and-after, take the "before" on the base branch (a worktree is fine) with the same camera.
3. Keep files small: at most about six images per PR, JPEG under about 1 MB each. Originals and large sets do not belong in `docs/pr-assets/`.

## Embedding them in the PR

The repository is private, so plain raw links do not render for outsiders, but permalinks to committed files render for everyone with access. After committing the screenshots, use the commit SHA, not the branch name (branch links break once the branch is deleted):

```markdown
![Short caption](https://github.com/<owner>/<repo>/blob/<commit-sha>/docs/pr-assets/<slug>/<file>.jpg?raw=true)
```

Put them in the "Screenshots" table of the PR template. Commit the screenshots in the same PR branch, as their own commit, so the permalink exists before the description is written.

## After merge

`docs/pr-assets/<slug>/` stays as the visual record of that PR. Prune it only in a dedicated `chore/` PR.
