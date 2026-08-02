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

    speech = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Text-to-speech (speech-dispatcher).

        plasma6 enables this by default, and it is the single largest thing in
        this system's closure that nothing here asked for: speech-dispatcher
        pulls mbrola, which pulls mbrola-voices at ~676 MB of recorded
        diphones. Nothing in this config speaks.

        Turn it back on if you want a screen reader (Orca), KDE's "Speak Text"
        actions, or any accessibility TTS — those genuinely need it, and 676 MB
        is a bad reason to go without if you do.
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

    # Orca is the real switch, not speechd. plasma6 sets `services.orca.enable`
    # to mkDefault true, and the orca module then turns on speechd itself — so
    # disabling speechd alone gets silently re-enabled and keeps the screen
    # reader installed anyway. Note orca is NOT in plasma6's `optionalPackages`,
    # so `environment.plasma6.excludePackages` does not reach it either.
    #
    # A plain assignment is enough here: it outranks the mkDefault upstream.
    services.orca.enable = cfg.speech;

    # Belt and braces, and the thing that actually drops mbrola-voices: orca is
    # the only reason speechd was on, but pin it so a future module quietly
    # enabling speechd cannot pull ~700 MB of diphones back in unnoticed.
    services.speechd.enable = lib.mkForce cfg.speech;

    environment.systemPackages = with pkgs; [
      kdePackages.spectacle
    ];
  };
}
