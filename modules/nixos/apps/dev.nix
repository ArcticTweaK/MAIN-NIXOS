{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.dev;
in
{
  options.arctic.apps.dev = {
    enable = lib.mkEnableOption "development applications";

    editors = lib.mkEnableOption "GUI editors and IDEs" // { default = true; };
    dotnet = lib.mkEnableOption ".NET SDK";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      kitty # GPU-accelerated terminal (configured in home-manager)
      claude-code
      devtoolbox
    ]
    ++ lib.optionals cfg.editors [
      vscodium
      jetbrains.pycharm
    ]
    ++ lib.optionals cfg.dotnet [
      dotnet-sdk_10
    ];
  };
}
