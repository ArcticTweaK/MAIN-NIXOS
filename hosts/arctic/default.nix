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
      # 50% of RAM, not a fixed 32G. This box has 31.2 GiB and the nix daemon
      # builds in /tmp — a fixed size at ~100% of RAM lets one large Electron
      # or Chromium build take the whole machine down with it.
      boot.tmpfsSize = "50%";

      nix = {
        # root ONLY. A trusted user can set post-build-hook/builders per
        # invocation (the daemon runs them as root) and import unsigned paths
        # into the store, which makes "trusted" a synonym for root.
        # nixos-rebuild is unaffected — it already runs under sudo.
        trustedUsers = [ "root" ];

        permittedInsecurePackages = [
          # Required by pkgs.ventoy-full-qt, which ships prebuilt binary blobs
          # (nixpkgs#404663). Accepted knowingly: it is only ever run manually
          # to write a bootable USB stick.
          #
          # olm-3.2.16 used to be listed here too and was verified absent from
          # the system closure — nothing needed it. Every entry in this list
          # needs a comment like this one, or it outlives its reason.
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

        # NixOS silently DROPS groups that do not exist, so a wrong entry here
        # fails open and looks like it worked. Every group below is asserted
        # to exist by something this config actually enables.
        extraGroups = [
          "wheel" # sudo
          "networkmanager"
          "video"
          "render"
          "audio"
          "input"
          "i2c" # <- hardware.i2c.enable (DDC/CI monitor control)
          "dialout" # serial devices (Pico)
          "tor" # <- services.tor.enable
          "wireshark" # <- programs.wireshark.enable
          "ydotool" # <- programs.ydotool.enable
          "kvm"
          "libvirtd" # root-equivalent: can pass through arbitrary host devices

          # No `docker` group. It was root-equivalent by design and is not
          # needed by rootless podman, which is what replaced it.
        ];

        # FIXME(commit 3): replaced with a sops-provided hashedPasswordFile.
        #
        # null, NOT "". The empty string is not "unset" — it declares an EMPTY
        # PASSWORD, which let anyone at the physical console get a shell as
        # this wheel/libvirtd user. mutableUsers = true means the password set
        # via `passwd` is untouched by this change.
        hashedPassword = null;
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
        backend = "nftables";
        localsend = true; # opens TCP+UDP 53317

        # No extra rules at all. Both rules that used to be here were
        # deletable rather than translatable: the docker0 blanket ACCEPT went
        # with docker, and the ESTABLISHED,RELATED accept was redundant —
        # every NixOS firewall backend already does that in the input chain.
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

      secrets = {
        enable = true;

        # STAGED OFF. Turn this on only after BOTH of:
        #   1. `sops secrets/arctic.yaml` contains real yescrypt hashes
        #      (mkpasswd -m yescrypt) instead of the REPLACE-ME placeholders
        #   2. /var/lib/sops-nix/key.txt exists on this machine, mode 0600 root
        # then rebuild and check `sudo grep '^arctic:' /etc/shadow` BEFORE
        # logging out. See README.md step 3.
        #
        # The placeholders are deliberately not valid hashes, so flipping this
        # early fails closed (nothing authenticates) rather than open.
        managePasswords = false;
      };

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
      podman.enable = true;
      podman.dockerCompat = true; # `docker` and `docker compose` still work
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
