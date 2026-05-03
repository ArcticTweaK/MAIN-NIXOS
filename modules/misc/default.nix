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

    # Browsers
    brave
    google-chrome
    firefox
    # Dev tools
    vscode                  # Code editor

    # Communication
    vesktop                 # Discord with Vencord (better privacy, plugins)
    quaternion                # Matrix client
    
    # Security / privacy — core tools live in security/default.nix
    tor-browser             # Tor Browser (GUI — separate from tor daemon in networking)

    # Media & misc
    prismlauncher           # Modded Minecraft (also in gaming — deduped by Nix)
    vlc                     # Fallback media player

    # Python ecosystem
    python3
    python3Packages.pip

    # Audio control
    pavucontrol             # PulseAudio/PipeWire volume control GUI
    pamixer                 # CLI volume control

    # Terminal
    kitty                   # GPU-accelerated terminal emulator

    # 2FA / identity
    #ente-auth               # GUI TOTP/HOTP manager -- not using rn -- on flatpak

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
    signal-cli              # Signal messenger CLI
    antigravity             # Googles IDE for AI Integration
    ollama                  # Local AI Models
    gnumake                 # default make .file
    hardinfo2               # 
    pixieditor              #
    godot                   #
    dotnet-sdk_10
    protontricks
    ydotool
    crossmacro
    sweethome3d
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
  
  # ─── SERVICES ────────────────────────────────────────────────────────────────
  services.timesyncd.enable = true;   # NTP — keep clock accurate for certs, logs, TOTP
}
