#!/usr/bin/env python3
"""
bump-version.py - Automatically bump version in .toc and .lua files
"""

import os
import re
import sys
from pathlib import Path


class Colors:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"


# Disable colors in CI environment
if os.getenv("CI") or os.getenv("GITHUB_ACTIONS"):
    Colors.RED = Colors.GREEN = Colors.YELLOW = Colors.NC = ""


def validate_version(version: str) -> bool:
    """Validate semantic versioning format (X.Y.Z)"""
    return bool(re.match(r"^\d+\.\d+\.\d+$", version))


def get_current_version() -> str:
    """Get current version from .toc file"""
    toc_path = Path("ConsumableManager.toc")
    if not toc_path.exists():
        print(f"{Colors.RED}Error: {toc_path.name} not found{Colors.NC}")
        return "unknown"

    content = toc_path.read_text(encoding="utf-8")
    for line in content.splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    return "unknown"


def update_file(filepath: str, old_content: str, new_content: str) -> bool:
    """Update file content using pathlib and return success status"""
    path = Path(filepath)
    if old_content == new_content:
        print(f"{Colors.YELLOW}ℹ{Colors.NC}  No changes needed: {path.name}")
        return True

    try:
        path.write_text(new_content, encoding="utf-8")
        return True
    except Exception as e:
        print(f"{Colors.RED}✗{Colors.NC} Error updating {path.name}: {e}")
        return False


def bump_version(new_version: str) -> int:
    """Bump version in .toc and .lua files"""
    print(f"{Colors.YELLOW}Bumping version to: {Colors.GREEN}{new_version}{Colors.NC}")

    current_version = get_current_version()
    print(f"Current version: {Colors.YELLOW}{current_version}{Colors.NC}")
    print(f"New version:     {Colors.GREEN}{new_version}{Colors.NC}\n")

    toc_path = Path("ConsumableManager.toc")
    lua_path = Path("ConsumableManager.lua")
    success = True

    # Update TOC
    if toc_path.exists():
        content = toc_path.read_text(encoding="utf-8")
        new_content = re.sub(
            r"^## Version:.*$",
            f"## Version: {new_version}",
            content,
            flags=re.MULTILINE,
        )
        if update_file(str(toc_path), content, new_content):
            print(f"{Colors.GREEN}✓{Colors.NC} Updated: {toc_path.name}")
        else:
            success = False
    else:
        print(f"{Colors.RED}✗{Colors.NC} File not found: {toc_path.name}")
        success = False

    # Update LUA
    if lua_path.exists():
        content = lua_path.read_text(encoding="utf-8")
        new_content = re.sub(
            r"^-- Version:.*$",
            f"-- Version: {new_version}",
            content,
            flags=re.MULTILINE,
        )
        new_content = re.sub(
            r'local version = HexColor\("v[\d.]+',
            f'local version = HexColor("v{new_version}',
            new_content,
        )

        if update_file(str(lua_path), content, new_content):
            print(
                f"{Colors.GREEN}✓{Colors.NC} Updated: {lua_path.name} (header + status)"
            )
        else:
            success = False
    else:
        print(f"{Colors.RED}✗{Colors.NC} File not found: {lua_path.name}")
        success = False

    if success:
        print(f"\n{Colors.GREEN}✓ Version bump complete!{Colors.NC}")
        return 0

    print(f"\n{Colors.RED}✗ Version bump failed!{Colors.NC}")
    return 2


def main():
    if len(sys.argv) != 2:
        print(f"{Colors.RED}Error: No version specified{Colors.NC}")
        sys.exit(1)

    new_version = sys.argv[1]
    if not validate_version(new_version):
        print(f"{Colors.RED}Error: Invalid version format{Colors.NC}")
        sys.exit(1)

    sys.exit(bump_version(new_version))


if __name__ == "__main__":
    main()
