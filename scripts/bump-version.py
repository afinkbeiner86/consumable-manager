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
    try:
        with open("ConsumableManager.toc", "r") as f:
            for line in f:
                if line.startswith("## Version:"):
                    return line.split(":", 1)[1].strip()
    except FileNotFoundError:
        print(f"{Colors.RED}Error: ConsumableManager.toc not found{Colors.NC}")
        return "unknown"
    except Exception as e:
        print(f"{Colors.RED}Error reading version: {e}{Colors.NC}")
        return "unknown"
    return "unknown"


def update_file(filepath: str, old_content: str, new_content: str) -> bool:
    """Update file content and return success status"""
    if old_content == new_content:
        print(f"{Colors.YELLOW}ℹ{Colors.NC}  No changes needed: {filepath}")
        return True

    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    except Exception as e:
        print(f"{Colors.RED}✗{Colors.NC} Error updating {filepath}: {e}")
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

    # Update ConsumableManager.toc
    try:
        with open("ConsumableManager.toc", "r", encoding="utf-8") as f:
            toc_content = f.read()

        new_toc = re.sub(
            r"^## Version:.*$",
            f"## Version: {new_version}",
            toc_content,
            flags=re.MULTILINE,
        )

        if update_file("ConsumableManager.toc", toc_content, new_toc):
            print(f"{Colors.GREEN}✓{Colors.NC} Updated: ConsumableManager.toc")
        else:
            success = False
    except FileNotFoundError:
        print(f"{Colors.RED}✗{Colors.NC} File not found: ConsumableManager.toc")
        success = False
    except Exception as e:
        print(f"{Colors.RED}✗{Colors.NC} Error with ConsumableManager.toc: {e}")
        success = False

    # Update ConsumableManager.lua
    try:
        with open("ConsumableManager.lua", "r", encoding="utf-8") as f:
            lua_content = f.read()

        # Update header comment
        new_lua = re.sub(
            r"^-- Version:.*$",
            f"-- Version: {new_version}",
            lua_content,
            flags=re.MULTILINE,
        )

        # Update status display version
        new_lua = re.sub(
            r'local version = HexColor\("v[\d.]+',
            f'local version = HexColor("v{new_version}',
            new_lua,
        )

        if update_file("ConsumableManager.lua", lua_content, new_lua):
            print(
                f"{Colors.GREEN}✓{Colors.NC} Updated: ConsumableManager.lua (header + status)"
            )
        else:
            success = False
    except FileNotFoundError:
        print(f"{Colors.RED}✗{Colors.NC} File not found: ConsumableManager.lua")
        success = False
    except Exception as e:
        print(f"{Colors.RED}✗{Colors.NC} Error with ConsumableManager.lua: {e}")
        success = False

    # Summary
    print()
    if success:
        print(f"{Colors.GREEN}✓ Version bump complete!{Colors.NC}")

        # Show next steps only if not in CI
        if not (os.getenv("CI") or os.getenv("GITHUB_ACTIONS")):
            print()
            print("Next steps:")
            print(f"  1. Review: {Colors.YELLOW}git diff{Colors.NC}")
            print(
                f"  2. Commit: {Colors.YELLOW}git add -A && git commit -m 'chore: bump version to {new_version}'{Colors.NC}"
            )
            print(f"  3. Tag:    {Colors.YELLOW}git tag v{new_version}{Colors.NC}")
            print(f"  4. Push:   {Colors.YELLOW}git push && git push --tags{Colors.NC}")

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
