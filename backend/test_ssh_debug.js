const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('SUCCESS! Authenticated to Hostinger!');
  conn.exec('pwd; whoami; ls -la /home/u170253497', (err, stream) => {
    if (err) throw err;
    let out = '';
    stream.on('data', d => out += d);
    stream.on('close', () => {
      console.log('Command output:\n', out);
      conn.end();
    });
  });
}).on('banner', (msg) => {
  console.log('Server Banner:', msg);
}).on('error', (err) => {
  console.error('SSH Error:', err.message, err.level);
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Sanvith@27',
  authHandler: (methodsLeft, partialSuccess, callback) => {
    console.log('Methods left from server:', methodsLeft);
    if (!methodsLeft || methodsLeft.includes('password')) {
      console.log('Attempting password auth...');
      return callback({ type: 'password', username: 'u170253497', password: 'Sanvith@27' });
    }
    if (methodsLeft.includes('keyboard-interactive')) {
      console.log('Attempting keyboard-interactive auth...');
      return callback({
        type: 'keyboard-interactive',
        username: 'u170253497',
        prompt: (name, instr, lang, prompts, finish) => {
          console.log('Prompt received:', prompts);
          finish(['Sanvith@27']);
        }
      });
    }
    callback(false);
  }
});
