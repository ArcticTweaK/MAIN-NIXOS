{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # GameMode optimizes your CPU/GPU on the fly
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud             # FPS, Temp, and usage overlay
    protonup-qt          # Easy way to install GE-Proton versions
    lutris               # For everything non-Steam
    heroic               # Epic, GOG, and Amazon Games
    bottles              # Run Windows software in "bottles"
    vulkan-loader
    vulkan-tools
  ];

  # Fix for some games that struggle with high file-handle counts
  security.pam.loginLimits = [{
    domain = "*";
    type = "hard";
    item = "nofile";
    value = "1048576";
  }];
}