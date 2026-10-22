const https = require('https');
const fs = require('fs');
const path = require('path');

function httpGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    }).on('error', reject);
  });
}

function httpPost(url, payload) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(payload);
    const u = new URL(url);
    const req = https.request({
      hostname: u.hostname,
      port: 443,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function syncChunks() {
  console.log('1. Fetching current chunks on https://acheva.in/api/ai/rag-chunks...');
  const remoteRes = await httpGet('https://acheva.in/api/ai/rag-chunks');
  const remoteChunks = remoteRes.data?.data?.chunks || [];
  console.log(`Found ${remoteChunks.length} existing chunks on acheva.in.`);
  
  const existingTitles = new Set(remoteChunks.map(c => (c.title || '').trim().toLowerCase()));

  const localFile = path.join(__dirname, '..', 'php_backend', 'data', 'rag_chunks.json');
  const localData = JSON.parse(fs.readFileSync(localFile, 'utf8'));
  const localChunks = localData.chunks || [];
  console.log(`Loaded ${localChunks.length} chunks from local library.`);

  let addedCount = 0;
  for (const chunk of localChunks) {
    const titleKey = (chunk.title || '').trim().toLowerCase();
    if (!existingTitles.has(titleKey)) {
      console.log(`Uploading: "${chunk.title}" [${chunk.category}]...`);
      const res = await httpPost('https://acheva.in/api/ai/rag-chunks', {
        title: chunk.title,
        content: chunk.content,
        category: chunk.category || 'Clinical Guidelines',
        condition: chunk.condition || 'General Health',
        severity: chunk.severity || 'Moderate',
        tags: Array.isArray(chunk.tags) ? chunk.tags : (chunk.tags || '').split(','),
        scheme_ref: chunk.scheme_ref || 'HealthExpress RAG'
      });
      if (res.status === 201 || res.status === 200) {
        addedCount++;
        existingTitles.add(titleKey);
      } else {
        console.error(`Failed to upload "${chunk.title}":`, res.data);
      }
    }
  }

  console.log(`\nSuccessfully added ${addedCount} new chunks to acheva.in!`);

  console.log('2. Publishing RAG updates on acheva.in...');
  const pubRes = await httpPost('https://acheva.in/api/ai/rag-chunks/publish', {});
  console.log('Publish result:', pubRes.data);

  console.log('3. Verifying updated count on acheva.in...');
  const finalRes = await httpGet('https://acheva.in/api/ai/rag-chunks');
  const finalChunks = finalRes.data?.data?.chunks || [];
  console.log(`🎉 Total chunks now live on acheva.in: ${finalChunks.length}`);
}

syncChunks().catch(console.error);
