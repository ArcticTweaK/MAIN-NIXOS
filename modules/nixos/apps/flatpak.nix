{ config, lib, ... }:

let
  cfg = config.arctic.apps.flatpak;
in
{
  options.arctic.apps.flatpak = {
    enable = lib.mkEnableOption ''
      declarative Flatpak.

      Needed here for one thing with no nixpkgs equivalent:
      org.vinegarhq.Sober, which is how Roblox runs on Linux. (`vinegar` in
      nixpkgs is the Roblox *Studio* wrapper, not Sober.)

      Everything installed by hand with `flatpak install` is invisible to this
      repo and dies with a wipe, which is exactly the reproducibility hole
      this closes
    '';

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "org.vinegarhq.Sober" ];
      description = "Flathub application IDs to keep installed.";
    };

    uninstallUnmanaged = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Remove any Flatpak or remote not declared above.

        This is what makes the declaration authoritative rather than additive,
        and it is the end state you want. Left off initially so that flipping
        it is a deliberate act — it WILL delete anything you installed by hand
        and forgot to list here, including its ~/.var/app data.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;

      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];

      packages = cfg.apps;

      inherit (cfg) uninstallUnmanaged;
      uninstallUnused = cfg.uninstallUnmanaged;

      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };

      # Not on activation: it would make every `nixos-rebuild switch` block on
      # network I/O against Flathub, and fail the rebuild when it is down.
      update.onActivation = false;

      restartOnFailure = {
        enable = true;
        restartDelay = "60s";
        exponentialBackoff = {
          enable = true;
          steps = 5;
          maxDelay = "30m";
        };
      };
    };
  };
}
