const https = require('https');

const projectId = "neurofit-52fe0";
const apiKey = "AIzaSyDcGovQH3Sd_0kdNeSISK6eNCdtjA_g9vg";
const publicDevUrl = "https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev";

const sampleSubCategories = [
  { parentId: 'cat_supplements_protein', parentName: 'Supplements & Protein', subId: 'sub_whey_isolate', name: 'Whey Isolate', imageUrl: `${publicDevUrl}/uploads/whey_protein.jpg`, itemCount: 18 },
  { parentId: 'cat_supplements_protein', parentName: 'Supplements & Protein', subId: 'sub_creatine', name: 'Creatine Monohydrate', imageUrl: `${publicDevUrl}/uploads/whey_protein.jpg`, itemCount: 12 },
  { parentId: 'cat_supplements_protein', parentName: 'Supplements & Protein', subId: 'sub_preworkout', name: 'Pre-Workout Formulas', imageUrl: `${publicDevUrl}/uploads/whey_protein.jpg`, itemCount: 14 },
  { parentId: 'cat_gym_equipment', parentName: 'Gym & Lifting Equipment', subId: 'sub_dumbbells', name: 'Adjustable Dumbbells', imageUrl: `${publicDevUrl}/uploads/gym_equipment.jpg`, itemCount: 32 },
  { parentId: 'cat_gym_equipment', parentName: 'Gym & Lifting Equipment', subId: 'sub_barbells_plates', name: 'Barbells & Olympic Plates', imageUrl: `${publicDevUrl}/uploads/gym_equipment.jpg`, itemCount: 28 },
  { parentId: 'cat_apparel', parentName: 'Performance Apparel', subId: 'sub_gym_tees', name: 'Compression Tees', imageUrl: `${publicDevUrl}/uploads/apparel.jpg`, itemCount: 40 },
  { parentId: 'cat_apparel', parentName: 'Performance Apparel', subId: 'sub_shorts', name: 'Lifting Shorts', imageUrl: `${publicDevUrl}/uploads/apparel.jpg`, itemCount: 24 },
];

function seedSubDoc(sub) {
  return new Promise((resolve) => {
    const nowIso = new Date().toISOString();
    const postBody = JSON.stringify({
      fields: {
        subCategoryId: { stringValue: sub.subId },
        id: { stringValue: sub.subId },
        parentCategoryId: { stringValue: sub.parentId },
        parentCategoryName: { stringValue: sub.parentName },
        name: { stringValue: sub.name },
        title: { stringValue: sub.name },
        slug: { stringValue: sub.name.toLowerCase().replace(/[^a-z0-9]+/g, '-') },
        imageUrl: { stringValue: sub.imageUrl },
        itemCount: { integerValue: String(sub.itemCount) },
        status: { stringValue: 'Active' },
        isActive: { booleanValue: true },
        createdAt: { timestampValue: nowIso },
        updatedAt: { timestampValue: nowIso }
      }
    });

    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: `/v1/projects/${projectId}/databases/(default)/documents/categories/${sub.parentId}/subcategories/${sub.subId}?key=${apiKey}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postBody)
      }
    };

    const req = https.request(options, (res) => {
      let b = '';
      res.on('data', chunk => b += chunk);
      res.on('end', () => {
        console.log(`Seeded sub-category ${sub.name} in categories/${sub.parentId}/subcategories => Status: ${res.statusCode}`);
        resolve();
      });
    });
    req.on('error', () => resolve());
    req.write(postBody);
    req.end();
  });
}

async function seedAllSubs() {
  for (const s of sampleSubCategories) {
    await seedSubDoc(s);
  }
  console.log('Successfully seeded all subcategories sub-collections in Firestore!');
}

seedAllSubs();
