const fs = require('fs');
const path = require('path');

const target1 = 'C:\\\\rohit projects\\\\neurofitadmin\\\\src\\\\app\\\\dashboard\\\\page.tsx';
const target2 = 'C:\\\\rohit projects\\\\neurofitadmin\\\\src\\\\app\\\\page.tsx';
const target3 = 'C:\\\\rohit projects\\\\neurofitadmin\\\\src\\\\app\\\\dashboard.tsx';

const code = fs.readFileSync('C:\\\\rohit projects\\\\neurofitadmin\\\\src\\\\components\\\\Dashboard.tsx', 'utf8');

fs.writeFileSync(target1, code, 'utf8');
fs.writeFileSync(target2, code, 'utf8');
fs.writeFileSync(target3, code, 'utf8');

console.log('Direct code updated in:');
console.log(' - ' + target1);
console.log(' - ' + target2);
console.log(' - ' + target3);
