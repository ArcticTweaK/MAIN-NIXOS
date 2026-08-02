{ lib, stdenvNoCC }:

# ─────────────────────────────────────────────────────────────────────────────
#  Sweet Ambar Blue — Plasma style, window decoration and colour scheme.
#
#  Vendored, not fetched. nixpkgs' `sweet-nova` packages only the BASE Sweet
#  set (Sweet-Dark / Sweet-Dark-transparent decorations, Sweet.colors, no
#  desktoptheme at all) — the Ambar Blue variants are not in nixpkgs at all,
#  and `sweet` itself was removed when gtk-engine-murrine went with GTK 2.
#
#  These arrived through KDE's "Get New Themes" and lived in ~/.local/share,
#  which a reinstall deletes. Committing the trees is what makes the desktop
#  this machine actually runs survive being rebuilt from this repo.
#
#  ── The names below are load-bearing ────────────────────────────────────────
#  Each install path must match exactly what is selected in
#  hosts/arctic/default.nix, because Plasma does not error on a missing theme —
#  it silently falls back to Breeze:
#
#      share/plasma/desktoptheme/Sweet-Ambar-Blue  <- plasma.theme.plasmaStyle
#      share/aurorae/themes/Sweet-ambar-blue       <- plasma.theme.windowDecoration
#                                                     ("__aurorae__svg__" + this)
#      share/color-schemes/SweetAmbarBlue.colors   <- plasma.theme.colorScheme
#
#  Note the inconsistent capitalisation (`-Ambar-` vs `-ambar-`) is UPSTREAM's,
#  taken from each theme's own metadata.desktop. Do not "fix" it.
#
#  Upstream: https://github.com/EliverLara/Sweet
# ─────────────────────────────────────────────────────────────────────────────

stdenvNoCC.mkDerivation {
  pname = "sweet-ambar-blue";
  version = "1.0.0"; # X-KDE-PluginInfo-Version from metadata.desktop

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plasma/desktoptheme $out/share/aurorae/themes
    cp -r ${./desktoptheme} $out/share/plasma/desktoptheme/Sweet-Ambar-Blue
    cp -r ${./aurorae}      $out/share/aurorae/themes/Sweet-ambar-blue

    install -Dm444 ${./SweetAmbarBlue.colors} \
      $out/share/color-schemes/SweetAmbarBlue.colors

    runHook postInstall
  '';

  meta = {
    description = "Sweet Ambar Blue Plasma style, Aurorae decoration and colour scheme";
    homepage = "https://github.com/EliverLara/Sweet";
    # The Plasma style declares CC BY-SA 4.0; the Aurorae decoration GPLv3.
    license = [ lib.licenses.cc-by-sa-40 lib.licenses.gpl3Only ];
    platforms = lib.platforms.linux;
  };
}
