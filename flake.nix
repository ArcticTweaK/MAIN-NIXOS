{
  description = "Arctic's Master NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Latest drivers/Plasma
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.arctic = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos/configuration.nix
        ./modules/gaming
        ./modules/networking
        ./modules/desktop
        ./modules/misc
      ];
    };
  };
}