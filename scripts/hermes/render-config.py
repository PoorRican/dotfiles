"""Render a Nix-owned Hermes config.yaml at build time.

Usage: render-config.py <settings.json> <out.yaml>

Runs with the Hermes sealed venv so the rendered file matches the installed
package: the schema version comes from DEFAULT_CONFIG (a config without it is
re-migrated on every start, and managed mode refuses that write), and the
top-level keys are checked against the roots Hermes actually knows so a stale
snapshot key fails the build instead of riding along silently.
"""

import json
import sys

import yaml
from hermes_cli.config import _EXTRA_KNOWN_ROOT_KEYS
from hermes_cli.config_defaults import DEFAULT_CONFIG


def main() -> int:
    settings_path, out_path = sys.argv[1], sys.argv[2]
    with open(settings_path, encoding="utf-8") as handle:
        settings = json.load(handle)

    known_roots = set(DEFAULT_CONFIG) | set(_EXTRA_KNOWN_ROOT_KEYS)
    unknown = sorted(key for key in settings if key not in known_roots)
    if unknown:
        print(
            "hermes: settings contain top-level keys this Hermes release does not know: "
            + ", ".join(unknown),
            file=sys.stderr,
        )
        return 1

    rendered = {"_config_version": DEFAULT_CONFIG["_config_version"]}
    rendered.update(settings)
    with open(out_path, "w", encoding="utf-8") as handle:
        yaml.safe_dump(rendered, handle, default_flow_style=False, sort_keys=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
