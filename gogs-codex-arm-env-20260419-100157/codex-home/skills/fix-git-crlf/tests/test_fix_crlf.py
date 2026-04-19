import subprocess
import tempfile
import unittest
from pathlib import Path


SKILL_DIR = Path("/home/parsifal/.codex/skills/fix-git-crlf")
SCRIPT_PATH = SKILL_DIR / "scripts" / "fix_crlf.py"


class FixGitCrlfTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp_dir.name) / "repo"
        self.repo.mkdir()
        self.run_git("init")
        self.run_git("config", "user.name", "Test User")
        self.run_git("config", "user.email", "test@example.com")

    def tearDown(self):
        self.temp_dir.cleanup()

    def run_git(self, *args, cwd=None, check=True):
        return subprocess.run(
            ["git", *args],
            cwd=cwd or self.repo,
            capture_output=True,
            text=True,
            check=check,
        )

    def run_script(self, *args, cwd=None):
        if not SCRIPT_PATH.exists():
            self.fail(f"missing script under test: {SCRIPT_PATH}")
        return subprocess.run(
            ["python3", str(SCRIPT_PATH), *args],
            cwd=cwd or self.repo,
            capture_output=True,
            text=True,
        )

    def write_bytes(self, relative_path, data):
        file_path = self.repo / relative_path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_bytes(data)
        return file_path

    def test_fixes_whitelisted_crlf_file_in_target_path(self):
        target = self.write_bytes("src/app.py", b"print('hi')\r\nprint('bye')\r\n")
        self.run_git("add", "src/app.py")

        result = self.run_script("src")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(target.read_bytes(), b"print('hi')\nprint('bye')\n")
        self.assertIn("fixed: 1", result.stdout)
        self.assertIn("src/app.py", result.stdout)

    def test_skips_gitignored_files(self):
        ignored = self.write_bytes("build/generated.py", b"print('ignore')\r\n")
        self.write_bytes(".gitignore", b"build/\n")

        result = self.run_script(".")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(ignored.read_bytes(), b"print('ignore')\r\n")
        self.assertIn("fixed: 0", result.stdout)

    def test_limits_bulk_fixes_to_current_path(self):
        inside = self.write_bytes("pkg/local.py", b"print('local')\r\n")
        outside = self.write_bytes("other/outside.py", b"print('outside')\r\n")
        self.run_git("add", "pkg/local.py", "other/outside.py")

        result = self.run_script(".", cwd=self.repo / "pkg")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(inside.read_bytes(), b"print('local')\n")
        self.assertEqual(outside.read_bytes(), b"print('outside')\r\n")
        self.assertIn("fixed: 1", result.stdout)
        self.assertIn("pkg/local.py", result.stdout)
        self.assertNotIn("other/outside.py", result.stdout)

    def test_warned_file_outside_whitelist_is_fixed(self):
        warned = self.write_bytes("templates/custom.tpl", b"alpha\r\nbeta\r\n")
        self.run_git("add", "templates/custom.tpl")

        result = self.run_script(
            ".",
            "--warned-file",
            "templates/custom.tpl",
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(warned.read_bytes(), b"alpha\nbeta\n")
        self.assertIn("fixed: 1", result.stdout)
        self.assertIn("templates/custom.tpl", result.stdout)

    def test_automatically_uses_git_diff_warnings_for_non_whitelisted_files(self):
        warned = self.write_bytes("templates/custom.tpl", b"alpha\r\nbeta\r\n")
        self.run_git("add", "templates/custom.tpl")

        result = self.run_script(".")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(warned.read_bytes(), b"alpha\nbeta\n")
        self.assertIn("templates/custom.tpl", result.stdout)

    def test_warned_binary_file_is_skipped(self):
        binary = self.write_bytes("assets/blob.bin", b"\x00\r\n\x01\r\n")
        self.run_git("add", "assets/blob.bin")

        result = self.run_script(".", "--warned-file", "assets/blob.bin")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(binary.read_bytes(), b"\x00\r\n\x01\r\n")
        self.assertIn("skipped: 1", result.stdout)
        self.assertIn("binary", result.stdout)

    def test_bulk_mode_fixes_vue_files_by_default(self):
        target = self.write_bytes("frontend/src/App.vue", b"<template>\r\n  <div />\r\n</template>\r\n")
        self.run_git("add", "frontend/src/App.vue")

        result = self.run_script(".")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(target.read_bytes(), b"<template>\n  <div />\n</template>\n")
        self.assertIn("frontend/src/App.vue", result.stdout)

    def test_bulk_mode_fixes_dockerfile_variants_by_default(self):
        target = self.write_bytes("docker/Dockerfile.backend-dev-qt6", b"FROM ubuntu:22.04\r\n")
        self.run_git("add", "docker/Dockerfile.backend-dev-qt6")

        result = self.run_script(".")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(target.read_bytes(), b"FROM ubuntu:22.04\n")
        self.assertIn("docker/Dockerfile.backend-dev-qt6", result.stdout)

    def test_bulk_mode_fixes_cmakelists_by_default(self):
        target = self.write_bytes("backend/CMakeLists.txt", b"cmake_minimum_required(VERSION 3.16)\r\n")
        self.run_git("add", "backend/CMakeLists.txt")

        result = self.run_script(".")

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(target.read_bytes(), b"cmake_minimum_required(VERSION 3.16)\n")
        self.assertIn("backend/CMakeLists.txt", result.stdout)

    def test_fails_outside_git_repository(self):
        plain_dir = Path(self.temp_dir.name) / "plain"
        plain_dir.mkdir()

        result = self.run_script(".", cwd=plain_dir)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("git repository", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
