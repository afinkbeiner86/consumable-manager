# Release Guide

Simple guide for creating releases with automated version management.

## Branch Strategy

- **`dev`** - Development branch (work here)
- **`main`** - Production branch (releases only)

## Quick Release Process

### 1. Develop on dev branch

```bash
git checkout dev
# Make your changes
git add .
git commit -m "feat: add new feature"
git push origin dev
```

### 2. Merge to main and tag

```bash
# Switch to main and merge
git checkout main
git merge dev
git push origin main

# Create version tag (triggers CI)
git tag v2.9.0
git push origin v2.9.0
```

### 3. CI Workflow

The GitHub Actions workflow will:
- Update version in `ConsumableManager.toc` and `ConsumableManager.lua`
- Create `ConsumableManager-2.9.0.zip` with addon files
- Publish GitHub Release

## Manual Version Bumping (Optional)

You can update the version manually before tagging if you want to commit it:

```bash
# Update version in files
python bump-version.py 2.9.0

# Review changes
git diff

# Commit version bump
git add ConsumableManager.toc ConsumableManager.lua
git commit -m "chore: bump version to 2.9.0"

# Tag and push
git tag v2.9.0
git push origin main --tags
```

## Version Numbering

Use [semantic versioning](https://semver.org/):

- **Major** (3.0.0) - Breaking changes
- **Minor** (2.9.0) - New features
- **Patch** (2.8.1) - Bug fixes

## Workflow Details

### Trigger

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Only tags like v2.9.0
    branches:
      - main      # Only from main branch
```

### What gets released

Only these 4 files in the ZIP:
- `Bindings.xml`
- `ConsumableManager.lua`
- `ConsumableManager.toc`
- `Data.lua`

## Troubleshooting

### Release didn't trigger

- Check tag format: must be `v*.*.*` (e.g., `v2.9.0`)
- Check you pushed the tag: `git push origin v2.9.0`
- Check branch: tag must be on `main` branch
- View workflow runs: Go to **Actions** tab on GitHub

### Wrong version in release

- The version comes from the git tag, not the files
- If tag is `v2.9.0`, the release will be version `2.9.0`
- Files are automatically updated to match the tag

### Need to delete a bad release

```bash
# Delete tag locally
git tag -d v2.9.0

# Delete tag remotely
git push origin :refs/tags/v2.9.0

# Delete release on GitHub (manual)
# Go to Releases → Click release → Delete release
```

## Tips

1. **Always work on dev branch** - Keep `main` clean for releases only
2. **Test before merging** - Make sure everything works on `dev` first
3. **Write good commit messages** - They show up in the release notes
4. **Use conventional commits** - Makes changelogs easier:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `chore:` for maintenance
   - `docs:` for documentation
5. **Tag after pushing to main** - Ensures CI has the latest code

## One-Liner Release Commands

For quick copy-paste:

```bash
# Merge dev to main and release
git checkout main && git merge dev && git push origin main && git tag v2.9.0 && git push origin v2.9.0 && git checkout dev
```

This will:
1. Switch to main
2. Merge dev
3. Push main
4. Create tag v2.9.0
5. Push tag (triggers CI)
6. Switch back to dev