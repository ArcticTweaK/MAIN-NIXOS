{ config, lib, ... }:

let
  cfg = config.arctic.dev.neovim;
in
{
  options.arctic.dev.neovim = {
    enable = lib.mkEnableOption "neovim configuration" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;

      # Explicit rather than inherited from home.stateVersion. These pull in
      # full Ruby and Python interpreters purely for legacy :ruby/:python
      # plugin hosts, which nothing in this config uses.
      withRuby = false;
      withPython3 = false;

      extraConfig = ''
        set number relativenumber
        set tabstop=4 shiftwidth=4 expandtab
        set clipboard=unnamedplus
        set ignorecase smartcase
        set termguicolors
        set undofile
      '';
    };
  };
}
