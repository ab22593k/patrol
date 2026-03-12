# Patrol Linux Native Automation

This directory contains the Linux implementation of Patrol's native automation capabilities, enabling desktop application testing on Linux using AT-SPI (Assistive Technology Service Provider Interface).

## Overview

The Linux implementation provides:
- **AT-SPI Integration**: Uses the standard Linux accessibility framework
- **Cross-Desktop Support**: Works with GNOME, KDE, and other desktop environments
- **Flutter App Support**: Can automate Flutter applications running on Linux
- **Native App Support**: Can automate any Linux application with accessibility support

## Architecture

```
Test Runner (Dart) → HTTP API → Python Service → AT-SPI → Target Applications
```

- **Dart Client**: `LinuxNativeAutomatorClient` - HTTP client for Patrol tests
- **Python Service**: `linux_automator_service.py` - Flask server with AT-SPI integration
- **AT-SPI**: Linux accessibility framework for inspecting and controlling applications

## Installation

### Prerequisites

1. **Linux Desktop Environment**: GNOME, KDE, XFCE, etc.
2. **Accessibility Support**: Must be enabled in your desktop environment
3. **Python 3.8+**: Required for the automation service

### Quick Setup

```bash
# Navigate to the Linux implementation directory
cd packages/patrol/linux

# Run the setup script
./setup.sh
```

### Manual Setup

1. **Install System Dependencies**:

   **Ubuntu/Debian:**
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip python3-pyatspi xdotool at-spi2-core
   ```

   **Fedora:**
   ```bash
   sudo dnf install python3 python3-pip python3-pyatspi xdotool at-spi2-core
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S python python-pip python-pyatspi xdotool at-spi2-core
   ```

2. **Install Python Dependencies**:
   ```bash
   pip3 install --user -r requirements.txt
   ```

3. **Enable Accessibility**:
   ```bash
   # For GNOME
   gsettings set org.gnome.desktop.interface toolkit-accessibility true
   
   # Or enable via GUI: Settings → Universal Access → Seeing → Large Text
   ```

## Usage

### Starting the Service

```bash
# Start the automation service
./linux_automator.sh

# Or run directly
python3 src/linux_automator_service.py
```

The service will start on `localhost:8081`.

### Using in Patrol Tests

```dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Linux automation example', (PatrolTester $) async {
    // The Linux automator will be automatically used on Linux platforms
    await $.native.tap(Selector(text: 'Button Text'));
    await $.native.enterText(
      Selector(className: 'TextField'), 
      text: 'Hello Linux!',
    );
    await $.native.swipe(
      from: Offset(0.5, 0.8),
      to: Offset(0.5, 0.2),
    );
  });
}
```

## Supported Features

### ✅ Implemented
- **Element Inspection**: Get accessibility tree of applications
- **Basic Interactions**: Tap, double tap, text entry
- **Gestures**: Swipe, drag
- **Keyboard Input**: Key presses, text typing
- **App Management**: Launch applications
- **Navigation**: Home, back (mapped to desktop equivalents)

### 🚧 Partially Implemented
- **Element Selection**: Basic text and role-based selectors
- **Wait Operations**: Basic visibility waiting

### ❌ Not Applicable / Future Work
- **Mobile-specific Features**: Volume control, airplane mode, cellular
- **System Settings**: WiFi, Bluetooth, location (desktop-specific)
- **Notifications**: Desktop notification center integration
- **Permissions**: Desktop permission dialogs

## Flutter Application Support

Flutter applications on Linux automatically expose accessibility through AT-SPI. To ensure your Flutter app works well with Patrol Linux:

1. **Enable Semantics**: Make sure your widgets have proper semantics
2. **Test Accessibility**: Use screen readers like Orca to verify accessibility
3. **Add Descriptions**: Use `semanticsLabel` and `semanticsHint` where appropriate

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Click me'),
  semanticsLabel: 'Action button',
)
```

## Troubleshooting

### Common Issues

1. **"Failed to connect to desktop"**
   - Ensure accessibility is enabled: `gsettings set org.gnome.desktop.interface toolkit-accessibility true`
   - Restart your session after enabling accessibility

2. **"xdotool not found"**
   - Install xdotool: `sudo apt install xdotool` (Ubuntu/Debian)

3. **"Element not found"**
   - Verify the target application has accessibility support
   - Check that the application is running and visible
   - Use AT-SPI inspection tools to verify element properties

4. **"Permission denied"**
   - Ensure the service has permission to control applications
   - Check firewall settings if running remotely

### Debugging Tools

1. **AT-SPI Inspector**: `accerciser` (GUI tool for inspecting accessibility)
2. **Monitor Events**: `python3 -c "import pyatspi; pyatspi.Registry.registerEventListener(...)"`

### Logs

Enable debug logging by setting the log level:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Development

### Project Structure

```
linux/
├── src/
│   ├── linux_automator_service.py    # Main automation service
│   └── linux_native_automator_client.dart  # Dart client
├── requirements.txt                  # Python dependencies
├── setup.sh                         # Installation script
├── linux_automator.sh              # Startup script
└── README.md                       # This file
```

### Adding New Features

1. **Python Service**: Add new endpoints in `linux_automator_service.py`
2. **Dart Client**: Implement methods in `LinuxNativeAutomatorClient`
3. **Contracts**: Update shared contracts if needed

### Testing

```bash
# Test the service directly
curl -X POST http://localhost:8081/initialize

# Test with a simple Patrol test
dart test integration_test/linux_test.dart
```

## Contributing

When contributing to the Linux implementation:

1. **Test on Multiple Desktops**: Ensure compatibility with GNOME, KDE, XFCE
2. **Accessibility First**: Prioritize accessibility standards over visual inspection
3. **Error Handling**: Provide clear error messages for common issues
4. **Documentation**: Update this README for new features

## License

This implementation follows the same license as the main Patrol project.