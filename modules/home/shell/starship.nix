{ config, lib, ... }:

let
  cfg = config.arctic.shell.starship;
in
{
  options.arctic.shell.starship = {
    enable = lib.mkEnableOption "the starship prompt" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        format = "$username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";

        username = {
          show_always = true;
          format = "[$user]($style)@";
          style_user = "bold cyan";
        };

        hostname = {
          ssh_only = false;
          format = "[$hostname]($style) ";
          style = "bold green";
        };

        directory = {
          truncation_length = 3;
          style = "bold blue";
        };

        git_branch.style = "bold purple";
        git_status.style = "bold red";

        nix_shell = {
          format = "[$symbol$state]($style) ";
          symbol = "❄️ ";
        };

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };
      };
    };
  };
}
