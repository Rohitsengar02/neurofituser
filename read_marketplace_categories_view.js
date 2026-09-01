const fs = require('fs');
const path = require('path');

const catViewPath = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib\\\\widgets\\\\marketplace_categories_view.dart';
if (fs.existsSync(catViewPath)) {
  console.log(fs.readFileSync(catViewPath, 'utf8'));
} else {
  console.log('marketplace_categories_view.dart not found');
}
