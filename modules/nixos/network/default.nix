_:

{
  imports = [
    ./base.nix
    ./dns.nix
    ./firewall.nix
    ./tor.nix
    ./tools.nix

    # No ./vpn.nix. VPN on this host is the Proton GUI app (pkgs.proton-vpn,
    # declared in modules/nixos/security/tools.nix), which manages its own
    # NetworkManager connections — a wireguard interface plus its killswitch
    # and IPv6-leak dummy devices.
    #
    # A declarative wg-quick module was written and then removed: maintaining
    # two mechanisms that both claim the default route is how you end up with
    # a tunnel you think is up and isn't. The app wins here because server
    # switching is the whole point, and that is inherently interactive.
    #
    # Cost of this choice: the VPN connections are imperative state and do not
    # survive a wipe. Recreating them is logging into the app. See README.
  ];
}
