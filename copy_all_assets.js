const fs = require('fs');
const path = require('path');

const srcDir = 'C:\\\\rohit projects\\\\neurofit\\\\assets';
const destDir = 'C:\\\\rohit projects\\\\neurofitadmin\\\\assets';

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach((childItemName) => {
      copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

// 1. Copy all assets
copyRecursiveSync(srcDir, destDir);
console.log('Successfully copied all assets (images & videos) from ' + srcDir + ' to ' + destDir);

// 2. Discover all subfolders in destDir to declare in pubspec.yaml
function getSubdirectories(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const subdirs = entries
    .filter(dirent => dirent.isDirectory())
    .map(dirent => path.join(dir, dirent.name));
  
  let allDirs = [dir];
  subdirs.forEach(s => {
    allDirs = allDirs.concat(getSubdirectories(s));
  });
  return allDirs;
}

const allAssetDirs = getSubdirectories(destDir);
const assetYamlEntries = allAssetDirs.map(d => {
  const rel = path.relative('C:\\\\rohit projects\\\\neurofitadmin', d).replace(/\\\\/g, '/');
  return '    - ' + rel + '/';
});

console.log('Asset paths to register in pubspec.yaml:', assetYamlEntries);

// 3. Update pubspec.yaml
const pubspecPath = 'C:\\\\rohit projects\\\\neurofitadmin\\\\pubspec.yaml';
let pubspec = fs.readFileSync(pubspecPath, 'utf8');

// Replace or insert assets block
const assetsBlock = '  assets:\\n' + assetYamlEntries.join('\\n');

if (pubspec.includes('  assets:')) {
  // Replace existing assets block
  pubspec = pubspec.replace(/  assets:[\\s\\S]*?(?=\\n\\s*#|\\n\\w|$)/, assetsBlock + '\\n');
} else {
  pubspec = pubspec.replace('  uses-material-design: true', '  uses-material-design: true\\n' + assetsBlock);
}

fs.writeFileSync(pubspecPath, pubspec, 'utf8');
console.log('pubspec.yaml updated with all asset folders!');
