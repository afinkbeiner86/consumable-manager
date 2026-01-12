#!/usr/bin/env python3
"""
bump-version.py - Automatically bump version in .toc and .lua files
Usage: python bump-version.py <new_version>
Example: python bump-version.py 2.9.0

Exit codes:
  0 - Success
  1 - Invalid arguments or version format
  2 - File operation error
"""

import os
import re
import sys
from pathlib import Path


# ANSI color codes (disabled in CI)
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
        print(f"{Colors.RED}Error: ConsumableManager.toc not found{Colors.NC}")
        return "unknown"
    try:
        content = toc_path.read_text(encoding="utf-8")
        for line in content.splitlines():
            if line.startswith("## Version:"):
                return line.split(":", 1)[1].strip()
    except Exception as e:
        print(f"{Colors.RED}Error reading version: {e}{Colors.NC}")
        return "unknown"
    return "unknown"


def update_file(filepath: str, old_content: str, new_content: str) -> bool:
    """Update file content and return success status"""
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
    """
    Bump version in .toc and .lua files
    Returns: 0 on success, 2 on error
    """

    print(f"{Colors.YELLOW}Bumping version to: {Colors.GREEN}{new_version}{Colors.NC}")

    current_version = get_current_version()
    print(f"Current version: {Colors.YELLOW}{current_version}{Colors.NC}")
    print(f"New version:     {Colors.GREEN}{new_version}{Colors.NC}")
    print()

    success = True
    toc_path = Path("ConsumableManager.toc")
    lua_path = Path("ConsumableManager.lua")

    # Update ConsumableManager.toc
    if toc_path.exists():
        toc_content = toc_path.read_text(encoding="utf-8")
        new_toc = re.sub(
            r"^## Version:.*$",
            f"## Version: {new_version}",
            toc_content,
            flags=re.MULTILINE,
        )

        if update_file(str(toc_path), toc_content, new_toc):
            print(f"{Colors.GREEN}✓{Colors.NC} Updated: {toc_path.name}")
        else:
            success = False
    else:
        print(f"{Colors.RED}✗{Colors.NC} File not found: {toc_path.name}")
        success = False

    # Update ConsumableManager.lua
    if lua_path.exists():
        lua_content = lua_path.read_text(encoding="utf-8")

        # Update header comment
        new_lua = re.sub(
            r"^-- Version:.*$",
            f"-- Version: {new_version}",
            lua_content,
            flags=re.MULTILINE,
        )

        # Update status display version (Improved regex to catch quoted versions)
        new_lua = re.sub(
            r"v\d+\.\d+\.\d+",
            f"v{new_version}",
            new_lua,
        )

        if update_file(str(lua_path), lua_content, new_lua):
            print(
                f"{Colors.GREEN}✓{Colors.NC} Updated: {lua_path.name} (header + status)"
            )
        else:
            success = False
    else:
        print(f"{Colors.RED}✗{Colors.NC} File not found: {lua_path.name}")
        success = False

    # Summary
    print()
    if success:
        print(f"{Colors.GREEN}✓ Version bump complete!{Colors.NC}")
        return 0
    else:
        print(f"{Colors.RED}✗ Version bump failed!{Colors.NC}")
        return 2


def main():
    if len(sys.argv) != 2:
        print(f"{Colors.RED}Error: No version specified{Colors.NC}")
        print(f"Usage: {sys.argv[0]} <new_version>")
        print(f"Example: {sys.argv[0]} 2.9.0")
        sys.exit(1)

    new_version = sys.argv[1]

    if not validate_version(new_version):
        print(f"{Colors.RED}Error: Invalid version format{Colors.NC}")
        print("Please use semantic versioning: X.Y.Z (e.g., 2.9.0)")
        sys.exit(1)

    exit_code = bump_version(new_version)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
