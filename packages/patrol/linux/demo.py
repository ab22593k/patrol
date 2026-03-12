#!/usr/bin/env python3
"""
Demonstration script for Linux Native Automation Service

This script demonstrates how to use the Linux automation service
to interact with desktop applications.
"""

import requests
import json
import time
import sys

# Service configuration
BASE_URL = "http://localhost:8081"


def test_service():
    """Test basic service functionality"""
    print("Testing Linux Native Automation Service...")

    try:
        # Test initialization
        print("1. Initializing service...")
        response = requests.post(f"{BASE_URL}/initialize")
        print(f"   Status: {response.status_code}")

        # Test configuration
        print("2. Configuring service...")
        config_data = {"findTimeoutMillis": 5000}
        response = requests.post(f"{BASE_URL}/configure", json=config_data)
        print(f"   Status: {response.status_code}")

        # Test getting UI tree
        print("3. Getting UI tree...")
        response = requests.post(f"{BASE_URL}/getNativeUITree", json={"maxDepth": 3})
        if response.status_code == 200:
            tree = response.json()
            print(f"   Found {len(tree.get('roots', []))} root applications")
            for i, root in enumerate(tree.get("roots", [])[:3]):  # Show first 3
                name = root.get("name", "Unknown")
                role = root.get("role", "Unknown")
                print(f"   {i + 1}. {name} ({role})")
        else:
            print(f"   Error: {response.status_code}")

        # Test key press
        print("4. Testing key press...")
        key_data = {"key": "Super"}  # Press Super key to open app launcher
        response = requests.post(f"{BASE_URL}/pressKey", json=key_data)
        print(f"   Status: {response.status_code}")

        print("\nService test completed successfully!")
        return True

    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to service.")
        print("Make sure the service is running:")
        print("  cd packages/patrol/linux")
        print("  ./linux_automator.sh")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False


def show_app_info():
    """Show information about running applications"""
    print("\nDetecting accessible applications...")

    try:
        import pyatspi

        desktop = pyatspi.Registry.getDesktop(0)

        apps = []
        for i in range(desktop.childCount):
            app = desktop.getChildAtIndex(i)
            if app.name and app.name.strip():
                apps.append(
                    {
                        "name": app.name,
                        "role": app.getRole()._name_,
                        "children": app.childCount,
                    }
                )

        if apps:
            print(f"Found {len(apps)} accessible applications:")
            for i, app in enumerate(apps[:10]):  # Show first 10
                print(
                    f"  {i + 1}. {app['name']} ({app['role']}) - {app['children']} children"
                )
        else:
            print("No accessible applications found.")
            print("Make sure accessibility is enabled:")
            print(
                "  gsettings set org.gnome.desktop.interface toolkit-accessibility true"
            )

    except ImportError:
        print("pyatspi not available. Install with: pip install pyatspi")
    except Exception as e:
        print(f"Error detecting apps: {e}")


def main():
    """Main demonstration function"""
    print("=== Linux Native Automation Demo ===\n")

    # Show system info
    print("System Information:")
    print(f"  Python version: {sys.version}")
    print(f"  Platform: {sys.platform}")

    # Show accessible applications
    show_app_info()

    # Test service
    print("\n" + "=" * 40)
    if test_service():
        print("\n✅ Linux automation is ready!")
        print("\nTo use in Patrol tests:")
        print("  1. Start the service: ./linux_automator.sh")
        print("  2. Run your Patrol tests with native automation")
        print("  3. Use $.native methods in your tests")
    else:
        print("\n❌ Service setup required")
        print("\nTo set up the service:")
        print("  1. cd packages/patrol/linux")
        print("  2. ./setup.sh")
        print("  3. ./linux_automator.sh")


if __name__ == "__main__":
    main()
