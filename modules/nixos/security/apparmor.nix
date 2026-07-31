{ config, lib, ... }:

let
  cfg = config.arctic.security.apparmor;
in
{
  options.arctic.security.apparmor = {
    enable = lib.mkEnableOption ''
      the AppArmor LSM.

      Read this before turning it on. AppArmor only loads profiles declared via
      `security.apparmor.policies.<name>`; `security.apparmor.packages` merely
      adds an #include search path and loads nothing. And the upstream
      `pkgs.apparmor-profiles` set is keyed on FHS paths (/usr/bin/firefox)
      that do not exist on NixOS.

      So `enable = true` with no policies confines NOTHING — it costs an
      apparmor=1 kernel flag and buys the false impression of coverage.
      Landlock (which modern applications actually use) is active either way.

      Turn this on only alongside real, hand-written policies
    '';
  };

  config = lib.mkIf cfg.enable {
    security.apparmor = {
      enable = true;
      killUnconfinedConfinables = false;
    };
  };
}
