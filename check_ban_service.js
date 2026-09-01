const fs = require('fs');
const path = require('path');

const banServicePath = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib\\\\services\\\\banners_backend_service.dart';
const code = fs.readFileSync(banServicePath, 'utf8');

console.log(code.slice(0, 1500));
