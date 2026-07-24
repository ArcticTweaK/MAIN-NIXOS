{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  MISC MODULE
#  Sound, general system packages, shell/editor programs, services.
#  Note: age, gnupg, keepassxc are declared in security/default.nix — no dupes.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── SOUND (Pipewire) ────────────────────────────────────────────────────────
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;   # Required for 32-bit games / Wine audio
    pulse.enable      = true;
    jack.enable       = true;   # Pro audio / low-latency if needed
    # Low-latency tuning for gaming
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate          = 48000;
        default.clock.quantum       = 32;
        default.clock.min-quantum   = 32;
        default.clock.max-quantum   = 32;
      };
    };
  };

  # Realtime audio priority (needed for low-latency pipewire)
  security.rtkit.enable = true;

  # ─── PACKAGES ────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop                    # Beautiful task manager
    nvtopPackages.nvidia    # GPU monitor
    iotop                   # Disk I/O monitor
    nethogs                 # Per-process network usage (also in networking — deduped by Nix)

    # File management
    unzip
    p7zip                   # 7z support
    rsync                   # Fast file sync / backup
    yazi                    # Blazing fast terminal file manager written in Rust, based on async I/O

    # Browsers
    brave
    librewolf
    tor-browser
    
    # Dev tools
    vscodium                # Open-source VSCode build
    scrcpy                  # Display and control Android devices over USB or TCP/IP


    # Communication
    equibop                 # Custom Discord App aiming to give you better performance and improve linux support (better privacy, plugins)

    # Python ecosystem
    python3
    python3Packages.pip

    # Audio control
    pavucontrol             # PulseAudio/PipeWire volume control GUI
    pamixer                 # CLI volume control

    # Terminal
    kitty                   # GPU-accelerated terminal emulator

    # Reverse engineering / forensics (complement to security module)
    ghidra                  # Reverse engineering suite
    imhex                   # Hex editor for binary analysis

    # Recording
    obs-studio              # Screen recording / streaming

    # IDEs
    jetbrains.pycharm       # Python IDE

    # Misc
    qbittorrent             # BitTorrent client
    popcorntime             # Stream Movies & TV Shows from torrents
    ollama                  # Local AI Models
    gnumake                 # default make .file
    hardinfo2               
    dotnet-sdk_10
    protontricks
    ydotool
    tree
  ];

  # ─── PROGRAMS ────────────────────────────────────────────────────────────────\
  programs.fish = {
    enable = true;
  };

  programs.neovim = {
    enable        = true;
    defaultEditor = true;
    vimAlias      = true;
    viAlias       = true;
  };

  virtualisation.waydroid.enable = true;
  
  # ─── SERVICES ────────────────────────────────────────────────────────────────
  services.timesyncd.enable = true;   # NTP — keep clock accurate for certs, logs, TOTP
}
