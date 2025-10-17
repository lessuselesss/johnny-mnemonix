# Apps Cell - Runnables Block
#
# Executable applications and utilities

{
  inputs,
  cell,
}: {
  # Flake inspection tool
  inspect-flake = import ./inspect-flake.nix {inherit inputs cell;};

  # Dendrix transformation tool
  transform-to-dendrix = import ./transform-to-dendrix.nix {inherit inputs cell;};
}
