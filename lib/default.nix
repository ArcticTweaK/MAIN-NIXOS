{ inputs, outputs }:

{
  mkHost = import ./mkHost.nix { inherit inputs outputs; };
}
