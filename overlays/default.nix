{ inputs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  Overlays. Wired into every host by lib/mkHost.nix.
# ─────────────────────────────────────────────────────────────────────────────

{
  # Packages defined locally in ./pkgs — exposed as pkgs.<name>.
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # Tweaks to existing nixpkgs packages. Keep each one commented with WHY,
  # and delete it the moment upstream fixes the thing.
  modifications = _final: _prev: { };
}
