const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { Client } = require('ssh2');
const https = require('https');

const rootDir = path.resolve(__dirname, '..');
const phpBackendDir = path.join(rootDir, 'php_backend');
const tarPath = path.join(__dirname, 'php_backend.tar.gz');

console.log('1. Creating php_backend.tar.gz archive...');
if (fs.existsSync(tarPath)) fs.unlinkSync(tarPath);
execSync(`tar -czf "${tarPath}" -C "${phpBackendDir}" .`, { stdio: 'inherit' });
console.log('Archive created, size:', (fs.statSync(tarPath).size / 1024).toFixed(1), 'KB');

console.log('2. Connecting to Hostinger via SSH/SFTP...');
const conn = new Client();

conn.on('ready', () => {
  console.log('SSH authenticated successfully.');

  conn.sftp((err, sftp) => {
    if (err) throw err;
    console.log('SFTP session opened.');

    const remoteArchive = '/home/u170253497/php_backend.tar.gz';
    const readStream = fs.createReadStream(tarPath);
    const writeStream = sftp.createWriteStream(remoteArchive);

    writeStream.on('close', () => {
      console.log('Uploaded archive to', remoteArchive);

      const deployCmd = `
        mkdir -p /home/u170253497/domains/vedvaidyam.com/public_html/healthexpress
        tar -xzf /home/u170253497/php_backend.tar.gz -C /home/u170253497/domains/vedvaidyam.com/public_html/healthexpress
        chmod -R 755 /home/u170253497/domains/vedvaidyam.com/public_html/healthexpress

        mkdir -p /home/u170253497/domains/showsnap.in/public_html/healthexpress
        tar -xzf /home/u170253497/php_backend.tar.gz -C /home/u170253497/domains/showsnap.in/public_html/healthexpress
        chmod -R 755 /home/u170253497/domains/showsnap.in/public_html/healthexpress

        rm -f /home/u170253497/php_backend.tar.gz
        echo "Extraction and permissions complete."
      `;

      conn.exec(deployCmd, (execErr, stream) => {
        if (execErr) throw execErr;
        let out = '';
        stream.on('data', d => out += d);
        stream.on('close', async () => {
          console.log(out.trim());
          conn.end();

          console.log('\n3. Testing live API endpoints over HTTPS...');
          await testEndpoint('https://vedvaidyam.com/healthexpress/api/health');
          await testEndpoint('https://vedvaidyam.com/healthexpress/api/public/sarvam-keys');
          await testEndpoint('https://vedvaidyam.com/healthexpress/sarvam-keys');
          await testEndpoint('https://vedvaidyam.com/healthexpress/sarvam-keys.php');

          process.exit(0);
        });
      });
    });

    readStream.pipe(writeStream);
  });
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Honey_comb@@#$%^&d1'
});

function testEndpoint(url) {
  return new Promise((resolve) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`\nGET ${url} -> Status: ${res.statusCode}`);
        try {
          const json = JSON.parse(data);
          console.log('JSON Response:', JSON.stringify(json).substring(0, 200) + '...');
        } catch (_) {
          console.log('Raw Response:', data.substring(0, 200));
        }
        resolve();
      });
    }).on('error', (err) => {
      console.log(`\nGET ${url} -> ERROR: ${err.message}`);
      resolve();
    });
  });
}
