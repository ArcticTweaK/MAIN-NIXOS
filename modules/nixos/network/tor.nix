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
    services.tor = {
      enable = true;
      client.enable = true;

      # FIXME(commit 2): TransPort/DNSPort open listeners that nothing routes
      # to — transparent proxying needs nat REDIRECT rules that do not exist.
      # StrictNodes without Entry/ExitNodes is documented as a no-op.
      # All three removed in commit 2.
      settings = {
        DNSPort = 9053;
        StrictNodes = false;
        TransPort = 9040;
      };
    };
  };
}
