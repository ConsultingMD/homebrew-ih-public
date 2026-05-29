## Claude Code Cask Update Workflow — Troubleshooting

### What the workflow does

The `update-claude-code-casks.yml` GitHub Actions workflow runs on a daily schedule. It:

1. Queries the npm registry for the current version of `@anthropic-ai/claude-code` at the `latest` (and `stable`) dist-tags.
2. Downloads the corresponding `SHASUMS256.txt` release asset from the GitHub release.
3. Extracts the SHA-256 for the `.zip` artifact.
4. Uses `sed` to substitute the new version and SHA into each cask `.rb` file.
5. Opens a PR with the changes if the version changed.
6. Attempts to auto-merge the PR once CI passes.

### Manually triggering the workflow

**GitHub UI:** Go to Actions → "Update Claude Code Casks" → "Run workflow" → click "Run workflow".

**gh CLI:**
```bash
gh workflow run update-claude-code-casks.yml --repo ConsultingMD/homebrew-ih-public
```

---

### Common failure modes

#### a. npm registry unreachable

**Symptom:** Workflow fails at the `npm dist-tag ls` or `npm view` step with a network error or non-zero exit code.

**Fix:** Re-run the workflow once the npm registry is reachable. No cask changes are needed.

---

#### b. SHASUMS256.txt not available

**Symptom:** Workflow fails when downloading or parsing `SHASUMS256.txt`. The GitHub release may not yet have this asset attached, or the release may be delayed behind the npm publish.

**Fix:** Wait 15–30 minutes for the release assets to appear, then re-trigger the workflow manually. If the asset never appears, check the upstream `anthropics/claude-code` releases page to confirm the release is complete.

---

#### c. sed substitution failed

**Symptom:** The `sed` step exits non-zero, or the resulting `.rb` file still contains the old version/SHA. This usually means the version string format or SHA format changed in a way the pattern no longer matches.

**Fix:**
1. Open the failing cask file (e.g., `Casks/claude-code@latest.rb`).
2. Identify the `version` and `sha256` lines.
3. Update the `sed` pattern in the workflow to match the current format, or manually apply the substitution (see "Manually bumping a cask version" below) and open a PR.

---

#### d. PR creation failed — branch already exists

**Symptom:** The `gh pr create` step fails with "A branch named X already exists."

**Cause:** A previous run opened a PR that was not merged or closed, and the branch is still present.

**Fix:**
- If the existing PR is still valid, merge or close it first, then delete the branch.
- If the PR is stale, close it, delete the branch, and re-run the workflow:
  ```bash
  gh pr close <PR_NUMBER> --repo ConsultingMD/homebrew-ih-public
  git push origin --delete update-claude-code-<version>
  ```

---

#### e. Auto-merge blocked — CODEOWNERS review required

**Symptom:** The PR is created and CI passes but auto-merge does not fire. The PR shows "Review required."

**Cause:** The CODEOWNERS rule exempts cask files from review, but the exemption only takes effect once the rule is on the default branch. If auto-merge is blocked, the exemption may not yet be active.

**Fix:** Request a review from a member of `@ConsultingMD/developer-platform` and approve the PR manually.

---

### Manually bumping a cask version

If the workflow is broken and you need to ship a version bump by hand:

1. Find the new version:
   ```bash
   npm view @anthropic-ai/claude-code dist-tags
   ```

2. Download and inspect the SHA:
   ```bash
   VERSION=<new_version>
   curl -fsSL "https://github.com/anthropics/claude-code/releases/download/v${VERSION}/SHASUMS256.txt"
   ```
   Copy the SHA-256 for the `.zip` artifact that the cask downloads.

3. Edit the cask file (`Casks/claude-code@latest.rb`):
   - Update the `version` line to the new version string.
   - Update the `sha256` line to the new SHA.

4. Verify the cask locally:
   ```bash
   brew audit --cask --new Casks/claude-code@latest.rb
   ```

5. Open a PR with the changes and request review.
