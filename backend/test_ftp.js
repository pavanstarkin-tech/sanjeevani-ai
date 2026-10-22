const ftp = require('basic-ftp');

async function testFtp() {
  const client = new ftp.Client();
  client.ftp.verbose = true;
  try {
    await client.access({
      host: '147.93.101.73',
      user: 'u170253497',
      password: 'Sanvith@27',
      secure: false
    });
    console.log('FTP LOGIN SUCCESSFUL!');
    const list = await client.list();
    console.log('Remote root directory contents:');
    for (const item of list) {
      console.log(' -', item.name, item.type === 2 ? '(DIR)' : '(FILE)');
    }
  } catch (err) {
    console.error('FTP Error:', err.message);
  } finally {
    client.close();
  }
}

testFtp();
