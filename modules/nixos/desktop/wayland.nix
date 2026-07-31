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

      # Deliberately NOT set here: MOZ_DISABLE_RDD_SANDBOX = "1".
      #
      # It was added to fix VA-API in Firefox, which is not installed. But Tor
      # Browser IS Firefox and does read it — so the only effect it ever had
      # was disabling the media-decode process sandbox in the one browser on
      # this machine where that sandbox matters most. Dead config that was
      # quietly a live regression.
      #
      # MOZ_ENABLE_WAYLAND went with it for the same reason: no Firefox, and
      # Tor Browser manages its own display backend.
    };
  };
}
