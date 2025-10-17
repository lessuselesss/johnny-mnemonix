# Unitype - Universal Type Transformation System
#
# Layer 5: Transformation layer that converts between any Nix types through
# a canonical intermediate representation (IR).
#
# Instead of N² transformations, we implement 2N (N encoders + N decoders).

{lib}: let
  # Need to make lib.unitype available for encoders/decoders to use
  # This creates a circular dependency, but it's okay because Nix is lazy
  unitype = {
    ir = import ./ir/definition.nix {inherit lib;};
  };

  # Extend lib with unitype for encoder/decoder access
  libWithUnitype = lib // {
    unitype = unitype;
  };
in {
  # IR (Intermediate Representation) - The "Rosetta Stone"
  ir = unitype.ir;

  # Encoders - Convert from specific types to IR
  encoders = {
    nixos = import ./encoders/nixos.nix {lib = libWithUnitype;};
    # dendrix = import ./encoders/dendrix.nix { lib = libWithUnitype; };
    # ...
  };

  # Transform engine (to be implemented)
  # transform = sourceType: targetType: value: result;

  # Decoders (to be implemented)
  # decoders = {
  #   nixos = import ./decoders/nixos.nix { lib = libWithUnitype; };
  #   dendrix = import ./decoders/dendrix.nix { lib = libWithUnitype; };
  #   iso = import ./decoders/iso.nix { lib = libWithUnitype; };
  #   # ...
  # };

  # Registry (to be implemented)
  # registry = import ./registry/default.nix { inherit lib; };
}
