#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

"""Check SonarQube generic coverage XML against a minimum percentage."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def usage() -> None:
    """Print command usage for invalid invocations."""
    print("usage: check-coverage.py <coverage.xml> <minimum-percent>", file=sys.stderr)


def coverage_percent(path: Path) -> tuple[float, int, int]:
    """Return covered percentage, covered lines, and total coverable lines."""
    root = ET.parse(path).getroot()
    total = 0
    covered = 0

    for line in root.findall(".//lineToCover"):
        total += 1
        if line.attrib.get("covered") == "true":
            covered += 1

    if total == 0:
        return 0.0, covered, total

    return (covered / total) * 100, covered, total


def main() -> int:
    """Check coverage and fail when it is not above the threshold."""
    if len(sys.argv) != 3:
        usage()
        return 2

    path = Path(sys.argv[1])
    minimum = float(sys.argv[2])
    percentage, covered, total = coverage_percent(path)
    print(f"coverage {percentage:.1f}% ({covered}/{total} lines), required > {minimum:.1f}%")

    if percentage <= minimum:
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
