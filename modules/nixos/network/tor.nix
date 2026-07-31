{ config, lib, ... }:

let
  cfg = config.arctic.network.tor;
in
{
  options.arctic.network.tor = {
    enable = lib.mkEnableOption ''
      the Tor client daemon.

      This provides a SOCKS5 proxy on 127.0.0.1:9050 for torsocks/proxychains.
      It is NOT system-wide anonymisation: nothing is routed through it unless
      an application is explicitly pointed at the SOCKS port.

      Tor Browser bundles its own tor and does not need this
    '';
  };

  config = lib.mkIf cfg.enable {
    # SOCKS5 on 127.0.0.1:9050 and nothing else.
    #
    # Deliberately no TransPort/DNSPort: those open listeners that only do
    # something if nat REDIRECT rules point traffic at them, and no such rules
    # exist here. Two idle ports that look like transparent proxying but
    # aren't is worse than not having them — it invites you to believe traffic
    # is going through Tor when it is going straight out.
    #
    # StrictNodes is likewise omitted: without ExitNodes/EntryNodes/
    # ExcludeNodes it is documented as having no effect either way.
    services.tor = {
      enable = true;
      client.enable = true;
    };
  };
}
