{ config, lib, ... }:

let
  cfg = config.arctic.network.firewall;
in
{
  options.arctic.network.firewall = {
    enable = lib.mkEnableOption "the host firewall" // { default = true; };

    backend = lib.mkOption {
      type = lib.types.enum [ "iptables" "nftables" ];
      default = "iptables";
      description = ''
        Firewall backend.

        Switching to "nftables" sets boot.blacklistedKernelModules = [ "ip_tables" ],
        which Docker requires — so Docker must be gone BEFORE the switch, never
        after. It also makes networking.firewall.extraCommands a hard assertion
        failure; the nftables equivalents are extraInputRules/extraForwardRules.
      '';
    };

    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };

    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
    };

    localsend = lib.mkEnableOption ''
      LocalSend.

      Use this rather than just installing the package: the module opens TCP
      and UDP 53317, without which discovery and receive silently fail behind
      the firewall
    '';

    extraCommands = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "iptables-backend only. Incompatible with nftables.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.nftables.enable = cfg.backend == "nftables";

    networking.firewall = {
      enable = true;

      # Loose reverse-path filtering. Strict (1) breaks WireGuard's fwmark
      # policy routing and LAN discovery (LocalSend, Steam Remote Play).
      checkReversePath = "loose";

      inherit (cfg) allowedTCPPorts allowedUDPPorts;

      logRefusedConnections = true;
      logRefusedPackets = false;
      rejectPackets = false;

      extraCommands = lib.mkIf (cfg.backend == "iptables") cfg.extraCommands;
    };

    programs.localsend.enable = cfg.localsend;

    assertions = [
      {
        assertion = cfg.backend == "nftables" -> cfg.extraCommands == "";
        message = ''
          networking.firewall.extraCommands is incompatible with the nftables
          backend. Use networking.firewall.extraInputRules instead.
        '';
      }
    ];
  };
}
