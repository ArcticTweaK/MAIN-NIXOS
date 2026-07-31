{ config, lib, ... }:

let
  cfg = config.arctic.desktop.wayland;
  nvidia = config.arctic.gpu.nvidia.enable;
in
{
  options.arctic.desktop.wayland = {
    enable = lib.mkEnableOption "Wayland session environment variables" // { default = true; };
  };

  config = lib.mkIf (config.arctic.desktop.enable && cfg.enable) {
    environment.sessionVariables = {
      # Electron/Chromium apps: use Wayland natively instead of XWayland.
      NIXOS_OZONE_WL = "1";

      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11";

      # Some SDL2 titles pick X11 by default and get worse frame pacing.
      SDL_VIDEODRIVER = "wayland";
    }
    // lib.optionalAttrs nvidia {
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
      LIBVA_DRIVER_NAME = "nvidia";

      # FIXME(commit 2): MOZ_* vars here target a Firefox that is not installed.
      # MOZ_DISABLE_RDD_SANDBOX in particular is read by Tor Browser (which IS
      # Firefox) and disables its media-decode sandbox. Removed in commit 2.
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };
  };
}
