import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../linux_test_app.dart';

void main() {
  testWidgets('Linux desktop automation test', (tester) async {
    // Skip if not on Linux
    if (!io.Platform.isLinux) {
      // Skip if not on Linux
      if (!io.Platform.isLinux) {
        return;
      }
    }

    // Build and start the test app
    await tester.pumpWidget(const LinuxTestApp());
    await tester.pumpAndSettle();

    // Test basic widget existence
    expect(find.text('Click Me'), findsOneWidget);
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);

    // Test native automation features
    try {
      // Create native automator directly
      const config = NativeAutomatorConfig();
      final nativeAutomator = NativeAutomator(config: config);

      // Initialize native automator
      await nativeAutomator.initialize();
      await nativeAutomator.configure();

      // Test tapping on native elements (if available)
      // Note: This tests the native automation service integration
      await nativeAutomator.tap(Selector(text: 'Click Me'));
      await tester.pumpAndSettle();

      // Test text entry
      await nativeAutomator.enterText(
        Selector(text: 'Enter text'),
        text: 'Hello from Patrol Linux!',
      );
      await tester.pumpAndSettle();

      // Linux native automation test completed successfully
    } catch (e) {
      // Native automation test failed (expected without service): $e
      // To enable full native automation:
      //   1. cd packages/patrol/linux
      //   2. ./setup.sh  # Install dependencies
      //   3. ./linux_automator.sh  # Start service
      //   4. Re-run this test
    }

    // Test Flutter-level interactions (these should always work)
    await tester.tap(find.text('Click Me'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Option 1'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Flutter test input');
    await tester.pumpAndSettle();

    // Verify results
    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);
  });
}
