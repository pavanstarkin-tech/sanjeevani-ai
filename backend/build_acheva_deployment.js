const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const adminDir = path.join(rootDir, 'admin_panel');
const adminDistDir = path.join(adminDir, 'dist');
const phpBackendDir = path.join(rootDir, 'php_backend');
const bundleDir = path.join(__dirname, 'acheva_deploy_bundle');
const tarGzPath = path.join(__dirname, 'acheva_public_html.tar.gz');
const zipPath = path.join(__dirname, 'acheva_public_html.zip');

console.log('=== 1. Building React Admin Panel with RAG Chunks Management ===');
execSync('npm run build', { cwd: adminDir, stdio: 'inherit' });

console.log('=== 2. Assembling acheva.in Deployment Bundle ===');
if (fs.existsSync(bundleDir)) {
  fs.rmSync(bundleDir, { recursive: true, force: true });
}
fs.mkdirSync(bundleDir, { recursive: true });

// Copy Admin Panel Dist files to root of bundle
console.log('Copying React Admin Panel dist to bundle root...');
fs.cpSync(adminDistDir, bundleDir, { recursive: true });

// Copy PHP Backend to /api subfolder
const apiTargetDir = path.join(bundleDir, 'api');
fs.mkdirSync(apiTargetDir, { recursive: true });
console.log('Copying PHP Backend to /api subfolder...');
fs.cpSync(phpBackendDir, apiTargetDir, { recursive: true });

// Create Root .htaccess for LiteSpeed / Apache routing
const rootHtaccess = `<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /

  # 1. Route API requests to api/index.php
  RewriteRule ^api/(.*)$ api/index.php [L,QSA]
  RewriteRule ^api$ api/index.php [L,QSA]

  # 2. Existing files and directories
  RewriteCond %{REQUEST_FILENAME} -f [OR]
  RewriteCond %{REQUEST_FILENAME} -d
  RewriteRule ^ - [L]

  # 3. Fallback to React Admin Single Page App
  RewriteRule ^ index.html [L]
</IfModule>
`;
fs.writeFileSync(path.join(bundleDir, '.htaccess'), rootHtaccess, 'utf8');

// Create API .htaccess
const apiHtaccess = `<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^(.*)$ index.php [QSA,L]
</IfModule>
`;
fs.writeFileSync(path.join(apiTargetDir, '.htaccess'), apiHtaccess, 'utf8');

// Create Tar.gz and Zip archive
console.log('=== 3. Creating Archives for Hostinger Deployment ===');
if (fs.existsSync(tarGzPath)) fs.unlinkSync(tarGzPath);
execSync(`tar -czf "${tarGzPath}" -C "${bundleDir}" .`, { stdio: 'inherit' });

console.log('Created tar.gz archive:', (fs.statSync(tarGzPath).size / 1024).toFixed(1), 'KB');

// Create PowerShell zip as well
try {
  if (fs.existsSync(zipPath)) fs.unlinkSync(zipPath);
  execSync(`powershell -Command "Compress-Archive -Path '${bundleDir}\\*' -DestinationPath '${zipPath}' -Force"`, { stdio: 'inherit' });
  console.log('Created zip archive:', (fs.statSync(zipPath).size / 1024).toFixed(1), 'KB');
} catch (e) {
  console.warn('Zip creation note:', e.message);
}

console.log('\n✅ Deployment Bundle successfully built and packaged!');
console.log('Files created:');
console.log('1. ' + tarGzPath);
console.log('2. ' + zipPath);
console.log('3. Folder: ' + bundleDir);
