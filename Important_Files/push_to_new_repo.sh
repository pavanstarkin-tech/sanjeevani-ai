#!/usr/bin/env bash
# ==============================================================================
# HealthExpress AI — Universal GitHub Repository Push & Dual Deployment (Bash)
# ==============================================================================
# Usage:
#   ./push_to_new_repo.sh "ghp_yourTokenHere" "healthyxpress-ai"
#   ./push_to_new_repo.sh "" "https://github.com/user/existing-repo.git"
# ==============================================================================

set -e

TOKEN="$1"
TARGET="$2"

if [ -z "$TOKEN" ] && [ -z "$TARGET" ]; then
  echo "You can provide either:"
  echo "  [Option A] A GitHub Personal Access Token (we will auto-create the repo for you)"
  echo "  [Option B] An existing GitHub Repository URL"
  read -p "Enter GitHub Access Token (ghp_...) OR Repository URL (https://github.com/...): " INPUT
  if [[ "$INPUT" == http* ]] || [[ "$INPUT" == git@* ]]; then
    TARGET="$INPUT"
  else
    TOKEN="$INPUT"
  fi
fi

USERNAME=""
if [ -n "$TOKEN" ]; then
  echo "Verifying GitHub Access Token via API..."
  USER_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/user || true)
  USERNAME=$(echo "$USER_JSON" | grep -o '"login": *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  if [ -n "$USERNAME" ]; then
    echo "Authenticated as GitHub User: @$USERNAME"
  fi
fi

if [ -n "$TARGET" ] && ([[ "$TARGET" == http* ]] || [[ "$TARGET" == git@* ]]); then
  # Direct repo URL
  PUBLIC_URL="$TARGET"
  if [ -n "$TOKEN" ] && [[ "$TARGET" == https://github.com/* ]]; then
    AUTH_URL=$(echo "$TARGET" | sed "s#https://github.com/#https://x-access-token:${TOKEN}@github.com/#")
  else
    AUTH_URL="$TARGET"
  fi
else
  REPO_NAME="$TARGET"
  if [ -z "$REPO_NAME" ]; then
    read -p "Enter target repository name (default: healthyxpress-ai): " REPO_NAME
    if [ -z "$REPO_NAME" ]; then
      REPO_NAME="healthyxpress-ai"
    fi
  fi

  if [ -n "$USERNAME" ] && [ -n "$TOKEN" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" https://api.github.com/repos/$USERNAME/$REPO_NAME || true)
    if [ "$HTTP_CODE" != "200" ]; then
      echo "Repository does not exist. Auto-creating https://github.com/$USERNAME/$REPO_NAME on GitHub..."
      curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/user/repos \
        -d "{\"name\":\"$REPO_NAME\",\"description\":\"HealthExpress AI — Intelligent Healthcare Platform\",\"private\":false,\"auto_init\":false}" > /dev/null
    fi
    AUTH_URL="https://x-access-token:${TOKEN}@github.com/${USERNAME}/${REPO_NAME}.git"
    PUBLIC_URL="https://github.com/$USERNAME/$REPO_NAME"
  else
    AUTH_URL="https://github.com/$REPO_NAME.git"
    PUBLIC_URL="$AUTH_URL"
  fi
fi

echo "Configuring workspace Git remote & pushing source code to main..."
git remote remove origin 2>/dev/null || true
git remote add origin "$AUTH_URL"
git branch -M main
git add .
git commit -m "feat: complete HealthExpress AI platform source code" --allow-empty
git push -u origin main --force

echo "Building Flutter Web Application..."
cd healthexpress
flutter pub get
flutter build web --release --base-href "/" --no-tree-shake-icons
cd ..

echo "Building React Vite Admin Panel..."
cd admin_panel
npm install
npm run build
cd ..

echo "Deploying to gh-pages branch..."
TEMP_DIR="temp_universal_deploy"
rm -rf "$TEMP_DIR"

git clone "$AUTH_URL" "$TEMP_DIR" 2>/dev/null || true
if [ -d "$TEMP_DIR" ]; then
  cd "$TEMP_DIR"
  git checkout gh-pages 2>/dev/null || git checkout -b gh-pages
  find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +
  cd ..
else
  mkdir -p "$TEMP_DIR"
  cd "$TEMP_DIR"
  git init
  git remote add origin "$AUTH_URL"
  git checkout -b gh-pages
  cd ..
fi

cp -r healthexpress/build/web/* "$TEMP_DIR/"
mkdir -p "$TEMP_DIR/admin"
cp -r admin_panel/dist/* "$TEMP_DIR/admin/"
touch "$TEMP_DIR/.nojekyll"

cd "$TEMP_DIR"
git add -A
git commit -m "deploy: update GitHub Pages with latest app & admin panel" --allow-empty
git push -u origin gh-pages --force
cd ..
rm -rf "$TEMP_DIR"

if [ -n "$PUBLIC_URL" ]; then
  git remote set-url origin "$PUBLIC_URL.git" 2>/dev/null || true
fi

echo "================================================================="
echo "  MIGRATION & DEPLOYMENT COMPLETE!"
echo "  Workspace Remote: $PUBLIC_URL"
echo "  GitHub Pages:     gh-pages branch"
echo "================================================================="
