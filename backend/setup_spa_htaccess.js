const { Client } = require('ssh2');

const htaccessContent = `
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  RewriteRule ^index\\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /admin/index.html [L]
</IfModule>
`;

const conn = new Client();
conn.on('ready', () => {
  conn.sftp((err, sftp) => {
    if (err) throw err;
    const paths = [
      '/home/u170253497/domains/showsnap.in/public_html/admin/.htaccess',
      '/home/u170253497/domains/vedvaidyam.com/public_html/admin/.htaccess'
    ];
    let done = 0;
    paths.forEach(p => {
      const stream = sftp.createWriteStream(p);
      stream.write(htaccessContent);
      stream.end(() => {
        console.log('Written .htaccess to', p);
        done++;
        if (done === paths.length) {
          conn.end();
          console.log('All done!');
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
