{ config, lib, ... }:

let
  cfg = config.arctic.dev.git;
in
{
  options.arctic.dev.git = {
    enable = lib.mkEnableOption "git configuration" // { default = true; };

    userName = lib.mkOption {
      type = lib.types.str;
      default = "arctic";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "arctictweak@gmail.com";
      description = ''
        An empty value here makes `git commit` fail outright with
        "unable to auto-detect email address".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };

        alias = {
          lg = "log --oneline --graph --decorate --all";
          st = "status -sb";
          co = "checkout";
          br = "branch";
          undo = "reset --soft HEAD~1";
        };

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.autocrlf = false;
      };
    };
  };
}
