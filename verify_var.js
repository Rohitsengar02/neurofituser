const fs = require('fs');
const dashboardFile = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib\\\\screens\\\\admin_dashboard_screen.dart';
const code = fs.readFileSync(dashboardFile, 'utf8');

console.log('Contains _selectedAnalyticsTab definition:', code.includes('int _selectedAnalyticsTab = 0;'));
console.log('Contains _selectedAnalyticsTab usage:', code.includes('_selectedAnalyticsTab == index'));
