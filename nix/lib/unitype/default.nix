# Unitype - Universal Type Transformation System
#
# Layer 5: Transformation layer that converts between any Nix types through
# a canonical intermediate representation (IR).
#
# Instead of N² transformations, we implement 2N (N encoders + N decoders).

{lib}: {
  # IR (Intermediate Representation) - The "Rosetta Stone"
  ir = import ./ir/definition.nix {inherit lib;};

  # Transform engine (to be implemented)
  # transform = sourceType: targetType: value: result;

  # Encoders (to be implemented)
  # encoders = {
  #   nixos = import ./encoders/nixos.nix { inherit lib; };
  #   dendrix = import ./encoders/dendrix.nix { inherit lib; };
  #   # ...
  # };

  # Decoders (to be implemented)
  # decoders = {
  #   nixos = import ./decoders/nixos.nix { inherit lib; };
  #   dendrix = import ./decoders/dendrix.nix { inherit lib; };
  #   iso = import ./decoders/iso.nix { inherit lib; };
  #   # ...
  # };

  # Registry (to be implemented)
  # registry = import ./registry/default.nix { inherit lib; };
}
