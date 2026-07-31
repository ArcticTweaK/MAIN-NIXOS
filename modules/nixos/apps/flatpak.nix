{ config, lib, ... }:

let
  cfg = config.arctic.apps.flatpak;
in
{
  options.arctic.apps.flatpak = {
    enable = lib.mkEnableOption ''
      Flatpak.

      Needed here for exactly one thing that has no nixpkgs equivalent:
      org.vinegarhq.Sober, which is how Roblox runs on Linux. (`vinegar` in
      nixpkgs is the Roblox *Studio* wrapper, not Sober.)
    '';
  };

  # FIXME(commit 6): this enables Flatpak but declares no remotes and no apps,
  # so every installed Flatpak — including Sober — is imperative state that a
  # wipe destroys. Made declarative in commit 6 via nix-flatpak.
  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
