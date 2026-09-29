import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary_flutter/core/api/api_client.dart';
import 'package:diary_flutter/core/database/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_api_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.init(isTest: true);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ApiClient URL Normalization Tests', () {
    test('prepends http:// if missing', () {
      expect(
        ApiClient.normalizeUrl('192.168.1.100:8080'),
        equals('http://192.168.1.100:8080'),
      );
    });

    test('preserves https://', () {
      expect(
        ApiClient.normalizeUrl('https://my-tailnet.ts.net:8080'),
        equals('https://my-tailnet.ts.net:8080'),
      );
    });

    test('trims trailing slashes and whitespace', () {
      expect(
        ApiClient.normalizeUrl('  http://100.64.1.2:8080/  '),
        equals('http://100.64.1.2:8080'),
      );
    });

    test('handles empty input', () {
      expect(ApiClient.normalizeUrl('   '), equals(''));
    });
  });

  group('ApiClient Tailscale Configuration & Failover State Tests', () {
    test('updates primary and Tailscale URLs cleanly in Hive storage', () {
      final client = ApiClient();
      client.updateUrls(
        mainUrl: '192.168.1.50:8080',
        tailscaleUrl: '100.80.90.100:8080',
      );

      expect(client.mainBaseUrl, equals('http://192.168.1.50:8080'));
      expect(client.tailscaleBaseUrl, equals('http://100.80.90.100:8080'));
      expect(client.activeBaseUrl, equals('http://192.168.1.50:8080'));
      expect(client.isTailscaleActive, isFalse);

      expect(HiveBoxes.getServerUrl(), equals('http://192.168.1.50:8080'));
      expect(HiveBoxes.getTailscaleUrl(), equals('http://100.80.90.100:8080'));
    });

    test('checkTailscaleHealth reports error if not configured', () async {
      final client = ApiClient();
      client.updateUrls(mainUrl: 'http://127.0.0.1:8080', tailscaleUrl: '');

      final ok = await client.checkTailscaleHealth();
      expect(ok, isFalse);
      expect(client.lastTailscaleCheckError, contains('not configured'));
    });
  });
}
