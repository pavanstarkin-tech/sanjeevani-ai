const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  conn.exec('ls -la /home/u170253497/domains/showsnap.in/public_html/app; find /home/u170253497/domains -maxdepth 3 -name "index.html" 2>/dev/null', (err, stream) => {
    if (err) throw err;
    stream.on('data', d => process.stdout.write(d));
    stream.on('close', () => conn.end());
  });
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Honey_comb@@#$%^&d1'
});
