_:

{
  imports = [
    ./kernel.nix
    ./sudo.nix
    ./apparmor.nix
    ./audit.nix
    ./clamav.nix
    ./gpg.nix
    ./secrets.nix
    ./tools.nix
  ];
}
