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

import json
import logging
import subprocess
import time
from typing import Dict, List, Optional, Any
from flask import Flask, request, jsonify
import pyatspi
from pyatspi import Accessible

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)


class LinuxAutomator:
    """Main automation class for Linux desktop applications"""

    def __init__(self):
        self.timeout_ms = 10000  # Default timeout
        self.desktop = None
        self._initialize_desktop()

    def _initialize_desktop(self):
        """Initialize desktop accessibility connection"""
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
            # Basic properties
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

            # Add children if any
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
            # Try to get component interface for bounds
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
                # Check if this element matches
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

                # Search children
                for i in range(accessible.childCount):
                    search_tree(accessible.getChildAtIndex(i))

            except Exception as e:
                logger.warning(f"Error searching element: {e}")

        # Search all applications
        for i in range(self.desktop.childCount):
            app = self.desktop.getChildAtIndex(i)
            search_tree(app)

        return results

    def tap(self, x: float, y: float):
        """Perform tap at coordinates"""
        try:
            # Use xdotool for clicking
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
            # Use xdotool for typing
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


# Global automator instance
automator = LinuxAutomator()


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

            # Move mouse and click
            subprocess.run(
                ["xdotool", "mousemove", str(int(center_x)), str(int(center_y))],
                check=True,
            )
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

        # Convert relative coordinates to absolute
        screen_width = 1920  # Default, should get from screen
        screen_height = 1080

        abs_start_x = int(start_x * screen_width)
        abs_start_y = int(start_y * screen_height)
        abs_end_x = int(end_x * screen_width)
        abs_end_y = int(end_y * screen_height)

        # Use xdotool for swipe
        subprocess.run(
            ["xdotool", "mousemove", str(abs_start_x), str(abs_start_y)], check=True
        )

        subprocess.run(["xdotool", "mousedown", "1"], check=True)

        # Move in steps
        for i in range(1, steps + 1):
            progress = i / steps
            curr_x = int(abs_start_x + (abs_end_x - abs_start_x) * progress)
            curr_y = int(abs_start_y + (abs_end_y - abs_start_y) * progress)
            subprocess.run(
                ["xdotool", "mousemove", str(curr_x), str(curr_y)], check=True
            )
            time.sleep(0.01)  # Small delay between steps

        subprocess.run(["xdotool", "mouseup", "1"], check=True)

        return jsonify({"status": "success"})

    except Exception as e:
        logger.error(f"Swipe failed: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    logger.info("Starting Linux Native Automation Service")
    app.run(host="localhost", port=8081, debug=True)
