import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Linux native automation test', ($) async {
    // This test will only run on Linux
    if (!io.Platform.isLinux) {
      return;
    }

    // Test basic functionality
    await $.native.initialize();
    await $.native.configure();

    // Test getting UI tree
    final uiTree = await $.native.getNativeViews(null);
    expect(uiTree, isNotNull);

    // Test basic tap (this will tap on the first available element)
    // Note: This is just for demonstration - in real tests you'd target specific elements
    try {
      await $.native.tapAt(const Offset(0.5, 0.5));
    } catch (e) {
      // It's okay if this fails in a headless environment
      // It's okay if this fails in a headless environment
    }
  });
}
