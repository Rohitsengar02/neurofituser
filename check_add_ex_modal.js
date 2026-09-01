const fs = require('fs');
const path = require('path');

const viewPath = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib\\\\widgets\\\\fitness_exercises_view.dart';
const code = fs.readFileSync(viewPath, 'utf8');

const lines = code.split('\n');
let start = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('class _AddExerciseBottomSheet')) {
    start = i;
    break;
  }
}

if (start != -1) {
  for (let i = start; i < Math.min(lines.length, start + 160); i++) {
    console.log(`${i + 1}: ${lines[i]}`);
  }
}
