{ lib, stdenvNoCC }:

# ─────────────────────────────────────────────────────────────────────────────
#  Simple Tux — the splash screen shown between login and desktop.
#
#  Vendored for the same reason as ../sweet-ambar-blue: a KDE Store download
#  that lived in ~/.local/share and would not survive a reinstall.
#
#  A splash is a KPackage of structure "Plasma/LookAndFeel/Splash", so it
#  installs under look-and-feel even though it is not a full Global Theme.
#  The directory name must equal the KPlugin Id in metadata.json
#  ("SimpleTuxSplash-Plasma6"), which is also what ksplashrc stores and what
#  arctic.plasma.theme.splashScreen selects.
#
#  Splash.qmlc — a compiled QML cache — is deliberately NOT vendored. It is a
#  build artifact tied to one Qt version; Plasma regenerates it at runtime, and
#  a stale one is worse than none.
# ─────────────────────────────────────────────────────────────────────────────

stdenvNoCC.mkDerivation {
  pname = "simpletux-splash";
  version = "0-unstable-2026-08-02"; # KDE Store download, upstream has no version

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plasma/look-and-feel
    cp -r ${./lookandfeel} $out/share/plasma/look-and-feel/SimpleTuxSplash-Plasma6

    runHook postInstall
  '';

  meta = {
    description = "Simple Tux splash screen for Plasma 6";
    license = lib.licenses.gpl3Only; # per metadata.json and bundled LICENSE
    platforms = lib.platforms.linux;
  };
}
