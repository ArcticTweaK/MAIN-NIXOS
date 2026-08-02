{ config, lib, ... }:

let
  cfg = config.arctic.security.kernel;
  virt = config.arctic.virt.libvirt.enable;
in
{
  options.arctic.security.kernel = {
    hardenSysctl = lib.mkEnableOption "hardened sysctl values" // { default = true; };
    hardenParams = lib.mkEnableOption "hardened boot.kernelParams" // { default = true; };
    blacklistModules = lib.mkEnableOption "blacklisting rarely-used protocol/filesystem modules" // { default = true; };

    disableRadios = lib.mkEnableOption ''
      blacklisting the WiFi and Bluetooth drivers outright.

      Off by default, unlike blacklistModules above: that list is safe
      anywhere, this one is a statement about a specific machine. Correct for
      a desktop that lives on Ethernet, wrong for anything that leaves the
      desk — so it is opted into per host, never assumed.

      This is what Plasma's airplane mode only looks like it does. That toggle
      drives NetworkManager for WiFi and BlueZ for Bluetooth, so on a host with
      no bluetoothd the Bluetooth half silently no-ops: `nmcli radio all` reads
      disabled while `rfkill list` still shows hci0 unblocked and powered
    '';

    sysrq = lib.mkOption {
      type = lib.types.int;
      default = 16;
      example = 0;
      description = ''
        Value for kernel.sysrq.

        Do NOT set 0 on this machine. With an out-of-tree GPU driver and a
        Wayland compositor, Alt+SysRq is the only clean way out of a wedged
        session — and cutting power to a btrfs filesystem is a worse outcome
        than the local-attacker scenario sysrq=0 defends against.

          0   disabled
          16  sync only (default here)
          176 sync + remount-ro + reboot
          1   everything
      '';
    };

    initOnFree = lib.mkEnableOption ''
      init_on_free=1, which zeroes pages as they are freed.

      Off by default: of every hardening parameter here this is the one that
      shows up in frametime graphs, because games are allocation-heavy. Turn
      it on and A/B the 1% lows in MangoHud before keeping it
    '';

    ipv6PrivacyExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        IPv6 privacy extensions (RFC 4941), via networking.tempAddresses.

        Without these the IPv6 address embeds a stable interface identifier
        that follows you across every network and site — a supercookie no
        browser setting can clear.

        Note this is already NixOS's default whenever IPv6 is enabled; it is
        set explicitly here so the property is visible rather than inherited.
        Do NOT implement it as a raw net.ipv6.conf.*.use_tempaddr sysctl —
        network-interfaces.nix already defines those and you get a
        "defined multiple times" eval error.
      '';
    };
  };

  config = lib.mkMerge [

    # ── sysctl ─────────────────────────────────────────────────────────────
    (lib.mkIf cfg.hardenSysctl {
      boot.kernel.sysctl = {
        # ── network ────────────────────────────────────────────────────────
        # rp_filter stays at 2 (loose). Strict (1) breaks WireGuard's fwmark
        # policy routing and LAN discovery (LocalSend, Steam Remote Play).
        "net.ipv4.conf.all.rp_filter" = 2;
        "net.ipv4.conf.default.rp_filter" = 2;

        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;

        # Deliberately NOT setting net.ipv6.conf.all.accept_ra = 0. It appears
        # in most hardening lists, but on a machine that gets IPv6 by SLAAC
        # from the router it means no IPv6 address at all — and it would
        # contradict the privacy extensions below, which only apply to
        # addresses RA gives you in the first place.

        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_rfc1337" = 1; # drop RFC1337 TIME-WAIT assassination
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.conf.all.log_martians" = 1;

        # Bigger socket buffers: helps Steam download throughput and
        # WireGuard, costs nothing.
        "net.core.rmem_max" = 7500000;
        "net.core.wmem_max" = 7500000;

        # ── kernel ─────────────────────────────────────────────────────────
        "kernel.kptr_restrict" = 2; # hide kernel pointers, even from root
        "kernel.dmesg_restrict" = 1; # `sudo dmesg` still works
        "kernel.kexec_load_disabled" = 1; # no live kernel replacement
        "kernel.randomize_va_space" = 2;
        "kernel.sysrq" = cfg.sysrq;

        # 1 (restricted) not 2/3: 2 and 3 break gdb, RenderDoc and Nsight.
        "kernel.yama.ptrace_scope" = 1;

        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
        "dev.tty.ldisc_autoload" = 0;

        # ── filesystem ─────────────────────────────────────────────────────
        "fs.protected_hardlinks" = 1;
        "fs.protected_symlinks" = 1;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
        "fs.suid_dumpable" = 0;

        # ── memory ─────────────────────────────────────────────────────────
        # Low swappiness suits a 31 GiB desktop: keep pages resident rather
        # than paging out under game load.
        "vm.swappiness" = 10;
      };

      # "default" == prefer temporary addresses for outgoing connections.
      # Goes through the NixOS option, not a raw sysctl — see the option docs.
      networking.tempAddresses = lib.mkIf cfg.ipv6PrivacyExtensions "default";

      # NOT set, each for a specific reason. Please don't helpfully add them:
      #
      #   kernel.unprivileged_userns_clone
      #       A Debian/hardened-kernel patch that does not exist on nixpkgs'
      #       kernel. It was set here for a long time and every boot logged
      #       "Couldn't write '1' to 'kernel/unprivileged_userns_clone'".
      #       Use security.unprivilegedUsernsClone on a patched kernel.
      #
      #   user.max_user_namespaces = 0 / security.allowUserNamespaces = false
      #       Breaks Steam's pressure-vessel runtime (most Proton titles),
      #       flatpak/bwrap (i.e. Sober, i.e. Roblox), and nix's build sandbox
      #       (nixpkgs has an explicit assertion for that last one).
      #
      #   vm.max_map_count
      #       nixpkgs already sets 1048576 via mkDefault. Never lower it:
      #       several DX12/Proton titles hard-fail below ~262144.
      #
      #   kernel.perf_event_paranoid = 3
      #       Breaks perf, intel_gpu_top and GPU profilers. MangoHud is
      #       unaffected (Vulkan layer + NVML), but it is a bad trade on a
      #       single-user desktop.

      # PAM's core limit does not bind systemd-coredump, which happily writes
      # crash dumps containing decrypted secrets and session keys to disk.
      systemd.coredump.enable = false;
    })

    # ── kernel command line ────────────────────────────────────────────────
    (lib.mkIf cfg.hardenParams {
      boot.kernelParams = [
        "slab_nomerge" # blocks cross-cache heap-spray techniques
        "init_on_alloc=1" # kills a large class of uninit-memory bugs
        "page_alloc.shuffle=1" # freelist randomisation
        "randomize_kstack_offset=on" # per-syscall kernel stack offset
        "vsyscall=none" # only affects pre-2013 static 64-bit binaries
      ]
      ++ lib.optional cfg.initOnFree "init_on_free=1"
      ++ lib.optional virt "iommu=pt";

      # NOT set:
      #   lockdown=confidentiality  CONFIG_SECURITY_LOCKDOWN_LSM is not set in
      #                             nixpkgs' kernel — the parameter is inert.
      #   module.sig_enforce=1      CONFIG_MODULE_SIG is not set — inert, and
      #                             logs "Unknown kernel command line parameters".
      #   debugfs=off               breaks ftrace/perf/bpftrace for negligible
      #                             gain against a threat model with no local
      #                             attacker.
      #   nosmt                     halves throughput on a 12600K to defend
      #                             against cross-HT side channels that need a
      #                             hostile co-tenant, which a desktop has not.
      #   mitigations=off           the opposite of hardening. Listed only
      #                             because gaming guides push it.
    })

    # ── module blacklist ───────────────────────────────────────────────────
    (lib.mkIf cfg.blacklistModules {
      boot.blacklistedKernelModules = [
        # uncommon network protocols, all with a history of CVEs
        "dccp"
        "sctp"
        "rds"
        "tipc"
        # uncommon filesystems — auto-mount of a crafted image is the risk
        "cramfs"
        "freevxfs"
        "jffs2"
        "hfs"
        "hfsplus"
        # DMA attack surface
        "firewire-core"
      ];

      # Deliberately NOT blacklisted, both of which used to be:
      #   udf          needed to mount UDF optical media and some game ISOs
      #   thunderbolt  this Z690 board exposes USB4/TB4 headers; blacklisting
      #                the module silently kills those ports
    })

    # ── radios ─────────────────────────────────────────────────────────────
    (lib.mkIf cfg.disableRadios {
      boot.blacklistedKernelModules = [
        "iwlwifi" # CNVi WiFi; iwlmvm is loaded by it and dies with it
        "btusb" # the AX201's Bluetooth side, which sits on USB 8087:0026
      ];

      # Recovery does NOT need a rebuild. NixOS writes a plain `blacklist` line
      # into /etc/modprobe.d/nixos.conf, which only stops udev autoloading — an
      # explicit modprobe still works, so a phone hotspot is two commands away
      # even from a TTY with no network:
      #     sudo modprobe iwlwifi && nmcli radio wifi on
      #
      # USB tethering is unaffected either way. That is a cdc_ncm/rndis gadget,
      # not a radio, and it never touches rfkill — so the common "I need mobile
      # data" case does not require undoing any of this.

      # NOT blacklisted, because neither is a radio:
      #   hid-logitech-hidpp  the Unifying/Lightspeed receiver is proprietary
      #                       2.4 GHz over its own dongle, not Bluetooth
      #   snd-usb-audio       likewise for the Arctis Pro Wireless base station
    })

    # ── assertions ─────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = (config.boot.kernel.sysctl."vm.max_map_count" or 1048576) >= 262144;
          message = "vm.max_map_count below 262144 breaks several Proton titles.";
        }
      ];

      warnings = lib.optional (cfg.hardenSysctl && cfg.sysrq == 0) ''
        arctic.security.kernel.sysrq = 0 disables the Alt+SysRq escape hatch.
        On NVIDIA + Wayland that is the only clean recovery from a wedged
        compositor. Consider 16 (sync) or 176 (sync+remount-ro+reboot).
      '';
    }
  ];
}
