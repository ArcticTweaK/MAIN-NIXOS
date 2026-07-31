{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.security.tools;
in
{
  options.arctic.security.tools = {
    enable = lib.mkEnableOption "security and privacy tooling";

    crypto = lib.mkEnableOption "encryption and password management" // { default = true; };
    proton = lib.mkEnableOption "the Proton desktop suite" // { default = true; };
    opsec = lib.mkEnableOption "metadata stripping tools" // { default = true; };
    audit = lib.mkEnableOption "host audit tooling (lynis, aide)";
    offensive = lib.mkEnableOption "web/binary security testing tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ]
      ++ lib.optionals cfg.crypto [
      age # modern file encryption; what sops uses here
      gnupg # still required for commit signing and package verification
      pinentry-qt
      sops # edits the encrypted files in ./secrets
      keepassxc # offline, audited password manager
    ]
      ++ lib.optionals cfg.proton [
      proton-vpn
      protonmail-desktop
      proton-pass
      proton-authenticator
    ]
      ++ lib.optionals cfg.opsec [
      exiftool # read/strip EXIF from images and documents
      mat2 # strip metadata from PDFs, audio, video
    ]
      ++ lib.optionals cfg.audit [
      lynis # `sudo lynis audit system`
      aide # file integrity monitoring
    ]
      ++ lib.optionals cfg.offensive [
      burpsuite
    ];
  };
}
