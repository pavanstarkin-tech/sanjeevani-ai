const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('SSH authenticated successfully!');
  conn.exec('ls -la /home/u170253497/domains', (err, stream) => {
    if (err) throw err;
    let out = '';
    stream.on('data', d => out += d);
    stream.on('close', () => {
      console.log('Domains list:\n', out);
      conn.end();
    });
  });
}).on('keyboard-interactive', (name, instructions, instructionsLang, prompts, finish) => {
  console.log('Handling keyboard-interactive prompt...');
  finish(prompts.map(() => 'Sanvith@27'));
}).on('error', (err) => {
  console.error('SSH Error:', err.message);
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Sanvith@27',
  tryKeyboard: true
});
