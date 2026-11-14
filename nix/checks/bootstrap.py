import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


bootstrap = Path(sys.argv.pop(1)).read_text()
final_stage = bootstrap[bootstrap.index('echo "[5/5]'):]
bash = shutil.which("bash")
mv = shutil.which("mv")
conflicting_files = ("nix/nix.custom.conf", "bashrc", "zshenv", "zshrc", "zprofile")


class BootstrapBackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bootstrap-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.etc = self.root / "etc"
        (self.etc / "nix").mkdir(parents=True)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.events = self.root / "events"
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "BOOTSTRAP_TEST_ROOT": str(self.root),
            "BOOTSTRAP_TEST_MV": mv,
            "BOOTSTRAP_TEST_MOVE": "move",
        }
        self.executable("nix", 'printf "switch\\n" >> "$BOOTSTRAP_TEST_ROOT/events"\n')
        self.executable("sudo", """
set -e
case "$1" in
  mv)
    [ "$#" -eq 4 ] && [ "$2" = -n ] || exit 90
    case "$3" in "$BOOTSTRAP_TEST_ROOT"/etc/*) ;; *) exit 91 ;; esac
    [ "$4" = "$3.before-nix-darwin" ] || exit 92
    case "$BOOTSTRAP_TEST_MOVE" in
      fail) exit 23 ;;
      skip) exit 0 ;;
    esac
    "$BOOTSTRAP_TEST_MV" "$2" "$3" "$4"
    printf 'backup %s\\n' "$3" >> "$BOOTSTRAP_TEST_ROOT/events"
    ;;
  "$BOOTSTRAP_TEST_ROOT/bin/nix")
    shift
    exec "$BOOTSTRAP_TEST_ROOT/bin/nix" "$@"
    ;;
  *) exit 93 ;;
esac
""")
        # Run the real final stage with /etc relocated; no installer or real sudo runs.
        self.script = self.root / "final-stage.sh"
        self.script.write_text(
            'set -e\nrepo_dir="$BOOTSTRAP_TEST_ROOT/repo"\nbootstrap_user=test\n'
            + final_stage.replace("/etc/", f"{self.etc}/")
        )

    def executable(self, name, body):
        path = self.bin / name
        path.write_text(f"#!{bash}\n{body}")
        path.chmod(0o755)

    def run_stage(self):
        return subprocess.run(
            [bash, str(self.script)], env=self.env, capture_output=True, text=True
        )

    def event_lines(self):
        return self.events.read_text().splitlines() if self.events.exists() else []

    def test_initial_files_are_preserved_before_switch_and_rerun(self):
        for name in conflicting_files:
            (self.etc / name).write_text(f"original {name}\n")
        for name in ("nix/nix.conf", "hosts"):
            (self.etc / name).write_text("keep\n")

        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in conflicting_files:
            self.assertFalse(os.path.lexists(self.etc / name), name)
            self.assertEqual(
                (self.etc / f"{name}.before-nix-darwin").read_text(),
                f"original {name}\n",
            )
        for name in ("nix/nix.conf", "hosts"):
            self.assertEqual((self.etc / name).read_text(), "keep\n")
        self.assertEqual(self.event_lines(), [
            *(f"backup {self.etc / name}" for name in conflicting_files), "switch"
        ])

        self.events.unlink()
        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.event_lines(), ["switch"])

    def test_managed_links_are_preserved_even_with_existing_backups(self):
        for name in conflicting_files:
            (self.etc / name).symlink_to(self.etc / "static" / name)
            (self.etc / f"{name}.before-nix-darwin").write_text("original\n")
        # Cover both live and dangling managed links.
        (self.etc / "static/nix").mkdir(parents=True)
        (self.etc / "static/nix/nix.custom.conf").write_text("managed\n")

        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in conflicting_files:
            self.assertEqual(os.readlink(self.etc / name), str(self.etc / "static" / name))
            self.assertEqual((self.etc / f"{name}.before-nix-darwin").read_text(), "original\n")
        self.assertEqual(self.event_lines(), ["switch"])

    def test_unmanaged_links_are_backed_up_without_changing_their_targets(self):
        (self.root / "custom-zshenv").write_text("custom\n")
        links = {"zshenv": "../custom-zshenv", "zshrc": "missing-target"}
        for name, target in links.items():
            (self.etc / name).symlink_to(target)

        result = self.run_stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name, target in links.items():
            self.assertFalse(os.path.lexists(self.etc / name))
            self.assertEqual(os.readlink(self.etc / f"{name}.before-nix-darwin"), target)
        self.assertEqual((self.root / "custom-zshenv").read_text(), "custom\n")
        self.assertEqual(self.event_lines()[-1], "switch")

    def test_existing_backup_stops_before_any_files_are_moved(self):
        sources = (self.etc / "nix/nix.custom.conf", self.etc / "zprofile")
        for source in sources:
            source.write_text("current\n")
        backup = self.etc / "zprofile.before-nix-darwin"
        for kind in ("file", "directory", "dangling-link"):
            with self.subTest(kind=kind):
                if kind == "file":
                    backup.write_text("original\n")
                elif kind == "directory":
                    backup.mkdir()
                else:
                    backup.symlink_to("missing-target")
                result = self.run_stage()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(str(backup), result.stderr)
                for source in sources:
                    self.assertEqual(source.read_text(), "current\n")
                self.assertEqual(self.event_lines(), [])
                if kind == "file":
                    self.assertEqual(backup.read_text(), "original\n")
                elif kind == "directory":
                    self.assertEqual(list(backup.iterdir()), [])
                else:
                    self.assertEqual(os.readlink(backup), "missing-target")
                if kind == "directory":
                    backup.rmdir()
                else:
                    backup.unlink()

    def test_source_directory_is_rejected_without_partial_changes(self):
        source = self.etc / "nix/nix.custom.conf"
        source.write_text("current\n")
        (self.etc / "zprofile").mkdir()
        result = self.run_stage()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(str(self.etc / "zprofile"), result.stderr)
        self.assertEqual(source.read_text(), "current\n")
        self.assertTrue((self.etc / "zprofile").is_dir())
        self.assertEqual(self.event_lines(), [])

    def test_failed_or_skipped_move_prevents_switch(self):
        source = self.etc / "nix/nix.custom.conf"
        source.write_text("current\n")
        for mode in ("fail", "skip"):
            with self.subTest(mode=mode):
                self.env["BOOTSTRAP_TEST_MOVE"] = mode
                result = self.run_stage()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(source.read_text(), "current\n")
                self.assertNotIn("switch", self.event_lines())


if __name__ == "__main__":
    unittest.main()
