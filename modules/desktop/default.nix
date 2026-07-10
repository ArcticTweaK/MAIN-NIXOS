{ config, pkgs, ... }:

{
  # ─── DISPLAY SERVER ──────────────────────────────────────────────────────────
  services.xserver.enable = true;

  # ─── KDE PLASMA 6 (Wayland-first) ────────────────────────────────────────────
  services.displayManager.sddm = {
    enable          = true;
    wayland.enable  = true;
    # Use the Breeze theme — clean and system-consistent
    theme           = "breeze";
    autoNumlock     = true;
  };
  services.desktopManager.plasma6.enable = true;

  # ─── NVIDIA ──────────────────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable      = true;
    enable32Bit = true;   # Required for Steam / 32-bit games
  };

  hardware.nvidia = {
    modesetting.enable    = true;
    powerManagement.enable = false;   # Desktop — no need for powersave
    open                  = true;     # Open kernel module (Turing+ GPUs)
    nvidiaSettings        = true;
    package               = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ─── WAYLAND / ELECTRON FIX ──────────────────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL          = "1";   # Force Electron apps to use Wayland
    MOZ_ENABLE_WAYLAND      = "1";   # Force Firefox/Zen to use Wayland
    QT_QPA_PLATFORM         = "wayland;xcb";
    GDK_BACKEND             = "wayland,x11";
    SDL_VIDEODRIVER         = "wayland";   # Helps some SDL games on Wayland
    __GL_GSYNC_ALLOWED      = "1";   # NEW: Enable G-Sync if your monitor supports it
    __GL_VRR_ALLOWED        = "1";   # NEW: Enable VRR (Variable Refresh Rate)
  };

  # ─── FONTS ───────────────────────────────────────────────────────────────────
  # NEW: A solid font set that covers programming, UI, and emoji
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono   # Best programming font
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Noto Sans" ];
        serif     = [ "Noto Serif" ];
      };
    };
  };

  # ─── FLATPAK ─────────────────────────────────────────────────────────────────
  services.flatpak.enable = true;

  # ─── DESKTOP PACKAGES ────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Screenshot / screen tools
    kdePackages.spectacle
    
    # Media
    mpv           # Lightweight, powerful video player
    imv           # Lightweight image viewer

    # Productivity
    obsidian      # Note-taking
    crossmacro    # A Linux Macro
    sweethome3d.application   # A Home Designer 3D & 2D  | Linux Supported
    pixieditor              # a pixel editor for game developers
    godot                   # Game engine (also in gaming — deduped by Nix)
  ];
}
