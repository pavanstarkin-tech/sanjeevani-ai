const { Client } = require('ssh2');

function tryAuth(pass) {
  return new Promise((resolve) => {
    const conn = new Client();
    conn.on('ready', () => {
      console.log('SUCCESS with password:', pass);
      conn.end();
      resolve(true);
    }).on('error', (err) => {
      console.log('Failed with password:', pass, err.message);
      resolve(false);
    }).connect({
      host: '147.93.101.73',
      port: 65002,
      username: 'u170253497',
      password: pass,
      readyTimeout: 10000
    });
  });
}

async function main() {
  const passwords = [
    'Sanvith@27',
    'sanvith@27',
    'Sanvith@2027',
    'Showsnap@987',
    'Healthxpress_1234567'
  ];
  for (const p of passwords) {
    const ok = await tryAuth(p);
    if (ok) break;
  }
}

main();
