const mysql = require('mysql2/promise');
require('dotenv').config();

const configs = [
  {
    label: 'Hostinger Domain (srv1117.hstgr.io)',
    host: 'srv1117.hstgr.io',
    port: 3306,
    user: process.env.DB_USER || 'u170253497_healthexpress',
    password: process.env.DB_PASSWORD || 'Healthxpress_1234567',
    database: process.env.DB_NAME || 'u170253497_healthexpress',
    connectTimeout: 8000,
  },
  {
    label: 'Direct Server IP (147.93.101.73)',
    host: '147.93.101.73',
    port: 3306,
    user: process.env.DB_USER || 'u170253497_healthexpress',
    password: process.env.DB_PASSWORD || 'Healthxpress_1234567',
    database: process.env.DB_NAME || 'u170253497_healthexpress',
    connectTimeout: 8000,
  }
];

async function testConnections() {
  console.log('--------------------------------------------------');
  console.log('Testing Remote MySQL Database Connections...');
  console.log('Database:', process.env.DB_NAME || 'u170253497_healthexpress');
  console.log('Username:', process.env.DB_USER || 'u170253497_healthexpress');
  console.log('--------------------------------------------------');

  for (const cfg of configs) {
    console.log(`\nAttempting connection to [${cfg.label}]...`);
    try {
      const conn = await mysql.createConnection({
        host: cfg.host,
        port: cfg.port,
        user: cfg.user,
        password: cfg.password,
        database: cfg.database,
        connectTimeout: cfg.connectTimeout,
      });

      console.log(`✅ SUCCESS: Connected to MySQL database via ${cfg.host}!`);
      const [rows] = await conn.execute('SELECT 1 + 1 AS testResult, NOW() AS serverTime, VERSION() AS mysqlVersion');
      console.log('Query result:', rows);
      await conn.end();
      return cfg;
    } catch (err) {
      console.log(`❌ FAILED for ${cfg.host}:`, err.message);
      if (err.code) console.log('Error code:', err.code);
    }
  }

  console.log('\n--------------------------------------------------');
  console.log('Note: If remote direct access to port 3306 is restricted by Hostinger firewall,');
  console.log('Hostinger requires enabling "Remote MySQL" with IP "%" (wildcard) in hPanel.');
  console.log('--------------------------------------------------');
}

testConnections();
