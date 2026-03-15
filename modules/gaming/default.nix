{ pkgs, config, ... }:

{
  # ─── STEAM ───────────────────────────────────────────────────────────────────
  programs.steam = {
    enable                              = true;
    remotePlay.openFirewall             = false;
    dedicatedServer.openFirewall        = false;
    localNetworkGameTransfers.openFirewall = false;

    # NEW: Extra compat tools available inside Steam
    extraCompatPackages = with pkgs; [
      proton-ge-bin   # GE-Proton baked in — no need for protonup-qt manually
    ];

    # NEW: Required for some anti-cheat and 32-bit games
    gamescopeSession.enable = true;
  };

  # ─── GAMESCOPE ───────────────────────────────────────────────────────────────
  # NEW: Valve's micro-compositor — better frame pacing, FSR upscaling, VRR
  programs.gamescope = {
    enable   = true;
    capSysNice = true;   # Allows gamescope to boost process priority
  };

  # ─── GAMEMODE ────────────────────────────────────────────────────────────────
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice         = 10;        # Boost game process priority
        ioprio         = 0;         # Highest I/O priority
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device              = 0;
        nv_powermizer_mode      = 1;   # Prefer maximum performance (NVIDIA)
        nv_powermizermode_game  = 1;
      };
      cpu = {
        park_cores = "no";
        pin_cores  = "yes";
      };
    };
  };

  # ─── MINECRAFT (Modded) ──────────────────────────────────────────────────────
  # PrismLauncher supports Modrinth, CurseForge, and custom instances
  # Java versions for different MC versions:
  #   MC ≥ 1.17  → Java 17+
  #   MC ≥ 1.20.5 → Java 21
  environment.systemPackages = with pkgs; [
    prismlauncher   # Best modded Minecraft launcher on Linux

    # Java runtimes — PrismLauncher can manage these automatically
    # but having them system-wide avoids duplication
    jdk21           # For MC 1.20.5+
    jdk17           # For MC 1.17–1.20.4

    # Gaming overlay & tools
    mangohud        # FPS, temps, GPU/CPU usage overlay
    lutris          # Universal game launcher (non-Steam)
    heroic          # Epic Games, GOG, Amazon Games
    bottles         # Windows software in isolated bottles

    # Vulkan
    vulkan-loader
    vulkan-tools
    dxvk            # NEW: DirectX → Vulkan translation layer (used by Proton/Wine)

    # Roblox — best approach on Linux is via Sober (Flatpak) or Wine
    # Sober is a native port runtime, install via Flatpak:
    # flatpak install flathub org.vinegarhq.Sober
    # (Listed here as a reminder — handled by flatpak in desktop module)
    wine-wayland    # NEW: Wine with native Wayland rendering
    winetricks      # NEW: Easy Wine prefix setup
  ];

  # ─── PERFORMANCE LIMITS ──────────────────────────────────────────────────────
  security.pam.loginLimits = [
    {
      domain = "*";
      type   = "hard";
      item   = "nofile";
      value  = "1048576";
    }
  ];

  # ─── WOOTING KEYBOARD ────────────────────────────────────────────────────────
  hardware.wooting.enable = true;

  services.udev.extraRules = ''
    # Wooting One Legacy
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
    SUBSYSTEM=="usb",    ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess"

    # Wooting Two Legacy
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
    SUBSYSTEM=="usb",    ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess"

    # Generic Wooting (USB HID)
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
    SUBSYSTEM=="usb",    ATTRS{idVendor}=="31e3", TAG+="uaccess"


    
    # Raspberry Pi Pico (RP2040) — Normal mode
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0005", TAG+="uaccess"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0005", TAG+="uaccess"

    # Raspberry Pi Pico — Bootloader mode (BOOTSEL)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", TAG+="uaccess"
  '';
}
