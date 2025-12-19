# sync-main-to-develop.ps1
# Sync main -> develop after a PR merge (Windows / PowerShell).
# Defaults: origin, main, develop. Override via parameters if needed.

[CmdletBinding()]
param(
  [string]$Remote = "origin",
  [string]$MainBranch = "main",
  [string]$DevBranch = "develop"
)

function Write-Log($msg) { Write-Host "[sync] $msg" }
function Fail($msg) { Write-Error "[sync] ERROR: $msg"; exit 1 }

# Ensure git is available
$null = Get-Command git -ErrorAction SilentlyContinue
if (-not $?) { Fail "git is not installed or not in PATH." }

# Ensure we're in a git repo
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Fail "Not inside a git repository." }

# Stop if working tree is dirty
$porcelain = git status --porcelain
if ($porcelain -and $porcelain.Trim().Length -gt 0) {
  Write-Host $porcelain
  Fail "Working tree has uncommitted changes. Commit/stash first."
}

# Stop if unresolved conflicts exist
$conflicts = git ls-files -u
if ($conflicts -and $conflicts.Trim().Length -gt 0) {
  Fail "Unresolved merge conflicts detected. Resolve them first."
}

Write-Log "Fetching latest from $Remote..."
git fetch $Remote --prune
if ($LASTEXITCODE -ne 0) { Fail "git fetch failed." }

# Helper: ensure branch exists locally; if not, try to create from remote
function Ensure-Branch([string]$Branch) {
  git show-ref --verify --quiet "refs/heads/$Branch"
  if ($LASTEXITCODE -ne 0) {
    Write-Log "Local branch '$Branch' not found. Attempting to create from $Remote/$Branch..."
    git show-ref --verify --quiet "refs/remotes/$Remote/$Branch"
    if ($LASTEXITCODE -ne 0) { Fail "Remote branch '$Remote/$Branch' not found." }
    git checkout -b $Branch "$Remote/$Branch" | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "Failed to create local branch '$Branch'." }
  }
}

Ensure-Branch $MainBranch
Ensure-Branch $DevBranch

Write-Log "Checking out $MainBranch..."
git checkout $MainBranch | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Failed to checkout '$MainBranch'." }

Write-Log "Updating $MainBranch from $Remote/$MainBranch (fast-forward only)..."
git pull --ff-only $Remote $MainBranch
if ($LASTEXITCODE -ne 0) {
  Fail "Could not fast-forward '$MainBranch'. If you have local commits/divergence, fix that first."
}

Write-Log "Checking out $DevBranch..."
git checkout $DevBranch | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Failed to checkout '$DevBranch'." }

Write-Log "Updating $DevBranch from $Remote/$DevBranch (fast-forward only)..."
git pull --ff-only $Remote $DevBranch
if ($LASTEXITCODE -ne 0) {
  Fail "Could not fast-forward '$DevBranch'. If you have local commits/divergence, fix that first."
}

Write-Log "Merging $MainBranch into $DevBranch..."
git merge --no-edit $MainBranch
if ($LASTEXITCODE -ne 0) {
  Fail "Merge failed. Resolve conflicts, then run: git commit ; git push $Remote $DevBranch"
}

Write-Log "Pushing $DevBranch to $Remote..."
git push $Remote $DevBranch
if ($LASTEXITCODE -ne 0) { Fail "Push failed." }

Write-Log "Done. '$DevBranch' now includes latest '$MainBranch'."
