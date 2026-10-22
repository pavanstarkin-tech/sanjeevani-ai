const fs = require('fs');
const file = 'c:\\Users\\shese\\Desktop\\healthyxpress_medha\\admin_panel\\src\\views\\AiManagementView.jsx';
let content = fs.readFileSync(file, 'utf8');

// Remove sessions tab button block
const sessionsTabBlock = /        <button \r?\n          className=\{activeTab === 'sessions' \? 'btn-primary' : 'btn-outline'\} \r?\n          onClick=\{\(\) => setActiveTab\('sessions'\)\}\r?\n          style=\{\{ display: 'flex', alignItems: 'center', gap: 6 \}\}\r?\n        >\r?\n          <Activity size=\{16\} \/> Live AI Triage Sessions \(\{aiSessions\.length > 0 \? aiSessions\.length : stats\.total_ai_sessions\}\)\r?\n        <\/button>\r?\n/;
content = content.replace(sessionsTabBlock, '');

// Update comment
content = content.replace(
  '{/* Tabs for Rules vs Live Triage Audit Sessions */}',
  '{/* Tabs for Rules vs RAG Sync */}'
);

fs.writeFileSync(file, content);
console.log('Done. Sessions tab removed.');
