# Library Cell - Builders Block
# Layer 3: High-level builders for common organizational systems
{
  inputs,
  cell,
}: let
  primitives = cell.primitives;
  composition = cell.composition;
in {
  # Classic Johnny Decimal builder
  mkJohnnyDecimal = import ./builders/johnny-decimal.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives composition;
  };

  # Semantic versioning builder
  mkVersioning = import ./builders/versioning.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives composition;
  };

  # Classification system builder (Dewey-like)
  mkClassification = import ./builders/classification.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives composition;
  };

  # Project numbering system builder
  mkProjectSystem = import ./builders/project-system.nix {
    inherit (inputs.nixpkgs) lib;
    inherit primitives composition;
  };
}
