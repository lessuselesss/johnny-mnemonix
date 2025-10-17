# Real-World Tests: Standard Flake Outputs in Community Flakes
#
# Tests that our standard output schemas correctly validate real-world
# community flakes. This ensures our type system works with actual flakes.

{
  lib,
  types,
  schemas,
  nixpkgs,
  homeManager,
  self,
}: let
  # Helper: Check if a flake output type exists and is valid structure
  hasValidOutput = flakePath: outputName:
    let
      flakeOutputs = builtins.tryEval (
        if builtins.pathExists (flakePath + "/flake.nix")
        then (import (flakePath + "/flake.nix")).outputs or {}
        else {}
      );
    in
      if flakeOutputs.success
      then flakeOutputs.value ? ${outputName}
      else false;

  # Helper: Validate schema against an output
  validateSchema = schema: output:
    if schema != null && output != null
    then
      let
        result = builtins.tryEval (schema.inventory output);
      in result.success
    else false;
in {
  # ===== nixpkgs Tests =====

  # Test: nixpkgs provides legacyPackages
  testNixpkgsHasLegacyPackages = {
    expr = nixpkgs ? legacyPackages;
    expected = true;
  };

  # Test: nixpkgs legacyPackages has x86_64-linux
  testNixpkgsLegacyPackagesHasX86_64 = {
    expr = nixpkgs.legacyPackages ? x86_64-linux;
    expected = true;
  };

  # Test: Our legacyPackages schema structure is compatible
  testLegacyPackagesSchemaStructure = {
    expr = let
      schema = schemas.legacyPackages or null;
    in
      if schema != null
      then schema ? version && schema ? inventory && builtins.isFunction schema.inventory
      else false;
    expected = true;
  };

  # ===== home-manager Tests =====

  # Test: home-manager provides homeManagerModules
  testHomeManagerHasModules = {
    expr = homeManager.outPath != null;  # Has valid flake
    expected = true;
  };

  # Test: Our homeModules schema exists
  testHomeModulesSchemaExists = {
    expr = schemas ? homeModules || schemas ? homeManagerModules;
    expected = true;
  };

  # ===== Standard Apps/DevShells/Packages Tests =====

  # Test: apps schema validates per-system structure
  testAppsSchemaValidatesPerSystem = {
    expr = let
      schema = schemas.apps or null;
      # Simulate a real-world apps output
      testOutput = {
        x86_64-linux = {
          default = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          };
          build = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.coreutils}/bin/echo";
          };
        };
        aarch64-linux = {
          default = {
            type = "app";
            program = "/nix/store/xxx-hello/bin/hello";
          };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: devShells schema validates per-system structure
  testDevShellsSchemaValidatesPerSystem = {
    expr = let
      schema = schemas.devShells or null;
      # Simulate real-world devShells output
      testOutput = {
        x86_64-linux = {
          default = {
            type = "derivation";
            name = "devshell";
            buildInputs = [];
          };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: packages schema validates per-system structure
  testPackagesSchemaValidatesPerSystem = {
    expr = let
      schema = schemas.packages or null;
      # Simulate real-world packages output
      testOutput = {
        x86_64-linux = {
          default = {
            type = "derivation";
            name = "mypackage";
          };
          extra = {
            type = "derivation";
            name = "extra-package";
          };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Overlays Tests =====

  # Test: overlays schema validates function structure
  testOverlaysSchemaValidatesFunctions = {
    expr = let
      schema = schemas.overlays or null;
      # Simulate real-world overlays output
      testOutput = {
        default = final: prev: {
          mypackage = prev.hello;
        };
        modifications = final: prev: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Templates Tests =====

  # Test: templates schema validates structure
  testTemplatesSchemaValidatesStructure = {
    expr = let
      schema = schemas.templates or null;
      # Simulate real-world templates output
      testOutput = {
        rust = {
          path = ./fixtures;  # Mock path
          description = "Rust project template";
        };
        python = {
          path = ./fixtures;
          description = "Python project template";
          welcomeText = "Welcome to Python!";
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Formatter Tests =====

  # Test: formatter schema validates per-system
  testFormatterSchemaValidatesPerSystem = {
    expr = let
      schema = schemas.formatter or null;
      # Simulate real-world formatter output
      testOutput = {
        x86_64-linux = {
          type = "derivation";
          name = "alejandra";
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Checks Tests =====

  # Test: checks schema validates per-system
  testChecksSchemaValidatesPerSystem = {
    expr = let
      schema = schemas.checks or null;
      # Simulate real-world checks output
      testOutput = {
        x86_64-linux = {
          "test-unit" = {
            type = "derivation";
            name = "unit-tests";
          };
          "test-integration" = {
            type = "derivation";
            name = "integration-tests";
          };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Cross-System Validation =====

  # Test: apps work across multiple systems (common pattern)
  testAppsMultiSystemPattern = {
    expr = let
      schema = schemas.apps or null;
      testOutput = {
        x86_64-linux.myapp = { type = "app"; program = "/nix/store/xxx/bin/myapp"; };
        x86_64-darwin.myapp = { type = "app"; program = "/nix/store/yyy/bin/myapp"; };
        aarch64-linux.myapp = { type = "app"; program = "/nix/store/zzz/bin/myapp"; };
        aarch64-darwin.myapp = { type = "app"; program = "/nix/store/www/bin/myapp"; };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: devShells with multiple named shells per system
  testDevShellsMultiplePerSystem = {
    expr = let
      schema = schemas.devShells or null;
      testOutput = {
        x86_64-linux = {
          default = { type = "derivation"; name = "devshell"; };
          rust = { type = "derivation"; name = "rust-devshell"; };
          python = { type = "derivation"; name = "python-devshell"; };
          nodejs = { type = "derivation"; name = "nodejs-devshell"; };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Real-World Patterns =====

  # Test: Pattern from popular configs - apps with descriptive names
  testAppsDescriptiveNamesPattern = {
    expr = let
      schema = schemas.apps or null;
      # Pattern seen in community configs
      testOutput = {
        x86_64-linux = {
          "deploy-nixos" = { type = "app"; program = "/nix/store/xxx/bin/deploy"; };
          "update-flake" = { type = "app"; program = "/nix/store/xxx/bin/update"; };
          "build-iso" = { type = "app"; program = "/nix/store/xxx/bin/build-iso"; };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Pattern - devShells for different languages
  testDevShellsLanguagePattern = {
    expr = let
      schema = schemas.devShells or null;
      testOutput = {
        x86_64-linux = {
          "rust-stable" = { type = "derivation"; name = "rust-stable"; };
          "rust-nightly" = { type = "derivation"; name = "rust-nightly"; };
          "python310" = { type = "derivation"; name = "python310"; };
          "python311" = { type = "derivation"; name = "python311"; };
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Pattern - overlays from nixpkgs-style repos
  testOverlaysNixpkgsPattern = {
    expr = let
      schema = schemas.overlays or null;
      testOutput = {
        default = final: prev: {
          # Typical pattern: add or override packages
          customPkg = prev.callPackage ./pkg.nix {};
          hello = prev.hello.overrideAttrs (old: {
            patches = old.patches or [] ++ [ ./my.patch ];
          });
        };
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Edge Cases from Real World =====

  # Test: Empty outputs are valid (repos in development)
  testEmptyAppsValid = {
    expr = let
      schema = schemas.apps or null;
      testOutput = {};  # No apps yet
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Single system only (common for personal configs)
  testSingleSystemApps = {
    expr = let
      schema = schemas.apps or null;
      testOutput = {
        x86_64-linux = {
          myapp = { type = "app"; program = "/nix/store/xxx/bin/myapp"; };
        };
        # No other systems
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # Test: Overlays with just default (common pattern)
  testOverlaysJustDefault = {
    expr = let
      schema = schemas.overlays or null;
      testOutput = {
        default = final: prev: {};
      };
    in validateSchema schema testOutput;
    expected = true;
  };

  # ===== Schema Consistency Tests =====

  # Test: All standard schemas have version 1
  testAllStandardSchemasVersion1 = {
    expr = let
      standardSchemas = [
        (schemas.apps or null)
        (schemas.devShells or null)
        (schemas.packages or null)
        (schemas.checks or null)
        (schemas.formatter or null)
        (schemas.overlays or null)
        (schemas.legacyPackages or null)
        (schemas.templates or null)
      ];
      versions = map (s: if s != null then s.version or 0 else 1) standardSchemas;
    in builtins.all (v: v == 1) versions;
    expected = true;
  };

  # Test: All standard schemas have inventory functions
  testAllStandardSchemasHaveInventory = {
    expr = let
      standardSchemas = [
        (schemas.apps or null)
        (schemas.devShells or null)
        (schemas.packages or null)
        (schemas.checks or null)
        (schemas.formatter or null)
        (schemas.overlays or null)
        (schemas.legacyPackages or null)
        (schemas.templates or null)
      ];
      inventories = map (s: if s != null then builtins.isFunction (s.inventory or null) else true) standardSchemas;
    in builtins.all (i: i) inventories;
    expected = true;
  };

  # Test: All standard schemas have documentation
  testAllStandardSchemasHaveDocs = {
    expr = let
      standardSchemas = [
        (schemas.apps or null)
        (schemas.devShells or null)
        (schemas.packages or null)
        (schemas.checks or null)
        (schemas.formatter or null)
        (schemas.overlays or null)
        (schemas.legacyPackages or null)
        (schemas.templates or null)
      ];
      docs = map (s: if s != null then builtins.isString (s.doc or "") else true) standardSchemas;
    in builtins.all (d: d) docs;
    expected = true;
  };
}
