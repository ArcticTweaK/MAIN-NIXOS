{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.desktop.audio;
in
{
  options.arctic.desktop.audio = {
    enable = lib.mkEnableOption "PipeWire audio" // { default = true; };

    lowLatency = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Pin the quantum to 32 samples @ 48 kHz (~0.67 ms).

        Good for games and voice chat. If you get crackling under heavy CPU
        load, this is the first thing to turn off — a starved quantum produces
        xruns, and the fix is a larger buffer, not a faster CPU.
      '';
    };
  };

  config = lib.mkIf (config.arctic.desktop.enable && cfg.enable) {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true; # 32-bit games / Wine audio
      pulse.enable = true;
      jack.enable = true;

      extraConfig.pipewire."92-low-latency" = lib.mkIf cfg.lowLatency {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 32;
          default.clock.min-quantum = 32;
          default.clock.max-quantum = 32;
        };
      };
    };

    # Realtime scheduling privileges — required for the low-latency quantum
    # above to actually be met rather than just requested.
    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      pavucontrol
      pamixer
    ];
  };
}
