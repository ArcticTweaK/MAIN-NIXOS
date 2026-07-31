{ config, lib, ... }:

let
  cfg = config.arctic.network.vpn.proton;
  secrets = config.arctic.security.secrets;
in
{
  options.arctic.network.vpn.proton = {
    enable = lib.mkEnableOption ''
      a declarative Proton WireGuard tunnel.

      Defined but NOT started by default — see autoStart. Gaming is the reason:
      routing Steam and Roblox through a VPN adds latency for no privacy gain
      on traffic that already identifies you by account
    '';

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Bring the tunnel up at boot.

        Left off so the tunnel is opt-in per session:
          sudo systemctl start  wg-quick-${cfg.interface}
          sudo systemctl stop   wg-quick-${cfg.interface}
      '';
    };

    killSwitch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Drop all non-tunnel egress while the tunnel is up.

        Without this, a tunnel that dies mid-session fails OPEN: traffic
        silently reverts to your ISP and you carry on believing you are
        covered. Implemented with wg-quick's own fwmark rules, which is why
        rp_filter must stay loose.
      '';
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "proton";
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.2.0.2/32" ];
      description = "Interface address from the Proton WireGuard config.";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.2.0.1" ];
      description = ''
        Resolver used while the tunnel is up.

        Proton's in-tunnel resolver, NOT the system DNS-over-TLS setup. Using
        the tunnel's own resolver is what prevents a DNS leak that would
        otherwise reveal every domain you visit to your ISP regardless of the
        tunnel.
      '';
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "203.0.113.10:51820";
      description = "Server Endpoint from the Proton WireGuard config.";
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Server PublicKey. Public by definition — safe in git.";
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "wg-proton-privatekey";
      description = ''
        Name of the sops secret holding the CLIENT private key.

        Never inline the key: this repo is public, and a WireGuard private key
        in git is a permanent identity leak that survives every later rewrite
        of history.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.${cfg.privateKeySecret} = { };

    networking.wg-quick.interfaces.${cfg.interface} = {
      inherit (cfg) address dns;
      autostart = cfg.autoStart;
      privateKeyFile = config.sops.secrets.${cfg.privateKeySecret}.path;

      peers = [
        {
          inherit (cfg) publicKey endpoint;
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          persistentKeepalive = 25; # keeps NAT mappings alive
        }
      ];
    };

    # wg-quick turns AllowedIPs = 0.0.0.0/0 plus a fwmark into a pair of
    # suppress_prefixlength policy rules that blackhole anything not leaving
    # via the tunnel. `table = "auto"` is what enables that path.
    networking.wg-quick.interfaces.${cfg.interface}.table =
      lib.mkIf cfg.killSwitch "auto";

    environment.shellAliases = {
      vpn-up = "sudo systemctl start wg-quick-${cfg.interface}";
      vpn-down = "sudo systemctl stop wg-quick-${cfg.interface}";
      vpn-status = "sudo wg show ${cfg.interface}";
    };

    assertions = [
      {
        assertion = secrets.enable;
        message = ''
          arctic.network.vpn.proton.enable requires
          arctic.security.secrets.enable — the WireGuard private key is read
          from sops and must never be written into this repo in plaintext.
        '';
      }
      {
        assertion = cfg.endpoint != "" && cfg.publicKey != "";
        message = ''
          arctic.network.vpn.proton needs `endpoint` and `publicKey` from the
          WireGuard config you download in the Proton VPN dashboard.
        '';
      }
    ];
  };
}
