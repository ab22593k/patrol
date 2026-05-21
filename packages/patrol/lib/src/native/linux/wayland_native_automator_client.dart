import 'dart:io';

import 'package:patrol/src/native/contracts/contracts.dart';
import 'package:patrol/src/native/contracts/native_automator_client.dart';

/// Signature for a screen-size detection strategy.
///
/// Runs a command and parses its output to extract the current
/// screen resolution. Returns `(width, height)` on success or `null`
/// if the method is unavailable or parsing fails.
typedef _ScreenSizeDetector = Future<(int, int)?> Function();

/// Linux evdev keycodes for ydotool compatibility.
///
/// Source: /usr/include/linux/input-event-codes.h
/// Full reference: packages/patrol/linux/KEYCODES.md
class _YdotoolKeys {
  static const enter = 28;
  static const meta = 125; // Super / Windows key
  static const tab = 15;
  static const alt = 56;
  static const left = 105;
  static const volumeUp = 115; // XF86AudioRaiseVolume
  static const volumeDown = 114; // XF86AudioLowerVolume
}

/// Wayland-compatible implementation of [NativeAutomatorClient] using ydotool.
///
/// ydotool uses the Linux kernel's uinput framework to inject input events at
/// the kernel level, which works on any Wayland compositor (and X11, TTY).
///
/// Keycode reference: packages/patrol/linux/KEYCODES.md
class WaylandNativeAutomatorClient extends NativeAutomatorClient {
  /// Creates a new WaylandNativeAutomatorClient instance.
  ///
  /// Optionally pass a custom [detectors] list to override the default
  /// priority order of screen-size detection strategies.
  WaylandNativeAutomatorClient(
    super.client,
    super.apiUri, {
    super.timeout,
    List<_ScreenSizeDetector>? detectors,
  }) : detectors = detectors ?? _defaultDetectors;
  static const _defaultScreenWidth = 1920;
  static const _defaultScreenHeight = 1080;

  /// Default priority-ordered list of screen-size detectors.
  ///
  /// To change priority, reorder this list. To add a strategy, write a
  /// `static _try*` method and add it here. To use a custom set for a
  /// particular instance, pass a list to [detectors] in the constructor.
  static final _defaultDetectors = <_ScreenSizeDetector>[
    _tryWlrRandr,
    _tryGnomeMonitorConfig,
    _tryMutterDBus,
    _tryGDBus,
    _tryKscreenDoctor,
    _tryXrandr,
  ];

  /// The priority-ordered list of detectors for this instance.
  ///
  /// Override this by constructing with a custom list, or rely on
  /// [_defaultDetectors] for the default priority.
  final List<_ScreenSizeDetector> detectors;

  /// Attempts to detect screen dimensions for converting relative coordinates.
  ///
  /// Tries each strategy in [detectors] priority order.
  /// Falls back to 1920×1080 if all return `null`.
  Future<(int, int)> _getScreenSize() async {
    for (final detect in detectors) {
      final result = await detect();
      if (result != null) return result;
    }
    return (_defaultScreenWidth, _defaultScreenHeight);
  }

  /// Detect via `wlr-randr` (wlroots compositors: Sway, Hyprland, …).
  ///
  /// Parses lines like: `HDMI-A-1 … 1920x1080 px`
  static Future<(int, int)?> _tryWlrRandr() async {
    try {
      final result = await Process.run(
        'wlr-randr',
        [],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        for (final line in output.split('\n')) {
          final match = RegExp(r'(\d+)x(\d+)\s+px').firstMatch(line);
          if (match != null) {
            return (int.parse(match.group(1)!), int.parse(match.group(2)!));
          }
        }
      }
    } catch (_) {
      // Not available or not a wlroots compositor
    }
    return null;
  }

  /// Detect via `gnome-monitor-config list` (GNOME Wayland).
  ///
  /// Parses lines like: `Mode: 1920x1080@60.000 (current)`
  static Future<(int, int)?> _tryGnomeMonitorConfig() async {
    try {
      final result = await Process.run(
        'gnome-monitor-config',
        ['list'],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        for (final line in output.split('\n')) {
          final match = RegExp(
            r'(\d+)x(\d+)(?:@\S+)?\s+\(current\)',
          ).firstMatch(line);
          if (match != null) {
            return (int.parse(match.group(1)!), int.parse(match.group(2)!));
          }
        }
      }
    } catch (_) {
      // Not available or not GNOME
    }
    return null;
  }

  /// Detect via `kscreen-doctor --outputs` (KDE Plasma Wayland).
  ///
  /// Parses lines like: `0:3840x2160@60*!` (current mode marked with `*!`)
  static Future<(int, int)?> _tryKscreenDoctor() async {
    try {
      final result = await Process.run(
        'kscreen-doctor',
        ['--outputs'],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        for (final line in output.split('\n')) {
          final match = RegExp(r'(\d+)x(\d+)@.*\*!').firstMatch(line);
          if (match != null) {
            return (int.parse(match.group(1)!), int.parse(match.group(2)!));
          }
        }
      }
    } catch (_) {
      // Not available or not KDE
    }
    return null;
  }

  /// Detect via `busctl` D-Bus call to Mutter DisplayConfig (GNOME Wayland).
  ///
  /// Fallback when `gnome-monitor-config` is not installed. Uses the Mutter
  /// D-Bus API directly to query the first physical monitor's first mode.
  ///
  /// busctl output for the mode tuple looks like:
  /// `(siidua{sv}) "0" 1920 1080 60000.000000 0 a{sv} 0`
  static Future<(int, int)?> _tryMutterDBus() async {
    try {
      final result = await Process.run(
        'busctl',
        [
          '--user',
          'call',
          'org.gnome.Mutter.DisplayConfig',
          '/org/gnome/Mutter/DisplayConfig',
          'org.gnome.Mutter.DisplayConfig',
          'GetCurrentState',
        ],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        // Match the first mode tuple containing "siid" (string, int, int, double).
        // Captures width and height from: (siidua{sv}) "0" 1920 1080 ...
        final match = RegExp(
          r'\([^)]*siid[^)]*\)\s+"[^"]*"\s+(\d+)\s+(\d+)',
        ).firstMatch(output);
        if (match != null) {
          return (int.parse(match.group(1)!), int.parse(match.group(2)!));
        }
      }
    } catch (_) {
      // Not connected to GNOME session bus or not GNOME Wayland
    }
    return null;
  }

  /// Detect via `gdbus` GVariant call to Mutter DisplayConfig (GNOME Wayland).
  ///
  /// Fallback when `gnome-monitor-config` is not installed and `busctl` is
  /// unavailable (e.g., on systems without systemd). `gdbus` is provided by
  /// GLib and is available on all GNOME systems.
  ///
  /// Parses the first mode tuple in GVariant text format:
  /// `("1920x1080@60.000", int32 1920, int32 1080, double 60.0, uint32 0, boolean true)`
  static Future<(int, int)?> _tryGDBus() async {
    try {
      final result = await Process.run(
        'gdbus',
        [
          'call',
          '--session',
          '--dest=org.gnome.Mutter.DisplayConfig',
          '--object-path=/org/gnome/Mutter/DisplayConfig',
          '--method=org.gnome.Mutter.DisplayConfig.GetCurrentState',
        ],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        // Match the first mode tuple containing width/height after a mode string.
        // GVariant text: ("1920x1080@60.000", int32 1920, int32 1080, ...)
        final match = RegExp(
          r'"[^"]*\d+x\d+[^"]*"\s*,\s*int32\s+(\d+)\s*,\s*int32\s+(\d+)',
        ).firstMatch(output);
        if (match != null) {
          return (int.parse(match.group(1)!), int.parse(match.group(2)!));
        }
      }
    } catch (_) {
      // gdbus not available or not GNOME Wayland
    }
    return null;
  }

  /// Detect via `xrandr --current` (XWayland fallback).
  ///
  /// Parses the header line: `Screen 0: … current 1920 x 1080 …`
  static Future<(int, int)?> _tryXrandr() async {
    try {
      final result = await Process.run(
        'xrandr',
        ['--current'],
        stdoutEncoding: null,
        stderrEncoding: null,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as List<int>)
            .map(String.fromCharCode)
            .join();
        final firstLine = output
            .split('\n')
            .firstWhere((l) => l.contains('current'), orElse: () => '');
        final match = RegExp(
          r'current\s+(\d+)\s+x\s+(\d+)',
        ).firstMatch(firstLine);
        if (match != null) {
          return (int.parse(match.group(1)!), int.parse(match.group(2)!));
        }
      }
    } catch (_) {
      // XWayland not available
    }
    return null;
  }

  /// Run ydotool with the given arguments.
  Future<void> _ydotool(List<String> args) async {
    final result = await Process.run('ydotool', args);
    if (result.exitCode != 0) {
      throw Exception(
        'ydotool failed (exit ${result.exitCode}): ${result.stderr}',
      );
    }
  }

  /// Press a single key by evdev keycode.
  Future<void> _ydotoolKeyPress(int keycode) async {
    await _ydotool(['key', keycode.toString()]);
  }

  /// Press a key combination (e.g. Alt+Left).
  ///
  /// Sends press events for all keys, then release events in reverse order.
  Future<void> _ydotoolKeyCombo(List<int> keycodes) async {
    final args = <String>['key'];
    for (final code in keycodes) {
      args.add('$code:1');
    }
    for (final code in keycodes.reversed) {
      args.add('$code:0');
    }
    await _ydotool(args);
  }

  // ---------------------------------------------------------------------------
  // Overrides — input methods via ydotool
  // ---------------------------------------------------------------------------

  @override
  Future<void> pressBack() async {
    // Alt+Left → key 56:1 105:1 105:0 56:0
    await _ydotoolKeyCombo([_YdotoolKeys.alt, _YdotoolKeys.left]);
  }

  @override
  Future<void> pressHome() async {
    // Super key
    await _ydotoolKeyPress(_YdotoolKeys.meta);
  }

  @override
  Future<void> pressRecentApps() async {
    // Alt+Tab
    await _ydotoolKeyCombo([_YdotoolKeys.alt, _YdotoolKeys.tab]);
  }

  @override
  Future<void> doublePressRecentApps() async {
    await pressRecentApps();
  }

  @override
  Future<void> openApp(OpenAppRequest request) async {
    // Open app launcher with Super key
    await _ydotoolKeyPress(_YdotoolKeys.meta);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Type app name via ydotool directly
    await _ydotool(['type', request.appId]);

    // Press Enter
    await _ydotoolKeyPress(_YdotoolKeys.enter);
  }

  @override
  Future<void> pressVolumeUp() async {
    await _ydotoolKeyPress(_YdotoolKeys.volumeUp);
  }

  @override
  Future<void> pressVolumeDown() async {
    await _ydotoolKeyPress(_YdotoolKeys.volumeDown);
  }

  @override
  Future<void> enterText(EnterTextRequest request) async {
    await _ydotool(['type', request.data]);
  }

  @override
  Future<void> tapAt(TapAtRequest request) async {
    final (screenWidth, screenHeight) = await _getScreenSize();
    final x = (request.x * screenWidth).round();
    final y = (request.y * screenHeight).round();

    await _ydotool(['mousemove', x.toString(), y.toString()]);
    await _ydotool(['click', '1']);
  }

  @override
  Future<void> doubleTap(TapRequest request) async {
    await tap(request); // HTTP → Python service
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tap(request);
  }

  @override
  Future<void> swipe(SwipeRequest request) async {
    final (screenWidth, screenHeight) = await _getScreenSize();
    final startX = (request.startX * screenWidth).round();
    final startY = (request.startY * screenHeight).round();
    final endX = (request.endX * screenWidth).round();
    final endY = (request.endY * screenHeight).round();

    await _ydotool(['mousemove', startX.toString(), startY.toString()]);
    await _ydotool(['mousedown', '1']);

    // Move in steps for smooth gesture
    final steps = request.steps;
    for (var i = 1; i <= steps; i++) {
      final progress = i / steps;
      final currX = (startX + (endX - startX) * progress).round();
      final currY = (startY + (endY - startY) * progress).round();
      await _ydotool(['mousemove', currX.toString(), currY.toString()]);
    }

    await _ydotool(['mouseup', '1']);
  }

  // ---------------------------------------------------------------------------
  // Overrides — UI tree via HTTP (same pattern as LinuxNativeAutomatorClient)
  // ---------------------------------------------------------------------------

  bool _matchesSelector(NativeView view, Selector selector) {
    if (selector.text != null && view.text != selector.text) return false;
    if (selector.textStartsWith != null &&
        (view.text == null ||
            !view.text!.startsWith(selector.textStartsWith!))) {
      return false;
    }
    if (selector.textContains != null &&
        (view.text == null || !view.text!.contains(selector.textContains!))) {
      return false;
    }
    if (selector.className != null && view.className != selector.className) {
      return false;
    }
    if (selector.contentDescription != null &&
        view.contentDescription != selector.contentDescription) {
      return false;
    }
    if (selector.contentDescriptionStartsWith != null &&
        (view.contentDescription == null ||
            !view.contentDescription!.startsWith(
              selector.contentDescriptionStartsWith!,
            ))) {
      return false;
    }
    if (selector.contentDescriptionContains != null &&
        (view.contentDescription == null ||
            !view.contentDescription!.contains(
              selector.contentDescriptionContains!,
            ))) {
      return false;
    }
    if (selector.resourceId != null &&
        view.resourceName != selector.resourceId) {
      return false;
    }
    if (selector.enabled != null && view.enabled != selector.enabled) {
      return false;
    }
    if (selector.focused != null && view.focused != selector.focused) {
      return false;
    }
    if (selector.pkg != null && view.applicationPackage != selector.pkg) {
      return false;
    }
    return true;
  }

  List<NativeView> _findMatchingViews(
    List<NativeView> views,
    Selector selector,
  ) {
    final result = <NativeView>[];
    for (final view in views) {
      if (_matchesSelector(view, selector)) {
        result.add(view);
      }
      result.addAll(_findMatchingViews(view.children, selector));
    }
    return result;
  }

  int _countMatchingViews(List<NativeView> views, Selector selector) {
    var count = 0;
    for (final view in views) {
      if (_matchesSelector(view, selector)) {
        count++;
      }
      count += _countMatchingViews(view.children, selector);
    }
    return count;
  }

  @override
  Future<GetNativeViewsResponse> getNativeViews(
    GetNativeViewsRequest request,
  ) async {
    final selector = request.selector;
    if (selector == null) {
      final tree = await getNativeUITree(
        GetNativeUITreeRequest(useNativeViewHierarchy: true),
      );
      return GetNativeViewsResponse(
        nativeViews: tree.roots,
        iosNativeViews: [],
        androidNativeViews: [],
      );
    }

    final tree = await getNativeUITree(
      GetNativeUITreeRequest(useNativeViewHierarchy: true),
    );

    final allMatching = _findMatchingViews(tree.roots, selector);
    final instance = selector.instance;
    final matchingViews = instance != null
        ? (allMatching.length > instance
              ? [allMatching[instance]]
              : <NativeView>[])
        : allMatching;

    return GetNativeViewsResponse(
      nativeViews: matchingViews,
      iosNativeViews: [],
      androidNativeViews: [],
    );
  }

  @override
  Future<void> waitUntilVisible(WaitUntilVisibleRequest request) async {
    final selector = request.selector;
    if (selector == null) {
      throw Exception('waitUntilVisible requires a non-null selector');
    }

    final startTime = DateTime.now();
    final timeout = Duration(milliseconds: request.timeoutMillis ?? 10000);

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final tree = await getNativeUITree(
          GetNativeUITreeRequest(useNativeViewHierarchy: true),
        );

        final matchingCount = _countMatchingViews(tree.roots, selector);
        final requiredCount = (selector.instance ?? 0) + 1;

        if (matchingCount >= requiredCount) {
          return;
        }
      } catch (_) {
        // Continue polling on transient errors
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw Exception('Element did not become visible within timeout');
  }

  // ---------------------------------------------------------------------------
  // Overrides — initialization / lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    // Ensure ydotoold is running before any input operations
    try {
      final pgrep = await Process.run('pgrep', ['-x', 'ydotoold']);
      if (pgrep.exitCode != 0) {
        stderr.writeln('Patrol (Linux): ydotoold not running — starting it...');
        Process.run('ydotoold', [], runInShell: true);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {
      stderr.writeln(
        'Patrol (Linux): Could not start ydotoold — '
        'install ydotool or check udev rules',
      );
    }

    stderr.writeln(
      'Patrol (Linux): WaylandNativeAutomatorClient active '
      '(ydotool via uinput)',
    );
    stderr.writeln(
      'Patrol (Linux): Ensure linux_automator_service.py is running on port 8081',
    );
  }

  @override
  Future<void> configure(ConfigureRequest request) async {
    stderr.writeln(
      'Patrol (Linux): configure called with timeout ${request.findTimeoutMillis}ms',
    );
  }

  @override
  Future<void> debug() async {
    stderr.writeln(
      'Patrol (Linux): Debug mode - Wayland native automator is active',
    );
  }

  @override
  Future<void> markPatrolAppServiceReady() async {
    // Not applicable on Linux
  }

  // ---------------------------------------------------------------------------
  // Overrides — no-ops (same as LinuxNativeAutomatorClient)
  // ---------------------------------------------------------------------------

  @override
  Future<void> openQuickSettings(OpenQuickSettingsRequest request) async {
    stderr.writeln(
      'Patrol (Linux): openQuickSettings is not applicable on Linux desktop',
    );
  }

  @override
  Future<void> openUrl(OpenUrlRequest request) async {
    await Process.run('xdg-open', [request.url]);
  }

  @override
  Future<void> enableAirplaneMode() async {
    stderr.writeln(
      'Patrol (Linux): Airplane mode is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> disableAirplaneMode() async {
    stderr.writeln(
      'Patrol (Linux): Airplane mode is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> enableWiFi() async {
    stderr.writeln(
      'Patrol (Linux): WiFi control requires system-specific implementation',
    );
  }

  @override
  Future<void> disableWiFi() async {
    stderr.writeln(
      'Patrol (Linux): WiFi control requires system-specific implementation',
    );
  }

  @override
  Future<void> enableCellular() async {
    stderr.writeln(
      'Patrol (Linux): Cellular is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> disableCellular() async {
    stderr.writeln(
      'Patrol (Linux): Cellular is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> enableBluetooth() async {
    stderr.writeln(
      'Patrol (Linux): Bluetooth control requires system-specific implementation',
    );
  }

  @override
  Future<void> disableBluetooth() async {
    stderr.writeln(
      'Patrol (Linux): Bluetooth control requires system-specific implementation',
    );
  }

  @override
  Future<void> enableDarkMode(DarkModeRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Dark mode control requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> disableDarkMode(DarkModeRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Dark mode control requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> enableLocation() async {
    stderr.writeln(
      'Patrol (Linux): Location services are not typically used on Linux desktop',
    );
  }

  @override
  Future<void> disableLocation() async {
    stderr.writeln(
      'Patrol (Linux): Location services are not typically used on Linux desktop',
    );
  }

  @override
  Future<void> openNotifications() async {
    stderr.writeln(
      'Patrol (Linux): Notification center access requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> closeNotifications() async {
    stderr.writeln(
      'Patrol (Linux): Notification center access requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> closeHeadsUpNotification() async {
    stderr.writeln(
      'Patrol (Linux): Heads-up notifications are not typically used on Linux desktop',
    );
  }

  @override
  Future<GetNotificationsResponse> getNotifications(
    GetNotificationsRequest request,
  ) async {
    stderr.writeln(
      'Patrol (Linux): Notification access requires desktop environment-specific implementation',
    );
    return GetNotificationsResponse(notifications: []);
  }

  @override
  Future<void> tapOnNotification(TapOnNotificationRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Notification interaction requires desktop environment-specific implementation',
    );
  }

  @override
  Future<PermissionDialogVisibleResponse> isPermissionDialogVisible(
    PermissionDialogVisibleRequest request,
  ) async {
    return PermissionDialogVisibleResponse(visible: false);
  }

  @override
  Future<void> handlePermissionDialog(HandlePermissionRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Permission dialogs are handled differently on Linux desktop',
    );
  }

  @override
  Future<IsVirtualDeviceResponse> isVirtualDevice() async {
    final result = await Process.run('systemd-detect-virt', []);
    return IsVirtualDeviceResponse(isVirtualDevice: result.exitCode == 0);
  }

  @override
  Future<GetOsVersionResponse> getOsVersion() async {
    final result = await Process.run('uname', ['-r']);
    final version = result.stdout.toString().trim();
    return GetOsVersionResponse(
      osVersion: int.tryParse(version.split('.')[0]) ?? 0,
    );
  }

  @override
  Future<void> setMockLocation(SetMockLocationRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Mock location is not applicable on Linux desktop',
    );
  }

  @override
  Future<void> setLocationAccuracy(SetLocationAccuracyRequest request) async {
    stderr.writeln(
      'Patrol (Linux): Location accuracy is not applicable on Linux desktop',
    );
  }

  @override
  Future<void> takeCameraPhoto(TakeCameraPhotoRequest request) async {
    stderr.writeln(
      'Patrol (Linux): takeCameraPhoto requires desktop-specific implementation',
    );
  }

  @override
  Future<void> pickImageFromGallery(PickImageFromGalleryRequest request) async {
    stderr.writeln(
      'Patrol (Linux): pickImageFromGallery requires desktop-specific implementation',
    );
  }

  @override
  Future<void> pickMultipleImagesFromGallery(
    PickMultipleImagesFromGalleryRequest request,
  ) async {
    stderr.writeln(
      'Patrol (Linux): pickMultipleImagesFromGallery requires desktop-specific implementation',
    );
  }
}
