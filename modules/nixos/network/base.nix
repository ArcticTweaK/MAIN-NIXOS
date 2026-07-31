{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.network;
in
{
  options.arctic.network = {
    manager.enable = lib.mkEnableOption "NetworkManager" // { default = true; };

    manager.wifiMacAddress = lib.mkOption {
      type = lib.types.enum [ "preserve" "permanent" "random" "stable" ];
      default = "random";
      description = ''
        WiFi MAC policy.

        "random" gives a fresh MAC per association — the right default, since a
        stable MAC is a persistent identifier every AP you ever join can log and
        correlate. "stable" is per-network but still trackable across
        reconnects to the same SSID.
      '';
    };

    manager.ethernetMacAddress = lib.mkOption {
      type = lib.types.enum [ "preserve" "permanent" "random" "stable" ];
      default = "permanent";
      description = ''
        Ethernet MAC policy.

        Left at "permanent": randomising a wired MAC gains ~nothing (the cable
        already identifies the physical location) and breaks DHCP reservations,
        port security and some ISP provisioning.
      '';
    };

    extraHosts = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Appended to /etc/hosts.";
    };
  };

  config = lib.mkIf cfg.manager.enable {
    networking.networkmanager = {
      enable = true;
      wifi.macAddress = cfg.manager.wifiMacAddress;
      ethernet.macAddress = cfg.manager.ethernetMacAddress;

      plugins = with pkgs; [ networkmanager-openvpn ];
    };

    networking.extraHosts = cfg.extraHosts;
  };
}
