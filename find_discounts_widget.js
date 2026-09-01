const fs = require('fs');
const path = require('path');

const widgetsDir = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib\\\\widgets';
const files = fs.readdirSync(widgetsDir);
console.log('Widgets matching discount / coupon / marketplace:');
console.log(files.filter(f => f.includes('discount') || f.includes('coupon') || f.includes('market')));

