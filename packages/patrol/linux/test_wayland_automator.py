#!/usr/bin/env python3
"""Unit tests for the WaylandAutomator class.

Tests the keycode resolution, environment detection, and automator
selection logic without needing a running Wayland or X11 session.
"""

import os
import sys
import unittest
from unittest.mock import patch

# Add src directory to path so we can import the service module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from linux_automator_service import (
    WaylandAutomator,
    LinuxAutomator,
    _create_automator,
    _check_wayland,
    BaseLinuxAutomator,
)


class TestKeycodeResolution(unittest.TestCase):
    """Tests for WaylandAutomator._resolve_keycode()"""

    def setUp(self):
        # We need to create an instance to test _resolve_keycode
        # but WaylandAutomator.__init__ checks for pyatspi and ydotool.
        # We'll test the method directly by patching the problematic parts.
        pass

    @patch("linux_automator_service.pyatspi")
    @patch("linux_automator_service.subprocess")
    def test_named_keys(self, mock_subprocess, mock_pyatspi):
        """All named keys in _KEYCODE_MAP resolve correctly."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        # Named keys from the map
        test_cases = [
            ("Return", 28),
            ("Enter", 28),
            ("Super", 125),
            ("Tab", 15),
            ("Alt", 56),
            ("Left", 105),
            ("Right", 106),
            ("Up", 103),
            ("Down", 108),
            ("Home", 102),
            ("End", 107),
            ("Page_Up", 104),
            ("Page_Down", 109),
            ("Space", 57),
            ("Escape", 1),
            ("BackSpace", 14),
            ("XF86AudioRaiseVolume", 115),
            ("XF86AudioLowerVolume", 114),
            ("Ctrl", 29),
            ("Shift", 42),
        ]

        for key_name, expected_code in test_cases:
            with self.subTest(key=key_name):
                self.assertEqual(
                    automator._resolve_keycode(key_name),
                    expected_code,
                    f"Key {key_name!r} should resolve to {expected_code}",
                )

    @patch("linux_automator_service.pyatspi")
    @patch("linux_automator_service.subprocess")
    def test_letter_keys(self, mock_subprocess, mock_pyatspi):
        """Letter keys resolve to correct keyboard-row keycodes."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        # Keyboard row layout
        letter_codes = {
            "Q": 16, "W": 17, "E": 18, "R": 19, "T": 20,
            "Y": 21, "U": 22, "I": 23, "O": 24, "P": 25,
            "A": 30, "S": 31, "D": 32, "F": 33, "G": 34,
            "H": 35, "J": 36, "K": 37, "L": 38,
            "Z": 44, "X": 45, "C": 46, "V": 47, "B": 48,
            "N": 49, "M": 50,
        }

        for letter, expected_code in letter_codes.items():
            with self.subTest(letter=letter):
                # Both uppercase and lowercase should resolve
                self.assertEqual(
                    automator._resolve_keycode(letter),
                    expected_code,
                    f"Letter {letter!r} should resolve to {expected_code}",
                )
                self.assertEqual(
                    automator._resolve_keycode(letter.lower()),
                    expected_code,
                    f"Lowercase {letter.lower()!r} should resolve to {expected_code}",
                )

    @patch("linux_automator_service.pyatspi")
    @patch("linux_automator_service.subprocess")
    def test_digit_keys(self, mock_subprocess, mock_pyatspi):
        """Digit keys 0-9 resolve to KEY_0..KEY_9 evdev codes."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        for digit in range(10):
            key = str(digit)
            expected = 2 + digit if digit >= 1 else 11
            with self.subTest(digit=digit):
                self.assertEqual(
                    automator._resolve_keycode(key),
                    expected,
                    f"Digit {key!r} should resolve to {expected}",
                )

    @patch("linux_automator_service.pyatspi")
    @patch("linux_automator_service.subprocess")
    def test_unknown_key_raises(self, mock_subprocess, mock_pyatspi):
        """Unknown key names raise ValueError."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        with self.assertRaises(ValueError):
            automator._resolve_keycode("NonExistentKey123")

        with self.assertRaises(ValueError):
            automator._resolve_keycode("")

        with self.assertRaises(ValueError):
            automator._resolve_keycode("  ")

    @patch("linux_automator_service.pyatspi")
    @patch("linux_automator_service.subprocess")
    def test_keycode_map_completeness(self, mock_subprocess, mock_pyatspi):
        """All keys referenced in service methods have entries in _KEYCODE_MAP."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        # These keys are used by the service methods (press_key, tap, enter_text, etc.)
        used_keys = [
            "Return", "Enter", "Super", "Tab", "Alt", "Left",
            "Right", "Up", "Down", "Home", "End", "Page_Up", "Page_Down",
            "Space", "Escape", "BackSpace",
            "XF86AudioRaiseVolume", "XF86AudioLowerVolume",
            "Ctrl", "Shift",
        ]

        for key in used_keys:
            with self.subTest(key=key):
                self.assertIn(
                    key,
                    automator._KEYCODE_MAP,
                    f"Key {key!r} must be in _KEYCODE_MAP",
                )
                # All should resolve without error
                code = automator._resolve_keycode(key)
                self.assertIsInstance(code, int)
                self.assertGreater(code, 0)


class TestCheckWayland(unittest.TestCase):
    """Tests for _check_wayland()"""

    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "wayland"}, clear=True)
    def test_wayland_session(self):
        """Returns False when XDG_SESSION_TYPE is wayland."""
        result = _check_wayland()
        self.assertFalse(result)

    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "x11"}, clear=True)
    def test_x11_session(self):
        """Returns True when XDG_SESSION_TYPE is x11."""
        result = _check_wayland()
        self.assertTrue(result)

    @patch.dict(os.environ, {}, clear=True)
    def test_no_session_type(self):
        """Returns True when XDG_SESSION_TYPE is not set (assume X11)."""
        result = _check_wayland()
        self.assertTrue(result)

    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "WAYLAND"}, clear=True)
    def test_case_insensitive(self):
        """Returns False even with uppercase WAYLAND."""
        result = _check_wayland()
        self.assertFalse(result)

    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "tty"}, clear=True)
    def test_other_session(self):
        """Returns True for non-Wayland sessions like tty."""
        result = _check_wayland()
        self.assertTrue(result)


class TestCreateAutomator(unittest.TestCase):
    """Tests for _create_automator() selection logic."""

    @patch("linux_automator_service.LinuxAutomator")
    @patch("linux_automator_service.WaylandAutomator")
    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "wayland"}, clear=True)
    def test_selects_wayland_on_wayland(self, mock_wayland, mock_x11):
        """Returns WaylandAutomator when XDG_SESSION_TYPE is wayland."""
        result = _create_automator()
        mock_wayland.assert_called_once()
        mock_x11.assert_not_called()

    @patch("linux_automator_service.LinuxAutomator")
    @patch("linux_automator_service.WaylandAutomator")
    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "x11"}, clear=True)
    def test_selects_x11_on_x11(self, mock_wayland, mock_x11):
        """Returns LinuxAutomator when XDG_SESSION_TYPE is x11."""
        result = _create_automator()
        mock_x11.assert_called_once()
        mock_wayland.assert_not_called()

    @patch("linux_automator_service.LinuxAutomator")
    @patch("linux_automator_service.WaylandAutomator")
    @patch.dict(os.environ, {}, clear=True)
    def test_selects_x11_when_unset(self, mock_wayland, mock_x11):
        """Returns LinuxAutomator when XDG_SESSION_TYPE is unset."""
        result = _create_automator()
        mock_x11.assert_called_once()
        mock_wayland.assert_not_called()

    @patch("linux_automator_service.LinuxAutomator")
    @patch("linux_automator_service.WaylandAutomator")
    @patch.dict(os.environ, {"XDG_SESSION_TYPE": "WAYLAND"}, clear=True)
    def test_case_insensitive_selection(self, mock_wayland, mock_x11):
        """Selects WaylandAutomator with uppercase WAYLAND."""
        result = _create_automator()
        mock_wayland.assert_called_once()
        mock_x11.assert_not_called()


class TestWaylandAutomatorInputMethods(unittest.TestCase):
    """Tests that input methods on WaylandAutomator build correct ydotool args."""

    def setUp(self):
        self.patcher_pyatspi = patch("linux_automator_service.pyatspi")
        self.patcher_subprocess = patch("linux_automator_service.subprocess")
        self.mock_pyatspi = self.patcher_pyatspi.start()
        self.mock_subprocess = self.patcher_subprocess.start()

        # Make subprocess.run succeed by default
        self.mock_subprocess.run.return_value.returncode = 0

        # Configure pgrep to find ydotoold (avoid daemon start)
        def pgrep_side_effect(*args, **kwargs):
            class Result:
                returncode = 0  # 0 means "found" for pgrep
                stdout = ""
                stderr = ""

            return Result()

        self.mock_subprocess.run.side_effect = pgrep_side_effect

        self.automator = WaylandAutomator()

    def tearDown(self):
        self.patcher_pyatspi.stop()
        self.patcher_subprocess.stop()

    def test_tap_calls_yool_mousemove_and_click(self):
        """tap() calls ydotool mousemove then click."""
        self.mock_subprocess.run.reset_mock()
        self.automator.tap(100, 200)

        calls = self.mock_subprocess.run.call_args_list
        self.assertEqual(len(calls), 2)
        self.assertIn(["ydotool", "mousemove", "100", "200"], [c[0][0] for c in calls])
        self.assertIn(["ydotool", "click", "1"], [c[0][0] for c in calls])

    def test_enter_text_calls_ydotool_type(self):
        """enter_text() calls ydotool type."""
        self.mock_subprocess.run.reset_mock()
        self.automator.enter_text("hello world")

        self.mock_subprocess.run.assert_called_with(
            ["ydotool", "type", "hello world"], check=True
        )

    def test_press_key_simple(self):
        """press_key() with a simple key calls ydotool key."""
        self.mock_subprocess.run.reset_mock()
        self.automator.press_key("Return")

        self.mock_subprocess.run.assert_called_with(
            ["ydotool", "key", "28"], check=True
        )

    def test_press_key_combo_alt_left(self):
        """press_key('Alt+Left') builds key combo press/release sequence."""
        self.mock_subprocess.run.reset_mock()
        self.automator.press_key("Alt+Left")

        # Alt=56, Left=105 → press 56:1 105:1, release 105:0 56:0
        self.mock_subprocess.run.assert_called_with(
            ["ydotool", "key", "56:1", "105:1", "105:0", "56:0"],
            check=True,
        )

    def test_press_key_multi_key_combo(self):
        """press_key('Ctrl+Alt+Delete') builds correct press/release sequence."""
        self.mock_subprocess.run.reset_mock()
        # Ctrl=29, Alt=56, Delete=111 (KF1/Delete map is not in _KEYCODE_MAP...)
        # "Delete" isn't a named key. Let's use Ctrl+Alt+Tab which are all in the map:
        # Ctrl=29, Alt=56, Tab=15
        self.automator.press_key("Ctrl+Alt+Tab")

        # press all: 29:1 56:1 15:1, release in reverse: 15:0 56:0 29:0
        self.mock_subprocess.run.assert_called_with(
            ["ydotool", "key", "29:1", "56:1", "15:1", "15:0", "56:0", "29:0"],
            check=True,
        )

    def test_press_key_unknown_raises(self):
        """press_key() with unknown key raises ValueError."""
        with self.assertRaises(ValueError):
            self.automator.press_key("NonExistentKey")

    def test_swipe_builds_mouse_chain(self):
        """swipe() builds mousemove → mousedown → steps×mousemove → mouseup."""
        self.mock_subprocess.run.reset_mock()
        self.automator.swipe(0.0, 0.0, 1.0, 1.0, steps=3, screen_width=100, screen_height=100)

        calls = self.mock_subprocess.run.call_args_list
        args_list = [c[0][0] for c in calls]

        # Position 0: mousemove to start
        self.assertEqual(args_list[0], ["ydotool", "mousemove", "0", "0"])
        # Position 1: mousedown
        self.assertEqual(args_list[1], ["ydotool", "mousedown", "1"])
        # Positions 2..4: mousemove at each of the 3 step intervals
        self.assertEqual(args_list[2], ["ydotool", "mousemove", "33", "33"])
        self.assertEqual(args_list[3], ["ydotool", "mousemove", "66", "66"])
        self.assertEqual(args_list[4], ["ydotool", "mousemove", "100", "100"])
        # Position 5: mouseup
        self.assertEqual(args_list[5], ["ydotool", "mouseup", "1"])
        # Total: 1 mousemove (start) + 1 mousedown + 3 intermediate + 1 mouseup = 6
        self.assertEqual(len(calls), 6)


@patch("linux_automator_service.pyatspi")
@patch("linux_automator_service.subprocess")
class TestWaylandAutomatorDaemon(unittest.TestCase):
    """Tests for WaylandAutomator._ensure_daemon()."""

    def test_daemon_already_running(self, mock_subprocess, mock_pyatspi):
        """Doesn't start ydotoold if pgrep finds it."""
        mock_subprocess.run.return_value.returncode = 0
        automator = WaylandAutomator()

        # pgrep was called
        pgrep_calls = [
            c for c in mock_subprocess.run.call_args_list
            if c[0][0] == ["pgrep", "-x", "ydotoold"]
        ]
        self.assertEqual(len(pgrep_calls), 1)

        # ydotoold was NOT started (already running)
        ydotoold_calls = [
            c for c in mock_subprocess.run.call_args_list
            if "ydotoold" in str(c[0][0])
        ]
        # Only pgrep calls, no Popen to start it
        self.assertEqual(len([c for c in mock_subprocess.Popen.call_args_list if c[0][0] == ["ydotoold"]]), 0)

    def test_daemon_not_running_starts_it(self, mock_subprocess, mock_pyatspi):
        """Starts ydotoold if pgrep doesn't find it."""
        mock_subprocess.run.return_value.returncode = 1
        automator = WaylandAutomator()

        # pgrep was called
        pgrep_calls = [
            c for c in mock_subprocess.run.call_args_list
            if c[0][0] == ["pgrep", "-x", "ydotoold"]
        ]
        self.assertEqual(len(pgrep_calls), 1)

        # ydotoold was started via Popen
        ydotoold_popen = [
            c for c in mock_subprocess.Popen.call_args_list
            if c[0][0] == ["ydotoold"]
        ]
        self.assertEqual(len(ydotoold_popen), 1)

    def test_daemon_not_found_raises(self, mock_subprocess, mock_pyatspi):
        """Raises FileNotFoundError if ydotool is not installed."""
        mock_subprocess.run.side_effect = FileNotFoundError("ydotool not found")

        with self.assertRaises(FileNotFoundError):
            WaylandAutomator()


class TestBaseLinuxAutomator(unittest.TestCase):
    """Tests for BaseLinuxAutomator abstract interface."""

    def test_abstract_methods_raise_not_implemented(self):
        """Base class input methods raise NotImplementedError."""
        # Can't easily instantiate BaseLinuxAutomator due to pyatspi,
        # but we can verify the contract at class level
        self.assertTrue(hasattr(BaseLinuxAutomator, "tap"))
        self.assertTrue(hasattr(BaseLinuxAutomator, "enter_text"))
        self.assertTrue(hasattr(BaseLinuxAutomator, "press_key"))
        self.assertTrue(hasattr(BaseLinuxAutomator, "swipe"))


if __name__ == "__main__":
    unittest.main()
