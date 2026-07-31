{
  description = "arctic — NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      pkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});

      outputs = self;
      myLib = import ./lib { inherit inputs outputs; };
    in
    {
      overlays = import ./overlays { inherit inputs; };
      packages = forAllSystems (system: import ./pkgs { pkgs = pkgsFor.${system}; });

      # ── Hosts ─────────────────────────────────────────────────────────────
      nixosConfigurations.arctic = myLib.mkHost {
        hostName = "arctic";
        stateVersion = "24.11";
      };

      # ── Reusable module trees, so a future host elsewhere can consume them ─
      nixosModules.default = ./modules/nixos;
      homeManagerModules.default = ./modules/home;

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);

      checks = forAllSystems (_system: {
        # `nix flake check` builds the whole system. This is the check that
        # matters: it catches every eval error, assertion and type mismatch.
        arctic = self.nixosConfigurations.arctic.config.system.build.toplevel;
      });

      devShells = forAllSystems (system: {
        default = pkgsFor.${system}.mkShell {
          name = "nixos-config";
          packages = with pkgsFor.${system}; [
            # formatting / linting
            nixfmt-tree
            statix
            deadnix
            # build ergonomics
            nix-output-monitor
            nvd
            # secrets & boot (used by the README runbook)
            sops
            age
            ssh-to-age
            sbctl
            mkpasswd
          ];
          shellHook = ''
            export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
            echo "nixos-config devshell — fmt | statix check | deadnix | sops secrets/arctic.yaml"
          '';
        };
      });
    };
}
