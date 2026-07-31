{ config, lib, ... }:

let
  cfg = config.arctic.network.dns;
in
{
  options.arctic.network.dns = {
    enable = lib.mkEnableOption "systemd-resolved" // { default = true; };

    # NOTE: the encrypted-DNS hardening lands in commit 6. This module
    # currently reproduces the existing plaintext behaviour so the scaffold
    # commit is a pure refactor.
    dnssec = lib.mkOption {
      type = lib.types.enum [ "true" "allow-downgrade" "false" ];
      default = "allow-downgrade";
    };
  };

  config = lib.mkIf cfg.enable {
    # NOTE the schema: dnssec/dnsovertls/domains/llmnr/fallbackDns are all
    # renamed aliases into settings.Resolve.* now, and extraConfig is removed
    # outright. Using the old names still works but warns on every eval.
    services.resolved = {
      enable = true;
      settings.Resolve.DNSSEC = cfg.dnssec;
    };

    # The resolved module already points NetworkManager at it; setting
    # networking.networkmanager.dns here would just be a redundant override.
  };
}
