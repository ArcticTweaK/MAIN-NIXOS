{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.gaming.steam;
in
{
  options.arctic.gaming.steam = {
    enable = lib.mkEnableOption "Steam";

    protonGE = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Ship GE-Proton as a Steam compatibility tool declaratively, instead of
        letting protonup-qt download it into ~/.steam at runtime. Same result,
        except this one survives a wipe.
      '';
    };

    gamescopeSession = lib.mkEnableOption "the gamescope session at the display manager" // { default = true; };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open Remote Play / dedicated server / local network transfer ports.

        Off by default: these listen on the LAN and none of them are needed for
        single-player or normal online play. Turn on only if you actually use
        Steam Remote Play or LAN game transfers.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;

      remotePlay.openFirewall = cfg.openFirewall;
      dedicatedServer.openFirewall = cfg.openFirewall;
      localNetworkGameTransfers.openFirewall = cfg.openFirewall;

      extraCompatPackages = lib.mkIf cfg.protonGE [ pkgs.proton-ge-bin ];

      gamescopeSession.enable = cfg.gamescopeSession;

      # The module-provided protontricks is wrapped with the right
      # extraCompatPaths, so it can actually see GE-Proton prefixes. The bare
      # `pkgs.protontricks` in systemPackages cannot.
      protontricks.enable = true;
    };
  };
}
