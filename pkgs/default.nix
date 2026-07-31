{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  Locally-defined packages. Exposed two ways:
#    - as flake output   .#<name>
#    - as pkgs.<name>    via overlays/default.nix `additions`
#
#  Empty for now, but wired up so adding one is a single line.
# ─────────────────────────────────────────────────────────────────────────────

{
  # example-package = pkgs.callPackage ./example-package { };
}
