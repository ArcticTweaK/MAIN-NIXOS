_:

# ─────────────────────────────────────────────────────────────────────────────
#  home-manager feature modules.
#
#  These live in a SEPARATE module fixpoint from the NixOS ones. To read system
#  state from here, use the `osConfig` argument — never try to reach the other
#  way, there is no supported path from home-manager back into NixOS.
#
#  Leaf names (shell / dev / terminal / desktop) are kept disjoint from the
#  NixOS side so `config.arctic.X` is never ambiguous when reading a file.
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [
    ./shell
    ./dev
    ./terminal
    ./packages.nix
  ];
}
