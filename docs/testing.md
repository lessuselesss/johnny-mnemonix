# Testing Guide

This document outlines testing procedures and guidelines for Johnny-Mnemonix.

## Test Structure

```
tests/
├── default.nix          # Main test suite
├── unit/               # Unit tests
│   ├── validation.nix
│   └── permissions.nix
├── integration/        # Integration tests
│   ├── structure.nix
│   └── plugins.nix
└── fixtures/          # Test data
    └── sample-structure.nix
```

## Unit Tests

### Validation Tests

```nix
# tests/unit/validation.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = import ../../lib { inherit pkgs; };
in
pkgs.lib.runTests {
  testValidAreaId = {
    expr = lib.schema.validate.areaId "10-19" "Personal";
    expected = true;
  };

  testInvalidAreaId = {
    expr = (lib.schema.validate.areaId "1019" "Invalid")
      or "invalid";
    expected = "invalid";
  };

  testValidCategoryId = {
    expr = lib.schema.validate.categoryId "11" "Finance";
    expected = true;
  };

  testValidItemId = {
    expr = lib.schema.validate.itemId "11.01" "Budget";
    expected = true;
  };
}
```

### Structure Tests

```nix
# tests/unit/structure.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = import ../../lib { inherit pkgs; };
in
pkgs.lib.runTests {
  testCreateStructure = {
    expr = lib.utils.path.makeItemPath {
      baseDir = "/home/user/Documents";
      areaId = "10-19";
      areaName = "Personal";
      categoryId = "11";
      categoryName = "Finance";
      itemId = "11.01";
      itemName = "Budget";
    };
    expected = "/home/user/Documents/10-19 Personal/11 Finance/11.01 Budget";
  };
}
```

## Integration Tests

### Basic Structure Test

```nix
# tests/integration/structure.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.nixosTest {
  name = "johnny-mnemonix-structure";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules ];
    
    johnny-mnemonix = {
      enable = true;
      baseDir = "/home/test/Documents";
      areas = {
        "10-19" = {
          name = "Personal";
          categories = {
            "11" = {
              name = "Finance";
              items = {
                "11.01" = "Budget";
              };
            };
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("home-manager-test.service")
    machine.succeed("test -d /home/test/Documents/10-19\\ Personal")
    machine.succeed("test -d /home/test/Documents/10-19\\ Personal/11\\ Finance")
    machine.succeed("test -d /home/test/Documents/10-19\\ Personal/11\\ Finance/11.01\\ Budget")
  '';
}
```

### Plugin Tests

```nix
# tests/integration/plugins.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.nixosTest {
  name = "johnny-mnemonix-plugins";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules ../../plugins/tags ];
    
    johnny-mnemonix = {
      enable = true;
      plugins.tags = {
        enable = true;
        tags = {
          "important" = "red";
          "archive" = "gray";
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("home-manager-test.service")
    machine.succeed("test -f /home/test/.config/johnny-mnemonix/tags.json")
  '';
}
```

## Performance Tests

```nix
# tests/performance/structure.nix
{ pkgs ? import <nixpkgs> {} }:

let
  lib = import ../../lib { inherit pkgs; };
  
  # Generate large test structure
  generateLargeStructure = count: 
    builtins.listToAttrs (builtins.genList (n: {
      name = "area-${toString n}";
      value = {
        categories = {
          "cat-${toString n}" = {
            items = {
              "item-${toString n}" = "Test Item ${toString n}";
            };
          };
        };
      };
    }) count);

in pkgs.nixosTest {
  name = "johnny-mnemonix-performance";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules ];
    
    johnny-mnemonix = {
      enable = true;
      areas = generateLargeStructure 1000;
    };
  };

  testScript = ''
    start_time = machine.succeed("date +%s.%N")
    machine.wait_for_unit("home-manager-test.service")
    end_time = machine.succeed("date +%s.%N")
    
    duration = float(end_time) - float(start_time)
    if duration > 5.0:
        raise Exception(f"Performance test failed: {duration}s > 5.0s")
  '';
}
```

## Running Tests

### All Tests
```bash
nix flake check
```

### Specific Tests
```bash
# Run unit tests
nix-build tests/unit

# Run integration tests
nix-build tests/integration

# Run performance tests
nix-build tests/performance
```

## Test Coverage

```nix
# tests/coverage.nix
{ pkgs ? import <nixpkgs> {} }:

let
  coverage = pkgs.nixosTest {
    name = "johnny-mnemonix-coverage";
    
    nodes.machine = { config, pkgs, ... }: {
      imports = [ ../../modules ];
      environment.systemPackages = [ pkgs.lcov ];
    };

    testScript = ''
      machine.succeed("lcov --capture --directory . --output-file coverage.info")
      machine.succeed("genhtml coverage.info --output-directory coverage")
    '';
  };
in coverage
```

## Continuous Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: cachix/install-nix-action@v12
      - run: nix flake check
```

## Writing New Tests

1. Create test file in appropriate directory
2. Follow existing test patterns
3. Include both positive and negative tests
4. Add performance considerations
5. Document test purpose and requirements

## Test Documentation

Each test file should include:
- Purpose of tests
- Requirements
- Expected outcomes
- Any special setup needed 