const ftp = require('basic-ftp');
const { Client } = require('ssh2');

async function testHost(name, host, user, password, port = 21, sshPort = 65002) {
  console.log(`\n--- Testing ${name} (${host}) FTP with ${user} / ${password} ---`);
  const client = new ftp.Client();
  client.ftp.verbose = false;
  try {
    await client.access({ host, user, password, secure: false, port });
    console.log(`✅ ${name} FTP SUCCESSFUL!`);
    const list = await client.list();
    console.log(`Contents (${list.length} items):`, list.map(i => i.name).slice(0, 10).join(', '));
    client.close();
    return true;
  } catch (e) {
    console.log(`❌ ${name} FTP failed:`, e.message);
    client.close();
  }

  console.log(`--- Testing ${name} (${host}) SSH port ${sshPort} with ${user} / ${password} ---`);
  return new Promise(resolve => {
    const conn = new Client();
    conn.on('ready', () => {
      console.log(`✅ ${name} SSH SUCCESSFUL!`);
      conn.exec('pwd; whoami; hostname', (err, stream) => {
        if (!err) {
          stream.on('data', d => console.log('SSH output:', d.toString().trim()));
        }
        conn.end();
        resolve(true);
      });
    }).on('error', err => {
      console.log(`❌ ${name} SSH failed:`, err.message);
      resolve(false);
    }).connect({
      host,
      port: sshPort,
      username: user,
      password,
      readyTimeout: 8000
    });
  });
}

async function run() {
  await testHost('acheva.in (Hostinger)', '193.203.185.110', 'u170253497', 'Sanvith@27');
  await testHost('acheva.in (Hostinger pwd 2)', '193.203.185.110', 'u170253497', 'Honey_comb@@#$%^&d1');
  await testHost('acheva.in by domain', 'acheva.in', 'u170253497', 'Sanvith@27');
  await testHost('147.93.101.73 (Sanvith@27)', '147.93.101.73', 'u170253497', 'Sanvith@27');
}

run();
