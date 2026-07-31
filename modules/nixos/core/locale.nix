{ config, lib, ... }:

let
  cfg = config.arctic.core.locale;
in
{
  options.arctic.core.locale = {
    enable = lib.mkEnableOption "locale and timezone" // { default = true; };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;
    i18n.defaultLocale = cfg.defaultLocale;

    # NTP. Accurate time is load-bearing for TLS validation, TOTP codes and
    # log correlation — all three fail confusingly when the clock drifts.
    services.timesyncd.enable = true;
  };
}
