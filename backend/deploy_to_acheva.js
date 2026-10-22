const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { Client } = require('ssh2');
const https = require('https');

async function main() {
  console.log('====================================================');
  console.log('🚀 DEPLOYING SANJEEVANI AI ADMIN PANEL & API TO ACHEVA.IN');
  console.log('====================================================');

  const buildScript = path.resolve(__dirname, 'build_acheva_deployment.js');
  console.log('\n[1/4] Running build_acheva_deployment.js...');
  execSync(`node "${buildScript}"`, { stdio: 'inherit' });

  const tarPath = path.resolve(__dirname, 'acheva_public_html.tar.gz');
  if (!fs.existsSync(tarPath)) {
    throw new Error('Tar archive not found: ' + tarPath);
  }
  const tarSizeMB = (fs.statSync(tarPath).size / (1024 * 1024)).toFixed(2);
  console.log(`\n[2/4] Deployment archive ready: ${tarPath} (${tarSizeMB} MB)`);

  console.log('\n[3/4] Connecting to acheva.in server (193.203.185.110:65002)...');
  const conn = new Client();

  await new Promise((resolve, reject) => {
    conn.on('ready', () => {
      console.log('✅ SSH Authenticated successfully as u833088220');
      conn.sftp((err, sftp) => {
        if (err) return reject(err);
        console.log('SFTP initialized. Uploading acheva_public_html.tar.gz to remote home...');

        const remoteTar = '/home/u833088220/acheva_public_html.tar.gz';
        sftp.fastPut(tarPath, remoteTar, (putErr) => {
          if (putErr) return reject(putErr);
          console.log('✅ Upload completed successfully.');

          console.log('\n[4/4] Extracting bundle into /home/u833088220/domains/acheva.in/public_html...');
          const deployCmd = `
            set -e
            TARGET_DIR="/home/u833088220/domains/acheva.in/public_html"
            mkdir -p "$TARGET_DIR"
            tar -xzf /home/u833088220/acheva_public_html.tar.gz -C "$TARGET_DIR"
            chmod -R 755 "$TARGET_DIR"
            rm -f /home/u833088220/acheva_public_html.tar.gz
            echo "--- Remote Extraction Done ---"
            ls -la "$TARGET_DIR"
            echo "--- API Directory Contents ---"
            ls -la "$TARGET_DIR/api"
            echo "--- Testing Local PHP Execution ---"
            php -r '
              require "/home/u833088220/domains/acheva.in/public_html/api/config/database.php";
              try {
                $db = Database::getConnection();
                echo "DB Connected OK! Doctors: " . $db->query("SELECT COUNT(*) FROM doctors")->fetchColumn() . "\\n";
              } catch(Exception $e) {
                echo "DB Error: " . $e->getMessage() . "\\n";
              }
            '
          `;

          conn.exec(deployCmd, (execErr, stream) => {
            if (execErr) return reject(execErr);
            stream.on('data', d => process.stdout.write(d.toString()));
            stream.stderr.on('data', d => process.stderr.write(d.toString()));
            stream.on('close', (code) => {
              if (code !== 0) {
                return reject(new Error('Remote deployment command exited with code ' + code));
              }
              console.log('✅ Remote deployment commands completed cleanly.');
              conn.end();
              resolve();
            });
          });
        });
      });
    }).on('error', err => {
      reject(err);
    }).connect({
      host: '193.203.185.110',
      port: 65002,
      username: 'u833088220',
      password: 'Pavan@22823',
      readyTimeout: 30000
    });
  });

  console.log('\n====================================================');
  console.log('🔍 VERIFYING LIVE DEPLOYMENT ON HTTPS://ACHEVA.IN');
  console.log('====================================================');

  const testEndpoints = [
    { url: 'https://acheva.in/', desc: 'React Admin Panel Homepage' },
    { url: 'https://acheva.in/api/health', desc: 'Backend Telemetry & DB Health' },
    { url: 'https://acheva.in/api/admin/stats', desc: 'Admin Stats & Analytics' },
    { url: 'https://acheva.in/api/hospitals', desc: 'Hospital Directory API' },
    { url: 'https://acheva.in/api/doctors', desc: 'Doctors Directory API' },
  ];

  for (const ep of testEndpoints) {
    try {
      const res = await checkUrl(ep.url);
      console.log(`✅ [${res.statusCode}] ${ep.desc} -> ${ep.url} (${res.bodyPreview})`);
    } catch (e) {
      console.error(`⚠️ [CHECK FAILED] ${ep.desc} (${ep.url}): ${e.message}`);
    }
  }

  console.log('\n🎉 ALL DEPLOYMENT AND VERIFICATION STEPS COMPLETE!');
}

function checkUrl(targetUrl) {
  return new Promise((resolve, reject) => {
    https.get(targetUrl, { timeout: 10000 }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        let preview = data.trim().replace(/\s+/g, ' ').slice(0, 100);
        resolve({ statusCode: res.statusCode, bodyPreview: preview });
      });
    }).on('error', reject);
  });
}

main().catch(err => {
  console.error('\n❌ Deployment Failed:', err);
  process.exit(1);
});
