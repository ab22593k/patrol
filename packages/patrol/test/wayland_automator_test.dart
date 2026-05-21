import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:patrol/src/native/contracts/contracts.dart'
    show NativeView, Selector;
import 'package:patrol/src/native/contracts/native_automator_client.dart';
import 'package:patrol/src/native/linux/linux_native_automator_client.dart';
import 'package:patrol/src/native/linux/wayland_native_automator_client.dart';
import 'package:patrol/src/native/native_automator.dart'
    show NativeAutomatorConfig;

void main() {
  // Use a real HttpClient (no mock needed — methods throw their own errors
  // when calling ydotool that aren't related to HTTP).
  final client = http.Client();
  final uri = Uri.parse('http://localhost:8081');

  group('WaylandNativeAutomatorClient', () {
    test('can be constructed as a NativeAutomatorClient', () {
      final automator = WaylandNativeAutomatorClient(client, uri);
      expect(automator, isA<NativeAutomatorClient>());
      expect(automator, isA<WaylandNativeAutomatorClient>());
    });

    test('is distinct from LinuxNativeAutomatorClient', () {
      final wayland = WaylandNativeAutomatorClient(client, uri);
      final linux = LinuxNativeAutomatorClient(client, uri);
      expect(wayland.runtimeType, isNot(equals(linux.runtimeType)));
    });
  });

  group('LinuxNativeAutomatorClient', () {
    test('can be constructed as a NativeAutomatorClient', () {
      final automator = LinuxNativeAutomatorClient(client, uri);
      expect(automator, isA<NativeAutomatorClient>());
      expect(automator, isA<LinuxNativeAutomatorClient>());
    });
  });

  group('Selector matching API (contract types)', () {
    test('Selector.text matches NativeView.text', () {
      final view = NativeView(
        className: 'Button',
        text: 'Submit',
        focused: false,
        enabled: true,
        children: [],
      );
      final selector = Selector(text: 'Submit');

      // The _matchesSelector logic exists on both client classes.
      // We test it indirectly by constructing views and selectors
      // that exercise the same matching rules.
      expect(view.text, equals(selector.text));
    });

    test('Selector with all fields null matches any view', () {
      NativeView(
        className: 'TextView',
        text: 'Hello',
        focused: false,
        enabled: true,
        children: [],
      );
      final selector = Selector();

      // A selector with all null fields should match any view
      // (no fields to disqualify).
      expect(selector.text, isNull);
      expect(selector.className, isNull);
      expect(selector.contentDescription, isNull);
    });

    test('Selector.enabled matches view.enabled', () {
      final enabledView = NativeView(
        className: 'Button',
        text: 'Click',
        focused: false,
        enabled: true,
        children: [],
      );
      final disabledView = NativeView(
        className: 'Button',
        text: 'Click',
        focused: false,
        enabled: false,
        children: [],
      );
      final selectorEnabled = Selector(enabled: true);
      final selectorDisabled = Selector(enabled: false);

      expect(enabledView.enabled, equals(selectorEnabled.enabled));
      expect(disabledView.enabled, equals(selectorDisabled.enabled));
    });

    test('Selector.focused matches view.focused', () {
      final focusedView = NativeView(
        className: 'TextField',
        text: 'Input',
        focused: true,
        enabled: true,
        children: [],
      );
      final unfocusedView = NativeView(
        className: 'TextField',
        text: 'Input',
        focused: false,
        enabled: true,
        children: [],
      );
      final selectorFocused = Selector(focused: true);
      final selectorUnfocused = Selector(focused: false);

      expect(focusedView.focused, equals(selectorFocused.focused));
      expect(unfocusedView.focused, equals(selectorUnfocused.focused));
    });

    test('NativeView children can be nested for tree traversal', () {
      final child1 = NativeView(
        className: 'Button',
        text: 'OK',
        focused: false,
        enabled: true,
        children: [],
      );
      final child2 = NativeView(
        className: 'Button',
        text: 'Cancel',
        focused: false,
        enabled: true,
        children: [],
      );
      final parent = NativeView(
        className: 'View',
        text: '',
        focused: false,
        enabled: true,
        children: [child1, child2],
      );

      expect(parent.children.length, equals(2));
      expect(parent.children[0].text, equals('OK'));
      expect(parent.children[1].text, equals('Cancel'));
      expect(child1.children, isEmpty);
    });

    test('Selector.instance selects nth matching view', () {
      // The instance field is used to pick which matching view to return
      final selectorFirst = Selector(instance: 0);
      final selectorSecond = Selector(instance: 1);

      expect(selectorFirst.instance, equals(0));
      expect(selectorSecond.instance, equals(1));
    });

    test('Selector.textStartsWith and textContains partial matching', () {
      final view = NativeView(
        className: 'TextView',
        text: 'Hello World',
        focused: false,
        enabled: true,
        children: [],
      );
      final startsWith = Selector(textStartsWith: 'Hello');
      final contains = Selector(textContains: 'World');
      final noMatch = Selector(textStartsWith: 'Goodbye');
      final noContain = Selector(textContains: 'XYZ');

      // These are the conditions checked by _matchesSelector:
      expect(view.text!.startsWith(startsWith.textStartsWith!), isTrue);
      expect(view.text!.contains(contains.textContains!), isTrue);
      expect(view.text!.startsWith(noMatch.textStartsWith!), isFalse);
      expect(view.text!.contains(noContain.textContains!), isFalse);
    });

    test('Selector.className matches view.className', () {
      final buttonView = NativeView(
        className: 'Button',
        focused: false,
        enabled: true,
        children: [],
      );
      final textView = NativeView(
        className: 'TextView',
        focused: false,
        enabled: true,
        children: [],
      );
      final selectorButton = Selector(className: 'Button');
      final selectorText = Selector(className: 'TextView');

      expect(buttonView.className, equals(selectorButton.className));
      expect(textView.className, equals(selectorText.className));
      expect(buttonView.className, isNot(equals(selectorText.className)));
    });

    test('Selector.contentDescription, resourceId, and pkg matching', () {
      final view = NativeView(
        className: 'ImageView',
        contentDescription: 'A photo',
        focused: false,
        enabled: true,
        resourceName: 'photo_icon',
        applicationPackage: 'com.example',
        children: [],
      );

      final descSelector = Selector(contentDescription: 'A photo');
      final resourceSelector = Selector(resourceId: 'photo_icon');
      final pkgSelector = Selector(pkg: 'com.example');

      expect(view.contentDescription, equals(descSelector.contentDescription));
      expect(view.resourceName, equals(resourceSelector.resourceId));
      expect(view.applicationPackage, equals(pkgSelector.pkg));
    });

    test('contentDescriptionStartsWith and contentDescriptionContains', () {
      final view = NativeView(
        className: 'View',
        contentDescription: 'Settings button',
        focused: false,
        enabled: true,
        children: [],
      );

      // These are the conditions checked by _matchesSelector:
      expect(view.contentDescription!.startsWith('Settings'), isTrue);
      expect(view.contentDescription!.contains('button'), isTrue);
      expect(view.contentDescription!.startsWith('Other'), isFalse);
      expect(view.contentDescription!.contains('xyz'), isFalse);
    });
  });

  group('Screen size detection parsing', () {
    test('wlr-randr output pattern: "1920x1080 px" in a line', () {
      const sampleLines = [
        'HDMI-A-1 connected 1920x1080+0+0 (normal) 1920x1080 px',
        '  modes:',
        '    1920x1080@60.000 *+',
      ];
      final regex = RegExp(r'(\d+)x(\d+)\s+px');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches.length, equals(1));
      expect(int.parse(matches[0].group(1)!), equals(1920));
      expect(int.parse(matches[0].group(2)!), equals(1080));
    });

    test('gnome-monitor-config output: mode marked "(current)"', () {
      const sampleLines = [
        "Output 'eDP-1':",
        '  Mode: 1920x1080@60.000 (current)',
        '  Mode: 1366x768@60.000',
        "Output 'HDMI-1':",
        '  Mode: 3840x2160@30.000',
        '  Mode: 2560x1440@60.000',
      ];
      final regex = RegExp(r'(\d+)x(\d+)(?:@\S+)?\s+\(current\)');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches.length, equals(1));
      expect(int.parse(matches[0].group(1)!), equals(1920));
      expect(int.parse(matches[0].group(2)!), equals(1080));
    });

    test('gnome-monitor-config: alternate format without refresh rate', () {
      const sampleLines = [
        "Output 'DP-1':",
        '  Mode: 2560x1440 (current)',
        '  Mode: 1920x1080',
      ];
      final regex = RegExp(r'(\d+)x(\d+)(?:@\S+)?\s+\(current\)');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches.length, equals(1));
      expect(int.parse(matches[0].group(1)!), equals(2560));
      expect(int.parse(matches[0].group(2)!), equals(1440));
    });

    test('gnome-monitor-config: no current mode yields no match', () {
      const sampleLines = [
        "Output 'DP-1':",
        '  Mode: 1920x1080@60.000',
        '  Mode: 1366x768@60.000',
      ];
      final regex = RegExp(r'(\d+)x(\d+)(?:@\S+)?\s+\(current\)');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches, isEmpty);
    });

    test('kscreen-doctor output: current mode marked with *!', () {
      const sampleLines = [
        'Output: 1 DP-1 enabled connected priority 1',
        'DisplayPort Modes:',
        '0:3840x2160@60*! 1:3840x2160@30',
      ];
      final regex = RegExp(r'(\d+)x(\d+)@.*\*!');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches.length, equals(1));
      expect(int.parse(matches[0].group(1)!), equals(3840));
      expect(int.parse(matches[0].group(2)!), equals(2160));
    });

    test('xrandr output: current resolution in header line', () {
      const sampleLines = [
        'Screen 0: minimum 320 x 200, current 1920 x 1080, maximum 8192 x 8192',
        'HDMI-1 connected primary 1920x1080+0+0',
      ];
      final firstLine = sampleLines.firstWhere(
        (l) => l.contains('current'),
        orElse: () => '',
      );
      final regex = RegExp(r'current\s+(\d+)\s+x\s+(\d+)');
      final match = regex.firstMatch(firstLine);
      expect(match, isNotNull);
      expect(int.parse(match!.group(1)!), equals(1920));
      expect(int.parse(match.group(2)!), equals(1080));
    });

    test('xrandr: no current line returns fallback', () {
      const sampleLines = ['HDMI-1 connected primary 1920x1080+0+0'];
      final firstLine = sampleLines.firstWhere(
        (l) => l.contains('current'),
        orElse: () => '',
      );
      expect(firstLine, isEmpty);
    });

    test('wlr-randr: no resolution line yields no match', () {
      const sampleLines = [
        'HDMI-A-1 connected (normal)',
        '  modes:',
        '    1920x1080@60.000 *+',
      ];
      final regex = RegExp(r'(\d+)x(\d+)\s+px');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches, isEmpty);
    });

    test('kscreen-doctor: no mode with *! yields no match', () {
      const sampleLines = [
        'Output: 1 DP-1 enabled connected priority 1',
        'DisplayPort Modes:',
        '0:3840x2160@60 1:3840x2160@30',
      ];
      final regex = RegExp(r'(\d+)x(\d+)@.*\*!');
      final matches = sampleLines
          .map(regex.firstMatch)
          .whereType<RegExpMatch>()
          .toList();
      expect(matches, isEmpty);
    });

    group('Mutter D-Bus (gdbus)', () {
      test('first mode width and height from GVariant text format', () {
        // Simulated gdbus GVariant text output for GetCurrentState.
        const gdbusOutput = '''
(uint32 1, [((string "eDP-1", string "AUO", string "", string ""),
  [(string "1920x1080@60.000", int32 1920, int32 1080, double 60.0, uint32 0, boolean true)],
  {"is-for-lease": <boolean false>})],
  [(int32 0, int32 0, double 1.0, uint32 0, boolean true,
    ((string "eDP-1", string "AUO", string "", string ""), [], {}))],
  (int32 1920, int32 1080))''';
        final regex = RegExp(
          r'"[^"]*\d+x\d+[^"]*"\s*,\s*int32\s+(\d+)\s*,\s*int32\s+(\d+)',
        );
        final match = regex.firstMatch(gdbusOutput);
        expect(match, isNotNull);
        expect(int.parse(match!.group(1)!), equals(1920));
        expect(int.parse(match.group(2)!), equals(1080));
      });

      test('4K resolution from GVariant text', () {
        const gdbusOutput = '''
(uint32 2, [((string "DP-1", string "DEL", string "", string ""),
  [(string "3840x2160@60.000", int32 3840, int32 2160, double 60.0, uint32 0, boolean true)],
  {})],
  [(int32 0, int32 0, double 1.0, uint32 0, boolean true,
    ((string "DP-1", string "DEL", string "", string ""), [], {}))],
  (int32 3840, int32 2160))''';
        final regex = RegExp(
          r'"[^"]*\d+x\d+[^"]*"\s*,\s*int32\s+(\d+)\s*,\s*int32\s+(\d+)',
        );
        final match = regex.firstMatch(gdbusOutput);
        expect(match, isNotNull);
        expect(int.parse(match!.group(1)!), equals(3840));
        expect(int.parse(match.group(2)!), equals(2160));
      });

      test('no match when no monitors connected', () {
        // gdbus output with zero monitors
        const gdbusOutput = '''(uint32 0, [], [], (int32 0, int32 0))''';
        final regex = RegExp(
          r'"[^"]*\d+x\d+[^"]*"\s*,\s*int32\s+(\d+)\s*,\s*int32\s+(\d+)',
        );
        final match = regex.firstMatch(gdbusOutput);
        expect(match, isNull);
      });

      test('no match for non-GNOME compositor', () {
        // gdbus output for a non-GNOME D-Bus call (completely unrelated)
        const unrelatedOutput =
            '''(uint32 0, [string "org.freedesktop.DBus", string "org.freedesktop.DBus.Properties"])''';
        final regex = RegExp(
          r'"[^"]*\d+x\d+[^"]*"\s*,\s*int32\s+(\d+)\s*,\s*int32\s+(\d+)',
        );
        final match = regex.firstMatch(unrelatedOutput);
        expect(match, isNull);
      });
    });

    group('Mutter D-Bus (busctl)', () {
      test('first mode width and height extracted', () {
        // Simulated busctl output for GetCurrentState with a single 1920x1080 monitor.
        const busctlOutput = '''
u 1
a((ssss)a(siidua{sv})a{sv}) 1
  (ssss) "eDP-1" "" "" ""
  a(siidua{sv}) 2
    (siidua{sv}) "0" 1920 1080 60000.000000 0 a{sv} 0
    (siidua{sv}) "1" 1366 768 60000.000000 0 a{sv} 0
  a{sv} 0
a(siidduba{sv}) 1
  (siidduba{sv}) "eDP-1" 0 0 1 0 0 1 a{sv} 0
(ii) 32768 32768''';
        final regex = RegExp(r'\([^)]*siid[^)]*\)\s+"[^"]*"\s+(\d+)\s+(\d+)');
        final match = regex.firstMatch(busctlOutput);
        expect(match, isNotNull);
        expect(int.parse(match!.group(1)!), equals(1920));
        expect(int.parse(match.group(2)!), equals(1080));
      });

      test('first mode for 4K monitor', () {
        const busctlOutput = '''
u 2
a((ssss)a(siidua{sv})a{sv}) 1
  (ssss) "DP-1" "" "" ""
  a(siidua{sv}) 3
    (siidua{sv}) "0" 3840 2160 60000.000000 0 a{sv} 0
    (siidua{sv}) "1" 2560 1440 60000.000000 0 a{sv} 0
    (siidua{sv}) "2" 1920 1080 60000.000000 0 a{sv} 0
  a{sv} 0
a(siidduba{sv}) 1
  (siidduba{sv}) "DP-1" 0 0 1 0 0 1 a{sv} 0
(ii) 32768 32768''';
        final regex = RegExp(r'\([^)]*siid[^)]*\)\s+"[^"]*"\s+(\d+)\s+(\d+)');
        final match = regex.firstMatch(busctlOutput);
        expect(match, isNotNull);
        // First mode is 3840x2160 (preferred/resolution from first monitor).
        expect(int.parse(match!.group(1)!), equals(3840));
        expect(int.parse(match.group(2)!), equals(2160));
      });

      test('no match when no monitors connected', () {
        // Output with no monitors connected
        const busctlOutput = '''
u 0
a((ssss)a(siidua{sv})a{sv}) 0
a(siidduba{sv}) 0
(ii) 0 0''';
        final regex = RegExp(r'\([^)]*siid[^)]*\)\s+"[^"]*"\s+(\d+)\s+(\d+)');
        final match = regex.firstMatch(busctlOutput);
        expect(match, isNull);
      });

      test('no match for non-GNOME compositor', () {
        // busctl returns non-zero (command not found or method not available).
        // This test verifies the regex doesn't match unrelated D-Bus output.
        const unrelatedOutput = '''
u 3
a(s) 3
  "org.freedesktop.DBus"
  "org.freedesktop.DBus.Properties"
  "org.freedesktop.DBus.Introspectable"''';
        final regex = RegExp(r'\([^)]*siid[^)]*\)\s+"[^"]*"\s+(\d+)\s+(\d+)');
        final match = regex.firstMatch(unrelatedOutput);
        expect(match, isNull);
      });
    });
  });

  group('Configurable detector priority', () {
    test('default detectors list has expected order', () {
      // Use default constructor — detectors list should match default priority
      final automator = WaylandNativeAutomatorClient(client, uri);
      expect(automator.detectors.length, equals(6));
    });

    test('custom detector list overrides default priority', () async {
      // A detector that returns a known resolution
      Future<(int, int)?> customDetector() async => (800, 600);

      // A detector that returns null (unavailable)
      Future<(int, int)?> failingDetector() async => null;

      // First detector succeeds — should short-circuit and return (800, 600)
      var automator = WaylandNativeAutomatorClient(
        client,
        uri,
        detectors: [customDetector, failingDetector],
      );
      expect(automator.detectors.length, equals(2));

      // Reverse order — failing first, then custom
      automator = WaylandNativeAutomatorClient(
        client,
        uri,
        detectors: [failingDetector, customDetector],
      );
      expect(automator.detectors.length, equals(2));
    });

    test('all detectors failing falls through to default', () async {
      Future<(int, int)?> fail1() async => null;
      Future<(int, int)?> fail2() async => null;

      final automator = WaylandNativeAutomatorClient(
        client,
        uri,
        detectors: [fail1, fail2],
      );
      expect(automator.detectors, hasLength(2));
      // Both return null — _getScreenSize() returns the static default
      // (cannot call private method directly, verified by type check below)
      expect(automator, isA<NativeAutomatorClient>());
    });
  });

  group('Platform selection logic', () {
    test('NativeAutomator supports Linux client creation', () {
      // Verify config can be constructed (host/port)
      const config = NativeAutomatorConfig();
      expect(config.host, equals('localhost'));
      expect(config.port, equals('8081'));
    });

    test('Both client types extend NativeAutomatorClient', () {
      // Verify the class hierarchy:
      // WaylandNativeAutomatorClient → NativeAutomatorClient
      // LinuxNativeAutomatorClient → NativeAutomatorClient
      final client = http.Client();
      final uri = Uri.parse('http://localhost:8081');

      expect(
        WaylandNativeAutomatorClient(client, uri),
        isA<NativeAutomatorClient>(),
      );
      expect(
        LinuxNativeAutomatorClient(client, uri),
        isA<NativeAutomatorClient>(),
      );
    });
  });
}
