#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

"""Convert xccov archive line counts into SonarQube generic coverage XML."""

from __future__ import annotations

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

APP_SOURCE_PREFIX = "MyTimeBuddy/"
LINE_COUNT_PATTERN = re.compile(r"^\s*(\d+):\s+(\*|\d+)\b")


def usage() -> None:
    """Print command usage for invalid invocations."""
    print(
        "usage: xccov-to-sonarqube-generic.py <result-bundle-or-xccovarchive> <output.xml> [project-root]",
        file=sys.stderr,
    )


def archive_flag(input_path: Path) -> list[str]:
    """Return xccov flags needed for result bundles versus raw archives."""
    if input_path.suffix == ".xcresult":
        return ["--archive"]
    return []


def run_xccov(input_path: Path, *args: str) -> str:
    """Run xccov and return stdout as text."""
    command = ["xcrun", "xccov", "view", *archive_flag(input_path), *args, str(input_path)]
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    return result.stdout


def relative_path(path: str, root: Path) -> str | None:
    """Return a Sonar-friendly path relative to the project when possible."""
    source = Path(path)
    if source.is_absolute():
        try:
            return source.resolve().relative_to(root).as_posix()
        except ValueError:
            return None
    return source.as_posix()


def source_files(input_path: Path, root: Path) -> list[tuple[str, str]]:
    """List app source files from the xccov archive."""
    file_list = run_xccov(input_path, "--file-list")
    files: list[tuple[str, str]] = []

    for raw_path in file_list.splitlines():
        if not raw_path:
            continue
        file_path = relative_path(raw_path, root)
        if file_path is None or not file_path.startswith(APP_SOURCE_PREFIX):
            continue
        files.append((raw_path, file_path))

    return files


def line_coverage(input_path: Path, source_path: str) -> dict[int, bool]:
    """Read executable line counts for one source file."""
    output = run_xccov(input_path, "--file", source_path)
    lines: dict[int, bool] = {}

    for raw_line in output.splitlines():
        match = LINE_COUNT_PATTERN.match(raw_line)
        if match is None:
            continue
        count = match.group(2)
        if count == "*":
            continue
        lines[int(match.group(1))] = int(count) > 0

    return lines


def parse_xccov(input_path: Path, root: Path) -> dict[str, dict[int, bool]]:
    """Parse xccov archive data into per-file covered line maps."""
    files: dict[str, dict[int, bool]] = {}

    for source_path, file_path in source_files(input_path, root):
        line_map = line_coverage(input_path, source_path)
        if line_map:
            files[file_path] = line_map

    return files


def write_generic_coverage(files: dict[str, dict[int, bool]], output: Path) -> None:
    """Write SonarQube generic coverage XML from parsed line coverage."""
    coverage = ET.Element("coverage", version="1")
    for file_path in sorted(files):
        file_element = ET.SubElement(coverage, "file", path=file_path)
        for line_number in sorted(files[file_path]):
            ET.SubElement(
                file_element,
                "lineToCover",
                lineNumber=str(line_number),
                covered=str(files[file_path][line_number]).lower(),
            )

    tree = ET.ElementTree(coverage)
    ET.indent(tree, space="  ")
    tree.write(output, encoding="utf-8", xml_declaration=True)


def main() -> int:
    """Convert the input xccov archive to SonarQube generic coverage XML."""
    if len(sys.argv) not in (3, 4):
        usage()
        return 2

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    root = Path(sys.argv[3] if len(sys.argv) == 4 else ".").resolve()
    files = parse_xccov(input_path, root)
    if not files:
        print(f"no {APP_SOURCE_PREFIX} coverage records found in {input_path}", file=sys.stderr)
        return 1

    write_generic_coverage(files, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
