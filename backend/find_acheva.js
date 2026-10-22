const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Connected to 147.93.101.73');
  conn.exec('find /home/u170253497 -name "*acheva*" 2>/dev/null; ls -la /home/u170253497/domains', (err, stream) => {
    if (err) throw err;
    stream.on('data', d => console.log(d.toString()));
    stream.on('close', () => conn.end());
  });
}).on('error', err => console.error('SSH Error:', err)).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Honey_comb@@#$%^&d1'
});
