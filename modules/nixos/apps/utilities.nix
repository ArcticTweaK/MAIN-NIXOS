{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.utilities;
in
{
  options.arctic.apps.utilities = {
    enable = lib.mkEnableOption "desktop utilities";

    monitoring = lib.mkEnableOption "system monitors" // { default = true; };
    archives = lib.mkEnableOption "archive and sync tools" // { default = true; };
    fileManagers = lib.mkEnableOption "terminal file managers" // { default = true; };
    chat = lib.mkEnableOption "chat clients" // { default = true; };
    usbTooling = lib.mkEnableOption "bootable-USB creation (ventoy)";
    automation = lib.mkEnableOption "input automation (ydotool, macros)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
    ]
    ++ lib.optionals cfg.monitoring [
      btop
      iotop
      hardinfo2
    ]
    ++ lib.optionals (cfg.monitoring && config.arctic.gpu.nvidia.enable) [
      nvtopPackages.nvidia
    ]
    ++ lib.optionals cfg.archives [
      unzip
      p7zip
      rsync
    ]
    ++ lib.optionals cfg.fileManagers [
      yazi
      superfile
    ]
    ++ lib.optionals cfg.chat [
      equibop # Discord client with better Linux/Wayland support
    ]
    ++ lib.optionals cfg.usbTooling [
      ventoy-full-qt
    ]
    ++ lib.optionals cfg.automation [
      ydotool
      crossmacro
    ];
  };
}
