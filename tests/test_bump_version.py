#!/usr/bin/env python3
"""
Unit tests for bump-version.py
"""

import importlib.util
import os
import sys
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
SCRIPT_PATH = BASE_DIR / "scripts" / "bump-version.py"


def load_bump_version(*, ci: bool = False):
    """
    Load bump-version.py as a fresh module instance.
    Optionally simulates CI environment.
    """
    module_name = "bump_version_test_instance"

    @contextmanager
    def ci_env():
        if ci:
            os.environ["CI"] = "true"
        try:
            yield
        finally:
            if ci:
                os.environ.pop("CI", None)

    with ci_env():
        spec = importlib.util.spec_from_file_location(module_name, SCRIPT_PATH)
        module = importlib.util.module_from_spec(spec)
        sys.modules.pop(module_name, None)
        spec.loader.exec_module(module)
        return module


class BaseBumpTest(unittest.TestCase):
    """Shared environment setup for file-based tests."""

    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.test_path = Path(self.tmp_dir.name)
        self.original_cwd = Path.cwd()
        os.chdir(self.test_path)

        self.bump_version = load_bump_version()

    def tearDown(self):
        os.chdir(self.original_cwd)
        self.tmp_dir.cleanup()

    def create_mock_project(self, version="2.8.0"):
        (self.test_path / "ConsumableManager.toc").write_text(
            f"## Version: {version}\n## Interface: 30300",
            encoding="utf-8",
        )
        (self.test_path / "ConsumableManager.lua").write_text(
            f"-- Version: {version}\nlocal v = 'v{version}'",
            encoding="utf-8",
        )


class TestVersionValidation(unittest.TestCase):
    """Test version format validation"""

    def test_validation(self):
        bump_version = load_bump_version()

        cases = [
            ("1.0.0", True),
            ("2.9.0", True),
            ("1.0", False),
            ("v1.0.0", False),
            ("", False),
        ]

        for version, expected in cases:
            with self.subTest(version=version):
                self.assertEqual(
                    bump_version.validate_version(version),
                    expected,
                )


class TestBumpLogic(BaseBumpTest):
    """Test the core version bumping functionality"""

    def test_successful_bump(self):
        self.create_mock_project("2.8.0")

        self.assertEqual(self.bump_version.get_current_version(), "2.8.0")
        self.assertEqual(self.bump_version.bump_version("2.9.0"), 0)

        toc = (self.test_path / "ConsumableManager.toc").read_text()
        lua = (self.test_path / "ConsumableManager.lua").read_text()

        self.assertIn("## Version: 2.9.0", toc)
        self.assertIn("-- Version: 2.9.0", lua)
        self.assertIn("'v2.9.0'", lua)

    def test_missing_files(self):
        self.assertEqual(self.bump_version.bump_version("2.9.0"), 2)


class TestCIEnvironment(unittest.TestCase):
    """Test behavior in CI environment"""

    def test_colors_disabled_in_ci(self):
        bump_version = load_bump_version(ci=True)

        self.assertEqual(bump_version.Colors.RED, "")
        self.assertEqual(bump_version.Colors.GREEN, "")
        self.assertEqual(bump_version.Colors.YELLOW, "")
        self.assertEqual(bump_version.Colors.NC, "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
