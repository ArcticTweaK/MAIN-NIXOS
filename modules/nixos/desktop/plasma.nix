{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.desktop;
in
{
  options.arctic.desktop = {
    enable = lib.mkEnableOption "a graphical desktop";

    plasma = lib.mkEnableOption "KDE Plasma 6" // { default = true; };

    xserver = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run the X server alongside Wayland.

        Not required for a Wayland-only Plasma session — XWayland comes from
        plasma6 itself. Keep it on only if you want an X11 fallback session
        selectable at the SDDM greeter (useful when a driver update breaks
        Wayland). Turning it off shrinks the closure.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.plasma) {
    services.xserver.enable = cfg.xserver;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
      autoNumlock = true;
    };

    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.spectacle
    ];
  };
}
