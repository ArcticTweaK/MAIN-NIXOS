{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.browsers;
in
{
  options.arctic.apps.browsers = {
    enable = lib.mkEnableOption "web browsers";

    brave = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Brave, the primary browser.

        Deliberately NOT accompanied by a `programs.chromium.extraOpts` managed
        policy block. Brave Origin is installable from inside Brave itself now,
        which supersedes the hand-written policy JSON that used to live here —
        and managed policy is a worse mechanism anyway, since it silently wins
        over the in-browser UI and drifts from what upstream ships.
      '';
    };

    tor = lib.mkEnableOption "Tor Browser (bundles its own tor daemon)" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ]
      ++ lib.optional cfg.brave brave
      ++ lib.optional cfg.tor tor-browser;
  };
}
