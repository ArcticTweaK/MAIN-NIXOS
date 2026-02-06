{ pkgs, ... }:

{
  # Nix settings & Experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Auto Garbage Collection (Keeps your boot menu clean)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Sound (Pipewire is the modern standard)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Essential "Misc" tools
  environment.systemPackages = with pkgs; [
    btop      # Better task manager
    nvtopPackages.nvidia # GPU monitor
    unzip
    pciutils
  ];
}