import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Linux native automator API availability tests.
///
/// These tests verify that the Linux implementation provides the expected API
/// without throwing compilation errors.
///
/// Note: These tests only run on Linux and verify API availability.
/// Actual functionality requires the linux_automator_service.py running.
void main() {
  group('Linux Native Automator API', () {
    test('NativeAutomatorConfig can be created on Linux', () {
      const config = NativeAutomatorConfig(host: 'localhost', port: '8081');
      expect(config.host, equals('localhost'));
      expect(config.port, equals('8081'));
    });

    test('NativeAutomator can be instantiated on Linux', () {
      if (!io.Platform.isLinux) {
        return;
      }
      const config = NativeAutomatorConfig(host: 'localhost', port: '8081');
      final automator = NativeAutomator(config: config);
      expect(automator, isNotNull);
    });

    test('resolvedAppId returns app name on Linux', () {
      if (!io.Platform.isLinux) {
        return;
      }
      const config = NativeAutomatorConfig(
        host: 'localhost',
        port: '8081',
        packageName: 'test.app',
      );
      final automator = NativeAutomator(config: config);
      // On Linux, it should use the android app name as fallback
      expect(automator.resolvedAppId, isNotEmpty);
    });

    test('Selector can be created on Linux', () {
      final selector = Selector(text: 'Test');
      expect(selector.text, equals('Test'));
    });

    test('Offset is available for tap/swipe operations', () {
      const offset = Offset(0.5, 0.5);
      expect(offset.dx, equals(0.5));
      expect(offset.dy, equals(0.5));
    });

    test('Duration can be used for timeouts', () {
      const timeout = Duration(seconds: 10);
      expect(timeout.inSeconds, equals(10));
    });
  });

  group('Linux Platform Detection', () {
    test('Platform.isLinux returns correct value', () {
      expect(io.Platform.isLinux, isTrue);
    });

    test('Platform.operatingSystem is linux', () {
      expect(io.Platform.operatingSystem, equals('linux'));
    });
  });
}
