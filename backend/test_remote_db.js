const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('SSH authenticated.');
  const testPhp = `
    php -r '
      require "domains/acheva.in/public_html/api/config/database.php";
      try {
        $db = Database::getConnection();
        $tables = $db->query("SHOW TABLES")->fetchAll();
        echo "SUCCESS: Connected to DB! Total tables: " . count($tables) . "\\n";
        foreach (array_slice($tables, 0, 5) as $t) {
          echo " - " . reset($t) . "\\n";
        }
      } catch (Exception $e) {
        echo "ERROR: " . $e->getMessage() . "\\n";
      }
    '
  `;
  conn.exec(testPhp, (err, stream) => {
    if (err) throw err;
    stream.on('data', d => console.log(d.toString()));
    stream.on('close', () => {
      conn.end();
      process.exit(0);
    });
  });
}).on('error', err => {
  console.error('SSH Error:', err);
  process.exit(1);
}).connect({
  host: '193.203.185.110',
  port: 65002,
  username: 'u833088220',
  password: 'Pavan@22823'
});
