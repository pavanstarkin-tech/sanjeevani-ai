# ==============================================================================
# HealthExpress AI — Universal GitHub Repository Push & Dual Deployment Script
# ==============================================================================
# Usage:
#   # Mode 1: Token-based Auto-Creation (Provide token, auto-creates & pushes)
#   .\push_to_new_repo.ps1 -GitHubToken "ghp_yourTokenHere" -RepoName "healthyxpress-ai"
#
#   # Mode 2: Existing Repository URL (With or without token)
#   .\push_to_new_repo.ps1 -SourceRepoUrl "https://github.com/yourname/your-repo.git"
#
#   # Mode 3: Fully Interactive (Prompts you for token or repo link)
#   .\push_to_new_repo.ps1
# ==============================================================================

param (
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = "",

    [Parameter(Mandatory=$false)]
    [string]$RepoName = "",

    [Parameter(Mandatory=$false)]
    [string]$SourceRepoUrl = "",

    [Parameter(Mandatory=$false)]
    [string]$PagesRepoUrl = "",

    [Parameter(Mandatory=$false)]
    [switch]$IsPrivate = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  HealthExpress AI — Universal GitHub Migration & Deployer       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Interactive input if neither Token nor SourceRepoUrl was passed
if ([string]::IsNullOrWhiteSpace($GitHubToken) -and [string]::IsNullOrWhiteSpace($SourceRepoUrl)) {
    Write-Host "`nYou can provide either:" -ForegroundColor Yellow
    Write-Host "  [Option A] A GitHub Personal Access Token (we will auto-create the repo for you)" -ForegroundColor Gray
    Write-Host "  [Option B] An existing GitHub Repository URL" -ForegroundColor Gray
    
    $userInput = Read-Host "`nEnter GitHub Access Token (ghp_...) OR Repository URL (https://github.com/...)"
    
    if ($userInput.StartsWith("http://") -or $userInput.StartsWith("https://") -or $userInput.StartsWith("git@")) {
        $SourceRepoUrl = $userInput.Trim()
    } else {
        $GitHubToken = $userInput.Trim()
    }
}

# 2. Token-Based Auto-Creation & Verification
$headers = $null
$username = ""

if (![string]::IsNullOrWhiteSpace($GitHubToken)) {
    $GitHubToken = $GitHubToken.Trim()
    Write-Host "`n[1/5] Verifying GitHub Access Token via API..." -ForegroundColor Yellow
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept"        = "application/vnd.github.v3+json"
        "User-Agent"    = "HealthExpress-Deployer"
    }

    try {
        $userProfile = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
        $username = $userProfile.login
        Write-Host "[SUCCESS] Authenticated as GitHub user: $username ($($userProfile.name))" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not verify token via API. Proceeding with provided Git credentials..." -ForegroundColor Yellow
    }
}

# 3. Resolve Target Repository URL
if (![string]::IsNullOrWhiteSpace($SourceRepoUrl)) {
    # Developer provided a direct repository URL
    $cleanRepoUrl = $SourceRepoUrl.Trim()
    if (![string]::IsNullOrWhiteSpace($GitHubToken) -and $cleanRepoUrl.StartsWith("https://github.com/")) {
        $authSourceUrl = $cleanRepoUrl -replace "https://github.com/", "https://x-access-token:$GitHubToken@github.com/"
    } else {
        $authSourceUrl = $cleanRepoUrl
    }
    $publicSourceUrl = $cleanRepoUrl
} else {
    # Developer provided a repo name or we auto-name it
    if ([string]::IsNullOrWhiteSpace($RepoName)) {
        $RepoName = Read-Host "Enter target repository name (default: healthyxpress-ai)"
        if ([string]::IsNullOrWhiteSpace($RepoName)) {
            $RepoName = "healthyxpress-ai"
        }
    }
    $RepoName = $RepoName.Trim()

    if (![string]::IsNullOrWhiteSpace($username) -and $headers -ne $null) {
        # Check if repository already exists on GitHub
        try {
            $checkRepo = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$RepoName" -Headers $headers -Method Get
            Write-Host "Found existing repository on GitHub: $username/$RepoName" -ForegroundColor Green
        } catch {
            # Auto-create the repo on GitHub!
            Write-Host "Repository '$RepoName' does not exist. Auto-creating repository under @$username..." -ForegroundColor Cyan
            $createBody = @{
                "name"        = $RepoName
                "description" = "HealthExpress AI — Intelligent Healthcare Platform (Telehealth, ABDM Aarogyasri, 15-Min Pharmacy Delivery)"
                "private"     = $IsPrivate.IsPresent
                "auto_init"   = $false
            } | ConvertTo-Json

            $newRepo = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers -Method Post -Body $createBody
            Write-Host "[SUCCESS] Created new repository: https://github.com/$username/$RepoName" -ForegroundColor Green
        }
        $authSourceUrl = "https://x-access-token:$GitHubToken@github.com/$username/$RepoName.git"
        $publicSourceUrl = "https://github.com/$username/$RepoName"
    } else {
        $authSourceUrl = "https://github.com/$RepoName.git"
        $publicSourceUrl = $authSourceUrl
    }
}

# Resolve Pages Deployment URL
if ([string]::IsNullOrWhiteSpace($PagesRepoUrl)) {
    $authPagesUrl = $authSourceUrl
    $publicPagesUrl = $publicSourceUrl
} else {
    $cleanPagesUrl = $PagesRepoUrl.Trim()
    if (![string]::IsNullOrWhiteSpace($GitHubToken) -and $cleanPagesUrl.StartsWith("https://github.com/")) {
        $authPagesUrl = $cleanPagesUrl -replace "https://github.com/", "https://x-access-token:$GitHubToken@github.com/"
    } else {
        $authPagesUrl = $cleanPagesUrl
    }
    $publicPagesUrl = $cleanPagesUrl
}

# 4. Configure Workspace Git Remote & Push Source Code
Write-Host "`n[2/5] Configuring Git Remote & Pushing Source Code to main..." -ForegroundColor Yellow
Write-Host "Target Repository: $publicSourceUrl" -ForegroundColor Gray

try {
    git remote remove origin 2>$null
} catch {}

git remote add origin $authSourceUrl
git branch -M main
git add .
git commit -m "feat: complete HealthExpress AI platform source code" --allow-empty
git push -u origin main --force

Write-Host "[SUCCESS] Source code successfully pushed to main branch!" -ForegroundColor Green

# 5. Compile Flutter Web App
Write-Host "`n[3/5] Building Flutter Web Distribution (Root /)..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\healthexpress"
flutter pub get
flutter build web --release --base-href "/" --no-tree-shake-icons
Set-Location "$PSScriptRoot"
Write-Host "[SUCCESS] Flutter Web build completed." -ForegroundColor Green

# 6. Compile React Vite Admin Panel
Write-Host "`n[4/5] Building React Vite Admin Panel (/admin)..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\admin_panel"
if (!(Test-Path "node_modules")) {
    npm install
}
npm run build
Set-Location "$PSScriptRoot"
Write-Host "[SUCCESS] React Admin Panel build completed." -ForegroundColor Green

# 7. Assemble and Deploy to GitHub Pages
Write-Host "`n[5/5] Assembling Dual-Bundle and Pushing to gh-pages..." -ForegroundColor Yellow
$tempDeployDir = "$PSScriptRoot\temp_universal_deploy"
if (Test-Path $tempDeployDir) {
    Remove-Item -Path $tempDeployDir -Recurse -Force -ErrorAction SilentlyContinue
}

git clone $authPagesUrl $tempDeployDir 2>$null
if (Test-Path $tempDeployDir) {
    Set-Location $tempDeployDir
    try {
        git checkout gh-pages 2>$null
    } catch {
        git checkout -b gh-pages
    }
    Get-ChildItem -Path $tempDeployDir -Exclude ".git" | Remove-Item -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $tempDeployDir | Out-Null
    Set-Location $tempDeployDir
    git init
    git remote add origin $authPagesUrl
    git checkout -b gh-pages
}

# Copy Flutter Web App to root
Copy-Item -Path "$PSScriptRoot\healthexpress\build\web\*" -Destination $tempDeployDir -Recurse -Force

# Copy React Admin Dashboard to /admin
$adminDest = "$tempDeployDir\admin"
if (!(Test-Path $adminDest)) {
    New-Item -ItemType Directory -Path $adminDest | Out-Null
}
Copy-Item -Path "$PSScriptRoot\admin_panel\dist\*" -Destination $adminDest -Recurse -Force

# Add .nojekyll
New-Item -ItemType File -Path "$tempDeployDir\.nojekyll" -Force | Out-Null

# Commit and push gh-pages
git add -A
git commit -m "deploy: update GitHub Pages with latest HealthExpress AI app & admin panel" --allow-empty
git push -u origin gh-pages --force

Set-Location "$PSScriptRoot"
Remove-Item -Path $tempDeployDir -Recurse -Force -ErrorAction SilentlyContinue

# Set clean workspace origin (without token embedded in plain text git config)
if (![string]::IsNullOrWhiteSpace($username) -and ![string]::IsNullOrWhiteSpace($RepoName)) {
    git remote set-url origin "https://github.com/$username/$RepoName.git" 2>$null
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "  MIGRATION & DEPLOYMENT COMPLETED SUCCESSFULLY!                 " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Workspace Remote URL: $publicSourceUrl" -ForegroundColor Cyan
Write-Host "GitHub Pages Branch:  gh-pages" -ForegroundColor Cyan
if (![string]::IsNullOrWhiteSpace($username) -and ![string]::IsNullOrWhiteSpace($RepoName)) {
    Write-Host "Live Web App:         https://$username.github.io/$RepoName/" -ForegroundColor Yellow
    Write-Host "Live Admin Panel:     https://$username.github.io/$RepoName/admin/" -ForegroundColor Yellow
}
Write-Host "=================================================================" -ForegroundColor Green
