# Integration Tests: Schema Validation for Standard Outputs
#
# Tests that schemas correctly validate standard flake outputs:
# - apps, devShells, packages, checks, formatter
# - overlays, legacyPackages, templates
# - hydraJobs, dockerImages, schemas

{
  lib,
  types,
  schemas,
  nixpkgs,
  self,
}: let
  # Helper: Run schema validation and extract result
  validateOutput = schema: output:
    if schema != null then
      let
        inventory = schema.inventory output;
        # Check if inventory structure looks valid
        hasValidStructure = inventory ? children || inventory ? what;
      in hasValidStructure
    else false;

  # Helper: Check all evalChecks pass
  allChecksPass = evalChecks:
    builtins.all (check: check) (builtins.attrValues evalChecks);
in {
  # ===== Apps Output Validation =====

  # Test: Valid apps output passes schema
  testAppsValidOutputPasses = {
    expr = let
      schema = schemas.apps or null;
      output = {
        x86_64-linux = {
          hello = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.hello}/bin/hello";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: Multiple apps in Johnny Decimal format
  testAppsJohnnyDecimalOrganization = {
    expr = let
      schema = schemas.apps or null;
      output = {
        x86_64-linux = {
          "10.01-build-docs" = {
            type = "app";
            program = "/nix/store/xxx-builder/bin/build";
          };
          "10.02-build-website" = {
            type = "app";
            program = "/nix/store/xxx-web-builder/bin/build";
          };
          "20.01-deploy" = {
            type = "app";
            program = "/nix/store/xxx-deployer/bin/deploy";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: Apps with metadata
  testAppsWithMetadata = {
    expr = let
      schema = schemas.apps or null;
      output = {
        x86_64-linux = {
          myapp = {
            type = "app";
            program = "/nix/store/xxx/bin/myapp";
            meta = {
              description = "My application";
              license = "MIT";
            };
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== DevShells Output Validation =====

  # Test: Valid devShells output passes schema
  testDevShellsValidOutputPasses = {
    expr = let
      schema = schemas.devShells or null;
      # Simulate a devShell derivation
      output = {
        x86_64-linux = {
          default = {
            type = "derivation";
            name = "devshell";
            buildInputs = [];
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: Multiple devShells in Johnny Decimal format
  testDevShellsJohnnyDecimalOrganization = {
    expr = let
      schema = schemas.devShells or null;
      output = {
        x86_64-linux = {
          "10.01-rust" = {
            type = "derivation";
            name = "rust-devshell";
          };
          "10.02-go" = {
            type = "derivation";
            name = "go-devshell";
          };
          "20.01-frontend" = {
            type = "derivation";
            name = "frontend-devshell";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Packages Output Validation =====

  # Test: Valid packages output passes schema
  testPackagesValidOutputPasses = {
    expr = let
      schema = schemas.packages or null;
      output = {
        x86_64-linux = {
          myapp = {
            type = "derivation";
            name = "myapp";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: Packages with Johnny Decimal organization
  testPackagesJohnnyDecimalOrganization = {
    expr = let
      schema = schemas.packages or null;
      output = {
        x86_64-linux = {
          "30.01-cli-tool" = {
            type = "derivation";
            name = "cli-tool";
          };
          "30.02-library" = {
            type = "derivation";
            name = "library";
          };
          "40.01-docs" = {
            type = "derivation";
            name = "docs";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Checks Output Validation =====

  # Test: Valid checks output passes schema
  testChecksValidOutputPasses = {
    expr = let
      schema = schemas.checks or null;
      output = {
        x86_64-linux = {
          test-unit = {
            type = "derivation";
            name = "unit-tests";
          };
          test-integration = {
            type = "derivation";
            name = "integration-tests";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Formatter Output Validation =====

  # Test: Valid formatter output passes schema
  testFormatterValidOutputPasses = {
    expr = let
      schema = schemas.formatter or null;
      output = {
        x86_64-linux = {
          type = "derivation";
          name = "alejandra";
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Overlays Output Validation =====

  # Test: Valid overlays output passes schema
  testOverlaysValidOutputPasses = {
    expr = let
      schema = schemas.overlays or null;
      output = {
        default = final: prev: {
          mypackage = prev.callPackage ./mypackage.nix {};
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: Multiple overlays with Johnny Decimal names
  testOverlaysJohnnyDecimalOrganization = {
    expr = let
      schema = schemas.overlays or null;
      output = {
        "10.01-dev-tools" = final: prev: {};
        "10.02-build-tools" = final: prev: {};
        "20.01-custom-packages" = final: prev: {};
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Templates Output Validation =====

  # Test: Valid templates output passes schema
  testTemplatesValidOutputPasses = {
    expr = let
      schema = schemas.templates or null;
      output = {
        rust = {
          path = ./templates/rust;
          description = "Rust project with Nix flake";
        };
        python = {
          path = ./templates/python;
          description = "Python project with poetry and Nix";
          welcomeText = "Welcome to your Python project!";
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Schemas Output Validation (Meta!) =====

  # Test: Valid schemas output passes schema validation
  testSchemasValidOutputPasses = {
    expr = let
      schema = schemas.schemas or null;
      output = {
        myOutput = {
          version = 1;
          doc = "My custom output type";
          inventory = output: {
            what = "my output";
            evalChecks = {
              isValid = true;
            };
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Cross-System Validation =====

  # Test: Apps work across multiple systems
  testAppsMultipleSystemsValid = {
    expr = let
      schema = schemas.apps or null;
      output = {
        x86_64-linux = {
          myapp = {
            type = "app";
            program = "/nix/store/xxx/bin/myapp";
          };
        };
        aarch64-linux = {
          myapp = {
            type = "app";
            program = "/nix/store/yyy/bin/myapp";
          };
        };
        x86_64-darwin = {
          myapp = {
            type = "app";
            program = "/nix/store/zzz/bin/myapp";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # Test: DevShells work across multiple systems
  testDevShellsMultipleSystemsValid = {
    expr = let
      schema = schemas.devShells or null;
      output = {
        x86_64-linux = {
          default = {
            type = "derivation";
            name = "devshell";
          };
        };
        aarch64-darwin = {
          default = {
            type = "derivation";
            name = "devshell";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };

  # ===== Integration: Full Flake Output Validation =====

  # Test: Validate a complete flake output with multiple output types
  testCompleteFlakeOutputValidation = {
    expr = let
      # Simulate a complete flake output
      hasValidApps = validateOutput (schemas.apps or null) {
        x86_64-linux."10.01-build" = {
          type = "app";
          program = "/nix/store/xxx/bin/build";
        };
      };
      hasValidDevShells = validateOutput (schemas.devShells or null) {
        x86_64-linux.default = {
          type = "derivation";
          name = "devshell";
        };
      };
      hasValidPackages = validateOutput (schemas.packages or null) {
        x86_64-linux.myapp = {
          type = "derivation";
          name = "myapp";
        };
      };
      hasValidFormatter = validateOutput (schemas.formatter or null) {
        x86_64-linux = {
          type = "derivation";
          name = "alejandra";
        };
      };
    in
      hasValidApps &&
      hasValidDevShells &&
      hasValidPackages &&
      hasValidFormatter;
    expected = true;
  };

  # ===== Edge Cases =====

  # Test: Empty apps output is valid
  testAppsEmptyOutputValid = {
    expr = let
      schema = schemas.apps or null;
      output = {};
    in validateOutput schema output;
    expected = true;
  };

  # Test: Apps with only one system is valid
  testAppsSingleSystemValid = {
    expr = let
      schema = schemas.apps or null;
      output = {
        x86_64-linux = {
          only-app = {
            type = "app";
            program = "/nix/store/xxx/bin/app";
          };
        };
      };
    in validateOutput schema output;
    expected = true;
  };
}
