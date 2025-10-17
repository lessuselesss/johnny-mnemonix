# Block: Unit Tests Exports
# Cell: tests
#
# This block exports all unit tests for primitives, composition, and builders.
# Test files return attribute sets of {expr, expected} pairs.

{
  inputs,
  cell,
}: let
  nixpkgsLib = inputs.nixpkgs.lib;

  # Our library (for testing)
  # Note: This will be partially available as components are implemented
  ourLib = inputs.self.lib.${inputs.nixpkgs.system} or {
    primitives = {};
    composition = {};
    builders = {};
  };

  # Test runner utilities
  testLib = import ./lib.nix {lib = nixpkgsLib;};

  # Helper to safely import test file (returns empty set if component not ready)
  safeImport = path: componentPath:
    if builtins.pathExists path
    then import path {lib = ourLib; nixpkgs = nixpkgsLib;}
    else builtins.trace "Warning: Test file ${path} not found yet" {};
in {
  # Export test runner for use in checks
  inherit testLib;

  # Layer 1: Primitives (55+ tests)
  primitives = {
    number-systems = safeImport ./primitives/number-systems.test.nix "primitives.numberSystems";
    fields = safeImport ./primitives/fields.test.nix "primitives.fields";
    constraints = safeImport ./primitives/constraints.test.nix "primitives.constraints";
    templates = safeImport ./primitives/templates.test.nix "primitives.templates";
  };

  # Layer 2: Composition (45+ tests)
  composition = {
    identifiers = safeImport ./composition/identifiers.test.nix "composition.identifiers";
    ranges = safeImport ./composition/ranges.test.nix "composition.ranges";
    hierarchies = safeImport ./composition/hierarchies.test.nix "composition.hierarchies";
    validators = safeImport ./composition/validators.test.nix "composition.validators";
  };

  # Layer 3: Builders (26+ tests)
  builders = {
    johnny-decimal = safeImport ./builders/johnny-decimal.test.nix "builders.mkJohnnyDecimal";
    versioning = safeImport ./builders/versioning.test.nix "builders.mkVersioning";
    classification = safeImport ./builders/classification.test.nix "builders.mkClassification";
  };
}
