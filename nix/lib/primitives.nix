# Library Cell - Primitives Block
# Layer 1: Atomic operations for number systems, fields, constraints, and templates
{
  inputs,
  cell,
}: {
  # Number system operations (radix, alphabet, conversions)
  numberSystems = import ./primitives/number-systems.nix {
    inherit (inputs.nixpkgs) lib;
  };

  # Field operations (constrained numbers with width/padding)
  fields = import ./primitives/fields.nix {
    inherit (inputs.nixpkgs) lib;
    numberSystems = import ./primitives/number-systems.nix {inherit (inputs.nixpkgs) lib;};
  };

  # Constraint predicates (range, enum, pattern, custom)
  constraints = import ./primitives/constraints.nix {
    inherit (inputs.nixpkgs) lib;
  };

  # Template operations (parse, render, validate)
  templates = import ./primitives/templates.nix {
    inherit (inputs.nixpkgs) lib;
  };

  # Numeral-name patterns (formatting conventions for identifiers)
  numeralNamePatterns = import ./primitives/numeral-name-patterns.nix {
    inherit (inputs.nixpkgs) lib;
  };
}
