{ config, pkgs, lib, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  ENTROPY USER + TRANSPARENT TOR PROXY (nftables)
#  All TCP/UDP traffic from UID entropy is transparently routed through Tor.
#  Kill switch: if Tor is down, traffic from entropy is dropped — never leaks.
# ─────────────────────────────────────────────────────────────────────────────

let
  # !! Must match the actual UID of the entropy user !!
  # Set this explicitly so nftables rules are stable.
  entropyUID = 1001;
in
{
  # ─── USER DECLARATION ────────────────────────────────────────────────────────
  users.users.entropy = {
    isNormalUser = true;
    uid          = entropyUID;
    description  = "entropy";
    shell        = pkgs.zsh;
    extraGroups  = [
      "networkmanager"
      "wheel"
      "wireshark"
      "tor"
      "dialout"
      "docker"
    ];
    hashedPassword = "";  # TODO: set via `passwd entropy` or sops-nix
  };

  # ─── ZSH (must be enabled system-wide for login shell) ───────────────────────
  programs.zsh.enable = true;


  # ─── NFTABLES — TRANSPARENT TOR PROXY FOR ENTROPY USER ───────────────────────
  #
  # Architecture:
  #   entropy process → nftables nat OUTPUT → redirect TCP→9040, UDP/53→9053
  #                   → Tor's TransPort/DNSPort handles the connection
  #
  # Kill switch:
  #   nftables filter OUTPUT: entropy traffic NOT going to loopback → DROP
  #   This means if Tor dies (9040 closed), connections from entropy fail
  #   rather than routing cleartext to the real destination.
  #
  # Exceptions:
  #   - Loopback (127.0.0.0/8): always allowed (Tor, services, local IPC)
  #   - Tor's own process (by UID): never redirected (prevent loop)
  #     NixOS runs tor as "tor" user — get UID with: id -u tor
  #
  # NOTE: This requires `networking.nftables.enable = true`.
  # This REPLACES the iptables firewall in networking.firewall.extraCommands.
  # If you have iptables rules there, migrate them to nftables syntax here.
  # ─────────────────────────────────────────────────────────────────────────────

  networking.nftables.enable = true;

  # Disable the iptables-based firewall (nftables replaces it)
  # The rules below include equivalent inbound DROP-by-default behavior.
  networking.firewall.enable = false;

  networking.nftables.ruleset = ''
    define ENTROPY_UID    = ${toString entropyUID}
    define TOR_TRANS_PORT = 9040
    define TOR_DNS_PORT   = 9053

    table ip nat {
      chain output {
        type nat hook output priority -100; policy accept;

        ip daddr 127.0.0.0/8 return

        meta skuid $ENTROPY_UID udp dport 53 dnat to 127.0.0.1:9053
        meta skuid $ENTROPY_UID tcp dport 53 dnat to 127.0.0.1:9053
        meta skuid $ENTROPY_UID ip protocol tcp dnat to 127.0.0.1:9040
      }
    }

    table ip filter {
      chain input {
        type filter hook input priority 0; policy drop;

        ct state { established, related } accept
        iif "lo" accept
        icmp type { echo-reply, destination-unreachable, echo-request, time-exceeded } accept
        log prefix "[nft-drop-in] " flags all drop
      }

      chain forward {
        type filter hook forward priority 0; policy drop;
        iifname "docker0" accept
        oifname "docker0" accept
      }

      chain output {
        type filter hook output priority 1; policy accept;

        ct state { established, related } accept
        oif "lo" accept
        meta skuid $ENTROPY_UID ct state new drop
      }
    }

    table ip6 filter {
      chain input {
        type filter hook input priority 0; policy drop;
        iif "lo" accept
        ct state { established, related } accept
        icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } accept
      }

      chain forward {
        type filter hook forward priority 0; policy drop;
      }

      chain output {
        type filter hook output priority 0; policy drop;
        oif "lo" accept
        icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } accept
        ct state { established, related } accept
        meta skuid $ENTROPY_UID drop
        accept
      }
    }
  '';

  # ─── HOME MANAGER — wire entropy into flake ──────────────────────────────────
  # (See flake.nix diff below — add this to the home-manager block)
}