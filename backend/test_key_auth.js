const fs = require('fs');
const path = require('path');
const os = require('os');
const { Client } = require('ssh2');

const keyPath = path.join(os.homedir(), '.ssh', 'id_rsa_hostinger');
console.log('Testing key auth with:', keyPath);

if (!fs.existsSync(keyPath)) {
  console.log('Key does not exist');
  process.exit(1);
}

const privateKey = fs.readFileSync(keyPath, 'utf8');

function tryConnect(passphrase) {
  return new Promise((resolve) => {
    const conn = new Client();
    conn.on('ready', () => {
      console.log('SSH KEY AUTH SUCCESS with passphrase:', passphrase ? 'YES' : 'NONE');
      conn.exec('whoami; pwd; ls -la /home/u170253497/domains', (err, stream) => {
        if (err) throw err;
        let out = '';
        stream.on('data', d => out += d);
        stream.on('close', () => {
          console.log('Domains output:\n', out);
          conn.end();
          resolve(true);
        });
      });
    }).on('error', (err) => {
      console.log('Key auth error (passphrase: ' + (passphrase || 'none') + '):', err.message);
      resolve(false);
    }).connect({
      host: '147.93.101.73',
      port: 65002,
      username: 'u170253497',
      privateKey: privateKey,
      passphrase: passphrase || undefined,
      readyTimeout: 10000
    });
  });
}

async function main() {
  await tryConnect(null);
  await tryConnect('Sanvith@27');
  await tryConnect('Showsnap@987');
}

main();
