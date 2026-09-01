const https = require('https');

const projectId = "neurofit-52fe0";
const apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";

const options = {
  hostname: 'firestore.googleapis.com',
  port: 443,
  path: `/v1/projects/${projectId}/databases/(default)/documents/products?key=${apiKey}&pageSize=50`,
  method: 'GET',
};

const req = https.request(options, (res) => {
  let b = '';
  res.on('data', c => b += c);
  res.on('end', () => {
    const json = JSON.parse(b);
    const docs = json.documents || [];
    console.log(`Verified ${docs.length} products in Firestore 'products' collection!`);
    docs.forEach((d, i) => {
      const name = d.name.split('/').pop();
      const title = d.fields.title?.stringValue || 'Untitled';
      const price = d.fields.price?.doubleValue || 0;
      const tags = d.fields.tags?.arrayValue?.values?.map(v => v.stringValue).join(', ') || '';
      console.log(`${i + 1}. [${name}] "${title}" - ₹${price} (Tags: ${tags})`);
    });
  });
});

req.on('error', e => console.error(e));
req.end();
