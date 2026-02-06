{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  # --- CORE SYSTEM ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;
  
  # LUKS (Keep this here since it's hardware-specific)
  boot.initrd.luks.devices."luks-224f9649-1173-4a89-befc-0807579fa011".device = "/dev/disk/by-uuid/224f9649-1173-4a89-befc-0807579fa011";

  networking.hostName = "arctic";
  networking.networkmanager.enable = true;

  # --- LOCALIZATION ---
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  # (You can keep the extraLocaleSettings here or move to a 'misc' module)

  # --- USER ACCOUNT ---
  users.users.arctic = {
    isNormalUser = true;
    description = "arctic";
    extraGroups = [ "networkmanager" "wheel" "video" ]; # Added 'video' for better GPU access
    packages = with pkgs; [];
  };

  # --- GLOBAL PACKAGES ---
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vscode
    brave
    git
    fastfetch
  ];

  system.stateVersion = "24.11"; 
}