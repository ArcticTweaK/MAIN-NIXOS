{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS (AdGuard Home, DoT upstreams), VPN tooling, network hardening.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── NETWORKMANAGER ──────────────────────────────────────────────────────────
  networking.networkmanager = {
    enable = true;
    dns = "none"; # AdGuard Home handles all DNS resolution
    wifi.macAddress = "stable";
    ethernet.macAddress = "stable";

    # ─── STATIC IP FOR ADGUARD HOME (enp4s0) ─────────────────────────────────
    ensureProfiles.profiles = {
      "enp4s0-static" = {
        connection = {
          id = "MAIN Ethernet";
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

  networking.resolvconf.enable = false;

  # This box resolves through its own AdGuard Home instance.
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
    allowedTCPPorts        = [];
    allowedUDPPorts        = [];

    # DNS (53) is only reachable via the LAN-facing interface, not globally —
    # so a future VPN/tun interface never inherits this rule by accident.
    interfaces."enp4s0" = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

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

  # ─── ADGUARD HOME ────────────────────────────────────────────────────────────
  # Web UI: loopback-only (http://127.0.0.1:3000), so no firewall hole is needed for it.
  # DNS: bind_hosts = 0.0.0.0 — binds on every interface present at start time
  # instead of pinning the static LAN IP directly. Pinning 192.168.1.109 caused
  # a "bind: cannot assign requested address" failure at boot even with the
  # address confirmed present — 0.0.0.0 sidesteps whatever that was. Still only
  # reachable from your actual LAN (192.168.1.109:53), not the whole internet.
  services.adguardhome = {
    enable  = true;
    host    = "127.0.0.1";
    port    = 3000;
    openFirewall    = false; # UI never leaves this box
    mutableSettings = true;  # web-UI edits (filter lists, admin user) persist;
                              # everything below still wins on every rebuild

    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port       = 53;

        upstream_dns = [
          "tls://dns.quad9.net"              # primary — filtered-at-source malware/phishing block
          "tls://unfiltered.adguard-dns.com"  # backup — AGH does the filtering, upstream shouldn't double-filter
        ];
        bootstrap_dns = [ "9.9.9.9" "149.112.112.112" ]; # resolves the hostnames above before DoT handshake

        enable_dnssec     = true;
        cache_size        = 4194304; # 4 MiB
        cache_optimistic  = true;
        ratelimit         = 0; # LAN-only server — no need to rate-limit your own devices
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled  = true;
      };

      querylog.enabled   = true; # visibility into what's actually phoning home
      statistics.enabled = true;
    };
  };

  # ─── BATTLEYE BYPASS (GTA V ONLINE) ──────────────────────────────────────────
  networking.extraHosts = ''
    0.0.0.0 paradise-s1.battleye.com
    0.0.0.0 test-s1.battleye.com
    0.0.0.0 paradiseenhanced-s1.battleye.com
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
    mtr      # path latency diagnostics — handy for confirming DNS/VPN isn't the bottleneck
    iperf3   # LAN throughput testing, since "not slow" is one of your actual requirements
  ];
}