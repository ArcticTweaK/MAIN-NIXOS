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
    ./disko.nix # declares the TARGET layout; inert while useDisko = false
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
      peripherals.logitech = true; # Unifying receiver 046d:c547, see plasma.input.mice
    };

    # ── Network ─────────────────────────────────────────────────────────────
    network = {
      # Fresh MAC per WiFi association. "stable" was still a persistent
      # per-SSID identifier that every AP could log and correlate.
      # Ethernet stays permanent: the cable already identifies the location,
      # and randomising it breaks DHCP reservations for nothing.
      manager.wifiMacAddress = "random";
      manager.ethernetMacAddress = "permanent";

      dns = {
        enable = true;
        provider = "quad9";
        overTls = true; # strict: encrypted or it does not resolve
        dnssec = true; # strict, NOT allow-downgrade
        mdns = true; # LocalSend + network printers
        llmnr = false;
      };

      firewall = {
        backend = "nftables";
        localsend = true; # opens TCP+UDP 53317

        # No extra rules at all. Both rules that used to be here were
        # deletable rather than translatable: the docker0 blanket ACCEPT went
        # with docker, and the ESTABLISHED,RELATED accept was redundant —
        # every NixOS firewall backend already does that in the input chain.
      };

      tor.enable = true; # SOCKS5 on 127.0.0.1:9050 for proxychains/torsocks

      # VPN is the Proton GUI app, not a declarative tunnel — see the comment
      # in modules/nixos/network/default.nix for why.

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
      kernel = {
        hardenSysctl = true;
        hardenParams = true;
        blacklistModules = true;
        ipv6PrivacyExtensions = true;

        # 16 = sync only. NOT 0: with NVIDIA + Wayland, Alt+SysRq is the only
        # clean way out of a wedged compositor, and cutting power to btrfs is
        # worse than the threat sysrq=0 defends against.
        sysrq = 16;

        # The one hardening param that shows up in frametime graphs. Try it
        # and A/B the 1% lows in MangoHud before leaving it on.
        initOnFree = false;
      };

      sudo.harden = true;
      gpg.enable = true;

      secrets = {
        enable = true;

        # ON. Both preconditions are met:
        #   1. secrets/arctic.yaml holds real yescrypt hashes for
        #      arctic-password and root-password (verified $y$j9T$..., 73 ch)
        #   2. /var/lib/sops-nix/key.txt is in place, 0600 root
        #
        # On a fresh install the hash SEEDS the account at creation; with
        # users.mutableUsers = true it is not re-asserted afterwards, so
        # `passwd` still works and survives every rebuild.
        managePasswords = true;
      };

      # OFF, and this is the honest setting rather than a downgrade.
      #
      # AppArmor only loads profiles from security.apparmor.policies;
      # security.apparmor.packages merely adds an #include search path and
      # loads nothing, and upstream apparmor-profiles are keyed on FHS paths
      # (/usr/bin/firefox) that do not exist on NixOS. So `enable = true` with
      # no policies confined NOTHING while looking like coverage.
      #
      # Landlock — which modern applications actually use — is active either
      # way. Turn this on only together with real, hand-written policies.
      apparmor.enable = false;

      audit.enable = true; # now includes the auditd daemon
      clamav.enable = true; # updater + weekly scan, no resident daemon

      # STAGED OFF. Turning this on replaces systemd-boot with lanzaboote and
      # needs a one-time trip into firmware to enroll keys — see README.md
      # step 6. Safe with the NVIDIA module on this system: nixpkgs' kernel
      # has CONFIG_SECURITY_LOCKDOWN_LSM unset, so Secure Boot cannot engage
      # the lockdown that blocks unsigned out-of-tree modules elsewhere.
      secureboot = {
        enable = false;
        autoProvision = true;
        includeMicrosoftKeys = true; # GPU option ROMs are signed by the MS CA
      };

      # fail2ban and usbguard are gone entirely. fail2ban's only jail was
      # sshd and this host runs no sshd; usbguard was disabled and had both
      # policies set to "allow", so it would have blocked nothing either way.

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
      flatpak = {
        enable = true;
        apps = [
          # The whole reason Flatpak is here — Roblox. Not in nixpkgs, and
          # `vinegar` is the Studio wrapper, not this.
          "org.vinegarhq.Sober"

          "com.github.tchx84.Flatseal" # per-app permission editor
          "io.github.flattool.Warehouse" # flatpak data management
          "tv.plex.PlexDesktop"
        ];

        # On. Audited 2026-08-01: the installed set was exactly the four above,
        # so taking authority here removed nothing. It now also prunes unused
        # runtimes (the module ties uninstallUnused to this), which is the only
        # thing that ever grows /var/lib/flatpak unattended.
        #
        # Consequence to keep in mind: `flatpak install` from a terminal is now
        # temporary — the next rebuild reverts it, along with its ~/.var/app
        # data. Add the app ID to the list above instead.
        uninstallUnmanaged = true;
      };

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

    # ── Disk ────────────────────────────────────────────────────────────────
    disk = {
      # THE reinstall flip. false = today's ext4 machine (./filesystems.nix).
      # Set true in the commit you install FROM, then delete filesystems.nix.
      # Do not `nixos-rebuild switch` with this true on the old disk.
      useDisko = true;

      # Staged. Path list written while the live machine was still observable.
      # wipeHome stays false even when this is turned on: /home is its own
      # subvolume, so wiping / alone already proves the config is complete
      # without putting a 119 GB Steam library and a decade of app state
      # behind a list I have to get exactly right.
      impermanence = {
        enable = false;
        wipeHome = false;
      };
    };
  };

  # ── home-manager: per-user overrides for this host ──────────────────────────
  home-manager.users.arctic.arctic = {
    dev.git.userEmail = "arctictweak@gmail.com";
    terminal.kitty.fontSize = lib.mkDefault 19;

    # ── KDE Plasma ────────────────────────────────────────────────────────────
    #  Captured from the live desktop, so applying this is a no-op — it takes
    #  ownership of settings that were already true rather than changing them.
    #  Every key not named here still belongs to System Settings; see the
    #  overrideConfig note in modules/home/desktop/plasma.nix.
    plasma = {
      theme = {
        lookAndFeel = "org.kde.breezedark.desktop";
        colorScheme = "BreezeDark";
        plasmaStyle = "default";

        # Union is the Plasma 6.5+ default widget style, NOT a leftover.
        widgetStyle = "Union";

        # Package comes from modules/nixos/apps/utilities.nix. Naming a theme
        # whose package is not installed silently falls back to Breeze.
        iconTheme = "Papirus";

        soundTheme = "freedesktop";

        # Not set: windowDecoration and splashScreen. The Global Theme above
        # already supplies both (Breeze decorations), and plasma-manager warns
        # against declaring them alongside lookAndFeel — the theme is applied
        # first and can clobber them. Declare them only if you drop
        # lookAndFeel and assemble the parts yourself.

        # Per-screen wallpaper, indexed by Plasma SCREEN NUMBER (not connector).
        # Verified against this machine with `kscreen-doctor -o`:
        #
        #   screen 0 = DP-3, priority 1, 2560x1440@240, rotation normal
        #              -> the main monitor. basement.jpg
        #   screen 1 = DP-4, priority 2, 2560x1440@165, rotation 8 (270°),
        #              geometry 0,0 1440x2560 -> the vertical panel on the LEFT.
        #              blackhole-abyss, whose 3838x7890 is natively portrait.
        #
        # If the wallpapers ever swap monitors the priorities changed — re-run
        # kscreen-doctor and reorder this list rather than editing anything else.
        wallpaper = [
          ../../assets/wallpapers/basement.jpg
          ../../assets/wallpapers/blackhole-abyss-wallpaper.jpg
        ];
      };

      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };

      fonts = {
        family = "Noto Sans";
        monospace = "JetBrainsMono Nerd Font"; # matches kitty + fonts.nix
        size = 10;
      };

      input = {
        mice = [
          {
            # A wireless Logitech: libinput sees the RECEIVER, so that is what
            # the settings key is built from. Confirm after any dongle change:
            #     grep '^\[Libinput' ~/.config/kcminputrc
            name = "Logitech USB Receiver";
            vendorId = "046d"; # 1133 decimal, as kcminputrc writes it
            productId = "c547"; # 50503 decimal

            sensitivity = 0.0; # dead centre of the System Settings slider

            # Flat, i.e. no mouse acceleration: pointer distance stays a fixed
            # multiple of mouse distance regardless of how fast you move. This
            # is the setting that keeps aim consistent in games — do not change
            # it to "default" without meaning to.
            accelerationProfile = "none";
          }
        ];

        # SDDM already does autoNumlock (modules/nixos/desktop/plasma.nix);
        # this is the session's, and they want to agree.
        keyboard.numlockOnStartup = "on";
      };

      behavior = {
        # 0.75 = animations at 3/4 duration. Visible feedback kept, latency cut.
        animationSpeed = 0.75;
        doubleClickInterval = 200;
      };

      kwin = {
        virtualDesktops = {
          number = 1;
          rows = 1;
        };
        tilingPadding = 4;

        # Off. Alt+Tab and the Meta+N task manager bindings already do this,
        # and it fires by accident during fast mouse movement in games.
        effects.shakeCursor = false;
      };

      # This machine is a desktop that is either in use or off, and it is the
      # LUKS passphrase that actually protects it at rest — an idle timer adds
      # interruption without adding much.
      screenLocker = {
        autoLock = false;
        lockOnResume = false;
      };

      extraSettings = {
        # kdeglobals has no plasma-manager wrapper for these two, and they are
        # what makes "Open Terminal Here" in Dolphin open kitty.
        kdeglobals.General.TerminalApplication = "kitty";
        kdeglobals.General.TerminalService = "kitty.desktop";
      };
    };
  };
}
