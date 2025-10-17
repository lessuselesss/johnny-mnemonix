# Integration Tests: Flake Schemas Validate Outputs
#
# Tests that our flake-schemas definitions correctly validate (and reject)
# various flake outputs.
#
# This is Level 2 testing - schemas working with actual flake outputs.

{
  lib,
  schemas,  # lib.types.schemas (all schemas)
}: let
  # Helper: Run schema validation
  validateOutput = schema: output: let
    inventory = schema.inventory output;
  in
    # Schema validation succeeds if inventory can be computed without error
    builtins.tryEval inventory;

  # Helper: Check all evalChecks pass
  allChecksPass = checks:
    builtins.all (check: check == true || check == null) (builtins.attrValues checks);

in {
  # ===== nixosModules Schema Tests =====

  # Test: Valid function-based NixOS module passes
  testNixosModulesFunctionValid = let
    output = {
      myModule = {config, pkgs, ...}: {
        services.nginx.enable = true;
      };
    };
    result = validateOutput schemas.nixosModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: Valid attrs-based NixOS module passes
  testNixosModulesAttrsValid = let
    output = {
      myModule = {
        options = {};
        config = {};
      };
    };
    result = validateOutput schemas.nixosModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: evalChecks validate importable modules
  testNixosModulesEvalChecks = let
    output = {
      validModule = {config, ...}: {};
      invalidModule = "not a module";
    };
    inventory = schemas.nixosModules.inventory output;
    validChecks = inventory.children.validModule.evalChecks;
    invalidChecks = inventory.children.invalidModule.evalChecks;
  in {
    expr = {
      validIsImportable = validChecks.isImportable;
      invalidIsImportable = invalidChecks.isImportable;
    };
    expected = {
      validIsImportable = true;
      invalidIsImportable = false;
    };
  };

  # ===== homeModules Schema Tests =====

  # Test: Valid home-manager module passes
  testHomeModulesValid = let
    output = {
      myConfig = {config, pkgs, ...}: {
        programs.git.enable = true;
      };
    };
    result = validateOutput schemas.homeModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # ===== jmModules Schema Tests =====

  # Test: Valid JM configuration passes
  testJmModulesValid = let
    output = {
      workspace = {
        baseDir = "/home/user/Documents";
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {};
          };
        };
      };
    };
    result = validateOutput schemas.jmModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: JD filename validation works
  testJmModulesJdFilenameCheck = let
    output = {
      "workspace" = {baseDir = "/home/user"; areas = {};};
      "[10.05]{10-19}__(10 Code)__[05 Lib]" = {baseDir = "/home/user"; areas = {};};
    };
    inventory = schemas.jmModules.inventory output;
    normalCheck = inventory.children.workspace.evalChecks.hasJDFilename;
    jdCheck = inventory.children."[10.05]{10-19}__(10 Code)__[05 Lib]".evalChecks.hasJDFilename;
  in {
    expr = {
      normalHasJdFilename = normalCheck;
      jdHasJdFilename = jdCheck;
    };
    expected = {
      normalHasJdFilename = false;  # Normal name doesn't match JD pattern
      jdHasJdFilename = true;  # JD filename matches pattern
    };
  };

  # Test: Invalid area range detected
  testJmModulesInvalidAreaRange = let
    output = {
      workspace = {
        baseDir = "/home/user";
        areas = {
          "invalid" = {  # Should be XX-YY format
            name = "Bad";
            categories = {};
          };
        };
      };
    };
    inventory = schemas.jmModules.inventory output;
    checks = inventory.children.workspace.evalChecks;
  in {
    expr = checks.areasAreValid;
    expected = false;
  };

  # ===== dendrixModules Schema Tests =====

  # Test: Valid aspect module passes
  testDendrixModulesValid = let
    output = {
      networking = {
        imports = [];
        exports = {};
      };
    };
    result = validateOutput schemas.dendrixModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: Invalid aspect name detected
  testDendrixModulesInvalidAspectName = let
    output = {
      "BadName" = {imports = []; exports = {};};  # Should be lowercase-hyphen
      "good-name" = {imports = []; exports = {};};
    };
    inventory = schemas.dendrixModules.inventory output;
    badCheck = inventory.children."BadName".evalChecks.hasValidAspectName;
    goodCheck = inventory.children."good-name".evalChecks.hasValidAspectName;
  in {
    expr = {
      badIsValid = badCheck;
      goodIsValid = goodCheck;
    };
    expected = {
      badIsValid = false;
      goodIsValid = true;
    };
  };

  # ===== typixModules Schema Tests =====

  # Test: Valid typix project passes
  testTypixModulesValid = let
    output = {
      "my-doc" = {
        src = /path/to/docs;
        entrypoint = "main.typ";
      };
    };
    result = validateOutput schemas.typixModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: Missing required fields detected
  testTypixModulesMissingFields = let
    output = {
      "incomplete" = {
        # Missing src and entrypoint
      };
    };
    inventory = schemas.typixModules.inventory output;
    checks = inventory.children.incomplete.evalChecks;
  in {
    expr = {
      hasSrc = checks.hasSrc;
      hasEntrypoint = checks.hasEntrypoint;
    };
    expected = {
      hasSrc = false;
      hasEntrypoint = false;
    };
  };

  # ===== stdModules Schema Tests =====

  # Test: Valid std cell passes
  testStdModulesValid = let
    output = {
      lib = {
        cellBlocks = ["primitives" "composition"];
      };
    };
    result = validateOutput schemas.stdModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # ===== flakeModules Schema Tests =====

  # Test: Valid flake-parts module passes
  testFlakeModulesValid = let
    output = {
      myModule = {
        perSystem = {config, ...}: {};
        flake = {};
      };
    };
    result = validateOutput schemas.flakeModules output;
  in {
    expr = result.success;
    expected = true;
  };

  # Test: Detects modules with perSystem or flake
  testFlakeModulesStructureCheck = let
    output = {
      hasPerSystem = {perSystem = {};};
      hasFlake = {flake = {};};
      hasNeither = {something = "else";};
    };
    inventory = schemas.flakeModules.inventory output;
  in {
    expr = {
      perSystemValid = inventory.children.hasPerSystem.evalChecks.hasPerSystemOrFlake;
      flakeValid = inventory.children.hasFlake.evalChecks.hasPerSystemOrFlake;
      neitherValid = inventory.children.hasNeither.evalChecks.hasPerSystemOrFlake;
    };
    expected = {
      perSystemValid = true;
      flakeValid = true;
      neitherValid = false;
    };
  };
}
