{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NETWORKING MODULE
#  Firewall, DNS-over-TLS, VPN tooling, network hardening.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── NETWORKMANAGER ──────────────────────────────────────────────────────────
  networking.networkmanager = {
    enable = true;
    # Use systemd-resolved for DNS (enables DoT below)
    dns = "systemd-resolved";
    # Stable MAC per network — prevents tracking across APs while keeping
    # a consistent identity per-network (better than random for reconnects)
    wifi.macAddress = "stable";
    ethernet.macAddress = "stable";
  };

  # ─── DNS-OVER-TLS (systemd-resolved) ─────────────────────────────────────────
  # Encrypts DNS queries — prevents ISP/network snooping on hostnames
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC      = "true";          # Validate DNS responses are authentic
      DNSOverTLS  = "opportunistic"; # Encrypt DNS when server supports it
      FallbackDNS = [
        #"9.9.9.9#dns.quad9.net"          # Quad9 — blocks malicious domains
        #"149.112.112.112#dns.quad9.net"  # Quad9 secondary
        #"1.1.1.1#cloudflare-dns.com"     # Cloudflare — fast, privacy-focused
      ];
    };
  };

  # ─── HTTP/HTTPS PROXY ────────────────────────────────────────────────────────
  # System-wide proxy env vars — respected by curl, httpie, most CLI tools,
  # Electron apps, and browsers launched from the shell.
  # Point these at mitmproxy (127.0.0.1:8080) for local interception,
  # or an external proxy IP for routing traffic elsewhere.
  environment.sessionVariables = {
    http_proxy  = "";
    https_proxy = "";
    HTTP_PROXY  = "";  # Uppercase variants for apps
    HTTPS_PROXY = "";  # that don't read lowercase
    #no_proxy    = "";     # Skip proxy for local traffic
    #NO_PROXY    = "";
  };

  # ─── FIREWALL ────────────────────────────────────────────────────────────────
  networking.firewall = {
    enable          = true;
    # Deny all inbound by default — only open what you explicitly need
    allowedTCPPorts = [];
    allowedUDPPorts = [];

    # Log refused packets (useful for auditing unexpected traffic)
    logRefusedConnections = true;
    logRefusedPackets     = false;  # Too noisy — enable only for debugging

    # Drop rather than reject — slower for port scanners, leaks less info
    rejectPackets = false;

    extraCommands = ''
      # Allow traffic from Docker's virtual network interface
      iptables -I INPUT -i docker0 -j ACCEPT
      # Allow responses to connections we initiated (stateful firewall)
      iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # ─── TOR ─────────────────────────────────────────────────────────────────────
  services.tor = {
    enable        = true;
    client.enable = true;
    settings = {
      # Expose a local DNS port that resolves through Tor
      # Point /etc/resolv.conf here or use proxychains for app-level routing
      DNSPort     = 9053;
      # false = Tor picks best relays automatically (recommended)
      StrictNodes = false;
    };
  };

  # ─── NETWORK TOOLS ───────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # ── Traffic Analysis ──────────────────────────────────────────────────────
    wireshark       # GUI packet capture — full protocol dissection, great for deep inspection
    tshark          # CLI version of Wireshark — scriptable, good for automated captures
    tcpdump         # Raw packet dump — lightweight, available everywhere, good for quick grabs
    nmap            # Port/host scanner — service detection, OS fingerprinting, scripting engine
    netcat-openbsd  # nc — TCP/UDP swiss army knife: port testing, file transfer, raw sockets

    # ── DNS Tools ────────────────────────────────────────────────────────────
    dig             # Standard DNS query tool — comes from bind-tools, universally supported
    dog             # Modern dig replacement — coloured output, supports DoH and DoT natively
    dnsx            # Fast bulk DNS resolver/prober — great for recon and validation

    # ── VPN / Tunneling ───────────────────────────────────────────────────────
    wireguard-tools # wg + wg-quick CLI — manage WireGuard tunnels and keypairs
    openvpn         # OpenVPN client — connects to .ovpn config files
    protonvpn-gui   # ProtonVPN GUI client — integrates with ProtonVPN accounts

    # ── Traffic Routing & Proxying ────────────────────────────────────────────
    proxychains-ng  # Force any app through Tor/SOCKS5 — useful for apps that ignore env vars
    tor             # Tor daemon + tooling — anonymising overlay network

    # ── HTTP / API Inspection ─────────────────────────────────────────────────
    httpie          # Modern curl alternative — human-friendly syntax, coloured JSON output
    curl            # Standard HTTP client — universal, scriptable, supports every protocol

    # ── Monitoring ───────────────────────────────────────────────────────────
    nethogs         # Per-process bandwidth usage — see which app is eating your bandwidth
    iftop           # Interface-level traffic monitor — live view of connections and throughput
    iproute2        # ip, ss, tc — modern replacement for ifconfig/netstat/route

    cli-tips        # CLI tool that provides useful tips and commands for Linux users
    zenmap          # Official Nmap GUI — visualise scan results, save profiles
  ];
}