"""Check the generated postinstall without modifying an installed application."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from zipfile import ZipFile


command = json.loads(Path(sys.argv.pop(1)).read_text())
assert len(command) == 3, "postinstall must pass the local repository to its script"
assert command[0] == "/bin/sh", "postinstall must use the POSIX shell"
script = Path(command[1])
repository = Path(command[2])
assert str(repository).startswith("/nix/store/"), "repository must live in the Nix store"
subprocess.run(["/bin/sh", "-n", script], check=True)
subprocess.run(["shellcheck", script], check=True)


class VrapperPostinstall(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        app = self.root / "DBeaver.app"
        self.features = app / "Contents/Eclipse/features"
        self.features.mkdir(parents=True)
        self.launcher = app / "Contents/MacOS/dbeaver"
        self.launcher.parent.mkdir(parents=True)
        self.arguments = self.root / "arguments.json"
        self.launcher.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "with open(os.environ['ARGUMENTS'], 'a') as log:\n"
            "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "sys.exit(int(os.environ.get('P2_EXIT', '0')))\n"
        )
        self.launcher.chmod(0o755)
        pgrep = self.root / "pgrep"
        pgrep.write_text('#!/bin/sh\nexit "${PGREP_EXIT:-1}"\n')
        pgrep.chmod(0o755)
        self.script = self.root / "postinstall.sh"
        # Substitute only external OS/application boundaries in a disposable copy.
        source = script.read_text()
        self.assertEqual(source.count("/Applications/DBeaver.app"), 2)
        self.assertEqual(source.count("/usr/bin/pgrep"), 1)
        source = source.replace("/Applications/DBeaver.app", str(app))
        source = source.replace("/usr/bin/pgrep", str(pgrep))
        self.assertIn(f'dbeaver_executable="{self.launcher}"', source)
        self.script.write_text(source)

    def run_postinstall(self, **environment):
        return subprocess.run(
            [command[0], self.script, repository],
            env={**os.environ, "ARGUMENTS": str(self.arguments), **environment},
            capture_output=True,
            text=True,
        )

    def test_repository_preserves_p2_metadata_and_core_artifacts(self):
        with ZipFile(repository / "content.jar") as jar:
            content = ET.fromstring(jar.read("content.xml"))
        unit = content.find("./units/unit[@id='net.sourceforge.vrapper.feature.group']")
        self.assertIsNotNone(unit, "core Vrapper installable unit must be present")
        self.assertEqual(unit.get("version"), "0.74.0")
        with ZipFile(repository / "artifacts.jar") as jar:
            artifacts = ET.fromstring(jar.read("artifacts.xml"))
        for classifier, name, directory in [
            ("org.eclipse.update.feature", "net.sourceforge.vrapper", "features"),
            ("osgi.bundle", "net.sourceforge.vrapper.core", "plugins"),
            ("osgi.bundle", "net.sourceforge.vrapper.eclipse", "plugins"),
        ]:
            with self.subTest(artifact=name):
                artifact = artifacts.find(f"./artifacts/artifact[@id='{name}']")
                self.assertIsNotNone(artifact)
                self.assertEqual(artifact.get("classifier"), classifier)
                with ZipFile(repository / directory / f"{name}_0.74.0.jar") as jar:
                    self.assertIsNone(jar.testzip())

    def test_installs_from_local_repository_when_feature_is_absent(self):
        # Fresh installs and app upgrades that remove Vrapper share this state.
        (self.features / "net.sourceforge.vrapper.plugin.surround_0.74.0").mkdir()
        result = self.run_postinstall()
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.arguments.read_text().splitlines()
        self.assertEqual(len(calls), 1, "director must be invoked exactly once")
        arguments = json.loads(calls[0])
        self.assertEqual(arguments[arguments.index("-repository") + 1], repository.as_uri())
        self.assertEqual(
            arguments[arguments.index("-installIU") + 1],
            "net.sourceforge.vrapper.feature.group",
        )
        self.assertEqual(
            arguments[arguments.index("-application") + 1],
            "org.eclipse.equinox.p2.director",
        )
        self.assertEqual(arguments[arguments.index("-trustedAuthorities") + 1], repository.as_uri())

    def test_skips_installed_feature(self):
        (self.features / "net.sourceforge.vrapper_0.74.0").mkdir()
        result = self.run_postinstall()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.arguments.exists(), "installed Vrapper must not be installed again")

    def test_running_application_aborts_before_installing(self):
        (self.features / "net.sourceforge.vrapper_0.74.0").mkdir()
        result = self.run_postinstall(PGREP_EXIT="0")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.arguments.exists())

    def test_missing_launcher_aborts(self):
        self.launcher.unlink()
        result = self.run_postinstall()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.arguments.exists())

    def test_director_failure_is_propagated(self):
        result = self.run_postinstall(P2_EXIT="42")
        self.assertEqual(result.returncode, 42)


unittest.main()
