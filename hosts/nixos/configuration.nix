{ config, pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  NIXOS SYSTEM — arctic (x86_64-linux)
#  Core: boot, user, kernel hardening, packages, virtualisation.
#  Desktop/gaming/networking/security live in their own modules.
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ─── BOOT ────────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Always track the latest stable kernel for driver & security updates
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.initrd.systemd.enable = true;

  # LUKS encrypted swap partition
  boot.initrd.luks.devices."luks-224f9649-1173-4a89-befc-0807579fa011".device =
    "/dev/disk/by-uuid/224f9649-1173-4a89-befc-0807579fa011";

  # Harden kernel parameters
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
    # Network hardening
    "net.ipv4.conf.all.rp_filter"               = 1;
    "net.ipv4.conf.default.rp_filter"           = 1;
    "net.ipv4.conf.all.accept_redirects"        = 0;
    "net.ipv4.conf.default.accept_redirects"    = 0;
    "net.ipv4.conf.all.send_redirects"          = 0;
    "net.ipv4.tcp_syncookies"                   = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts"      = 1;
    "net.ipv6.conf.all.accept_redirects"        = 0;
    "net.ipv6.conf.default.accept_redirects"    = 0;
    # Prevent kernel pointer leaks
    "kernel.kptr_restrict"                      = 2;
    # Restrict dmesg to root
    "kernel.dmesg_restrict"                     = 1;
    # Disable magic sysrq
    "kernel.sysrq"                              = 0;
    # Prevent ptrace abuse
    "kernel.yama.ptrace_scope"                  = 1;
    # Randomize memory layout
    "kernel.randomize_va_space"                 = 2;
  };

  # Blacklist uncommon/risky kernel modules
  boot.blacklistedKernelModules = [
    "dccp" "sctp" "rds" "tipc"      # Uncommon network protocols
    "cramfs" "freevxfs" "jffs2"     # Uncommon filesystems
    "hfs" "hfsplus" "udf"
    "firewire-core" "thunderbolt"   # DMA attack vectors
  ];
 

  # ─── LOCALIZATION ────────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ─── USER ────────────────────────────────────────────────────────────────────
  users.users.arctic = {
    isNormalUser = true;
    description  = "arctic";
    extraGroups  = [
      "networkmanager" "wheel" "video"
      "libvirtd" "kvm" "docker" "wireshark" "tor"
      "dialout" "i2c" "input" "render" "storage" "audio"
    ];
    # FIX: Must match home-manager shell (fish), not bash.
    # home-manager sets fish as the interactive shell but the login shell
    # must also be fish for it to take effect properly.
    shell = pkgs.fish;
    # IMPORTANT: Set via `passwd arctic` after first boot, or use sops-nix.
    # Do NOT leave this empty on a system exposed to any network.
    hashedPassword = ""; # TODO: replace with `mkpasswd -m sha-512`
  };

  # Enable DDC/CI (Monitor Control)
  hardware.i2c.enable = true;

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  # ─── GLOBAL PACKAGES ─────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
  "olm-3.2.16"
  ];

  environment.systemPackages = with pkgs; [
    # Dev essentials
    git
    gcc
    go
    nodejs_22
    python3
    rustup

    # System utils
    fastfetch
    lm_sensors
    pciutils
    usbutils
    file
    bat
    fd
    ripgrep
    eza
    fzf
    zoxide
    tmux
    libmtp

    # Database
    postgresql_16
  ];
  # To get your phone recognized as a storage device (MTP)
  services.gvfs.enable = true;


  environment.homeBinInPath = true;
  environment.variables = {
    PATH   = [ "$HOME/scripts" "$HOME/.cargo/bin" ];
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  environment.shellAliases = {
    manage    = "bash ~/nixos-config/nix-manage.sh";
    sys-check = "/home/arctic/scripts/sys-check";
    sudo      = "sudo ";
    cls       = "clear";
    ls        = "eza --icons --group-directories-first";
    ll        = "eza -la --icons --group-directories-first";
    cat       = "bat --style=plain";
    grep      = "rg";
    net-scan  = "/home/arctic/scripts/net-scan";
    net-quick = "net-scan quick";
    net-full  = "net-scan full";
    net-net   = "net-scan net";
    net-ls    = "net-scan ls";
  };

  # ─── NIX SETTINGS ────────────────────────────────────────────────────────────
  nix.settings = {
    auto-optimise-store   = true;
    experimental-features = [ "nix-command" "flakes" ];
    sandbox               = true;
    trusted-users         = [ "root" "arctic" ];
    max-jobs              = "auto";
    cores                 = 0;
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      curl
      openssl
      stdenv.cc.cc.lib
    ];
  };

  # ─── VIRTUALISATION ──────────────────────────────────────────────────────────
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable   = true;

  virtualisation.docker = {
    enable          = true;
    enableOnBoot    = false;
    rootless = {
      enable            = true;
      setSocketVariable = true;
    };
  };


  # ─── OPENCLAW ────────────────────────────────────────────────────────────────
  systemd.user.services.openclaw-gateway = {
    description = "OpenClaw Gateway";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "/home/arctic/.npm-global/bin/openclaw gateway run";
      Restart = "on-failure";
      RestartSec = "5s";
      WorkingDirectory = "/home/arctic/.openclaw";
      Environment = [
        "HOME=/home/arctic"
        "OPENCLAW_STATE_DIR=/home/arctic/.openclaw"
        "OPENCLAW_CONFIG_PATH=/home/arctic/.openclaw/openclaw.json"
        "PATH=/home/arctic/.npm-global/bin:/run/current-system/sw/bin"
      ];
      StandardOutput = "append:/tmp/openclaw/openclaw-gateway.log";
      StandardError = "append:/tmp/openclaw/openclaw-gateway.log";
    };
  };

  systemd.tmpfiles.rules = [
    "d /tmp/openclaw 0755 arctic arctic -"
  ];
  system.stateVersion = "24.11";
}
