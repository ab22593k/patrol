#!/usr/bin/env python3
"""
Linux Native Automation Service for Patrol

This service provides Linux desktop automation capabilities using AT-SPI
(Assistive Technology Service Provider Interface), which is the standard
accessibility framework for Linux desktop environments.

Requirements:
- pyatspi2: Python bindings for AT-SPI
- Flask: Web framework for HTTP API
"""

import logging
import os
import subprocess
import time
from typing import Dict, List, Optional, Any
from flask import Flask, request, jsonify
import pyatspi
from pyatspi import Accessible

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _check_wayland():
    """Check if running under Wayland and log appropriately."""
    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()
    if session_type == "wayland":
        logger.info(
            "Detected Wayland session — WaylandAutomator will handle input "
            "via ydotool (uinput)."
        )
        return False
    return True


app = Flask(__name__)


class BaseLinuxAutomator:
    """
    Base automation class with AT-SPI tree traversal and shared initialization.

    Subclasses override the input methods (tap, enter_text, press_key, swipe)
    to use the appropriate backend (xdotool for X11, ydotool for Wayland).
    """

    def __init__(self):
        self.timeout_ms = 10000  # Default timeout
        self.desktop = None
        self._initialize_desktop()

    def _initialize_desktop(self):
        """Initialize desktop accessibility connection"""
        _check_wayland()
        try:
            self.desktop = pyatspi.Registry.getDesktop(0)
            logger.info("Connected to desktop accessibility")
        except Exception as e:
            logger.error(f"Failed to connect to desktop: {e}")
            raise

    def configure(self, timeout_ms: int):
        """Configure automator settings"""
        self.timeout_ms = timeout_ms
        logger.info(f"Configured timeout: {timeout_ms}ms")

    def get_accessible_tree(
        self, accessible: Accessible, max_depth: int = 10, current_depth: int = 0
    ) -> Dict[str, Any]:
        """Convert AT-SPI accessible tree to Patrol format"""
        if current_depth >= max_depth:
            return {}

        try:
            node = {
                "className": accessible.__class__.__name__,
                "name": accessible.name or "",
                "description": accessible.description or "",
                "role": self._get_role_name(accessible.getRole()),
                "states": [state._name_ for state in accessible.getState().getStates()],
                "bounds": self._get_bounds(accessible),
                "enabled": accessible.getState().contains(pyatspi.STATE_ENABLED),
                "visible": accessible.getState().contains(pyatspi.STATE_VISIBLE),
                "showing": accessible.getState().contains(pyatspi.STATE_SHOWING),
                "focused": accessible.getState().contains(pyatspi.STATE_FOCUSED),
                "childCount": accessible.childCount,
            }

            if accessible.childCount > 0:
                children = []
                for i in range(accessible.childCount):
                    try:
                        child = accessible.getChildAtIndex(i)
                        children.append(
                            self.get_accessible_tree(
                                child, max_depth, current_depth + 1
                            )
                        )
                    except Exception as e:
                        logger.warning(f"Error getting child {i}: {e}")
                node["children"] = children

            return node

        except Exception as e:
            logger.warning(f"Error processing accessible: {e}")
            return {}

    def _get_role_name(self, role) -> str:
        """Get human-readable role name"""
        try:
            return role._name_
        except:
            return str(role)

    def _get_bounds(self, accessible: Accessible) -> Dict[str, float]:
        """Get bounding box of accessible element"""
        try:
            component = accessible.queryComponent()
            if component:
                x, y, width, height = component.getBounds(pyatspi.DESKTOP_COORDS)
                return {
                    "x": float(x),
                    "y": float(y),
                    "width": float(width),
                    "height": float(height),
                }
        except:
            pass

        return {"x": 0.0, "y": 0.0, "width": 0.0, "height": 0.0}

    def find_elements(
        self, text: Optional[str] = None, role_name: Optional[str] = None
    ) -> List[Accessible]:
        """Find elements matching criteria"""
        results = []

        def search_tree(accessible: Accessible):
            try:
                matches = True

                if text is not None:
                    matches = matches and (
                        text.lower() in (accessible.name or "").lower()
                    )

                if role_name is not None:
                    matches = matches and (
                        self._get_role_name(accessible.getRole()) == role_name
                    )

                if matches:
                    results.append(accessible)

                for i in range(accessible.childCount):
                    search_tree(accessible.getChildAtIndex(i))

            except Exception as e:
                logger.warning(f"Error searching element: {e}")

        for i in range(self.desktop.childCount):
            app = self.desktop.getChildAtIndex(i)
            search_tree(app)

        return results

    # --- Input methods — overridden by subclasses ---

    def tap(self, x: float, y: float):
        raise NotImplementedError("Subclasses must implement tap()")

    def enter_text(self, text: str):
        raise NotImplementedError("Subclasses must implement enter_text()")

    def press_key(self, key: str):
        raise NotImplementedError("Subclasses must implement press_key()")

    def swipe(
        self,
        start_x: float,
        start_y: float,
        end_x: float,
        end_y: float,
        steps: int = 12,
        screen_width: int = 1920,
        screen_height: int = 1080,
    ):
        raise NotImplementedError("Subclasses must implement swipe()")


class LinuxAutomator(BaseLinuxAutomator):
    """X11 automator using xdotool for mouse/keyboard input."""

    def tap(self, x: float, y: float):
        """Move mouse to (x, y) and click using xdotool"""
        try:
            subprocess.run(
                ["xdotool", "mousemove", str(int(x)), str(int(y))], check=True
            )
            subprocess.run(["xdotool", "click", "1"], check=True)
            logger.info(f"Tapped at ({x}, {y})")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to tap: {e}")
            raise
        except FileNotFoundError:
            logger.error("xdotool not found. Install with: sudo apt install xdotool")
            raise

    def enter_text(self, text: str):
        """Enter text using keyboard"""
        try:
            subprocess.run(["xdotool", "type", text], check=True)
            logger.info(f"Entered text: {text}")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to enter text: {e}")
            raise
        except FileNotFoundError:
            logger.error("xdotool not found. Install with: sudo apt install xdotool")
            raise

    def press_key(self, key: str):
        """Press a key"""
        try:
            subprocess.run(["xdotool", "key", key], check=True)
            logger.info(f"Pressed key: {key}")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to press key: {e}")
            raise
        except FileNotFoundError:
            logger.error("xdotool not found. Install with: sudo apt install xdotool")
            raise

    def swipe(
        self,
        start_x: float,
        start_y: float,
        end_x: float,
        end_y: float,
        steps: int = 12,
        screen_width: int = 1920,
        screen_height: int = 1080,
    ):
        """Perform swipe gesture using xdotool"""
        abs_start_x = int(start_x * screen_width)
        abs_start_y = int(start_y * screen_height)
        abs_end_x = int(end_x * screen_width)
        abs_end_y = int(end_y * screen_height)

        subprocess.run(
            ["xdotool", "mousemove", str(abs_start_x), str(abs_start_y)], check=True
        )
        subprocess.run(["xdotool", "mousedown", "1"], check=True)

        for i in range(1, steps + 1):
            progress = i / steps
            curr_x = int(abs_start_x + (abs_end_x - abs_start_x) * progress)
            curr_y = int(abs_start_y + (abs_end_y - abs_start_y) * progress)
            subprocess.run(
                ["xdotool", "mousemove", str(curr_x), str(curr_y)], check=True
            )
            time.sleep(0.01)

        subprocess.run(["xdotool", "mouseup", "1"], check=True)
        logger.info(f"Swiped from ({start_x}, {start_y}) to ({end_x}, {end_y})")


class WaylandAutomator(BaseLinuxAutomator):
    """
    Wayland-compatible automator using ydotool (uinput) for input.

    ydotool injects input events at the kernel level, bypassing the
    compositor, which works on all Wayland compositors.

    Keycode reference: packages/patrol/linux/KEYCODES.md
    """

    # xdotool key name -> Linux evdev keycode
    # Source: /usr/include/linux/input-event-codes.h
    _KEYCODE_MAP: dict[str, int] = {
        "Return": 28,
        "Enter": 28,
        "Super": 125,
        "Tab": 15,
        "Alt": 56,
        "Left": 105,
        "Right": 106,
        "Up": 103,
        "Down": 108,
        "Home": 102,
        "End": 107,
        "Page_Up": 104,
        "Page_Down": 109,
        "Space": 57,
        "Escape": 1,
        "BackSpace": 14,
        "XF86AudioRaiseVolume": 115,
        "XF86AudioLowerVolume": 114,
        "Ctrl": 29,
        "Shift": 42,
    }

    # Keyboard row layout for letter -> evdev keycode mapping
    _LETTER_KEYCODES: dict[str, int] = {
        "Q": 16,
        "W": 17,
        "E": 18,
        "R": 19,
        "T": 20,
        "Y": 21,
        "U": 22,
        "I": 23,
        "O": 24,
        "P": 25,
        "A": 30,
        "S": 31,
        "D": 32,
        "F": 33,
        "G": 34,
        "H": 35,
        "J": 36,
        "K": 37,
        "L": 38,
        "Z": 44,
        "X": 45,
        "C": 46,
        "V": 47,
        "B": 48,
        "N": 49,
        "M": 50,
    }

    def __init__(self):
        self.timeout_ms = 10000
        self.desktop = None
        self._initialize_desktop()
        self._ensure_daemon()

    def _ensure_daemon(self):
        """Ensure ydotoold is running; start it if possible."""
        try:
            result = subprocess.run(
                ["pgrep", "-x", "ydotoold"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode != 0:
                logger.info("ydotoold not running — starting it...")
                subprocess.Popen(
                    ["ydotoold"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                time.sleep(0.5)
        except FileNotFoundError:
            logger.error(
                "ydotool is not installed. Install with: sudo apt install ydotool"
            )
            raise
        except Exception as e:
            logger.warning(f"Failed to check/start ydotoold: {e}")

    def _resolve_keycode(self, key: str) -> int:
        """Resolve an xdotool-style key name to its Linux evdev keycode."""
        key = key.strip()

        if key in self._KEYCODE_MAP:
            return self._KEYCODE_MAP[key]

        if len(key) == 1 and key.isalpha():
            upper = key.upper()
            if upper in self._LETTER_KEYCODES:
                return self._LETTER_KEYCODES[upper]

        if len(key) == 1 and key.isdigit():
            digit = int(key)
            return 2 + digit if digit >= 1 else 11

        raise ValueError(f"Unknown key name: {key!r}")

    # --- Input methods using ydotool ---

    def tap(self, x: float, y: float):
        """Move mouse to (x, y) and click using ydotool."""
        try:
            subprocess.run(
                ["ydotool", "mousemove", str(int(x)), str(int(y))], check=True
            )
            subprocess.run(["ydotool", "click", "1"], check=True)
            logger.info(f"Tapped at ({x}, {y}) [ydotool]")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to tap: {e}")
            raise
        except FileNotFoundError:
            logger.error("ydotool not found. Install with: sudo apt install ydotool")
            raise

    def enter_text(self, text: str):
        """Enter text using ydotool type."""
        try:
            subprocess.run(["ydotool", "type", text], check=True)
            logger.info(f"Entered text: {text[:50]}... [ydotool]")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to enter text: {e}")
            raise
        except FileNotFoundError:
            logger.error("ydotool not found. Install with: sudo apt install ydotool")
            raise

    def press_key(self, key: str):
        """Press a key or key combination using ydotool keycodes.

        Handles both simple keys ("Return", "Tab") and key
        combinations ("Alt+Left", "Alt+Tab").
        """
        try:
            parts = [p.strip() for p in key.split("+")]
            keycodes = [self._resolve_keycode(p) for p in parts]

            if len(keycodes) == 1:
                subprocess.run(["ydotool", "key", str(keycodes[0])], check=True)
            else:
                # Key combination: press all, release in reverse
                args = ["key"]
                for code in keycodes:
                    args.append(f"{code}:1")
                for code in reversed(keycodes):
                    args.append(f"{code}:0")
                subprocess.run(["ydotool"] + args, check=True)

            logger.info(f"Pressed key: {key} [ydotool]")
        except ValueError as e:
            logger.error(f"Failed to resolve keycode for {key}: {e}")
            raise
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to press key {key}: {e}")
            raise
        except FileNotFoundError:
            logger.error("ydotool not found. Install with: sudo apt install ydotool")
            raise

    def swipe(
        self,
        start_x: float,
        start_y: float,
        end_x: float,
        end_y: float,
        steps: int = 12,
        screen_width: int = 1920,
        screen_height: int = 1080,
    ):
        """Perform swipe gesture using ydotool mouse commands."""
        abs_start_x = int(start_x * screen_width)
        abs_start_y = int(start_y * screen_height)
        abs_end_x = int(end_x * screen_width)
        abs_end_y = int(end_y * screen_height)

        subprocess.run(
            ["ydotool", "mousemove", str(abs_start_x), str(abs_start_y)], check=True
        )
        subprocess.run(["ydotool", "mousedown", "1"], check=True)

        for i in range(1, steps + 1):
            progress = i / steps
            curr_x = int(abs_start_x + (abs_end_x - abs_start_x) * progress)
            curr_y = int(abs_start_y + (abs_end_y - abs_start_y) * progress)
            subprocess.run(
                ["ydotool", "mousemove", str(curr_x), str(curr_y)], check=True
            )
            time.sleep(0.01)

        subprocess.run(["ydotool", "mouseup", "1"], check=True)
        logger.info(
            f"Swiped from ({start_x}, {start_y}) to ({end_x}, {end_y}) [ydotool]"
        )


def _create_automator() -> BaseLinuxAutomator:
    """Create the appropriate automator based on the display server."""
    session_type = os.environ.get("XDG_SESSION_TYPE", "").lower()

    if session_type == "wayland":
        logger.info(
            "XDG_SESSION_TYPE is 'wayland' — using WaylandAutomator "
            "(ydotool via uinput)"
        )
        return WaylandAutomator()

    return LinuxAutomator()


# Global automator instance
automator = _create_automator()


@app.route("/initialize", methods=["POST"])
def initialize():
    """Initialize the automator"""
    try:
        logger.info("Initializing Linux automator")
        return jsonify({"status": "success"})
    except Exception as e:
        logger.error(f"Initialization failed: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/configure", methods=["POST"])
def configure():
    """Configure automator settings"""
    try:
        data = request.get_json()
        timeout_ms = data.get("findTimeoutMillis", 10000)
        automator.configure(timeout_ms)
        return jsonify({"status": "success"})
    except Exception as e:
        logger.error(f"Configuration failed: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/getNativeUITree", methods=["POST"])
def get_native_ui_tree():
    """Get the entire native UI tree"""
    try:
        data = request.get_json()
        max_depth = data.get("maxDepth", 10)

        tree = {"roots": []}

        # Get all applications
        for i in range(automator.desktop.childCount):
            app = automator.desktop.getChildAtIndex(i)
            app_tree = automator.get_accessible_tree(app, max_depth)
            if app_tree:
                tree["roots"].append(app_tree)

        return jsonify(tree)
    except Exception as e:
        logger.error(f"Failed to get UI tree: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/tap", methods=["POST"])
def tap():
    """Tap on an element"""
    try:
        data = request.get_json()
        selector = data.get("selector", {})

        # Find element by selector
        text = selector.get("text")
        role = selector.get("className")

        elements = automator.find_elements(text=text, role_name=role)

        if not elements:
            return jsonify({"error": "Element not found"}), 404

        # Get bounds and click center
        element = elements[0]
        bounds = automator._get_bounds(element)

        if bounds["width"] > 0 and bounds["height"] > 0:
            center_x = bounds["x"] + bounds["width"] / 2
            center_y = bounds["y"] + bounds["height"] / 2

            # Move mouse and click via active automator (xdotool or ydotool)
            automator.tap(center_x, center_y)

            return jsonify({"status": "success"})
        else:
            return jsonify({"error": "Element has no valid bounds"}), 400

    except Exception as e:
        logger.error(f"Tap failed: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/enterText", methods=["POST"])
def enter_text():
    """Enter text into a focused element"""
    try:
        data = request.get_json()
        text = data.get("data", "")

        automator.enter_text(text)
        return jsonify({"status": "success"})

    except Exception as e:
        logger.error(f"Enter text failed: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/pressKey", methods=["POST"])
def press_key():
    """Press a key"""
    try:
        data = request.get_json()
        key = data.get("key", "Return")

        automator.press_key(key)
        return jsonify({"status": "success"})

    except Exception as e:
        logger.error(f"Press key failed: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/swipe", methods=["POST"])
def swipe():
    """Perform swipe gesture"""
    try:
        data = request.get_json()
        start_x = data.get("startX", 0.0)
        start_y = data.get("startY", 0.0)
        end_x = data.get("endX", 0.0)
        end_y = data.get("endY", 0.0)
        steps = data.get("steps", 12)

        automator.swipe(start_x, start_y, end_x, end_y, steps)

        return jsonify({"status": "success"})

    except Exception as e:
        logger.error(f"Swipe failed: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    logger.info("Starting Linux Native Automation Service")
    app.run(host="localhost", port=8081, debug=True)
