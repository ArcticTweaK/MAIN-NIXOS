{ config, lib, ... }:

let
  cfg = config.arctic.disk.impermanence;
  user = config.arctic.core.users.primary.name;
in
{
  options.arctic.disk.impermanence = {
    enable = lib.mkEnableOption ''
      an ephemeral root.

      @root is rolled back to a blank btrfs snapshot on every boot, so
      anything not declared in this config or listed below simply vanishes.
      That is the strongest possible proof the config is complete: config
      drift cannot accumulate because there is nowhere for it to accumulate.

      STAGED OFF. The path list below was written while the live machine was
      still observable — reconstructing it after a wipe is how people lose
      things. Turn it on only after the reinstall, and expect a few rounds of
      "oh, that needed persisting"
    '';

    root = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Subvolume that survives the rollback.";
    };

    wipeHome = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Also wipe /home, persisting only the user directories listed below.

        Default false, and that is the recommended setting for this machine.
        /home is its own btrfs subvolume, so wiping / alone already gives you
        the reproducibility guarantee for system state (/etc, /var, /srv)
        while leaving user data alone.

        Turning this on means every unlisted dotfile is gone on reboot. On a
        box with a 119 GB Steam library and a decade of accumulated app state,
        the failure mode is losing something you did not know you had, and the
        marginal security gain over an encrypted disk is small.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # /persist must be mounted before anything tries to bind-mount out of it.
    fileSystems.${cfg.root}.neededForBoot = true;

    environment.persistence.${cfg.root} = {
      hideMounts = true;

      directories = [
        # ── Identity and boot. Losing these breaks the machine, not just an
        #    app: uid/gid allocations, the Secure Boot keys and the age key
        #    that decrypts every secret in this repo.
        "/var/lib/nixos"
        "/var/lib/sbctl"
        "/var/lib/sops-nix"

        "/var/lib/systemd" # timer stamps, random seed
        "/var/lib/private" # systemd DynamicUser state
        "/var/lib/machines"

        # ── Network. Without this every WiFi PSK is gone on each boot.
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
        "/var/lib/bluetooth"
        "/var/lib/nftables" # deletions.nft, included by the firewall

        # ── Services that hold real state
        "/var/lib/flatpak" # system flatpak install; tens of GB
        "/var/lib/containers" # podman images and volumes
        "/var/lib/libvirt" # VM definitions and disks
        "/var/lib/clamav" # signature database
        "/var/lib/tor"
        "/var/lib/fwupd"
        "/var/lib/upower"
        "/var/lib/power-profiles-daemon"
        "/var/lib/udisks2"
        "/var/lib/AccountsService"
        "/var/lib/sddm"

        # ── Logs, including the audit trail. An audit log that resets on
        #    every boot is not an audit log.
        "/var/log"
      ];

      files = [
        # Stable machine-id matters for journald continuity and for systemd
        # units keyed on it. A new one each boot orphans all prior logs.
        "/etc/machine-id"
      ];

      # Only meaningful when /home is being wiped. If it is NOT (the default),
      # these bind mounts would shadow the real ~ directories with empty ones
      # from /persist — actively destructive. Hence the guard.
      users.${user} = lib.mkIf cfg.wipeHome {
        directories = [
          # ── Games. Steam alone is ~119 GB; re-downloading is a day.
          ".local/share/Steam"
          ".steam"
          ".local/share/PrismLauncher"
          ".local/share/lutris"
          ".local/share/bottles"
          ".local/share/cartridges"
          "PortProton"
          ".wine"

          # ── Flatpak. .var/app is where Sober keeps the Roblox login.
          ".var/app"
          ".local/share/flatpak"

          # ── Credentials
          ".ssh"
          ".gnupg"
          ".pki"
          ".secrets"
          ".local/share/keyrings"

          # ── Desktop and app state
          ".config"
          ".local/state"
          ".local/share"
          ".cache" # not strictly needed, but rebuilding it every boot hurts

          # ── Toolchains, which are slow and annoying to restore
          ".cargo"
          ".rustup"
          ".npm"
          ".npm-global"
          ".dotnet"
          ".gradle"
          ".java"
          ".vscode"
          ".vscode-oss"

          # ── Documents
          "Desktop"
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"
          "Projects"
          "Software"
          "nixos-config"
          "scripts"
        ];
      };
    };
  };
}
