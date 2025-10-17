# Unit Tests: Standard Flake Types
#
# Tests the standard Nix flake output type definitions from flakes/standard.nix
#
# TDD: These tests validate that standard flake outputs have correct:
# - Module input structure (how to define them)
# - Output schemas (how to validate them)

{
  lib,
  types,    # Module types
  schemas,  # Output schemas
}: let
  # Get the standard flake type
  standardFlakeType = if types ? standard then types.standard else {};

  # Get standard schemas
  appsSchema = schemas.apps or null;
  devShellsSchema = schemas.devShells or null;
  packagesSchema = schemas.packages or null;
  checksSchema = schemas.checks or null;
  formatterSchema = schemas.formatter or null;
  overlaysSchema = schemas.overlays or null;
  templatesSchema = schemas.templates or null;
  schemasSchema = schemas.schemas or null;
in {
  # ===== Module Input Structure Tests =====

  # Test: moduleInput exists and has required fields
  testStandardModuleInputExists = {
    expr = standardFlakeType ? moduleInput;
    expected = true;
  };

  testStandardModuleInputHasDescription = {
    expr = standardFlakeType.moduleInput ? description;
    expected = true;
  };

  testStandardModuleInputHasExample = {
    expr = standardFlakeType.moduleInput ? example;
    expected = true;
  };

  testStandardModuleInputHasSchema = {
    expr = standardFlakeType.moduleInput ? schema;
    expected = true;
  };

  # ===== Apps Module Input Tests =====

  # Test: Apps module input schema exists
  testStandardAppsInputExists = {
    expr = standardFlakeType.moduleInput.schema ? apps;
    expected = true;
  };

  # Test: Apps accept valid app definition
  testAppsInputValidApp = {
    expr = let
      appsType = standardFlakeType.moduleInput.schema.apps.type;
      validApp = {
        type = "app";
        program = "/nix/store/xxx-hello/bin/hello";
      };
    in lib.types.check (lib.types.attrsOf appsType) {"my-app" = validApp;};
    expected = true;
  };

  # Test: Apps require program attribute
  testAppsInputRequiresProgram = {
    expr = let
      appsType = standardFlakeType.moduleInput.schema.apps.type;
      invalidApp = {
        type = "app";
        # missing program
      };
    in lib.types.check (lib.types.attrsOf appsType) {"my-app" = invalidApp;};
    expected = false;
  };

  # Test: Apps can include metadata
  testAppsInputWithMeta = {
    expr = let
      appsType = standardFlakeType.moduleInput.schema.apps.type;
      appWithMeta = {
        type = "app";
        program = "/nix/store/xxx-hello/bin/hello";
        meta.description = "Hello world application";
      };
    in lib.types.check (lib.types.attrsOf appsType) {"hello" = appWithMeta;};
    expected = true;
  };

  # ===== DevShells Module Input Tests =====

  # Test: DevShells module input schema exists
  testStandardDevShellsInputExists = {
    expr = standardFlakeType.moduleInput.schema ? devShells;
    expected = true;
  };

  # Test: DevShells accept package (simulated as attrset with type)
  testDevShellsInputValidShell = {
    expr = let
      devShellsType = standardFlakeType.moduleInput.schema.devShells.type;
      validShell = {
        type = "derivation";
        name = "devShell";
      };
    in lib.types.check (lib.types.attrsOf devShellsType) {"default" = validShell;};
    expected = true;
  };

  # ===== Packages Module Input Tests =====

  # Test: Packages module input schema exists
  testStandardPackagesInputExists = {
    expr = standardFlakeType.moduleInput.schema ? packages;
    expected = true;
  };

  # ===== Schemas Output Tests =====

  # Test: Standard flake type exports schemas
  testStandardHasSchemas = {
    expr = standardFlakeType ? schemas;
    expected = true;
  };

  # ===== Apps Output Schema Tests =====

  # Test: Apps schema exists
  testAppsSchemaExists = {
    expr = appsSchema != null;
    expected = true;
  };

  # Test: Apps schema has version 1
  testAppsSchemaVersion = {
    expr = if appsSchema != null then appsSchema.version else 0;
    expected = 1;
  };

  # Test: Apps schema has inventory function
  testAppsSchemaHasInventory = {
    expr = if appsSchema != null then builtins.isFunction appsSchema.inventory else false;
    expected = true;
  };

  # Test: Apps schema validates correct output structure
  testAppsSchemaValidatesCorrectOutput = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            hello = {
              type = "app";
              program = "/nix/store/xxx-hello/bin/hello";
            };
          };
        };
        inventory = appsSchema.inventory output;
      in
        inventory ? children &&
        inventory.children ? x86_64-linux &&
        inventory.children.x86_64-linux ? children &&
        inventory.children.x86_64-linux.children ? hello
    else false;
    expected = true;
  };

  # Test: Apps schema checks type field
  testAppsSchemaChecksType = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            badapp = {
              type = "app";
              program = "/nix/store/xxx/bin/badapp";
            };
          };
        };
        inventory = appsSchema.inventory output;
        appChecks = inventory.children.x86_64-linux.children.badapp.evalChecks;
      in
        appChecks.hasType && appChecks.typeIsApp
    else false;
    expected = true;
  };

  # Test: Apps schema detects missing program
  testAppsSchemaDetectsMissingProgram = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            badapp = {
              type = "app";
              # missing program
            };
          };
        };
        inventory = appsSchema.inventory output;
        appChecks = inventory.children.x86_64-linux.children.badapp.evalChecks;
      in
        !appChecks.hasProgram
    else true;  # If schema doesn't exist, test passes vacuously
    expected = true;
  };

  # ===== DevShells Output Schema Tests =====

  # Test: DevShells schema exists
  testDevShellsSchemaExists = {
    expr = devShellsSchema != null;
    expected = true;
  };

  # Test: DevShells schema has version 1
  testDevShellsSchemaVersion = {
    expr = if devShellsSchema != null then devShellsSchema.version else 0;
    expected = 1;
  };

  # Test: DevShells schema validates correct output
  testDevShellsSchemaValidatesCorrectOutput = {
    expr = if devShellsSchema != null then
      let
        output = {
          x86_64-linux = {
            default = {
              type = "derivation";
              name = "devShell";
            };
          };
        };
        inventory = devShellsSchema.inventory output;
      in
        inventory ? children &&
        inventory.children ? x86_64-linux &&
        inventory.children.x86_64-linux ? children &&
        inventory.children.x86_64-linux.children ? default
    else false;
    expected = true;
  };

  # Test: DevShells schema checks for derivation
  testDevShellsSchemaChecksDerivation = {
    expr = if devShellsSchema != null then
      let
        output = {
          x86_64-linux = {
            rust = {
              type = "derivation";
              name = "rust-shell";
            };
          };
        };
        inventory = devShellsSchema.inventory output;
        shellChecks = inventory.children.x86_64-linux.children.rust.evalChecks;
      in
        shellChecks.isDerivation
    else false;
    expected = true;
  };

  # ===== Packages Output Schema Tests =====

  # Test: Packages schema exists
  testPackagesSchemaExists = {
    expr = packagesSchema != null;
    expected = true;
  };

  # Test: Packages schema version
  testPackagesSchemaVersion = {
    expr = if packagesSchema != null then packagesSchema.version else 0;
    expected = 1;
  };

  # Test: Packages schema validates derivations
  testPackagesSchemaValidatesDerivation = {
    expr = if packagesSchema != null then
      let
        output = {
          x86_64-linux = {
            myapp = {
              type = "derivation";
              name = "myapp";
            };
          };
        };
        inventory = packagesSchema.inventory output;
      in
        inventory.children.x86_64-linux.children.myapp.evalChecks.isDerivation
    else false;
    expected = true;
  };

  # ===== Checks Output Schema Tests =====

  # Test: Checks schema exists
  testChecksSchemaExists = {
    expr = checksSchema != null;
    expected = true;
  };

  # Test: Checks schema version
  testChecksSchemaVersion = {
    expr = if checksSchema != null then checksSchema.version else 0;
    expected = 1;
  };

  # ===== Formatter Output Schema Tests =====

  # Test: Formatter schema exists
  testFormatterSchemaExists = {
    expr = formatterSchema != null;
    expected = true;
  };

  # Test: Formatter schema validates per-system structure
  testFormatterSchemaValidatesPerSystem = {
    expr = if formatterSchema != null then
      let
        output = {
          x86_64-linux = {
            type = "derivation";
            name = "alejandra";
          };
        };
        inventory = formatterSchema.inventory output;
      in
        inventory.children ? x86_64-linux &&
        inventory.children.x86_64-linux.evalChecks.isDerivation
    else false;
    expected = true;
  };

  # ===== Overlays Output Schema Tests =====

  # Test: Overlays schema exists
  testOverlaysSchemaExists = {
    expr = overlaysSchema != null;
    expected = true;
  };

  # Test: Overlays schema checks for functions
  testOverlaysSchemaChecksFunction = {
    expr = if overlaysSchema != null then
      let
        output = {
          default = final: prev: {};  # Overlay function
        };
        inventory = overlaysSchema.inventory output;
      in
        inventory.children.default.evalChecks.isFunction
    else false;
    expected = true;
  };

  # ===== Templates Output Schema Tests =====

  # Test: Templates schema exists
  testTemplatesSchemaExists = {
    expr = templatesSchema != null;
    expected = true;
  };

  # Test: Templates schema checks required fields
  testTemplatesSchemaChecksRequiredFields = {
    expr = if templatesSchema != null then
      let
        output = {
          rust = {
            path = ./templates/rust;
            description = "Rust project";
          };
        };
        inventory = templatesSchema.inventory output;
        checks = inventory.children.rust.evalChecks;
      in
        checks.hasPath && checks.hasDescription && checks.descriptionIsString
    else false;
    expected = true;
  };

  # Test: Templates schema detects missing description
  testTemplatesSchemaDetectsMissingDescription = {
    expr = if templatesSchema != null then
      let
        output = {
          incomplete = {
            path = ./templates/incomplete;
            # missing description
          };
        };
        inventory = templatesSchema.inventory output;
        checks = inventory.children.incomplete.evalChecks;
      in
        !checks.hasDescription
    else true;
    expected = true;
  };

  # ===== Schemas Output Schema Tests (Meta!) =====

  # Test: Schemas schema exists (meta-schema!)
  testSchemasSchemaExists = {
    expr = schemasSchema != null;
    expected = true;
  };

  # Test: Schemas schema validates schema structure
  testSchemasSchemaValidatesSchemaStructure = {
    expr = if schemasSchema != null then
      let
        output = {
          myOutput = {
            version = 1;
            doc = "My custom output";
            inventory = output: {};
          };
        };
        inventory = schemasSchema.inventory output;
        checks = inventory.children.myOutput.evalChecks;
      in
        checks.hasVersion &&
        checks.versionIs1 &&
        checks.hasInventory &&
        checks.inventoryIsFunction
    else false;
    expected = true;
  };

  # Test: Schemas schema detects wrong version
  testSchemasSchemaDetectsWrongVersion = {
    expr = if schemasSchema != null then
      let
        output = {
          badSchema = {
            version = 2;  # Wrong version
            doc = "Bad schema";
            inventory = output: {};
          };
        };
        inventory = schemasSchema.inventory output;
        checks = inventory.children.badSchema.evalChecks;
      in
        !checks.versionIs1
    else true;
    expected = true;
  };

  # ===== Integration: Module Input + Output Schema Consistency =====

  # Test: All module inputs have corresponding schemas
  testModuleInputsHaveSchemas = {
    expr = let
      inputs = standardFlakeType.moduleInput.schema or {};
      schemas = standardFlakeType.schemas or {};
      inputNames = builtins.attrNames inputs;
      # Check that each input has a schema (or vice versa is acceptable)
      # For standard outputs, we define schemas for all
    in
      (schemas ? apps) &&
      (schemas ? devShells) &&
      (schemas ? packages) &&
      (schemas ? checks) &&
      (schemas ? formatter);
    expected = true;
  };

  # Test: All schemas have version 1
  testAllSchemasHaveVersion1 = {
    expr = let
      schemas = standardFlakeType.schemas or {};
      allSchemas = builtins.attrValues schemas;
      versions = map (s: s.version or 0) allSchemas;
    in
      builtins.all (v: v == 1) versions;
    expected = true;
  };

  # Test: All schemas have inventory functions
  testAllSchemasHaveInventory = {
    expr = let
      schemas = standardFlakeType.schemas or {};
      allSchemas = builtins.attrValues schemas;
      inventories = map (s: builtins.isFunction (s.inventory or null)) allSchemas;
    in
      builtins.all (i: i) inventories;
    expected = true;
  };
}
