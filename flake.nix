{
  description = "Arctic's Master NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager for per-user dotfile/program management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository — extra packages not in nixpkgs
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, home-manager, nur, ... }@inputs: {
    nixosConfigurations.arctic = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.overlays = [ nur.overlays.default ]; }
        ./hosts/nixos/configuration.nix
        ./modules/gaming
        ./modules/networking
        ./modules/desktop
        ./modules/misc
        ./modules/security
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.arctic = import ./home/arctic.nix;
        }
      ];
    };
  };
}
