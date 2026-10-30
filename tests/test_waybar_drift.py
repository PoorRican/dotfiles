"""Exercise the Drift widget against the real tray protocol, not cached state."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shlex
import subprocess
import unittest

REPO = Path(__file__).resolve().parents[1]
HELPER = REPO / "bin/waybar-drift"
HINT = "Left-click: start/pause recording\nRight-click: record a note"
ITEM = ":1.42/org/ayatana/NotificationItem/drift"
MENU = "/org/ayatana/NotificationItem/drift/Menu"


def menu_layout(label):
    # Shape returned by busctl --json=short for com.canonical.dbusmenu.GetLayout.
    return [47, [0, {}, [{"type": "(ia{sv}av)", "data": [362, {
        "label": {"type": "s", "data": label}
    }, []]}]]]


class WaybarDriftTests(unittest.TestCase):
    def setUp(self):
        source = (REPO / "configs/waybar/config.jsonc").read_text()
        self.config = json.loads("\n".join(
            line for line in source.splitlines()
            if not line.lstrip().startswith("//")
        ))

    def test_eye_is_immediately_after_idle_allow(self):
        modules = self.config["modules-left"]
        self.assertEqual(modules.count("custom/drift"), 1)
        self.assertEqual(modules[modules.index("idle_inhibitor") + 1], "custom/drift")
        self.assertEqual(self.config["custom/drift"]["format"], "{text}")

    def test_left_click_toggles_recording(self):
        self.assertEqual(shlex.split(self.config["custom/drift"]["on-click"]),
                         ["/home/swe/.local/bin/drift", "toggle"])

    def test_right_click_opens_the_native_note_prompt(self):
        self.assertEqual(shlex.split(self.config["custom/drift"]["on-click-right"]),
                         ["/home/swe/.local/bin/drift", "note"])

    def test_state_is_refreshed_regularly_and_after_clicks(self):
        module = self.config["custom/drift"]
        self.assertEqual(module.get("exec"), "/home/swe/.local/bin/waybar-drift")
        self.assertEqual(module.get("return-type"), "json")
        self.assertEqual(module.get("interval"), 1)
        self.assertTrue(module.get("exec-on-event"))
        self.assertNotIn("tooltip-format", module, "Do not override the live status tooltip")

    def test_recording_eye_is_red_even_on_hover(self):
        css = (REPO / "configs/waybar/style.css").read_text()
        self.assertIn("#custom-drift.recording,", css)
        self.assertIn("#custom-drift.recording:hover", css)
        body = css.split("#custom-drift.recording:hover", 1)[1].split("}", 1)[0]
        self.assertIn("color: #ff5555;", body)
        self.assertIn("opacity: 1;", body)

    def test_helper_is_managed_declaratively(self):
        module = (REPO / "nix/modules/hyprland-desktop.nix").read_text()
        self.assertIn('home.file.".local/bin/waybar-drift"', module)
        self.assertIn('dotfiles + "/bin/waybar-drift"', module)
        self.assertTrue(HELPER.is_file(), "The live-state helper has not been implemented")

    def test_eye_shares_module_spacing_and_hover_styling(self):
        css = (REPO / "configs/waybar/style.css").read_text()
        shared = css.split("/* --- shared module spacing (V6.ce) --- */", 1)[1]
        self.assertIn("#custom-drift,", shared.split("{", 1)[0])
        hover = shared.split("#clock:hover,", 1)[1].split("{", 1)[0]
        self.assertIn("#custom-drift:hover,", hover)


class LiveStateTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(HELPER.is_file(), "The live-state helper has not been implemented")
        loader = importlib.machinery.SourceFileLoader("waybar_drift", str(HELPER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        assert spec is not None
        self.helper = importlib.util.module_from_spec(spec)
        loader.exec_module(self.helper)

    def query(self, label="● Recording", entries=None):
        def run(*args):
            if args[0] == "get-property":
                if args[-1] == "RegisteredStatusNotifierItems":
                    return [ITEM] if entries is None else entries
                if args[-1] == "Title":
                    return "drift"
                if args[-1] == "Menu":
                    return MENU
            if args[0] == "call":
                self.assertEqual(args[1:5], (":1.42", MENU, "com.canonical.dbusmenu", "GetLayout"))
                return menu_layout(label)
            self.fail(f"Unexpected D-Bus request: {args}")
        return run

    def test_recording_uses_eye_and_recording_class(self):
        output = self.helper.render(self.query())
        self.assertEqual(output["text"], "")
        self.assertEqual(output["class"], "recording")
        self.assertIn("Drift: recording", output["tooltip"])
        self.assertIn(HINT, output["tooltip"])

    def test_paused_is_not_red(self):
        output = self.helper.render(self.query("❚❚ Paused"))
        self.assertEqual(output["class"], "paused")
        self.assertIn("Drift: paused", output["tooltip"])
        self.assertIn(HINT, output["tooltip"])

    def test_external_state_changes_are_not_cached(self):
        self.assertEqual(self.helper.render(self.query())["class"], "recording")
        self.assertEqual(self.helper.render(self.query("❚❚ Paused"))["class"], "paused")

    def test_no_running_drift_is_unavailable(self):
        output = self.helper.render(self.query(entries=[]))
        self.assertEqual(output["class"], "unavailable")
        self.assertIn("unavailable", output["tooltip"])

    def test_unknown_status_never_claims_recording(self):
        self.assertEqual(self.helper.render(self.query("Unknown"))["class"], "unavailable")

    def test_disappearing_tray_items_do_not_hide_a_later_drift_item(self):
        query = self.query(entries=[":1.9/gone", ITEM])
        def with_stale(*args):
            if len(args) > 1 and args[1] == ":1.9":
                raise subprocess.CalledProcessError(1, "busctl")
            return query(*args)
        self.assertEqual(self.helper.render(with_stale)["class"], "recording")

    def test_missing_bus_or_malformed_reply_fails_closed(self):
        for error in (FileNotFoundError(), subprocess.TimeoutExpired("busctl", 2),
                      ValueError("malformed JSON"), KeyError("data")):
            def failed(*args):
                raise error
            self.assertEqual(self.helper.render(failed)["class"], "unavailable")


if __name__ == "__main__":
    unittest.main()
