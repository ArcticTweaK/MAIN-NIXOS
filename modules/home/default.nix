_:

# ─────────────────────────────────────────────────────────────────────────────
#  home-manager feature modules.
#
#  These live in a SEPARATE module fixpoint from the NixOS ones. To read system
#  state from here, use the `osConfig` argument — never try to reach the other
#  way, there is no supported path from home-manager back into NixOS.
#
#  Option leaf names are kept disjoint from the NixOS side so `config.arctic.X`
#  is never ambiguous when reading a file. Note this constrains the OPTION
#  namespace, not the directory name: ./desktop holds the Plasma module, but
#  its options live under `arctic.plasma` because the NixOS tree already owns
#  `arctic.desktop`.
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [
    ./shell
    ./dev
    ./terminal
    ./desktop
    ./packages.nix
  ];
}
