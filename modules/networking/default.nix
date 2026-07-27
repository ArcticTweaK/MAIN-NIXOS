{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS (NetworkManager + systemd-resolved), VPN tooling, network hardening.
#  NOTE: AdGuard Home removed (was fighting DNS resolution for some apps/games).
#        Re-add later as its own opt-in module if you want it back.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── NETWORKMANAGER ──────────────────────────────────────────────────────────
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";   # hand DNS to resolved instead of overriding it
    wifi.macAddress = "stable";
    ethernet.macAddress = "stable";
    # No static enp4s0 profile anymore — that was pinned specifically for
    # AdGuard Home's bind address. Plain DHCP now, like before AGH existed.
  };

  # ─── SYSTEMD-RESOLVED ────────────────────────────────────────────────────────
  # Built-in resolver. NetworkManager feeds it whatever DNS your router/DHCP
  # or VPN hands out — no manual /etc/resolv.conf pinning anymore.
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
  };

  # ─── HTTP/HTTPS PROXY ────────────────────────────────────────────────────────
  environment.sessionVariables = {
    http_proxy  = "";
    https_proxy = "";
    HTTP_PROXY  = "";
    HTTPS_PROXY = "";
  };

  # ─── FIREWALL ────────────────────────────────────────────────────────────────
  networking.firewall = {
    enable          = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
    # No more interface-scoped port 53 rule — that hole only existed so LAN
    # devices could reach AdGuard Home's DNS server on this box.

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
    proton-vpn
    proxychains-ng
    tor
    httpie
    curl
    nethogs
    iftop
    iproute2
    cli-tips
    zenmap
    mtr
    iperf3
  ];
}
