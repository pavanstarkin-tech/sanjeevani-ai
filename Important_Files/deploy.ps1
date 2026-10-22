# HealthExpress Automated Deployment Script for Windows PowerShell
Write-Host "[DEPLOY] Starting HealthExpress Dual Deployment..." -ForegroundColor Cyan

# 1. Build Flutter Web Application
Write-Host "[1/3] Building Flutter Web App (Root /)..." -ForegroundColor Yellow
Set-Location healthexpress
flutter build web --release --base-href "/healthyxpress_medha/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Flutter build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Copy-Item "build\web\index.html" "build\web\404.html" -Force
New-Item -ItemType File -Force -Path "build\web\.nojekyll" | Out-Null
Set-Location ..

# 2. Build React Vite Admin Panel
Write-Host "[2/3] Building React Vite Admin Panel (/admin)..." -ForegroundColor Yellow
Set-Location admin_panel
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Admin Panel build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# 3. Assemble and Push to gh-pages branch
Write-Host "[3/3] Assembling and Pushing to gh-pages branch..." -ForegroundColor Green
if (Test-Path "temp_gh_pages") { Remove-Item -Recurse -Force "temp_gh_pages" }
git worktree prune
git worktree add -B gh-pages temp_gh_pages gh-pages
Get-ChildItem -Path temp_gh_pages -Exclude ".git" | Remove-Item -Recurse -Force

Copy-Item -Recurse -Force "healthexpress\build\web\*" "temp_gh_pages\"
Copy-Item -Force "healthexpress\build\web\.nojekyll" "temp_gh_pages\.nojekyll"

New-Item -ItemType Directory -Force -Path "temp_gh_pages\admin" | Out-Null
Copy-Item -Recurse -Force "admin_panel\dist\*" "temp_gh_pages\admin\"

Set-Location temp_gh_pages
git add -A
git commit -m "deploy: update GitHub Pages with latest app and admin panel"
Set-Location ..
git worktree remove temp_gh_pages --force

git push origin gh-pages --force

Write-Host "[DONE] Deployment Complete! Live at:" -ForegroundColor Green
Write-Host "App:   https://pavanstarkin-tech.github.io/healthyxpress_medha/" -ForegroundColor Cyan
Write-Host "Admin: https://pavanstarkin-tech.github.io/healthyxpress_medha/admin/" -ForegroundColor Cyan
