const fs = require('fs');
const path = require('path');

const adminDir = 'C:\\\\rohit projects\\\\neurofitadmin';

// 1. Create assets/videos if missing
const videosDir = path.join(adminDir, 'assets', 'videos');
if (!fs.existsSync(videosDir)) {
  fs.mkdirSync(videosDir, { recursive: true });
}

// 2. Fix pubspec.yaml to only have valid assets
const pubspecContent = `name: neurofitadmin
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.13.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^8.2.1
  fl_chart: ^1.2.0
  intl: ^0.20.3
  shimmer: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
`;

fs.writeFileSync(path.join(adminDir, 'pubspec.yaml'), pubspecContent, 'utf8');

// 3. Fix test/widget_test.dart
const testDart = `import 'package:flutter_test/flutter_test.dart';
import 'package:neurofitadmin/main.dart';

void main() {
  testWidgets('Admin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroFitAdminApp());
    expect(find.text('Dashboard'), findsWidgets);
  });
}
`;

fs.writeFileSync(path.join(adminDir, 'test', 'widget_test.dart'), testDart, 'utf8');
console.log('Fixed pubspec.yaml, created videos dir, and updated widget_test.dart');
