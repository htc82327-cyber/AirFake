from pathlib import Path
import plistlib, re, sys

root = Path(__file__).resolve().parents[1]

required = [
    "Makefile", "control", "Tweak.xm", "AirFake.plist",
    "airfakeapp/Makefile", "airfakeapp/main.m", "airfakeapp/AppDelegate.h",
    "airfakeapp/AppDelegate.m", "airfakeapp/AFRootViewController.h",
    "airfakeapp/AFRootViewController.m", "airfakeapp/Resources/Info.plist",
    "airfakeapp/Resources/AirFakeIcon@2x.png",
    "airfakeapp/Resources/AirFakeIcon@3x.png",
    "airfakeprefs/Makefile", "airfakeprefs/entry.plist",
    "airfakeprefs/Resources/Info.plist", "airfakeprefs/Resources/Root.plist",
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit("Missing files: " + ", ".join(missing))

for rel in [
    "airfakeapp/Resources/Info.plist",
    "airfakeprefs/Resources/Info.plist",
    "airfakeprefs/Resources/Root.plist",
    "airfakeprefs/entry.plist",
]:
    with (root / rel).open("rb") as f:
        plistlib.load(f)

control = (root / "control").read_text()
if "Version: 0.2.1" not in control:
    raise SystemExit("control version mismatch")

mk = (root / "Makefile").read_text()
for sub in ["airfakeapp", "airfakeprefs"]:
    if f"SUBPROJECTS += {sub}" not in mk:
        raise SystemExit(f"missing subproject {sub}")

tweak = (root / "Tweak.xm").read_text()
checks = [
    "@interface SBApplication",
    "%hook SBApplication",
    "AFRespringDarwinNotification",
    "dispatch_block_create((dispatch_block_flags_t)0",
]
for value in checks:
    if value not in tweak:
        raise SystemExit(f"Tweak.xm check failed: {value}")

print("AirFake source validation OK")
