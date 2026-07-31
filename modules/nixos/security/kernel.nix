{ config, lib, ... }:

let
  cfg = config.arctic.security.kernel;
in
{
  options.arctic.security.kernel = {
    hardenSysctl = lib.mkEnableOption "hardened sysctl values" // { default = true; };
    blacklistModules = lib.mkEnableOption "blacklisting rarely-used protocol/filesystem modules" // { default = true; };
  };

  # NOTE: the full kernel hardening pass (boot.kernelParams, the extended
  # sysctl set, the gaming-safety assertions) lands in commit 6. This file
  # currently reproduces the pre-existing values verbatim so that the scaffold
  # commit is a pure refactor with no behaviour change.
  config = lib.mkMerge [
    (lib.mkIf cfg.hardenSysctl {
      boot.kernel.sysctl = {
        # FIXME(commit 6): hardened-kernel-only sysctl, no-op on nixpkgs'
        # vanilla kernel. Logs "Couldn't write ... ignoring" every boot.
        "kernel.unprivileged_userns_clone" = 1;

        # network
        "net.ipv4.conf.all.rp_filter" = 2;
        "net.ipv4.conf.default.rp_filter" = 2;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # kernel
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.sysrq" = 0;
        "kernel.yama.ptrace_scope" = 1;
        "kernel.randomize_va_space" = 2;
      };
    })

    (lib.mkIf cfg.blacklistModules {
      boot.blacklistedKernelModules = [
        # uncommon network protocols
        "dccp"
        "sctp"
        "rds"
        "tipc"
        # uncommon filesystems
        "cramfs"
        "freevxfs"
        "jffs2"
        "hfs"
        "hfsplus"
        "udf"
        # DMA attack surface
        "firewire-core"
        "thunderbolt"
      ];
    })
  ];
}
