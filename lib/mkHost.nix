{ inputs, outputs }:

# ─────────────────────────────────────────────────────────────────────────────
#  mkHost — the single place where a machine is assembled.
#
#  Everything that is true for EVERY host lives here: the nixpkgs instance,
#  overlays, third-party NixOS modules, home-manager wiring. A host file
#  (hosts/<name>/default.nix) should contain nothing but `arctic.*` switches
#  and facts specific to that machine.
#
#  Adding a second machine is therefore:
#      nixosConfigurations.laptop = myLib.mkHost {
#        hostName = "laptop"; stateVersion = "25.05";
#      };
#  plus a hosts/laptop/ directory.
# ─────────────────────────────────────────────────────────────────────────────

{ hostName
, system ? "x86_64-linux"
, stateVersion
, homeStateVersion ? stateVersion
, users ? [ "arctic" ]
, extraModules ? [ ]
}:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs outputs hostName system; };

  modules = [
    # ── nixpkgs instance + host identity ────────────────────────────────────
    {
      nixpkgs.hostPlatform = system;
      nixpkgs.overlays = [
        inputs.nur.overlays.default
        outputs.overlays.additions
        outputs.overlays.modifications
      ];

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    }

    # ── third-party modules (all inert until their options are set) ─────────
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.impermanence.nixosModules.impermanence

    # ── our option modules ──────────────────────────────────────────────────
    ../modules/nixos

    # ── the host itself ─────────────────────────────────────────────────────
    ../hosts/${hostName}

    # ── home-manager ────────────────────────────────────────────────────────
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        # Without this, activation HARD-FAILS on a fresh install the moment any
        # unmanaged dotfile exists (~/.config/fish/config.fish, ~/.gitconfig,
        # ~/.config/kitty/kitty.conf all qualify). Reproducibility depends on it.
        backupFileExtension = "hm-bak";

        extraSpecialArgs = { inherit inputs outputs hostName; };

        sharedModules = [
          ../modules/home
          { home.stateVersion = homeStateVersion; }
        ];

        users = inputs.nixpkgs.lib.genAttrs users (user: {
          home.username = user;
          home.homeDirectory = "/home/${user}";
        });
      };
    }
  ] ++ extraModules;
}
