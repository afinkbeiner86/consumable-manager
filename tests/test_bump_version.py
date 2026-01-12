#!/usr/bin/env python3
"""
Unit tests for bump-version.py
"""

import os
import shutil
import sys
import tempfile
import unittest

# Add scripts directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

# Import the module (we need to refactor bump-version.py slightly to be testable)
import importlib.util

spec = importlib.util.spec_from_file_location("bump_version", "scripts/bump-version.py")
bump_version = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bump_version)


class TestVersionValidation(unittest.TestCase):
    """Test version format validation"""

    def test_valid_versions(self):
        """Test that valid semantic versions are accepted"""
        valid_versions = ["1.0.0", "2.9.0", "10.20.30", "0.0.1", "99.99.99"]
        for version in valid_versions:
            with self.subTest(version=version):
                self.assertTrue(bump_version.validate_version(version))

    def test_invalid_versions(self):
        """Test that invalid versions are rejected"""
        invalid_versions = [
            "1.0",  # Missing patch
            "1",  # Only major
            "v1.0.0",  # With v prefix
            "1.0.0-beta",  # With suffix
            "1.0.0.0",  # Too many parts
            "a.b.c",  # Non-numeric
            "1.0.x",  # Contains non-digit
            "",  # Empty
            "1.0.",  # Trailing dot
            ".1.0.0",  # Leading dot
        ]
        for version in invalid_versions:
            with self.subTest(version=version):
                self.assertFalse(bump_version.validate_version(version))


class TestFileUpdates(unittest.TestCase):
    """Test file update operations"""

    def setUp(self):
        """Create temporary directory with test files"""
        self.test_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()
        os.chdir(self.test_dir)

        # Create test .toc file
        self.toc_content = """## Interface: 30300
## Title: Consumable Manager
## Version: 2.8.0
## Author: Test Author
## SavedVariables: ConsumableManagerDB

ConsumableManager.lua
Data.lua
"""
        with open("ConsumableManager.toc", "w") as f:
            f.write(self.toc_content)

        # Create test .lua file
        self.lua_content = """--------------------------------------------------------------------------------
-- ConsumableManager
-- Version: 2.8.0
-- Purpose: Test addon
--------------------------------------------------------------------------------

local function DisplayAddonStatus()
    local version = HexColor("v2.8.0", "888888")
    print(version)
end
"""
        with open("ConsumableManager.lua", "w") as f:
            f.write(self.lua_content)

    def tearDown(self):
        """Clean up temporary directory"""
        os.chdir(self.original_cwd)
        shutil.rmtree(self.test_dir)

    def test_get_current_version(self):
        """Test reading current version from .toc file"""
        version = bump_version.get_current_version()
        self.assertEqual(version, "2.8.0")

    def test_get_current_version_missing_file(self):
        """Test handling of missing .toc file"""
        os.remove("ConsumableManager.toc")
        version = bump_version.get_current_version()
        self.assertEqual(version, "unknown")

    def test_update_toc_file(self):
        """Test updating version in .toc file"""
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 0)  # Success

        with open("ConsumableManager.toc", "r") as f:
            content = f.read()

        self.assertIn("## Version: 2.9.0", content)
        self.assertNotIn("## Version: 2.8.0", content)

    def test_update_lua_file_header(self):
        """Test updating version in .lua file header"""
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 0)

        with open("ConsumableManager.lua", "r") as f:
            content = f.read()

        self.assertIn("-- Version: 2.9.0", content)
        self.assertNotIn("-- Version: 2.8.0", content)

    def test_update_lua_file_status_display(self):
        """Test updating version in status display"""
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 0)

        with open("ConsumableManager.lua", "r") as f:
            content = f.read()

        self.assertIn('local version = HexColor("v2.9.0"', content)
        self.assertNotIn('local version = HexColor("v2.8.0"', content)

    def test_update_multiple_versions(self):
        """Test updating version multiple times"""
        # First update
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 0)

        # Second update
        result = bump_version.bump_version("3.0.0")
        self.assertEqual(result, 0)

        with open("ConsumableManager.toc", "r") as f:
            toc_content = f.read()
        with open("ConsumableManager.lua", "r") as f:
            lua_content = f.read()

        self.assertIn("## Version: 3.0.0", toc_content)
        self.assertIn("-- Version: 3.0.0", lua_content)
        self.assertIn('local version = HexColor("v3.0.0"', lua_content)

    def test_missing_toc_file(self):
        """Test handling when .toc file is missing"""
        os.remove("ConsumableManager.toc")
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 2)  # Error code

    def test_missing_lua_file(self):
        """Test handling when .lua file is missing"""
        os.remove("ConsumableManager.lua")
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 2)  # Error code

    def test_update_preserves_other_content(self):
        """Test that updating version doesn't modify other content"""
        result = bump_version.bump_version("2.9.0")
        self.assertEqual(result, 0)

        with open("ConsumableManager.toc", "r") as f:
            content = f.read()

        # Check that other fields are preserved
        self.assertIn("## Interface: 30300", content)
        self.assertIn("## Title: Consumable Manager", content)
        self.assertIn("## Author: Test Author", content)
        self.assertIn("ConsumableManager.lua", content)


class TestUpdateFile(unittest.TestCase):
    """Test the update_file helper function"""

    def test_update_file_no_changes(self):
        """Test update_file when content is identical"""
        content = "test content"
        result = bump_version.update_file("test.txt", content, content)
        self.assertTrue(result)

    def test_update_file_with_changes(self):
        """Test update_file when content changes"""
        with tempfile.NamedTemporaryFile(mode="w", delete=False) as f:
            f.write("old content")
            temp_file = f.name

        try:
            result = bump_version.update_file(temp_file, "old content", "new content")
            self.assertTrue(result)

            with open(temp_file, "r") as f:
                content = f.read()
            self.assertEqual(content, "new content")
        finally:
            os.unlink(temp_file)


class TestCIEnvironment(unittest.TestCase):
    """Test behavior in CI environment"""

    def test_colors_disabled_in_ci(self):
        """Test that colors are disabled when CI env var is set"""
        # Set CI environment variable
        os.environ["CI"] = "true"

        # Reload module to pick up environment variable
        importlib.reload(bump_version)

        # Colors should be empty strings
        self.assertEqual(bump_version.Colors.RED, "")
        self.assertEqual(bump_version.Colors.GREEN, "")
        self.assertEqual(bump_version.Colors.YELLOW, "")
        self.assertEqual(bump_version.Colors.NC, "")

        # Clean up
        del os.environ["CI"]
        importlib.reload(bump_version)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and error conditions"""

    def setUp(self):
        """Create temporary directory"""
        self.test_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()
        os.chdir(self.test_dir)

    def tearDown(self):
        """Clean up"""
        os.chdir(self.original_cwd)
        shutil.rmtree(self.test_dir)

    def test_empty_toc_file(self):
        """Test with empty .toc file"""
        with open("ConsumableManager.toc", "w") as f:
            f.write("")
        with open("ConsumableManager.lua", "w") as f:
            f.write("-- Version: 1.0.0")

        version = bump_version.get_current_version()
        self.assertEqual(version, "unknown")

    def test_malformed_toc_file(self):
        """Test with malformed .toc file"""
        with open("ConsumableManager.toc", "w") as f:
            f.write("garbage content\nno version here\n")
        with open("ConsumableManager.lua", "w") as f:
            f.write("-- Version: 1.0.0")

        version = bump_version.get_current_version()
        self.assertEqual(version, "unknown")

    def test_version_with_spaces(self):
        """Test .toc with spaces around version"""
        with open("ConsumableManager.toc", "w") as f:
            f.write("## Version:   2.8.0   \n")
        with open("ConsumableManager.lua", "w") as f:
            f.write("-- Version: 2.8.0")

        version = bump_version.get_current_version()
        self.assertEqual(version, "2.8.0")


if __name__ == "__main__":
    # Run tests with verbose output
    unittest.main(verbosity=2)
