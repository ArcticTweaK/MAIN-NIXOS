{ config, lib, pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  Theme PACKAGES — the assets, not the selection.
#
#  Split of responsibility, and it matters:
#
#      this file                      installs the theme files    (system)
#      modules/home/desktop/plasma.nix  picks which one is active (user)
#
#  A theme only works if BOTH halves are done. Naming a theme in
#  `arctic.plasma.theme.*` whose package is not installed here does not error —
#  Plasma silently falls back to Breeze, which is the single most confusing
#  failure mode in a declarative KDE setup.
#
#  KDE finds these under /run/current-system/sw/share/{icons,color-schemes,
#  plasma,aurorae,Kvantum}, exactly where it finds Breeze.
#
#  ── Themes installed BY HAND do not live here ───────────────────────────────
#  Anything dropped into ~/.local/share or ~/.icons by a KDE Store "Get New
#  Themes" download is invisible to this file and is DELETED by a reinstall.
#  See the audit table in EMPYREAN.md §10 for which of this desktop's themes
#  are currently in that category.
# ─────────────────────────────────────────────────────────────────────────────

let
  cfg = config.arctic.desktop.themes;
in
{
  options.arctic.desktop.themes = {
    enable = lib.mkEnableOption "declarative theme packages" // { default = true; };

    icons = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Icon theme packages: Papirus (in all three tints) and candy-icons.

        Papirus is what this desktop selects; the rest are alternatives that
        cost closure size only while this is on.
      '';
    };

    cursors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Cursor theme packages. `whitesur-cursors` provides `WhiteSur-cursors`,
        which is what this desktop selects — the name in
        `arctic.plasma.cursor.theme` must match a directory this installs.
      '';
    };

    sweet = lib.mkEnableOption ''
      the Sweet theme family (`sweet-nova`).

      Provides the Sweet-Dark and Sweet-Dark-transparent window decorations,
      the Sweet colour scheme, Sweet-cursors, the Sweet Kvantum styles and the
      `com.github.eliverlara.sweet` Global Theme.

      NOT the Ambar Blue or Mars variants — upstream nixpkgs packages only the
      base Sweet set. If you are running Sweet-Ambar-Blue, this package does
      not cover it
    '';

    whiteSur = lib.mkEnableOption ''
      the WhiteSur theme family (`whitesur-kde` + `whitesur-icon-theme`).

      A complete macOS-alike set: window decorations, colour schemes, Plasma
      styles, Global Themes, a Kvantum style and icons. Pairs with the
      WhiteSur cursors this desktop already uses
    '';

    vendored = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Themes committed into this repo under `pkgs/`, because nixpkgs does not
        carry them: `sweet-ambar-blue` (Plasma style + Aurorae decoration +
        colour scheme) and `simpletux-splash`.

        These are what this desktop actually selects. Turning this off does not
        break the build — it makes Plasma silently fall back to Breeze, which
        is the failure mode this whole module exists to prevent.
      '';
    };
  };

  config = lib.mkIf (config.arctic.desktop.enable && cfg.enable) {
    environment.systemPackages =
      lib.optionals cfg.icons [
        # Moved here from apps/utilities.nix — an icon theme is a theme, not a
        # utility, and it belongs next to the module that selects it.
        pkgs.papirus-icon-theme
        pkgs.candy-icons
      ]
      ++ lib.optionals cfg.cursors [
        pkgs.whitesur-cursors
      ]
      ++ lib.optionals cfg.sweet [
        pkgs.sweet-nova
      ]
      ++ lib.optionals cfg.whiteSur [
        pkgs.whitesur-kde
        pkgs.whitesur-icon-theme
      ]
      ++ lib.optionals cfg.vendored [
        # From ./pkgs, reachable as pkgs.* via overlays/default.nix `additions`.
        pkgs.sweet-ambar-blue
        pkgs.simpletux-splash
      ];
  };
}
