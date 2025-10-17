# Block: Type Tests Exports
# Cell: tests
#
# This block exports all type system tests including:
# - Unit tests (common types, module types, flake types)
# - Integration tests (schema validation)
# - Real-world tests (community flakes, dogfooding)

{
  inputs,
  cell,
}: let
  nixpkgsLib = inputs.nixpkgs.lib;

  # Our types layer (for testing)
  ourTypes = inputs.self.lib.${inputs.nixpkgs.system}.types or {
    moduleTypes = {};
    flakeTypes = {};
    schemas = {};
    moduleInputs = {};
  };

  # Test runner utilities
  testLib = import ./lib.nix {lib = nixpkgsLib;};

  # Helper to safely import test file
  safeImport = path: description:
    if builtins.pathExists path
    then import path {
      lib = nixpkgsLib;
      types = ourTypes.moduleTypes;
      schemas = ourTypes.schemas;
      # Community flakes for real-world testing
      # These will be fetched on-demand when tests run
      nixpkgs = inputs.nixpkgs;
      homeManager = inputs.home-manager;
      # NOTE: Add other community flake inputs as they become available
      # dendrix, typix, colmena, etc.
      self = inputs.self;  # For dogfooding tests
    }
    else builtins.trace "Warning: Test file ${path} not found yet (${description})" {};

in {
  # Export test runner for use in checks
  inherit testLib;

  # ===== Unit Tests: Type Definitions =====
  unit = {
    # Test common Johnny Decimal types
    common-types = safeImport ./types/unit/common-types.nix "Common JD types";

    # Test module types for each flake class
    module-types-nixos = safeImport ./types/unit/module-types-nixos.nix "NixOS module types";
    module-types-home-manager = safeImport ./types/unit/module-types-home-manager.nix "home-manager module types";
    module-types-darwin = safeImport ./types/unit/module-types-darwin.nix "nix-darwin module types";
    module-types-dendrix = safeImport ./types/unit/module-types-dendrix.nix "Dendrix module types";
    module-types-system-manager = safeImport ./types/unit/module-types-system-manager.nix "system-manager module types";
    module-types-typix = safeImport ./types/unit/module-types-typix.nix "Typix module types";
    module-types-jm = safeImport ./types/unit/module-types-jm.nix "Johnny-Mnemonix module types";
    module-types-std = safeImport ./types/unit/module-types-std.nix "divnix/std module types";
    module-types-hive = safeImport ./types/unit/module-types-hive.nix "Hive/Colmena module types";

    # Test flake types (moduleInput + schemas)
    flake-types-structure = safeImport ./types/unit/flake-types-structure.nix "Flake type structure";
  };

  # ===== Integration Tests: Schema Validation =====
  integration = {
    # Test schemas validate correct outputs
    schemas-validate-outputs = safeImport ./types/integration/schemas-validate-outputs.nix "Schema output validation";

    # Test schemas reject invalid outputs
    schemas-reject-invalid = safeImport ./types/integration/schemas-reject-invalid.nix "Schema rejection tests";

    # Test cross-schema consistency
    schemas-consistency = safeImport ./types/integration/schemas-consistency.nix "Schema consistency";
  };

  # ===== Real-World Tests: Community Flakes =====
  real-world = {
    # Standard flake types
    nixos-community = safeImport ./types/real-world/nixos-community.nix "NixOS community modules";
    home-manager-community = safeImport ./types/real-world/home-manager-community.nix "home-manager community modules";

    # Custom flake types
    dendrix-community = safeImport ./types/real-world/dendrix-community.nix "Dendrix community modules";
    typix-community = safeImport ./types/real-world/typix-community.nix "Typix community projects";

    # Dogfooding
    jm-dogfood = safeImport ./types/real-world/jm-dogfood.nix "Johnny-Mnemonix dogfooding";
    std-dogfood = safeImport ./types/real-world/std-dogfood.nix "divnix/std dogfooding";
  };
}
