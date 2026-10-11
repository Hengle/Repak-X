param (
    [string]$Message = "Update backend"
)

Write-Host "=== Backend Push Helper ===" -ForegroundColor Cyan

# Change to repo root (scripts are in scripts/Repak-X_scripts/, so go up 2 levels)
$scriptDir = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
Set-Location $repoRoot

# Source the version bump utility
. "$scriptDir\version_bump.ps1"

# Check for [run-ci] release
$versionResult = Invoke-VersionBump -RepoRoot $repoRoot

# Define backend directories (excludes website/ and other frontend dirs)
$backendDirs = @("repak", "repak-x", "oodle_loader", "uasset_toolkit")

# 1. Add Rust Source Files from backend directories only
Write-Host "Staging Rust files (*.rs, Cargo.toml)..."
foreach ($dir in $backendDirs) {
    if (Test-Path $dir) {
        git add "$dir/**/*.rs"
        git add "$dir/**/Cargo.toml"
    }
}
# Add root-level Cargo.toml only (NOT Cargo.lock)
git add "Cargo.toml"

# 2. Add C# Source Files from uasset_toolkit only
Write-Host "Staging C# files (*.cs, *.csproj, *.sln)..."
git add "uasset_toolkit/**/*.cs"
git add "uasset_toolkit/**/*.csproj"
git add "uasset_toolkit/**/*.sln"

# 3. Add Root Configuration (root level only)
Write-Host "Staging root config files..."
git add "*.bat"
git add "*.md"
git add ".gitignore"
git add ".gitmodules"
git add "rust-toolchain.toml"

# 4. Add scripts directory
Write-Host "Staging scripts..."
git add "scripts/**/*.ps1"
git add "scripts/**/*.bat"

# 5. Add submodule pointer if it changed
Write-Host "Staging submodule reference (UAssetToolRivals)..."
git add "UAssetToolRivals"

# 6. Check if anything was staged
$status = git status --porcelain
if (-not $status) {
    Write-Host "No backend changes detected to commit." -ForegroundColor Yellow
    Write-Host "Current Git Status:" -ForegroundColor Gray
    git status
    exit
}

# 7. Commit (prepend [run-ci] if this is a release)
if ($versionResult.RunCI) {
    $Message = "[run-ci] $Message"
} elseif ($versionResult.DryCI) {
    $Message = "[dry-ci] $Message"
}
Write-Host "Committing: $Message" -ForegroundColor Green
git commit -m "$Message"

# 8. Push
Write-Host "Pushing to origin/main..." -ForegroundColor Cyan
git push

Write-Host "Backend push complete!" -ForegroundColor Green
