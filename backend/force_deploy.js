const fs = require('fs');
const path = require('path');
const { Client } = require('ssh2');

const rootDir = path.resolve(__dirname, '..');
const localController = path.join(rootDir, 'php_backend', 'controllers', 'ApiKeyPoolController.php');
const localData = path.join(rootDir, 'php_backend', 'data', 'sarvam_api_keys.json');
const localIndex = path.join(rootDir, 'php_backend', 'index.php');
const localResponse = path.join(rootDir, 'php_backend', 'helpers', 'Response.php');

const remoteBase = '/home/u170253497/domains/vedvaidyam.com/public_html/healthexpress';

const conn = new Client();
conn.on('ready', () => {
  console.log('SSH authenticated.');
  conn.sftp((err, sftp) => {
    if (err) throw err;
    console.log('SFTP opened.');

    const files = [
      { local: localController, remote: remoteBase + '/controllers/ApiKeyPoolController.php' },
      { local: localData, remote: remoteBase + '/data/sarvam_api_keys.json' },
      { local: localIndex, remote: remoteBase + '/index.php' },
      { local: localResponse, remote: remoteBase + '/helpers/Response.php' }
    ];

    let count = 0;
    files.forEach(f => {
      sftp.fastPut(f.local, f.remote, putErr => {
        if (putErr) {
          console.error('Error putting ' + f.remote, putErr);
        } else {
          console.log('Uploaded: ' + f.remote);
        }
        count++;
        if (count === files.length) {
          conn.exec(`chmod -R 755 ${remoteBase}/data && chmod 644 ${remoteBase}/data/sarvam_api_keys.json`, (e, stream) => {
            stream.on('close', () => {
              console.log('Permissions updated. Done.');
              conn.end();
            });
          });
        }
      });
    });
  });
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Honey_comb@@#$%^&d1'
});
