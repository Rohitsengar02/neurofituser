const fs = require('fs');
const path = require('path');

const adminLib = 'C:\\\\rohit projects\\\\neurofitadmin\\\\lib';
const servicesDir = path.join(adminLib, 'services');
if (!fs.existsSync(servicesDir)) {
  fs.mkdirSync(servicesDir, { recursive: true });
}

const r2ServiceContent = `import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Cloudflare R2 Storage Configuration & Media Helper for NeuroFit
class R2StorageConfig {
  static const String accountId = '61519b8c6a1a20d3535eb39e85687539';
  static const String apiToken = 'cfat_CUzcTemF5447Ag5mi2gIrcDGYyrMrHSrO9PY6q5Sc69f5185';
  static const String accessKeyId = '83e598b2d02375f5719eb04eaedfc77e';
  static const String secretAccessKey = 'bfd40c9b9f43b4d6f02c7d328465f6f659d85d847dd3a097ec2e20adad9dc79f';
  static const String s3Endpoint = 'https://61519b8c6a1a20d3535eb39e85687539.r2.cloudflarestorage.com';
  static const String publicDevUrl = 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev';
  static const String bucketName = 'neurofit';

  /// Helper to get the absolute public CDN URL for any uploaded asset path
  static String getPublicUrl(String assetKey) {
    if (assetKey.startsWith('http://') || assetKey.startsWith('https://')) {
      return assetKey;
    }
    final cleanKey = assetKey.startsWith('/') ? assetKey.substring(1) : assetKey;
    return '\$publicDevUrl/\$cleanKey';
  }
}
`;

fs.writeFileSync(path.join(servicesDir, 'r2_storage_service.dart'), r2ServiceContent, 'utf8');
console.log('Successfully created R2StorageConfig helper service in lib/services/r2_storage_service.dart!');
