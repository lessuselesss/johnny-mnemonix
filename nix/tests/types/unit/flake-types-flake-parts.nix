# Unit Tests: flake-parts Flake Types
#
# Tests the flake-parts type definitions from flakes/flake-parts.nix
# including the newly added apps and devShells schemas

{
  lib,
  types,
  schemas,
  ...
}: let
  # Get flake-parts flake type
  flakePartsType = if types ? flakeParts then types.flakeParts else {};

  # Get schemas added to flake-parts
  appsSchema = schemas.apps or null;
  devShellsSchema = schemas.devShells or null;
in {
  # ===== flake-parts Module Input Tests =====

  # Test: flake-parts module input exists
  testFlakePartsModuleInputExists = {
    expr = flakePartsType ? moduleInput;
    expected = true;
  };

  # Test: Example shows perSystem usage
  testFlakePartsExampleHasPerSystem = {
    expr = if flakePartsType ? moduleInput
      then lib.hasInfix "perSystem" flakePartsType.moduleInput.example
      else false;
    expected = true;
  };

  # Test: Example shows devShells
  testFlakePartsExampleHasDevShells = {
    expr = if flakePartsType ? moduleInput
      then lib.hasInfix "devShells" flakePartsType.moduleInput.example
      else false;
    expected = true;
  };

  # ===== flake-parts Schemas Tests =====

  # Test: flake-parts exports schemas
  testFlakePartsHasSchemas = {
    expr = flakePartsType ? schemas;
    expected = true;
  };

  # Test: flake-parts has flakeModules schema
  testFlakePartsHasFlakeModulesSchema = {
    expr = if flakePartsType ? schemas
      then flakePartsType.schemas ? flakeModules
      else false;
    expected = true;
  };

  # Test: flake-parts has modules schema
  testFlakePartsHasModulesSchema = {
    expr = if flakePartsType ? schemas
      then flakePartsType.schemas ? modules
      else false;
    expected = true;
  };

  # Test: flake-parts has apps schema
  testFlakePartsHasAppsSchema = {
    expr = if flakePartsType ? schemas
      then flakePartsType.schemas ? apps
      else false;
    expected = true;
  };

  # Test: flake-parts has devShells schema
  testFlakePartsHasDevShellsSchema = {
    expr = if flakePartsType ? schemas
      then flakePartsType.schemas ? devShells
      else false;
    expected = true;
  };

  # ===== Apps Schema Tests (from flake-parts) =====

  # Test: Apps schema has documentation
  testAppsSchemaHasDoc = {
    expr = if appsSchema != null
      then appsSchema ? doc && builtins.isString appsSchema.doc
      else true;  # If no schema, test passes vacuously
    expected = true;
  };

  # Test: Apps schema doc mentions Johnny Decimal
  testAppsSchemaDocMentionsJohnnyDecimal = {
    expr = if appsSchema != null && appsSchema ? doc
      then lib.hasInfix "Johnny Decimal" appsSchema.doc
      else true;  # If no doc, test passes vacuously
    expected = true;
  };

  # Test: Apps schema validates per-system structure
  testAppsSchemaValidatesPerSystemStructure = {
    expr = if appsSchema != null then
      let
        # Valid per-system apps output
        output = {
          x86_64-linux = {
            "10.01-build" = {
              type = "app";
              program = "/nix/store/xxx-builder/bin/build";
            };
            "20.01-test" = {
              type = "app";
              program = "/nix/store/xxx-tester/bin/test";
            };
          };
          aarch64-linux = {
            "10.01-build" = {
              type = "app";
              program = "/nix/store/yyy-builder/bin/build";
            };
          };
        };
        inventory = appsSchema.inventory output;
      in
        # Check both systems are present
        inventory ? children &&
        inventory.children ? x86_64-linux &&
        inventory.children ? aarch64-linux &&
        # Check Johnny Decimal organized apps
        inventory.children.x86_64-linux ? children &&
        inventory.children.x86_64-linux.children ? "10.01-build" &&
        inventory.children.x86_64-linux.children ? "20.01-test"
    else false;
    expected = true;
  };

  # Test: Apps schema validates app structure
  testAppsSchemaValidatesAppStructure = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            myapp = {
              type = "app";
              program = "/nix/store/xxx-myapp/bin/myapp";
            };
          };
        };
        inventory = appsSchema.inventory output;
        appChecks = inventory.children.x86_64-linux.children.myapp.evalChecks;
      in
        appChecks.isAttrs &&
        appChecks.hasType &&
        appChecks.typeIsApp &&
        appChecks.hasProgram &&
        appChecks.programIsString
    else false;
    expected = true;
  };

  # Test: Apps schema detects invalid type
  testAppsSchemaDetectsInvalidType = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            badapp = {
              type = "wrong";  # Should be "app"
              program = "/nix/store/xxx/bin/badapp";
            };
          };
        };
        inventory = appsSchema.inventory output;
        appChecks = inventory.children.x86_64-linux.children.badapp.evalChecks;
      in
        !appChecks.typeIsApp
    else true;
    expected = true;
  };

  # Test: Apps schema detects missing program
  testAppsSchemaDetectsMissingProgram = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            incomplete = {
              type = "app";
              # missing program
            };
          };
        };
        inventory = appsSchema.inventory output;
        appChecks = inventory.children.x86_64-linux.children.incomplete.evalChecks;
      in
        !appChecks.hasProgram
    else true;
    expected = true;
  };

  # ===== DevShells Schema Tests (from flake-parts) =====

  # Test: DevShells schema has documentation
  testDevShellsSchemaHasDoc = {
    expr = if devShellsSchema != null
      then devShellsSchema ? doc && builtins.isString devShellsSchema.doc
      else true;
    expected = true;
  };

  # Test: DevShells schema doc mentions Johnny Decimal
  testDevShellsSchemaDocMentionsJohnnyDecimal = {
    expr = if devShellsSchema != null && devShellsSchema ? doc
      then lib.hasInfix "Johnny Decimal" devShellsSchema.doc
      else true;
    expected = true;
  };

  # Test: DevShells schema validates per-system structure
  testDevShellsSchemaValidatesPerSystemStructure = {
    expr = if devShellsSchema != null then
      let
        output = {
          x86_64-linux = {
            "10.01-rust-env" = {
              type = "derivation";
              name = "rust-devshell";
            };
            "20.01-node-env" = {
              type = "derivation";
              name = "node-devshell";
            };
          };
        };
        inventory = devShellsSchema.inventory output;
      in
        inventory ? children &&
        inventory.children ? x86_64-linux &&
        inventory.children.x86_64-linux ? children &&
        inventory.children.x86_64-linux.children ? "10.01-rust-env" &&
        inventory.children.x86_64-linux.children ? "20.01-node-env"
    else false;
    expected = true;
  };

  # Test: DevShells schema validates derivation
  testDevShellsSchemaValidatesDerivation = {
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
        shellChecks = inventory.children.x86_64-linux.children.default.evalChecks;
      in
        shellChecks.isAttrs && shellChecks.isDerivation
    else false;
    expected = true;
  };

  # Test: DevShells schema detects non-derivation
  testDevShellsSchemaDetectsNonDerivation = {
    expr = if devShellsSchema != null then
      let
        output = {
          x86_64-linux = {
            badshell = {
              # Not a derivation - missing type field
              name = "badshell";
            };
          };
        };
        inventory = devShellsSchema.inventory output;
        shellChecks = inventory.children.x86_64-linux.children.badshell.evalChecks;
      in
        !shellChecks.isDerivation
    else true;
    expected = true;
  };

  # ===== Integration: Johnny Decimal Organization =====

  # Test: Apps support Johnny Decimal names
  testAppsSupportsJohnnyDecimalNames = {
    expr = if appsSchema != null then
      let
        output = {
          x86_64-linux = {
            "10.01-build-docs" = {
              type = "app";
              program = "/nix/store/xxx/bin/build-docs";
            };
            "10.02-build-site" = {
              type = "app";
              program = "/nix/store/xxx/bin/build-site";
            };
            "20.01-deploy-staging" = {
              type = "app";
              program = "/nix/store/xxx/bin/deploy-staging";
            };
          };
        };
        inventory = appsSchema.inventory output;
        x86Apps = inventory.children.x86_64-linux.children;
      in
        x86Apps ? "10.01-build-docs" &&
        x86Apps ? "10.02-build-site" &&
        x86Apps ? "20.01-deploy-staging"
    else false;
    expected = true;
  };

  # Test: DevShells support Johnny Decimal names
  testDevShellsSupportsJohnnyDecimalNames = {
    expr = if devShellsSchema != null then
      let
        output = {
          x86_64-linux = {
            "10.01-rust-env" = {
              type = "derivation";
              name = "rust-env";
            };
            "10.02-go-env" = {
              type = "derivation";
              name = "go-env";
            };
            "20.01-frontend-env" = {
              type = "derivation";
              name = "frontend-env";
            };
          };
        };
        inventory = devShellsSchema.inventory output;
        x86Shells = inventory.children.x86_64-linux.children;
      in
        x86Shells ? "10.01-rust-env" &&
        x86Shells ? "10.02-go-env" &&
        x86Shells ? "20.01-frontend-env"
    else false;
    expected = true;
  };

  # ===== flake-parts vs Standard Overlap Tests =====

  # Test: Both flake-parts and standard provide apps schema
  testAppsSchemaProvidedByBoth = {
    expr =
      (flakePartsType ? schemas && flakePartsType.schemas ? apps) &&
      (appsSchema != null);
    expected = true;
  };

  # Test: Both flake-parts and standard provide devShells schema
  testDevShellsSchemaProvidedByBoth = {
    expr =
      (flakePartsType ? schemas && flakePartsType.schemas ? devShells) &&
      (devShellsSchema != null);
    expected = true;
  };

  # Test: Apps schema from both sources should be compatible (same version)
  testAppsSchemaVersionConsistency = {
    expr = let
      flakePartsAppsSchema = if flakePartsType ? schemas && flakePartsType.schemas ? apps
        then flakePartsType.schemas.apps
        else null;
      standardAppsSchema = appsSchema;
    in
      if flakePartsAppsSchema != null && standardAppsSchema != null
      then flakePartsAppsSchema.version == standardAppsSchema.version
      else true;  # If either is missing, test passes vacuously
    expected = true;
  };
}
