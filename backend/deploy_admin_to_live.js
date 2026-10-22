const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { Client } = require('ssh2');

console.log('1. Packaging admin_panel/dist...');
const adminDist = path.resolve(__dirname, '..', 'admin_panel', 'dist');
const tarPath = path.resolve(__dirname, 'admin_panel.tar.gz');

execSync(`tar -czf "${tarPath}" -C "${adminDist}" .`);
console.log('Packaged successfully. Size:', fs.statSync(tarPath).size, 'bytes');

console.log('2. Connecting via SSH to 147.93.101.73...');
const conn = new Client();
conn.on('ready', () => {
  console.log('SSH authenticated.');
  conn.sftp((err, sftp) => {
    if (err) throw err;
    console.log('SFTP ready. Uploading tar.gz...');

    const remoteTar = '/home/u170253497/admin_panel.tar.gz';
    sftp.fastPut(tarPath, remoteTar, (putErr) => {
      if (putErr) throw putErr;
      console.log('Uploaded tar.gz to server.');

      const cmd = `
        mkdir -p /home/u170253497/domains/vedvaidyam.com/public_html/admin
        tar -xzf /home/u170253497/admin_panel.tar.gz -C /home/u170253497/domains/vedvaidyam.com/public_html/admin
        chmod -R 755 /home/u170253497/domains/vedvaidyam.com/public_html/admin
        rm -f /home/u170253497/admin_panel.tar.gz

        cat << 'EOF' > /home/u170253497/domains/vedvaidyam.com/public_html/admin/.htaccess
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  RewriteRule ^index\\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /admin/index.html [L]
</IfModule>
EOF
        echo "Deployment to vedvaidyam.com/admin completed!"
      `;

      conn.exec(cmd, (execErr, stream) => {
        if (execErr) throw execErr;
        stream.on('data', d => console.log(d.toString()));
        stream.on('close', () => {
          console.log('Done!');
          conn.end();
        });
      });
    });
  });
}).on('error', err => console.error('SSH Error:', err)).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Honey_comb@@#$%^&d1'
});
