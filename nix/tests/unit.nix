# Block: Unit Tests Exports
# Cell: tests
#
# This block exports all unit tests for primitives, composition, and builders.

{
  inputs,
  cell,
}: let
  lib = inputs.self.lib.${inputs.nixpkgs.system} or {};
in {
  # Layer 1: Primitives (55+ tests)
  primitives = {
    # number-systems = import ./primitives/number-systems.test.nix {inherit lib;};
    # fields = import ./primitives/fields.test.nix {inherit lib;};
    # constraints = import ./primitives/constraints.test.nix {inherit lib;};
    # templates = import ./primitives/templates.test.nix {inherit lib;};
  };

  # Layer 2: Composition (45+ tests)
  composition = {
    # identifiers = import ./composition/identifiers.test.nix {inherit lib;};
    # ranges = import ./composition/ranges.test.nix {inherit lib;};
    # hierarchies = import ./composition/hierarchies.test.nix {inherit lib;};
    # validators = import ./composition/validators.test.nix {inherit lib;};
  };

  # Layer 3: Builders (26+ tests)
  builders = {
    # johnny-decimal = import ./builders/johnny-decimal.test.nix {inherit lib;};
    # versioning = import ./builders/versioning.test.nix {inherit lib;};
    # classification = import ./builders/classification.test.nix {inherit lib;};
  };
}
