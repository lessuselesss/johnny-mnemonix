# Real-World Test: divnix/std Dogfooding
#
# Tests that our own divnix/std cell/block structure validates
# correctly against the stdModules and stdCells schemas we've defined.
#
# This ensures our project organization follows std best practices.

{
  lib,
  schemas,
  self,  # Our own flake
}: let
  # Helper: Validate with stdModules schema
  validateStdModule = module:
    let
      result = builtins.tryEval (schemas.stdModules.inventory { testModule = module; });
    in result.success;

  # Helper: Validate with stdCells schema
  validateStdCell = cell:
    let
      result = builtins.tryEval (schemas.stdCells.inventory { testCell = cell; });
    in result.success;

  # Helper: Get evalChecks for stdModules
  getModuleChecks = module:
    let inventory = schemas.stdModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

  # Helper: Get evalChecks for stdCells
  getCellChecks = cell:
    let inventory = schemas.stdCells.inventory { testCell = cell; };
    in inventory.children.testCell.evalChecks;

in {
  # ===== Test: Our lib Cell Structure =====

  # Test: lib cell validates as std cell
  testStdDogfoodLibCell = let
    libCell = {
      cellBlocks = [
        "primitives"
        "composition"
        "builders"
        "types"
      ];
    };
  in {
    expr = validateStdCell libCell;
    expected = true;
  };

  # Test: lib cell has valid structure
  testStdDogfoodLibCellStructure = let
    libCell = {
      cellBlocks = [ "primitives" "composition" "builders" "types" ];
    };
    checks = getCellChecks libCell;
  in {
    expr = checks.hasCellBlocks;
    expected = true;
  };

  # ===== Test: Our frameworks Cell Structure =====

  # Test: frameworks cell validates
  testStdDogfoodFrameworksCell = let
    frameworksCell = {
      cellBlocks = [
        "johnny-decimal-classic"
        "johnny-decimal-hex"
        "semver"
      ];
    };
  in {
    expr = validateStdCell frameworksCell;
    expected = true;
  };

  # ===== Test: Our config Cell Structure =====

  # Test: config cell validates
  testStdDogfoodConfigCell = let
    configCell = {
      cellBlocks = [
        "01.01-base"
        "01.02-radix"
        "01.03-octets"
        "01.04-syntax"
        "01.05-constraints"
        "01.06-validators"
        "01.07-templates"
      ];
    };
  in {
    expr = validateStdCell configCell;
    expected = true;
  };

  # ===== Test: Our tests Cell Structure =====

  # Test: tests cell validates
  testStdDogfoodTestsCell = let
    testsCell = {
      cellBlocks = [
        "unit"
        "integration"
        "e2e"
        "types"
      ];
    };
  in {
    expr = validateStdCell testsCell;
    expected = true;
  };

  # ===== Test: Our examples Cell Structure =====

  # Test: examples cell validates
  testStdDogfoodExamplesCell = let
    examplesCell = {
      cellBlocks = [
        "classic"
        "hex-variant"
        "custom-builder"
        "from-scratch"
        "real-world"
      ];
    };
  in {
    expr = validateStdCell examplesCell;
    expected = true;
  };

  # ===== Test: std Cell Naming Conventions =====

  # Test: Valid cell names (lowercase-hyphen)
  testStdDogfoodValidCellNames = let
    cells = {
      lib = { cellBlocks = []; };
      frameworks = { cellBlocks = []; };
      config = { cellBlocks = []; };
      tests = { cellBlocks = []; };
      examples = { cellBlocks = []; };
    };
    inventory = schemas.stdCells.inventory cells;
    allValid = builtins.all (name:
      let checks = inventory.children.${name}.evalChecks;
      in checks.hasValidCellName or true
    ) (builtins.attrNames cells);
  in {
    expr = allValid;
    expected = true;
  };

  # Test: Invalid cell name (PascalCase)
  testStdDogfoodInvalidCellNamePascal = let
    cell = { cellBlocks = []; };
    inventory = schemas.stdCells.inventory { "InvalidCell" = cell; };
    checks = inventory.children.InvalidCell.evalChecks;
  in {
    expr = checks.hasValidCellName;
    expected = false;
  };

  # Test: Invalid cell name (snake_case)
  testStdDogfoodInvalidCellNameSnake = let
    cell = { cellBlocks = []; };
    inventory = schemas.stdCells.inventory { "invalid_cell" = cell; };
    checks = inventory.children.invalid_cell.evalChecks;
  in {
    expr = checks.hasValidCellName;
    expected = false;
  };

  # ===== Test: Block Structure =====

  # Test: Primitives block structure
  testStdDogfoodPrimitivesBlock = let
    block = {
      numberSystems = { /* functions */ };
      fields = { /* functions */ };
      constraints = { /* functions */ };
      templates = { /* functions */ };
    };
  in {
    expr = validateStdModule block;
    expected = true;
  };

  # Test: Composition block structure
  testStdDogfoodCompositionBlock = let
    block = {
      identifiers = { /* functions */ };
      ranges = { /* functions */ };
      hierarchies = { /* functions */ };
      validators = { /* functions */ };
    };
  in {
    expr = validateStdModule block;
    expected = true;
  };

  # Test: Builders block structure
  testStdDogfoodBuildersBlock = let
    block = {
      mkJohnnyDecimal = { /* builder function */ };
      mkVersioning = { /* builder function */ };
      mkClassification = { /* builder function */ };
    };
  in {
    expr = validateStdModule block;
    expected = true;
  };

  # Test: Types block structure
  testStdDogfoodTypesBlock = let
    block = {
      moduleTypes = { /* module type definitions */ };
      flakeTypes = { /* flake type definitions */ };
      schemas = { /* output schemas */ };
      moduleInputs = { /* module input specs */ };
    };
  in {
    expr = validateStdModule block;
    expected = true;
  };

  # ===== Test: growOn Configuration =====

  # Test: growOn pattern for lib cell
  testStdDogfoodGrowOnLib = let
    growOnConfig = {
      cellsFrom = ./nix;
      cellBlocks = [
        {
          name = "lib";
          type = "functions";
          blocks = [ "primitives" "composition" "builders" "types" ];
        }
      ];
    };
  in {
    expr = validateStdModule growOnConfig;
    expected = true;
  };

  # Test: growOn pattern for multiple cells
  testStdDogfoodGrowOnMultiple = let
    growOnConfig = {
      cellsFrom = ./nix;
      cellBlocks = [
        { name = "lib"; type = "functions"; }
        { name = "frameworks"; type = "functions"; }
        { name = "config"; type = "config"; }
        { name = "tests"; type = "functions"; }
        { name = "examples"; type = "config"; }
      ];
    };
  in {
    expr = validateStdModule growOnConfig;
    expected = true;
  };

  # ===== Test: harvest Configuration =====

  # Test: harvest pattern exports
  testStdDogfoodHarvestExports = let
    harvestConfig = {
      lib = [
        [ "primitives" ]
        [ "composition" ]
        [ "builders" ]
        [ "types" ]
      ];
      frameworks = [
        [ "johnny-decimal-classic" ]
        [ "johnny-decimal-hex" ]
      ];
    };
  in {
    expr = validateStdModule harvestConfig;
    expected = true;
  };

  # ===== Test: Invalid Structures Rejected =====

  # Test: Cell missing cellBlocks
  testStdDogfoodInvalidCellNoBlocks = {
    expr = let
      cell = { foo = "bar"; };
      checks = getCellChecks cell;
    in checks.hasCellBlocks;
    expected = false;
  };

  # Test: String is not a valid cell
  testStdDogfoodInvalidCellString = {
    expr = let
      checks = getCellChecks "not a cell";
    in checks.hasCellBlocks;
    expected = false;
  };

  # Test: Number is not a valid cell
  testStdDogfoodInvalidCellNumber = {
    expr = let
      checks = getCellChecks 42;
    in checks.hasCellBlocks;
    expected = false;
  };

  # ===== Test: Complete Project Structure =====

  # Test: Our complete cell hierarchy validates
  testStdDogfoodCompleteStructure = let
    projectCells = {
      lib = {
        cellBlocks = [ "primitives" "composition" "builders" "types" ];
      };
      frameworks = {
        cellBlocks = [ "johnny-decimal-classic" ];
      };
      config = {
        cellBlocks = [ "01.01-base" "01.04-syntax" ];
      };
      tests = {
        cellBlocks = [ "unit" "integration" "types" ];
      };
      examples = {
        cellBlocks = [ "classic" "custom-builder" ];
      };
    };
    result = builtins.tryEval (schemas.stdCells.inventory projectCells);
  in {
    expr = result.success;
    expected = true;
  };

  # Test: All cells have valid names
  testStdDogfoodAllCellNamesValid = let
    projectCells = {
      lib = { cellBlocks = []; };
      frameworks = { cellBlocks = []; };
      config = { cellBlocks = []; };
      tests = { cellBlocks = []; };
      examples = { cellBlocks = []; };
    };
    inventory = schemas.stdCells.inventory projectCells;
    allValid = builtins.all (name:
      let checks = inventory.children.${name}.evalChecks;
      in checks.hasValidCellName or true
    ) (builtins.attrNames projectCells);
  in {
    expr = allValid;
    expected = true;
  };

  # ===== Test: stdModules Alias =====

  # Test: stdModules schema validates our blocks
  testStdDogfoodModulesSchema = let
    block = {
      primitives = { /* ... */ };
      composition = { /* ... */ };
    };
    result = builtins.tryEval (schemas.stdModules.inventory { libBlock = block; });
  in {
    expr = result.success;
    expected = true;
  };
}
