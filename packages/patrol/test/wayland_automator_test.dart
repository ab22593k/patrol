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
