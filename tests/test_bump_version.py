#!/usr/bin/env python3
"""
Unit tests for bump-version.py
"""

import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
SCRIPT_PATH = BASE_DIR / "scripts" / "bump-version.py"

spec = importlib.util.spec_from_file_location("bump_version", str(SCRIPT_PATH))
bump_version = importlib.util.module_from_spec(spec)
# Assigning spec to the module is required for importlib.reload() to work
bump_version.__spec__ = spec
sys.modules["bump_version"] = bump_version
spec.loader.exec_module(bump_version)


class BaseBumpTest(unittest.TestCase):
    """Shared environment setup for file-based tests."""

    def setUp(self):
        """Create temporary directory and switch CWD"""
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.test_path = Path(self.tmp_dir.name)
        self.original_cwd = Path.cwd()
        os.chdir(self.test_path)

    def tearDown(self):
        """Restore CWD and cleanup temp files"""
        os.chdir(self.original_cwd)
        self.tmp_dir.cleanup()

    def create_mock_project(self, version="2.8.0"):
        """Helper to scaffold standard test files."""
        (self.test_path / "ConsumableManager.toc").write_text(
            f"## Version: {version}\n## Interface: 30300", encoding="utf-8"
        )
        (self.test_path / "ConsumableManager.lua").write_text(
            f"-- Version: {version}\nlocal v = 'v{version}'", encoding="utf-8"
        )


class TestVersionValidation(unittest.TestCase):
    """Test version format validation"""

    def test_validation(self):
        """Test that valid and invalid semantic versions are handled"""
        cases = [
            ("1.0.0", True),
            ("2.9.0", True),
            ("1.0", False),
            ("v1.0.0", False),
            ("", False),
        ]
        for version, expected in cases:
            with self.subTest(version=version):
                self.assertEqual(bump_version.validate_version(version), expected)


class TestBumpLogic(BaseBumpTest):
    """Test the core version bumping functionality"""

    def test_successful_bump(self):
        """Test happy path: reading current and updating to new version."""
        self.create_mock_project("2.8.0")
        self.assertEqual(bump_version.get_current_version(), "2.8.0")
        self.assertEqual(bump_version.bump_version("2.9.0"), 0)

        toc_content = (self.test_path / "ConsumableManager.toc").read_text()
        lua_content = (self.test_path / "ConsumableManager.lua").read_text()

        self.assertIn("## Version: 2.9.0", toc_content)
        self.assertIn("-- Version: 2.9.0", lua_content)
        self.assertIn("'v2.9.0'", lua_content)

    def test_missing_files(self):
        """Verify error code 2 when files are missing."""
        self.assertEqual(bump_version.bump_version("2.9.0"), 2)


class TestCIEnvironment(unittest.TestCase):
    """Test behavior in CI environment"""

    def test_colors_disabled_in_ci(self):
        """Verify reload() functionality with registered sys.modules."""
        import importlib

        os.environ["CI"] = "true"
        # Reloading now works because __spec__ was assigned during import
        importlib.reload(bump_version)
        try:
            self.assertEqual(bump_version.Colors.RED, "")
        finally:
            del os.environ["CI"]
            importlib.reload(bump_version)


if __name__ == "__main__":
    unittest.main(verbosity=2)
