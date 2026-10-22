const fs = require('fs');
const readline = require('readline');

const transcriptPath = 'C:\\Users\\shese\\.gemini\\antigravity-ide\\brain\\84052a48-5d16-4643-b0b5-aa93210da14e\\.system_generated\\logs\\transcript.jsonl';

const fileStream = fs.createReadStream(transcriptPath);
const rl = readline.createInterface({
  input: fileStream,
  crlfDelay: Infinity
});

let found = [];

rl.on('line', (line) => {
  if (line.includes('acheva.in') && (line.includes('deploy') || line.includes('upload') || line.includes('pushed') || line.includes('SFTP') || line.includes('archive') || line.includes('build_acheva'))) {
    try {
      const parsed = JSON.parse(line);
      const text = parsed.content || JSON.stringify(parsed.tool_calls || {});
      if (text.length > 20) {
        found.push({
          step: parsed.step_index,
          type: parsed.type,
          content: text.slice(0, 300)
        });
      }
    } catch (_) {}
  }
});

rl.on('close', () => {
  console.log(`Found ${found.length} matches:`);
  found.slice(-15).forEach(m => {
    console.log(`\n--- Step ${m.step} (${m.type}) ---`);
    console.log(m.content);
  });
});
