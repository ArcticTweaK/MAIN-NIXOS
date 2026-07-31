{ config, lib, ... }:

let
  cfg = config.arctic.network.dns;

  providers = {
    quad9 = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
      "2620:fe::fe#dns.quad9.net"
      "2620:fe::9#dns.quad9.net"
    ];
    # Same clean setup, but Mullvad's endpoint also blocks ads and trackers.
    # Swap "base" for "dns" if a blocked domain ever breaks something.
    mullvad = [
      "194.242.2.3#base.dns.mullvad.net"
      "2a07:e340::3#base.dns.mullvad.net"
    ];
    cloudflare = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
      "2606:4700:4700::1111#one.one.one.one"
    ];
  };
in
{
  options.arctic.network.dns = {
    enable = lib.mkEnableOption "systemd-resolved" // { default = true; };

    provider = lib.mkOption {
      type = lib.types.enum [ "quad9" "mullvad" "cloudflare" "custom" ];
      default = "quad9";
      description = ''
        Upstream resolver.

        quad9      Swiss non-profit, blocks known-malicious domains, no logging
        mullvad    also blocks ads/trackers at the resolver
        cloudflare fast, but it is an ad-adjacent company seeing every query
      '';
    };

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Used when provider == "custom".

        Each entry MUST carry the `#hostname` SNI suffix, e.g.
        "9.9.9.9#dns.quad9.net". Without it, strict DNS-over-TLS has no name
        to validate the server certificate against and every lookup fails.
      '';
    };

    overTls = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Strict DNS-over-TLS: encrypted, or the query does not happen.

        The failure mode to know about is captive portals — hotel and airport
        wifi intercept plaintext :53 to show you a login page, and with strict
        DoT that interception simply fails instead of redirecting. Set this to
        false temporarily to get through one.
      '';
    };

    dnssec = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Strict DNSSEC validation.

        Note this is "true", not resolved's "allow-downgrade". Downgrade mode
        silently accepts unvalidated answers whenever the upstream appears not
        to support DNSSEC — which is exactly the state an on-path attacker
        induces, so it validates precisely when nobody is attacking you.
      '';
    };

    mdns = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep multicast DNS for LocalSend and network printers.";
    };

    llmnr = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Link-Local Multicast Name Resolution. Off: it broadcasts this
        machine's hostname to every network you join, is a well-known
        credential-relay vector on Windows-heavy LANs, and nothing here uses it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved = {
      enable = true;

      # NOTE the schema. dnssec/dnsovertls/domains/llmnr/fallbackDns are
      # renamed aliases into settings.Resolve.* in current nixpkgs, and
      # extraConfig was removed outright. The old names still work but warn.
      settings.Resolve = {
        DNS = if cfg.provider == "custom" then cfg.servers else providers.${cfg.provider};

        DNSOverTLS = if cfg.overTls then "true" else "false";
        DNSSEC = if cfg.dnssec then "true" else "false";

        # Route EVERY lookup through the configured servers. Without "~.",
        # a DHCP-supplied resolver wins for any domain it claims, so the ISP
        # router quietly keeps answering despite all of the above.
        Domains = [ "~." ];

        # Empty, deliberately. resolved ships compiled-in Cloudflare and
        # Google fallbacks that it uses in PLAINTEXT when the configured
        # servers fail — a silent escape hatch out of every guarantee here.
        FallbackDNS = [ ];

        MulticastDNS = if cfg.mdns then "yes" else "no";
        LLMNR = if cfg.llmnr then "true" else "false";
      };
    };

    assertions = [
      {
        assertion = cfg.provider == "custom" -> cfg.servers != [ ];
        message = "arctic.network.dns.provider = \"custom\" requires arctic.network.dns.servers.";
      }
      {
        assertion = cfg.overTls -> lib.all (s: lib.hasInfix "#" s)
          (if cfg.provider == "custom" then cfg.servers else providers.${cfg.provider});
        message = ''
          Strict DNS-over-TLS requires every server to carry a #hostname SNI
          suffix for certificate validation, e.g. "9.9.9.9#dns.quad9.net".
        '';
      }
    ];
  };
}
