{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  Locally-defined packages. Exposed two ways:
#    - as flake output   .#<name>
#    - as pkgs.<name>    via overlays/default.nix `additions`
#
#  Empty for now, but wired up so adding one is a single line.
# ─────────────────────────────────────────────────────────────────────────────

{
  # KDE themes this desktop runs that nixpkgs does not carry. Vendored rather
  # than fetched — see each package's header for why.
  sweet-ambar-blue = pkgs.callPackage ./sweet-ambar-blue { };
  simpletux-splash = pkgs.callPackage ./simpletux-splash { };
}
