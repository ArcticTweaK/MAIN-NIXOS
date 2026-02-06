{ ... }: {
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ]; # Add ports for Minecraft/Servers here
    allowedUDPPorts = [ ];
  };
  hardware.bluetooth.enable = false; # Standard for controllers/headphones
}