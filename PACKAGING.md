# Packaging ForeverGuildComms with BigWigsMods/packager

The addon is configured for [BigWigsMods/packager](https://github.com/BigWigsMods/packager)
and WoW Forever beta (**Interface `16001`**). The in-game addon version remains
**`0.3.0-beta`**. The packager recognises the Forever game type from the TOC;
no `-g` override is required.

## GitHub repository layout

**Important:** Commit the *contents* of the extracted `ForeverGuildComms/` folder
to your GitHub repository root. For example, this must exist:

```text
<repository-root>/
  .github/workflows/package.yml
  .pkgmeta
  .gitignore
  ForeverGuildComms.toc
  Core.lua
  Roster.lua
  Alerts.lua
  Tabard.lua
  UI.lua
  Options.lua
  TitanMenu.lua
  Broker.lua
  README.md
  PACKAGING.md
  install/
    Install-ForeverGuildComms.cmd
    Install-ForeverGuildComms.ps1
    INSTALL-README.txt
  tests/
```

Do **not** upload only the outer downloaded ZIP to GitHub, or leave the TOC
under an extra `ForeverGuildComms/` folder relative to `.pkgmeta`.
The `.pkgmeta` file and `.github/workflows` directory must be committed.

## Make a release

1. Push the addon sources and `.github/workflows/package.yml` to GitHub.
2. Create an **annotated** tag for the desired version, e.g. in your local
   Git repository after committing:

   ```bash
   git tag -a v0.3.0-beta -m "ForeverGuildComms 0.3.0 beta"
   git push origin v0.3.0-beta
   ```

   Only create the tag if it does not exist. For subsequent updates, change
   the TOC version first, commit, and tag with a matching *new* version.
3. The tag push starts the GitHub Actions **Package ForeverGuildComms** workflow.
   It builds a ZIP and, provided repository permissions allow it, creates
   or updates a GitHub Release with the ZIP attached.
4. Repository **Settings > Actions > General > Workflow permissions** must
   permit write access via `contents: write` for GitHub releases.

The output may have a `-forever` suffix in its filename because the packager
includes the game flavour. That is normal and does not change the addon version.

## Publish to CurseForge, WoWInterface, or Wago (optional)

The workflow exposes optional tokens as GitHub repository secrets:

| Service | Secret | Required TOC metadata |
| --- | --- | --- |
| CurseForge | `CF_API_TOKEN` | `## X-Curse-Project-ID: <real numeric project ID>` |
| WoWInterface | `WOWI_API_TOKEN` | `## X-WoWI-ID: <real numeric addon ID>` |
| Wago | `WAGO_API_TOKEN` | `## X-Wago-ID: <real project ID>` |

Add real IDs for the services you actually use; do **not** paste placeholders
into the TOC. Publishing to those platforms depends on them recognising and
accepting the Forever game type. No service account, project ID, or secret has
been created or configured by this ZIP.

## What goes into which ZIP?

- **Manual ZIP (this downloaded source archive):** Includes the three
  Windows files under `install/`, tests, `.pkgmeta`, the GitHub workflow,
  and the addon. Run `install/Install-ForeverGuildComms.cmd` after extraction.
- **Packager ZIP (from GitHub Actions):** Contains the `.toc`, its loadable
  Lua files and `README.md`. `.pkgmeta` excludes `install/`, `tests/`,
  `PACKAGING.md` and the GitHub workflow; hidden config files are skipped
  automatically. This clean ZIP is for normal addon-manager installation.

The in-game addon does not need BigWigs or TitanPanel to be present for packaging.
TitanPanel integration remains optional at runtime.

## Test before publishing

To run a package build locally after downloading the BigWigs packager
(`release.sh`), run this from your **Git checkout root**:

```bash
bash /path/to/packager/release.sh -d
```

`-d` means **build locally without uploading**. Output goes to `.release/`.
Use a real Git checkout, not an extracted ZIP, because release.sh reads Git
tags and history for versioning. See the packager's own README for platform
requirements.
