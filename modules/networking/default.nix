{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS-over-TLS, VPN tooling, network hardening.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── NETWORKMANAGER ──────────────────────────────────────────────────────────
  networking.networkmanager = {
    enable = true;
    dns = "none"; # was "systemd-resolved" — resolved is disabled now, AdGuard Home handles DNS
    wifi.macAddress = "stable";
    ethernet.macAddress = "stable";

    # ─── STATIC IP FOR ADGUARD HOME (enp4s0) ─────────────────────────────────
    # Locks 192.168.1.109 so the router's DHCP DNS pointer never breaks.
    # Confirm 192.168.1.1 is actually your gateway via `ip route | grep default`
    # before rebuilding — adjust if different.
    ensureProfiles.profiles = {
      "enp4s0-static" = {
        connection = {
          id = "enp4s0-static";
          type = "ethernet";
          interface-name = "enp4s0";
        };
        ipv4 = {
          method = "manual";
          address1 = "192.168.1.109/24,192.168.1.1";
          dns = "127.0.0.1;";
          ignore-auto-dns = true;
        };
      };
    };
  };

  # ─── DNS-OVER-TLS (systemd-resolved) ─────────────────────────────────────────
  services.resolved = {
    enable = false; # changed for dealing with AdGuardHome
    settings.Resolve = {
      LLMNR       = "false";
      DNS         = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net";
      DNSSEC      = "true";
      DNSOverTLS  = "opportunistic";
      FallbackDNS = "";
    };
  };

  networking.resolvconf.enable = false;

  # This box resolves through its own AdGuard Home instance now.
  environment.etc."resolv.conf" = {
    text = "nameserver 127.0.0.1\n";
  };

  networking.nameservers = [ "127.0.0.1" ];

  # ─── HTTP/HTTPS PROXY ────────────────────────────────────────────────────────
  environment.sessionVariables = {
    http_proxy  = "";
    https_proxy = "";
    HTTP_PROXY  = "";
    HTTPS_PROXY = "";
  };

  # ─── FIREWALL ────────────────────────────────────────────────────────────────
  networking.firewall = {
    enable                = true;
    allowedTCPPorts       = [];
    allowedUDPPorts       = [];
    logRefusedConnections = true;
    logRefusedPackets     = false;
    rejectPackets         = false;
    extraCommands         = ''
      iptables -I INPUT -i docker0 -j ACCEPT
      iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # ─── TOR ─────────────────────────────────────────────────────────────────────
  services.tor = {
    enable        = true;
    client.enable = true;
    settings = {
      DNSPort     = 9053;
      StrictNodes = false;
      TransPort   = 9040;
    };
  };

# ─── AdGuardHome ───────────────
  services.adguardhome = {
  enable = true;
  openFirewall = true;
};

    # ─── BATTLEYE BYPASS (GTA V ONLINE) ──────────────────────────────────────────
  # This blocks the anti-cheat "call home" to allow Invite-Only sessions.
  networking.extraHosts = ''
    0.0.0.0 paradise-s1.battleye.com          # Legacy Edition
    0.0.0.0 test-s1.battleye.com              # Test Servers
    0.0.0.0 paradiseenhanced-s1.battleye.com  # Enhanced Edition (2025/2026)
  '';

  # ─── NETWORK TOOLS ───────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    wireshark
    tshark
    tcpdump
    nmap
    netcat-openbsd
    dig
    dog
    dnsx
    wireguard-tools
    openvpn
    protonvpn-gui
    proxychains-ng
    tor
    httpie
    curl
    nethogs
    iftop
    iproute2
    cli-tips
    zenmap
  ];
}