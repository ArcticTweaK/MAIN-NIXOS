{ lib, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  arctic — desktop workstation
#
#  This file is the machine's complete manifest. It should contain nothing but
#  `arctic.*` switches and host-specific facts; if you find yourself writing a
#  raw NixOS option here, that option probably wants to become an `arctic.*`
#  one in modules/nixos/ instead.
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [
    ./hardware.nix
    ./filesystems.nix
  ];

  arctic = {

    # ── Core ────────────────────────────────────────────────────────────────
    core = {
      boot = {
        # FIXME(commit 2): 32G of tmpfs on a 31.2 GiB machine, with the nix
        # daemon building in /tmp. One large Electron build OOMs the box.
        tmpfsSize = "32G";
      };

      nix = {
        # FIXME(commit 2): "arctic" here is root-equivalent via the nix daemon.
        trustedUsers = [ "root" "arctic" ];

        permittedInsecurePackages = [
          # FIXME(commit 2): verified absent from the system closure — nothing
          # needs it (no Matrix client installed).
          "olm-3.2.16"

          # Required by pkgs.ventoy-full-qt, which ships prebuilt binary blobs
          # (nixpkgs#404663). Accepted knowingly: it is only ever run manually
          # to write a bootable USB stick.
          "ventoy-qt5-1.1.12"
        ];
      };

      locale = {
        timeZone = "America/New_York";
        defaultLocale = "en_US.UTF-8";
      };

      users.primary = {
        name = "arctic";
        description = "arctic";

        extraGroups = [
          "wheel" # sudo
          "networkmanager"
          "video"
          "render"
          "audio"
          "input"
          "i2c" # DDC/CI monitor control
          "dialout" # serial devices (Pico)
          "tor"
          "wireshark" # created by arctic.network.tools.capture
          "kvm"
          "libvirtd" # root-equivalent: can pass through host devices
          "docker" # FIXME(commit 4): root-equivalent. Gone with podman.
          "ydotool" # FIXME(commit 2): group does not exist until
          #           programs.ydotool.enable is set
          "storage" # FIXME(commit 2): no such group on NixOS
          "plugdev" # FIXME(commit 2): no such group on NixOS
        ];

        # FIXME(commit 3): "" means EMPTY PASSWORD — anyone at the physical
        # console gets a shell as this wheel/libvirtd user. Replaced with a
        # sops-provided hashedPasswordFile.
        hashedPassword = "";
      };

      packages.database = true; # postgresql
      hardware.android = true; # adb / fastboot / MTP udev
    };

    # ── Desktop ─────────────────────────────────────────────────────────────
    desktop = {
      enable = true;
      plasma = true;
      xserver = true; # keeps an X11 fallback session at the SDDM greeter
      audio.lowLatency = true;
    };

    gpu.nvidia = {
      enable = true;
      open = true; # RTX 3070 Ti is Ampere — open module is correct
      branch = "stable";
      vaapi = true;
    };

    # ── Gaming ──────────────────────────────────────────────────────────────
    gaming = {
      enable = true;
      steam.protonGE = true;
      launchers.minecraft = true;
      launchers.wine = true;
      peripherals.wooting = true;
      peripherals.pico = true;
    };

    # ── Network ─────────────────────────────────────────────────────────────
    network = {
      # FIXME(commit 6): "stable" is still a persistent per-SSID identifier.
      # Moving WiFi to "random" once the DNS/privacy pass lands.
      manager.wifiMacAddress = "stable";
      manager.ethernetMacAddress = "stable";

      firewall = {
        backend = "iptables"; # FIXME(commit 5): -> nftables, after docker goes
        localsend = true; # opens TCP+UDP 53317
        # FIXME(commit 5): rule 1 disappears with docker; rule 2 is redundant,
        # both firewall backends already accept ESTABLISHED,RELATED.
        extraCommands = ''
          iptables -I INPUT -i docker0 -j ACCEPT
          iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        '';
      };

      tor.enable = true; # SOCKS5 on 127.0.0.1:9050 for proxychains/torsocks

      tools = {
        enable = true;
        capture = true; # creates the wireshark group + setcap dumpcap wrapper
        scanning = true;
      };

      # GTA V Online refuses to connect through these BattlEye endpoints on
      # Linux; blackholing them is the standard workaround.
      extraHosts = ''
        0.0.0.0 paradise-s1.battleye.com
        0.0.0.0 test-s1.battleye.com
        0.0.0.0 paradiseenhanced-s1.battleye.com
      '';
    };

    # ── Security ────────────────────────────────────────────────────────────
    security = {
      kernel.hardenSysctl = true;
      kernel.blacklistModules = true;
      sudo.harden = true;
      gpg.enable = true;

      # FIXME(commit 6): each of these is currently non-functional. See the
      # per-module comments — they are fixed or deleted in the hardening pass.
      apparmor.enable = true; # no policies loaded -> confines nothing
      audit.enable = true; # no auditd -> no audit.log, no ausearch
      clamav.enable = true; # daemon resident, nothing ever scans
      fail2ban.enable = true; # jails an sshd that does not exist
      usbguard.enable = false; # and both policies are "allow" anyway

      tools = {
        enable = true;
        crypto = true;
        proton = true;
        opsec = true;
        audit = true;
        offensive = true;
      };
    };

    # ── Virtualisation ──────────────────────────────────────────────────────
    virt = {
      docker.enable = true; # FIXME(commit 4): -> rootless podman
      libvirt.enable = true;
    };

    # ── Applications ────────────────────────────────────────────────────────
    apps = {
      flatpak.enable = true; # required for Sober (Roblox)

      browsers.enable = true;
      dev = {
        enable = true;
        editors = true;
        dotnet = true;
      };
      media = {
        enable = true;
        creation = true;
        server = true;
        torrent = true;
      };
      office.enable = true;
      utilities = {
        enable = true;
        usbTooling = true;
        automation = true;
      };
      reverseEngineering.enable = true;
    };
  };

  # ── home-manager: per-user overrides for this host ──────────────────────────
  home-manager.users.arctic = {
    arctic.dev.git.userEmail = "arctictweak@gmail.com";
    arctic.terminal.kitty.fontSize = lib.mkDefault 19;
  };
}
