{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.network.tools;
in
{
  options.arctic.network.tools = {
    enable = lib.mkEnableOption "network diagnostic tooling";

    capture = lib.mkEnableOption ''
      packet capture (Wireshark/tcpdump).

      Enabling this creates the `wireshark` group and installs the setcap
      dumpcap wrapper. Without it, group membership is meaningless and capture
      only works as root
    '';

    captureGui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the Qt GUI rather than just tshark.

        `programs.wireshark.package` defaults to `wireshark-cli`, so leaving
        this off silently downgrades a GUI install to a terminal-only one.
      '';
    };

    scanning = lib.mkEnableOption "nmap and friends";
  };

  config = lib.mkIf cfg.enable {
    programs.wireshark = lib.mkIf cfg.capture {
      enable = true;
      dumpcap.enable = true;
      package = if cfg.captureGui then pkgs.wireshark else pkgs.wireshark-cli;
    };

    environment.systemPackages = with pkgs; [
      # reachability / path
      curl
      dig
      dog
      mtr
      iproute2
      iperf3
      cli-tips

      # throughput / per-process
      nethogs
      iftop

      # tunnels & proxies
      wireguard-tools
      proxychains-ng

      httpie
    ]
    ++ lib.optionals cfg.capture [
      tcpdump
      tshark
    ]
    ++ lib.optionals cfg.scanning [
      nmap
      zenmap
      netcat-openbsd
      dnsx
    ];
  };
}
