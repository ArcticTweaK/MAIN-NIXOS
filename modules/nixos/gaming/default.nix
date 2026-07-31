{ config, lib, ... }:

let
  cfg = config.arctic.gaming;
in
{
  imports = [
    ./steam.nix
    ./performance.nix
    ./launchers.nix
    ./peripherals.nix
  ];

  options.arctic.gaming.enable = lib.mkEnableOption ''
    gaming support.

    This is a master switch: turning it on enables Steam, gamescope, gamemode
    and the launchers below via mkDefault, so a host can still opt out of any
    single one on the next line
  '';

  config = lib.mkIf cfg.enable {
    arctic.gaming = {
      steam.enable = lib.mkDefault true;
      gamescope.enable = lib.mkDefault true;
      gamemode.enable = lib.mkDefault true;
      launchers.enable = lib.mkDefault true;
    };

    assertions = [
      {
        # Steam's pressure-vessel runtime and flatpak/bwrap (i.e. Sober, which
        # is how Roblox runs here) both need unprivileged user namespaces.
        # Disabling them is the single most common way a "hardened" NixOS
        # config silently breaks every Proton title on the machine.
        assertion = config.security.allowUserNamespaces;
        message = ''
          arctic.gaming.enable requires unprivileged user namespaces
          (Steam pressure-vessel, flatpak/bwrap for Sober/Roblox).
          Do not set security.allowUserNamespaces = false.
        '';
      }
    ];
  };
}
