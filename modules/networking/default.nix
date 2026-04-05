{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS-over-TLS, VPN tooling, network hardening.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── NETWORKMANAGER ──────────────────────────────────────────────────────────
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    wifi.macAddress = "stable";
    ethernet.macAddress = "stable";
    settings."global-dns-domain-*".servers = "9.9.9.9,149.112.112.112";
  };

  # ─── DNS-OVER-TLS (systemd-resolved) ─────────────────────────────────────────
  services.resolved = {
    enable = true;
    settings.Resolve = {
      LLMNR       = "false";
      DNS         = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net";
      DNSSEC      = "true";
      DNSOverTLS  = "opportunistic";
      FallbackDNS = "";
    };
  };

  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";

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