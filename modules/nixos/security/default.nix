_:

{
  imports = [
    ./kernel.nix
    ./sudo.nix
    ./apparmor.nix
    ./audit.nix
    ./clamav.nix
    ./fail2ban.nix
    ./usbguard.nix
    ./gpg.nix
    ./tools.nix
  ];
}
