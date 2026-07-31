_:

# ─────────────────────────────────────────────────────────────────────────────
#  All NixOS feature modules.
#
#  Importing this does NOTHING on its own — every module is gated behind an
#  `arctic.*` option that defaults to off (or, for a few universally-correct
#  ones, to on). A host turns on what it needs in hosts/<name>/default.nix.
#
#  Convention: every directory's default.nix lists its siblings explicitly.
#  No listFilesRecursive — it breaks the moment a non-module .nix lands here.
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [
    ./core
    ./desktop
    ./gaming
    ./network
    ./security
    ./virt
    ./apps
    ./disk
  ];
}
