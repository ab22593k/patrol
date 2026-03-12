import 'dart:io';
// The following ignores are required because the contract classes are generated
// and might not be fully compatible with the current analyzer settings.
// ignore_for_file: undefined_method, undefined_identifier, non_type_as_type_argument, missing_required_argument

import 'package:http/http.dart' as http;
import 'package:patrol/src/native/contracts/contracts.dart';
import 'package:patrol/src/native/contracts/native_automator_client.dart';

/// Linux-specific implementation of NativeAutomatorClient
class LinuxNativeAutomatorClient extends NativeAutomatorClient {
  LinuxNativeAutomatorClient(super.client, super.baseUri, {super.timeout});

  @override
  Future<void> initialize() async {
    await makeRequest(() => client.post(Uri.parse('$baseUri/initialize')));
  }

  @override
  Future<void> configure(ConfigureRequest request) async {
    await makeRequest(
      () => client.post(
        Uri.parse('$baseUri/configure'),
        body: toJsonString(request),
      ),
    );
  }

  @override
  Future<GetNativeUITreeResponse> getNativeUITree(
    GetNativeUITreeRequest request,
  ) async {
    final response = await makeRequest(
      () => client.post(
        Uri.parse('$baseUri/getNativeUITree'),
        body: toJsonString(request),
      ),
    );

    return GetNativeUITreeResponse.fromJson(response.body);
  }

  @override
  Future<void> tap(TapRequest request) async {
    await makeRequest(
      () => client.post(Uri.parse('$baseUri/tap'), body: toJsonString(request)),
    );
  }

  @override
  Future<void> enterText(EnterTextRequest request) async {
    await makeRequest(
      () => client.post(
        Uri.parse('$baseUri/enterText'),
        body: toJsonString(request),
      ),
    );
  }

  @override
  Future<void> swipe(SwipeRequest request) async {
    await makeRequest(
      () =>
          client.post(Uri.parse('$baseUri/swipe'), body: toJsonString(request)),
    );
  }

  // Linux-specific methods not in the base interface
  Future<void> pressKey(String key) async {
    await makeRequest(
      () =>
          client.post(Uri.parse('$baseUri/pressKey'), body: '{"key": "$key"}'),
    );
  }

  // Override methods that are not applicable to Linux
  @override
  Future<void> pressBack() async {
    // Linux doesn't have a back button - could map to Alt+Left
    await pressKey('Alt+Left');
  }

  @override
  Future<void> pressHome() async {
    // Map to Super key (Windows/Command key)
    await pressKey('Super');
  }

  @override
  Future<void> pressRecentApps() async {
    // Map to Alt+Tab
    await pressKey('Alt+Tab');
  }

  @override
  Future<void> doublePressRecentApps() async {
    // Not directly applicable on Linux
    await pressKey('Alt+Tab');
  }

  @override
  Future<void> openApp(OpenAppRequest request) async {
    // Use desktop environment's app launcher
    await pressKey('Super'); // Open app launcher
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Type app name and press Enter
    await enterText(EnterTextRequest(data: request.appId));
    await pressKey('Return');
  }

  @override
  Future<void> openQuickSettings(OpenQuickSettingsRequest request) {
    // Linux desktop environments don't have quick settings like mobile
    // Could implement system tray interaction if needed
    throw UnimplementedError('openQuickSettings is not applicable on Linux');
  }

  @override
  Future<void> openUrl(OpenUrlRequest request) async {
    // Use xdg-open to open URLs
    await Process.run('xdg-open', [request.url]);
  }

  @override
  Future<void> pressVolumeUp() async {
    // Map to volume up key if available
    await pressKey('XF86AudioRaiseVolume');
  }

  @override
  Future<void> pressVolumeDown() async {
    // Map to volume down key if available
    await pressKey('XF86AudioLowerVolume');
  }

  // Network and system settings methods - not typically applicable on Linux
  @override
  Future<void> enableAirplaneMode() {
    throw UnimplementedError(
      'Airplane mode is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> disableAirplaneMode() {
    throw UnimplementedError(
      'Airplane mode is not typically used on Linux desktop',
    );
  }

  @override
  Future<void> enableWiFi() {
    // Could use nmcli if NetworkManager is available
    throw UnimplementedError(
      'WiFi control requires system-specific implementation',
    );
  }

  @override
  Future<void> disableWiFi() {
    throw UnimplementedError(
      'WiFi control requires system-specific implementation',
    );
  }

  @override
  Future<void> enableCellular() {
    throw UnimplementedError('Cellular is not typically used on Linux desktop');
  }

  @override
  Future<void> disableCellular() {
    throw UnimplementedError('Cellular is not typically used on Linux desktop');
  }

  @override
  Future<void> enableBluetooth() {
    throw UnimplementedError(
      'Bluetooth control requires system-specific implementation',
    );
  }

  @override
  Future<void> disableBluetooth() {
    throw UnimplementedError(
      'Bluetooth control requires system-specific implementation',
    );
  }

  @override
  Future<void> enableDarkMode(DarkModeRequest request) {
    throw UnimplementedError(
      'Dark mode control requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> disableDarkMode(DarkModeRequest request) {
    throw UnimplementedError(
      'Dark mode control requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> enableLocation() {
    throw UnimplementedError(
      'Location services are not typically used on Linux desktop',
    );
  }

  @override
  Future<void> disableLocation() {
    throw UnimplementedError(
      'Location services are not typically used on Linux desktop',
    );
  }

  // Notification methods - desktop-specific implementation needed
  @override
  Future<void> openNotifications() {
    throw UnimplementedError(
      'Notification center access requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> closeNotifications() {
    throw UnimplementedError(
      'Notification center access requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> closeHeadsUpNotification() {
    throw UnimplementedError(
      'Heads-up notifications are not typically used on Linux desktop',
    );
  }

  @override
  Future<GetNotificationsResponse> getNotifications(
    GetNotificationsRequest request,
  ) {
    throw UnimplementedError(
      'Notification access requires desktop environment-specific implementation',
    );
  }

  @override
  Future<void> tapOnNotification(TapOnNotificationRequest request) {
    throw UnimplementedError(
      'Notification interaction requires desktop environment-specific implementation',
    );
  }

  // Permission methods - not typically applicable on Linux desktop
  @override
  Future<PermissionDialogVisibleResponse> isPermissionDialogVisible(
    PermissionDialogVisibleRequest request,
  ) {
    throw UnimplementedError(
      'Permission dialogs are not typically used on Linux desktop',
    );
  }

  @override
  Future<void> handlePermissionDialog(HandlePermissionRequest request) {
    throw UnimplementedError(
      'Permission dialogs are not typically used on Linux desktop',
    );
  }

  @override
  Future<void> setLocationAccuracy(SetLocationAccuracyRequest request) {
    throw UnimplementedError(
      'Location permissions are not typically used on Linux desktop',
    );
  }

  // Camera and gallery methods - would require desktop-specific implementation
  @override
  Future<void> takeCameraPhoto(TakeCameraPhotoRequest request) {
    throw UnimplementedError(
      'Camera access requires desktop-specific implementation',
    );
  }

  @override
  Future<void> pickImageFromGallery(PickImageFromGalleryRequest request) {
    throw UnimplementedError(
      'Gallery access requires desktop-specific implementation',
    );
  }

  @override
  Future<void> pickMultipleImagesFromGallery(
    PickMultipleImagesFromGalleryRequest request,
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
      } catch (err) {
        // Continue polling
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw Exception('Element did not become visible within timeout');
  }

  @override
  Future<void> markPatrolAppServiceReady() {
    // Not applicable on Linux
    return Future.value();
  }

  @override
  Future<void> setMockLocation(SetMockLocationRequest request) {
    throw UnimplementedError(
      'Mock location is not applicable on Linux desktop',
    );
  }

  @override
  Future<void> debug() {
    // Print debug information
    // print('Linux Native Automator Debug Info:');
    // print('Base URI: $baseUri');
    // print('Timeout: $timeout');
    return Future.value();
  }
}
