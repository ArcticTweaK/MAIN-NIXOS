{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS-over-TLS, VPN tooling, network hardening.
#  NOTE: Firewall is now handled by nftables in hosts/nixos/entropy-user.nix
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
      LLMNR      = "false";
      DNS        = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net";
      DNSSEC     = "true";
      DNSOverTLS = "opportunistic";
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
  # Replaced by nftables ruleset in hosts/nixos/entropy-user.nix
  # That ruleset covers: inbound drop-by-default, Docker bridge,
  # established/related, and the entropy transparent Tor proxy + kill switch.
  networking.firewall.enable = false;

  # ─── TOR ─────────────────────────────────────────────────────────────────────
  services.tor = {
    enable        = true;
    client.enable = true;
    settings = {
      DNSPort     = 9053;
      StrictNodes = false;
      # TransPort for entropy's transparent proxy (nftables redirects UID traffic here)
      TransPort   = 9040;
      #SocksListenAddress = "127.0.0.1";
      #SocksPort   = "127.0.0.1:9050";
    };
  };

  # ─── NETWORK TOOLS ───────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # ── Traffic Analysis ──────────────────────────────────────────────────────
    wireshark
    tshark
    tcpdump
    nmap
    netcat-openbsd

    # ── DNS Tools ────────────────────────────────────────────────────────────
    dig
    dog
    dnsx

    # ── VPN / Tunneling ───────────────────────────────────────────────────────
    wireguard-tools
    openvpn
    protonvpn-gui

    # ── Traffic Routing & Proxying ────────────────────────────────────────────
    proxychains-ng
    tor

    # ── HTTP / API Inspection ─────────────────────────────────────────────────
    httpie
    curl

    # ── Monitoring ───────────────────────────────────────────────────────────
    nethogs
    iftop
    iproute2

    cli-tips
    zenmap
  ];
}