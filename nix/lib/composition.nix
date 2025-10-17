# Library Cell - Composition Block
# Layer 2: Compose primitives into identifiers, ranges, hierarchies, validators
{
  inputs,
  cell,
}: let
  primitives = cell.primitives;
in {
  # Multi-field identifier composition
  identifiers = import ./composition/identifiers.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives;
  };

  # Range derivation from fields
  ranges = import ./composition/ranges.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives;
  };

  # Hierarchy tree construction
  hierarchies = import ./composition/hierarchies.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives;
  };

  # Constraint composition and validation
  validators = import ./composition/validators.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives;
  };
}
