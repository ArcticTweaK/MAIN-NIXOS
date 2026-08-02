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
    # Use the module, not the bare package: it runs the ydotoold daemon and
    # creates the `ydotool` group, without which the group listed in the
    # user's extraGroups does not exist and membership means nothing.
    programs.ydotool.enable = cfg.automation;

    # papirus-icon-theme moved to modules/nixos/desktop/themes.nix — an icon
    # theme belongs next to the module that selects it, not in "utilities".
    environment.systemPackages = with pkgs;
    lib.optionals cfg.monitoring [
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
      crossmacro
    ];
  };
}
