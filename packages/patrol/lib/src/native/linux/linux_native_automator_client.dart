import 'dart:io';
import 'package:patrol/src/native/contracts/contracts.dart';
import 'package:patrol/src/native/contracts/native_automator_client.dart';

/// Linux-specific implementation of NativeAutomatorClient
/// Linux implementation of the NativeAutomatorClient.
///
/// This class provides native automation capabilities for Linux systems using
/// xdotool and other Linux-specific tools.
class LinuxNativeAutomatorClient extends NativeAutomatorClient {
  /// Creates a new LinuxNativeAutomatorClient instance.
  ///
  /// [client] - The underlying client for communication.
  /// [apiUri] - The API URI for the native automator service.
  /// [timeout] - The timeout for operations.
  LinuxNativeAutomatorClient(super.client, super.apiUri, {super.timeout});

  /// Simulates pressing the back button on Linux.
  ///
  /// Linux doesn't have a physical back button, so this maps to Alt+Left key combination.
  @override
  Future<void> pressBack() async {
    // Linux doesn't have a back button - could map to Alt+Left
    await Process.run('xdotool', ['key', 'Alt+Left']);
  }

  /// Simulates pressing the home button on Linux.
  ///
  /// Linux doesn't have a physical home button, so this maps to Super key (Windows key).
  @override
  Future<void> pressHome() async {
    // Map to Super key (Windows/Command key)
    await Process.run('xdotool', ['key', 'Super']);
  }

  /// Simulates pressing the recent apps button on Linux.
  ///
  /// Maps to Alt+Tab key combination to switch between applications.
  @override
  Future<void> pressRecentApps() async {
    // Map to Alt+Tab
    await Process.run('xdotool', ['key', 'Alt+Tab']);
  }

  /// Simulates double pressing the recent apps button on Linux.
  ///
  /// Not directly applicable on Linux, but uses Alt+Tab as closest approximation.
  @override
  Future<void> doublePressRecentApps() async {
    // Not directly applicable on Linux
    await Process.run('xdotool', ['key', 'Alt+Tab']);
  }

  /// Opens an application on Linux using the desktop environment's launcher.
  ///
  /// Uses xdotool to type the application name and press Enter.
  @override
  Future<void> openApp(OpenAppRequest request) async {
    // Use desktop environment's app launcher
    await Process.run('xdotool', ['key', 'Super']); // Open app launcher
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Type app name and press Enter
    await enterText(
      EnterTextRequest(
        data: request.appId,
        appId: '',
        keyboardBehavior: KeyboardBehavior.showAndDismiss,
      ),
    );
    await Process.run('xdotool', ['key', 'Return']);
  }

  /// Opens quick settings on Linux.
  ///
  /// Linux desktop environments don't have quick settings like mobile devices.
  /// This method throws an UnimplementedError.
  @override
  Future<void> openQuickSettings(OpenQuickSettingsRequest request) {
    // Linux desktop environments don't have quick settings like mobile
    // Could implement system tray interaction if needed
    throw UnimplementedError('openQuickSettings is not applicable on Linux');
  }

  /// Opens a URL on Linux using the default web browser.
  ///
  /// Uses xdg-open to open the URL with the system's default browser.
  @override
  Future<void> openUrl(OpenUrlRequest request) async {
    // Use xdg-open to open URLs
    await Process.run('xdg-open', [request.url]);
  }

  /// Simulates pressing the volume up button on Linux.
  ///
  /// Maps to the volume up key if available on the system.
  @override
  Future<void> pressVolumeUp() async {
    // Map to volume up key if available
    await Process.run('xdotool', ['key', 'XF86AudioRaiseVolume']);
  }

  /// Simulates pressing the volume down button on Linux.
  ///
  /// Maps to the volume down key if available on the system.
  @override
  Future<void> pressVolumeDown() async {
    // Map to volume down key if available
    await Process.run('xdotool', ['key', 'XF86AudioLowerVolume']);
  }

  // Network and system settings methods - not typically applicable on Linux
  /// Simulates pressing the airplane mode button on Linux.
  ///
  /// Airplane mode is not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableAirplaneMode() {
    throw UnimplementedError(
      'Airplane mode is not typically used on Linux desktop',
    );
  }

  /// Simulates disabling airplane mode on Linux.
  ///
  /// Airplane mode is not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableAirplaneMode() {
    throw UnimplementedError(
      'Airplane mode is not typically used on Linux desktop',
    );
  }

  /// Simulates enabling WiFi on Linux.
  ///
  /// WiFi control requires system-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableWiFi() {
    // Could use nmcli if NetworkManager is available
    throw UnimplementedError(
      'WiFi control requires system-specific implementation',
    );
  }

  /// Simulates disabling WiFi on Linux.
  ///
  /// WiFi control requires system-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableWiFi() {
    throw UnimplementedError(
      'WiFi control requires system-specific implementation',
    );
  }

  /// Simulates enabling cellular on Linux.
  ///
  /// Cellular is not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableCellular() {
    throw UnimplementedError('Cellular is not typically used on Linux desktop');
  }

  /// Simulates disabling cellular on Linux.
  ///
  /// Cellular is not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableCellular() {
    throw UnimplementedError('Cellular is not typically used on Linux desktop');
  }

  /// Simulates enabling Bluetooth on Linux.
  ///
  /// Bluetooth control requires system-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableBluetooth() {
    throw UnimplementedError(
      'Bluetooth control requires system-specific implementation',
    );
  }

  /// Simulates disabling Bluetooth on Linux.
  ///
  /// Bluetooth control requires system-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableBluetooth() {
    throw UnimplementedError(
      'Bluetooth control requires system-specific implementation',
    );
  }

  /// Simulates enabling dark mode on Linux.
  ///
  /// Dark mode control requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableDarkMode(DarkModeRequest request) {
    throw UnimplementedError(
      'Dark mode control requires desktop environment-specific implementation',
    );
  }

  /// Simulates disabling dark mode on Linux.
  ///
  /// Dark mode control requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableDarkMode(DarkModeRequest request) {
    throw UnimplementedError(
      'Dark mode control requires desktop environment-specific implementation',
    );
  }

  /// Simulates enabling location services on Linux.
  ///
  /// Location services are not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> enableLocation() {
    throw UnimplementedError(
      'Location services are not typically used on Linux desktop',
    );
  }

  /// Simulates disabling location services on Linux.
  ///
  /// Location services are not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> disableLocation() {
    throw UnimplementedError(
      'Location services are not typically used on Linux desktop',
    );
  }

  // Notification methods - desktop-specific implementation needed
  /// Simulates opening notifications on Linux.
  ///
  /// Notification center access requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> openNotifications() {
    throw UnimplementedError(
      'Notification center access requires desktop environment-specific implementation',
    );
  }

  /// Simulates closing notifications on Linux.
  ///
  /// Notification center access requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> closeNotifications() {
    throw UnimplementedError(
      'Notification center access requires desktop environment-specific implementation',
    );
  }

  /// Simulates closing heads-up notifications on Linux.
  ///
  /// Notification center access requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> closeHeadsUpNotification() {
    throw UnimplementedError(
      'Heads-up notifications are not typically used on Linux desktop',
    );
  }

  /// Gets notifications on Linux.
  ///
  /// Notification access requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<GetNotificationsResponse> getNotifications(
    GetNotificationsRequest request,
  ) {
    throw UnimplementedError(
      'Notification access requires desktop environment-specific implementation',
    );
  }

  /// Taps on a notification on Linux.
  ///
  /// Notification interaction requires desktop environment-specific implementation.
  /// This method throws an UnimplementedError.
  @override
  Future<void> tapOnNotification(TapOnNotificationRequest request) {
    throw UnimplementedError(
      'Notification interaction requires desktop environment-specific implementation',
    );
  }

  // Permission methods - not typically applicable on Linux desktop
  /// Checks if a permission dialog is visible on Linux.
  ///
  /// Permission dialogs are not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<PermissionDialogVisibleResponse> isPermissionDialogVisible(
    PermissionDialogVisibleRequest request,
  ) {
    throw UnimplementedError(
      'Gallery access requires desktop-specific implementation',
    );
  }

  // Device info methods
  @override
  Future<IsVirtualDeviceResponse> isVirtualDevice() async {
    // Check if running in a virtual machine
    final result = await Process.run('systemd-detect-virt', []);
    final isVirtual = result.exitCode == 0;
    return IsVirtualDeviceResponse(isVirtualDevice: isVirtual);
  }

  @override
  Future<GetOsVersionResponse> getOsVersion() async {
    final result = await Process.run('uname', ['-r']);
    final version = result.stdout.toString().trim();
    return GetOsVersionResponse(
      osVersion: int.tryParse(version.split('.')[0]) ?? 0,
    );
  }

  // Methods not implemented in base class
  @override
  Future<void> doubleTap(TapRequest request) async {
    // Implement double tap by tapping twice quickly
    await tap(request);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tap(request);
  }

  @override
  Future<void> tapAt(TapAtRequest request) async {
    // Use xdotool to tap at specific coordinates
    final screenResult = await Process.run('xdotool', ['getdisplaygeometry']);
    final screenParts = screenResult.stdout.toString().trim().split(' ');
    final screenWidth = int.parse(screenParts[0]);
    final screenHeight = int.parse(screenParts[1]);

    final x = (request.x * screenWidth).round();
    final y = (request.y * screenHeight).round();

    await Process.run('xdotool', ['mousemove', x.toString(), y.toString()]);
    await Process.run('xdotool', ['click', '1']);
  }

  @override
  Future<GetNativeViewsResponse> getNativeViews(GetNativeViewsRequest request) {
    // This would require more complex implementation to filter by selector
    throw UnimplementedError(
      'getNativeViews requires advanced selector implementation',
    );
  }

  @override
  Future<void> waitUntilVisible(WaitUntilVisibleRequest request) async {
    // Implement polling for visibility
    final startTime = DateTime.now();
    final timeout = Duration(milliseconds: request.timeoutMillis ?? 10000);

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final views = await getNativeViews(
          GetNativeViewsRequest(
            selector: request.selector,
            appId: request.appId,
          ),
        );
        if (views.nativeViews.isNotEmpty) {
          return;
        }
      } catch (e) {
        // Continue polling
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw Exception('Element did not become visible within timeout');
  }

  @override
  Future<void> markPatrolAppServiceReady() async {
    // Not applicable on Linux
  }

  @override
  Future<void> setMockLocation(SetMockLocationRequest request) {
    throw UnimplementedError(
      'Mock location is not applicable on Linux desktop',
    );
  }

  /// Handles permission dialog on Linux.
  ///
  /// Permission dialogs are not typically used on Linux desktop systems.
  /// This method throws an UnimplementedError.
  @override
  Future<void> handlePermissionDialog(HandlePermissionRequest request) {
    throw UnimplementedError(
      'Permission dialogs are not typically used on Linux desktop',
    );
  }
}
