{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.core.packages;
in
{
  options.arctic.core.packages = {
    enable = lib.mkEnableOption "baseline system packages" // { default = true; };

    devEssentials = lib.mkEnableOption "compilers and language runtimes" // { default = true; };
    database = lib.mkEnableOption "postgresql client/server tooling";
  };

  config = lib.mkIf cfg.enable {
    # Deliberately at SYSTEM level rather than home-manager: these are the
    # tools you need in a root shell or a recovery console, where the user
    # profile isn't loaded.
    environment.systemPackages = with pkgs; [
      # core
      git
      file
      tree

      # modern CLI replacements (aliased in home-manager)
      bat
      fd
      ripgrep
      eza
      fzf
      zoxide
      tmux

      # hardware introspection
      fastfetch
      lm_sensors
      pciutils
      usbutils
      libmtp
    ]
    ++ lib.optionals cfg.devEssentials [
      gcc
      gnumake
      nodejs_22
      python3
      python3Packages.pip
    ]
    ++ lib.optionals cfg.database [
      postgresql_16
    ];
  };
}
