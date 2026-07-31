{ config, lib, ... }:

let
  cfg = config.arctic.network.firewall;
in
{
  options.arctic.network.firewall = {
    enable = lib.mkEnableOption "the host firewall" // { default = true; };

    backend = lib.mkOption {
      type = lib.types.enum [ "iptables" "nftables" ];
      default = "nftables";
      description = ''
        Firewall backend.

        "nftables" sets boot.blacklistedKernelModules = [ "ip_tables" ], which
        Docker requires — so Docker must be gone BEFORE the switch, never
        after. It also makes networking.firewall.extraCommands a hard
        assertion failure; the equivalents are extraInputRules and
        extraForwardRules, which exist ONLY in this backend (a one-way door).

        Podman and libvirt both detect nftables and configure netavark and
        their own firewall backend accordingly — nothing to do by hand.
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

    extraInputRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "nftables-backend only. Raw nft rules for the input chain.";
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

      # Off: on a desktop this is mostly broadcast/mDNS/SSDP chatter from the
      # LAN, and a journal full of noise is a journal nobody reads.
      logRefusedConnections = false;
      logRefusedPackets = false;

      # DROP rather than REJECT — no ICMP unreachable back to a scanner.
      rejectPackets = false;

      extraCommands = lib.mkIf (cfg.backend == "iptables") cfg.extraCommands;
      extraInputRules = lib.mkIf (cfg.backend == "nftables") cfg.extraInputRules;
    };

    programs.localsend.enable = cfg.localsend;

    assertions = [
      {
        assertion = cfg.backend == "nftables" -> cfg.extraCommands == "";
        message = ''
          arctic.network.firewall.extraCommands is incompatible with the
          nftables backend. Use extraInputRules instead.
        '';
      }
      {
        # nftables blacklists the ip_tables module, which dockerd needs.
        # Getting this order backwards leaves docker unable to set up any
        # container networking, and the failure is not obviously firewall-shaped.
        assertion = cfg.backend == "nftables" -> !config.virtualisation.docker.enable;
        message = ''
          The nftables backend blacklists the ip_tables kernel module, which
          Docker requires. Remove virtualisation.docker before switching the
          firewall backend, not after.
        '';
      }
    ];
  };
}
