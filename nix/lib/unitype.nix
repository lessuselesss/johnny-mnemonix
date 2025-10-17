# Library Cell - Unitype Block
# Layer 5: Universal type transformation through canonical IR
{
  inputs,
  cell,
}: let
  inherit (inputs.nixpkgs) lib;

  # Extend lib with types system for validation
  libWithTypes = lib // {
    types = cell.types or {};
  };
in
  import ./unitype/default.nix {lib = libWithTypes;}
