# Tests Cell (`tests`)

**Cell Type**: Test suite
**Purpose**: Comprehensive test coverage for johnny-declarative-decimal
**Blocks**: `unit.nix`, `integration.nix`, `e2e.nix`
**Status**: ✅ Unit tests complete (126/126 passing), Integration & E2E pending

---

## Overview

The `tests` cell provides comprehensive test coverage following **Test-Driven Development (TDD)** methodology. All library components were developed using strict RED → GREEN → REFACTOR cycles, ensuring:

- Tests written before implementation
- 100% test coverage on critical paths
- Clear API contracts defined by tests
- Regression prevention

---

## Test Philosophy

### RED → GREEN → REFACTOR

1. **🔴 RED**: Write failing test that defines desired behavior
2. **🟢 GREEN**: Write minimal code to make test pass
3. **🔵 REFACTOR**: Improve code while keeping tests green

### Coverage Goals

- **Primitives**: 95%+ (core functionality)
- **Composition**: 90%+ (integration points)
- **Builders**: 85%+ (higher-level)
- **Frameworks**: 80%+ (end-to-end)

---

## Directory Structure

```
nix/tests/
├── README.md                           # This file
├── CLAUDE.md                           # Test specifications
│
├── unit.nix                            # Block: Unit test exports
├── integration.nix                     # Block: Integration test exports
├── e2e.nix                             # Block: End-to-end test exports
│
├── primitives/
│   ├── number-systems.test.nix         # 20 tests ✅
│   ├── fields.test.nix                 # 15 tests ✅
│   ├── constraints.test.nix            # 10 tests ✅
│   └── templates.test.nix              # 10 tests ✅
│
├── composition/
│   ├── identifiers.test.nix            # 15 tests ✅
│   ├── ranges.test.nix                 # 10 tests ✅
│   ├── hierarchies.test.nix            # 12 tests ✅
│   └── validators.test.nix             # 8 tests ✅
│
├── builders/
│   ├── johnny-decimal.test.nix         # 10 tests ✅
│   ├── versioning.test.nix             # 8 tests ✅
│   └── classification.test.nix         # 8 tests ✅
│
├── types/                              # Type System Tests
│   ├── unit/
│   │   ├── common-types.nix            # Common JD types ⏳
│   │   ├── module-types-*.nix          # Module option types ⏳
│   │   ├── flake-types-standard.nix    # Standard flake types ✅
│   │   └── flake-types-flake-parts.nix # flake-parts integration ✅
│   ├── integration/
│   │   ├── schemas-validate-outputs.nix       # Schema validation ⏳
│   │   ├── schemas-validate-standard-outputs.nix  # Standard validation ✅
│   │   └── schemas-reject-invalid.nix  # Rejection tests ⏳
│   └── real-world/
│       ├── standard-outputs-community.nix  # Community patterns ✅
│       ├── nixos-community.nix            # NixOS modules ✅
│       ├── home-manager-community.nix     # home-manager ✅
│       └── nix-darwin-community.nix       # nix-darwin ✅
│
├── integration/                        # ⏳ Pending
│   ├── two-pass-loading.test.nix       # 5+ tests
│   ├── self-validation.test.nix        # 5+ tests
│   └── framework-integration.test.nix  # 5+ tests
│
└── e2e/                                # ⏳ Pending
    ├── home-manager.test.nix           # 3+ tests
    └── real-world-scenarios.test.nix   # 5+ tests
```

---

## Test Format

All tests follow **nixpkgs test format**:

```nix
{lib}: let
  component = lib.primitives.numberSystems;
in {
  # Test naming: test<ComponentName><What><Expected>
  testNumberSystemsDecimalParse = {
    expr = component.parse component.decimal "42";
    expected = 42;
  };

  testNumberSystemsInvalidReturnsNull = {
    expr = component.parse component.decimal "invalid";
    expected = null;
  };
}
```

**Convention**: Each test returns an attrset with:
- `expr`: The expression to evaluate
- `expected`: The expected result

---

## Running Tests

### All Tests
```bash
nix build .#checks.x86_64-linux.tests-all
```

### By Layer
```bash
# Primitives (55 tests)
nix build .#checks.x86_64-linux.primitives-all

# Composition (45 tests)
nix build .#checks.x86_64-linux.composition-all

# Builders (26 tests)
nix build .#checks.x86_64-linux.builders-all
```

### Individual Components
```bash
# Specific primitive
nix build .#checks.x86_64-linux.primitives-number-systems  # 20 tests
nix build .#checks.x86_64-linux.primitives-fields          # 15 tests

# Specific composition
nix build .#checks.x86_64-linux.composition-identifiers    # 15 tests
nix build .#checks.x86_64-linux.composition-hierarchies    # 12 tests

# Specific builder
nix build .#checks.x86_64-linux.builders-johnny-decimal    # 10 tests
nix build .#checks.x86_64-linux.builders-versioning        # 8 tests
```

### Watch Mode (Development)
```bash
# Re-run tests on file changes
nix build .#checks.x86_64-linux.primitives-all --rebuild
```

---

## Unit Tests (126/126 tests ✅)

### Primitives Layer (55 tests)

#### `number-systems.test.nix` (20 tests)
Tests for base conversion operations.

**Test Suites**:
1. Creation (2 tests): decimal, hex, binary, custom systems
2. Parsing (6 tests): valid, invalid, empty, leading zeros
3. Formatting (6 tests): decimal, hex, binary, zero, negative, large
4. Validation (4 tests): valid, invalid, empty, case sensitivity
5. Round-trip (2 tests): decimal, hex

**Example**:
```nix
testNumberSystemsDecimalParse = {
  expr = ns.parse ns.decimal "42";
  expected = 42;
};

testNumberSystemsHexFormat = {
  expr = ns.format ns.hex 255;
  expected = "FF";
};
```

#### `fields.test.nix` (15 tests)
Tests for constrained fields with width/padding.

**Test Suites**:
1. Fixed-width fields (5 tests): creation, zero padding, parsing, overflow, wrong width
2. Variable-width fields (3 tests): any length, formatting, hex
3. Padding modes (3 tests): none, zeros, spaces
4. Range derivation (4 tests): 2-digit, hex, variable, validation

**Example**:
```nix
testFieldsFormatZeroPadding = let
  field = fields.mk {
    system = ns.decimal;
    width = 3;
    padding = "zeros";
  };
in {
  expr = fields.format field 42;
  expected = "042";
};
```

#### `constraints.test.nix` (10 tests)
Tests for validation predicates.

**Test Suites**:
1. Range constraints (3 tests): accept, too low, too high
2. Enum constraints (3 tests): accept, reject, empty
3. Pattern constraints (2 tests): match, no match
4. Custom constraints (2 tests): predicate true, predicate false

**Example**:
```nix
testConstraintsRangeAccept = let
  constraint = constraints.range {min = 0; max = 99;};
in {
  expr = constraints.check constraint 50;
  expected = true;
};
```

#### `templates.test.nix` (10 tests)
Tests for template parsing and rendering.

**Test Suites**:
1. Template parsing (3 tests): simple, with widths, extract names
2. Rendering (4 tests): simple, missing field, with width, extra fields
3. Extraction (3 tests): from string, mismatch, validate width

**Example**:
```nix
testTemplatesRenderSimple = let
  template = templates.parse "{dept}-{year}";
in {
  expr = templates.render template {dept = "ENG"; year = "24";};
  expected = "ENG-24";
};
```

### Composition Layer (45 tests)

#### `identifiers.test.nix` (15 tests)
Tests for multi-field identifier composition.

**Test Suites**:
1. Creation (3 tests): 2-field, 3-field, separator
2. Parsing (4 tests): valid, invalid format, wrong field count, edge cases
3. Formatting (3 tests): 2-field, 3-field, missing field
4. Validation (3 tests): valid, invalid separator, incomplete
5. Round-trip (2 tests): parse→format, complex

**Example**:
```nix
testIdentifiersParse2Field = let
  id = identifiers.mk {
    fields = [field1 field2];
    separator = ".";
  };
in {
  expr = identifiers.parse id "10.05";
  expected = {field0 = 10; field1 = 5;};
};
```

#### `ranges.test.nix` (10 tests)
Tests for range operations and containment.

**Test Suites**:
1. Creation (2 tests): simple range, open-ended
2. Contains single identifier (3 tests): in range, out, open-ended
3. Range containment (3 tests): full, disjoint, partial
4. Validation (2 tests): well-formed, inverted

**Example**:
```nix
testRangesContainsIdentifier = let
  r = ranges.mk {start = [10 0]; end = [19 99];};
in {
  expr = ranges.contains r [15 5];
  expected = true;  # 15.05 is in 10.00-19.99
};
```

#### `hierarchies.test.nix` (12 tests)
Tests for multi-level hierarchy navigation.

**Test Suites**:
1. Creation (2 tests): hierarchy, level names
2. Level detection (2 tests): area vs item
3. Parent navigation (3 tests): item→category, category→area, area→null
4. Path generation (2 tests): full breadcrumb, partial
5. Validation (3 tests): valid, empty, too deep

**Example**:
```nix
testHierarchiesPathSimple = let
  hierarchy = mkJDHierarchy;
in {
  expr = hierarchies.path hierarchy [10 5 3];
  expected = "10 / 10.05 / 10.05.03";
};
```

#### `validators.test.nix` (8 tests)
Tests for constraint composition.

**Test Suites**:
1. Creation from constraints (2 tests): range, enum
2. Combining validators (3 tests): all pass, one fails, empty list
3. Validation with results (3 tests): pass, fail, combined types

**Example**:
```nix
testValidatorsCombineAllPass = let
  v1 = validators.fromConstraint (constraints.range {min = 0; max = 100;});
  v2 = validators.fromConstraint (constraints.enum [10 20 30 40 50]);
  combined = validators.combine [v1 v2];
in {
  expr = validators.check combined 30;
  expected = true;  # In range AND in enum
};
```

### Builders Layer (26 tests)

#### `johnny-decimal.test.nix` (10 tests)
Tests for Johnny Decimal system builder.

**Test Suites**:
1. Basic builder (3 tests): classic creation, parse, format
2. Customization (4 tests): hex, 3-level, separators, digits
3. Validation & constraints (3 tests): correct, incorrect, constraints

**Example**:
```nix
testBuildersJDParse = let
  jd = mkJohnnyDecimal {};
in {
  expr = jd.parse "10.05";
  expected = {category = 10; item = 5;};
};
```

#### `versioning.test.nix` (8 tests)
Tests for versioning system builder.

**Test Suites**:
1. Basic versioning (3 tests): semver, format, prerelease
2. Version comparison (3 tests): less than, equal, prerelease
3. Version bumping (2 tests): major, patch

**Example**:
```nix
testBuildersVersionCompareLT = let
  ver = mkVersioning {};
in {
  expr = ver.compare "1.2.3" "1.2.4";
  expected = -1;  # 1.2.3 < 1.2.4
};
```

#### `classification.test.nix` (8 tests)
Tests for classification system builder.

**Test Suites**:
1. Basic classification (3 tests): 3-level, path, validate
2. Navigation (3 tests): parent, ancestors, siblings
3. Presets (2 tests): Dewey Decimal, file system

**Example**:
```nix
testBuildersClassificationPath = let
  cls = mkClassification {depth = 3; separators = ["."];};
in {
  expr = cls.path [10 5 2];
  expected = "10 / 10.05 / 10.05.02";
};
```

---

## Integration Tests (⏳ Pending)

### Planned Tests (15+ tests)

#### `two-pass-loading.test.nix` (5 tests)
Tests for configuration two-pass loading.

**Planned Suites**:
1. Pass 1 parsing with defaults
2. Pass 2 validation with loaded config
3. Self-consistency assertions
4. Error handling on validation failure
5. Performance (< 5s for 100 modules)

#### `self-validation.test.nix` (5 tests)
Tests for self-validating configurations.

**Planned Suites**:
1. Config modules use JD naming
2. Config defines its own syntax
3. Bootstrap → validate → export cycle
4. Clear errors on mismatch
5. Metadata preservation

#### `framework-integration.test.nix` (5 tests)
Tests for framework-layer integration.

**Planned Suites**:
1. Classic JD framework
2. Hex variant framework
3. Framework composition
4. Home-manager integration
5. Cross-framework compatibility

---

## E2E Tests (⏳ Pending)

### Planned Tests (8+ tests)

#### `home-manager.test.nix` (3 tests)
Tests for full home-manager activation.

**Planned Suites**:
1. Directory creation succeeds
2. Index generation works
3. Git integration functional

#### `real-world-scenarios.test.nix` (5 tests)
Tests for realistic use cases.

**Planned Suites**:
1. Office workspace setup
2. Software project organization
3. Document management
4. Multi-user environment
5. Migration from manual JD

---

## Test Coverage Strategy

### Layer 1 (Primitives): Test every function
```nix
# For each function:
- Happy path (normal input)
- Edge cases (empty, null, boundary values)
- Error cases (invalid input)
- Type variations (where applicable)
```

### Layer 2 (Composition): Test integration
```nix
# For each composition:
- Components work together correctly
- Proper error propagation
- Expected outputs from varied inputs
- Round-trip tests (parse → format → parse)
```

### Layer 3 (Builders): Test defaults and customization
```nix
# For each builder:
- Default configuration works
- Each parameter can be customized
- Invalid configurations rejected
- Generated system is valid
```

---

## Test Naming Convention

```
test<Component><What><Expected>
```

**Examples**:
- `testNumberSystemsDecimalParse`: Tests number-systems decimal parsing
- `testIdentifiersFormat3Field`: Tests identifiers formatting with 3 fields
- `testBuildersJDValidateCorrect`: Tests johnny-decimal builder validation (correct case)

**Rules**:
- Use camelCase
- Start with `test`
- Include component name
- Describe what is being tested
- Optionally include expected behavior

---

## Adding New Tests

### 1. Create Test File

```nix
# nix/tests/my-layer/my-component.test.nix
{lib, nixpkgs}: let
  myComponent = lib.my-layer.my-component or null;
in
  if myComponent == null
  then {}
  else {
    testMyComponentBasic = {
      expr = myComponent.doSomething "input";
      expected = "output";
    };
  };
```

### 2. Add to Block Export

```nix
# nix/tests/unit.nix (or integration.nix, e2e.nix)
{inputs, cell}: let
  lib = inputs.self.lib.${inputs.nixpkgs.system};
in {
  my-layer = {
    my-component = import ./my-layer/my-component.test.nix {inherit lib;};
  };
}
```

### 3. Add Check to Flake

```nix
# In flake.nix checks
checks = {
  my-layer-my-component = nixpkgs.lib.runTests (import ./nix/tests/my-layer/my-component.test.nix {inherit lib;});
};
```

### 4. Run Test

```bash
nix build .#checks.x86_64-linux.my-layer-my-component
```

---

## Test Development Workflow

### TDD Cycle

```bash
# 1. Write test (RED)
vim nix/tests/primitives/my-component.test.nix

# 2. Verify test fails
nix build .#checks.x86_64-linux.primitives-my-component
# Should fail with expected error

# 3. Implement (GREEN)
vim nix/lib/primitives/my-component.nix

# 4. Verify test passes
nix build .#checks.x86_64-linux.primitives-my-component
# Should succeed

# 5. Refactor (REFACTOR)
vim nix/lib/primitives/my-component.nix
# Improve code, keep tests green

# 6. Commit
git add nix/tests/primitives/my-component.test.nix nix/lib/primitives/my-component.nix
git commit -m "feat(primitives): implement my-component with TDD"
```

---

## Current Status

### Completed (246+ tests)
- ✅ Primitives: 55/55 tests (100%)
- ✅ Composition: 45/45 tests (100%)
- ✅ Builders: 26/26 tests (100%)
- ✅ Types (Standard): 120+ tests (Unit + Integration + Real-world)
  - Unit: flake-types-standard, flake-types-flake-parts
  - Integration: schemas-validate-standard-outputs
  - Real-world: standard-outputs-community, nixos-community, home-manager-community, nix-darwin-community

### Pending
- ⏳ Types (Remaining): Common types, module types
- ⏳ Integration: 0/15 tests (0%)
- ⏳ E2E: 0/8 tests (0%)

**Total**: 246+/280+ tests (87.8%+)

---

## Type System Tests (120+ tests ✅)

The type system tests validate our complete type definitions for standard Nix flake outputs, ensuring compatibility with real-world community patterns.

### Unit Tests: Flake Type Definitions

#### `flake-types-standard.nix` (50+ tests)
Tests for standard Nix flake output types (apps, devShells, packages, etc.)

**Test Suites**:
1. Apps schema validation (10+ tests)
2. DevShells schema validation (8+ tests)
3. Packages schema validation (8+ tests)
4. Checks schema validation (6+ tests)
5. Overlays schema validation (6+ tests)
6. Templates schema validation (6+ tests)
7. Standard outputs structure validation (6+ tests)

**Example**:
```nix
testAppsSchemaValidatesCorrectOutput = {
  expr = let
    output = {
      x86_64-linux.hello = {
        type = "app";
        program = "/nix/store/xxx-hello/bin/hello";
      };
    };
  in validateSchema appsSchema output;
  expected = true;
};
```

#### `flake-types-flake-parts.nix` (40+ tests)
Tests for flake-parts integration with Johnny Decimal organization

**Test Suites**:
1. flake-parts module structure (8+ tests)
2. Apps with JD naming (10+ tests)
3. DevShells with JD naming (10+ tests)
4. Module class organization (8+ tests)
5. Per-system outputs validation (4+ tests)

**Example**:
```nix
testAppsSupportsJohnnyDecimalNames = {
  expr = let
    output = {
      x86_64-linux = {
        "10.01-build-docs" = { type = "app"; program = "..."; };
        "20.01-deploy-staging" = { type = "app"; program = "..."; };
      };
    };
  in validateSchema appsSchema output;
  expected = true;
};
```

### Integration Tests: Schema Validation

#### `schemas-validate-standard-outputs.nix` (30+ tests)
Tests that schemas correctly validate realistic flake output structures

**Test Suites**:
1. Apps validation (6+ tests)
2. DevShells validation (6+ tests)
3. Packages validation (6+ tests)
4. Multi-output validation (6+ tests)
5. Cross-system validation (6+ tests)

**Example**:
```nix
testCompleteFlakeOutputValidation = {
  expr = let
    hasValidApps = validateOutput schemas.apps {...};
    hasValidDevShells = validateOutput schemas.devShells {...};
    hasValidPackages = validateOutput schemas.packages {...};
  in hasValidApps && hasValidDevShells && hasValidPackages;
  expected = true;
};
```

### Real-World Tests: Community Patterns

#### `standard-outputs-community.nix` (30+ tests)
Tests that our schemas validate actual community flake patterns

**Test Suites**:
1. nixpkgs legacyPackages structure (4+ tests)
2. home-manager modules (4+ tests)
3. Standard apps/devShells/packages patterns (9+ tests)
4. Overlays and templates (4+ tests)
5. Cross-system and edge cases (6+ tests)
6. Schema consistency (3+ tests)

**Example**:
```nix
testAppsDescriptiveNamesPattern = {
  expr = let
    # Pattern seen in community configs
    testOutput = {
      x86_64-linux = {
        "deploy-nixos" = { type = "app"; program = "..."; };
        "update-flake" = { type = "app"; program = "..."; };
      };
    };
  in validateSchema schemas.apps testOutput;
  expected = true;
};
```

#### `nixos-community.nix` (14+ tests)
Tests NixOS module and configuration patterns from the community

**Test Suites**:
1. nixosModules schema validation (4+ tests)
2. nixosConfigurations schema validation (4+ tests)
3. Community organization patterns (2+ tests)
4. Johnny Decimal naming support (2+ tests)
5. Schema properties validation (2+ tests)

#### `home-manager-community.nix` (16+ tests)
Tests home-manager module and configuration patterns

**Test Suites**:
1. homeModules schema validation (4+ tests)
2. homeConfigurations schema validation (4+ tests)
3. Tool category organization (3+ tests)
4. Development environment patterns (2+ tests)
5. Alias compatibility (1+ tests)
6. Schema properties validation (2+ tests)

#### `nix-darwin-community.nix` (14+ tests)
Tests nix-darwin module and configuration patterns for macOS

**Test Suites**:
1. darwinModules schema validation (4+ tests)
2. darwinConfigurations schema validation (4+ tests)
3. macOS subsystem patterns (2+ tests)
4. Mixed architecture support (2+ tests)
5. Schema properties validation (2+ tests)

---

## Related Documentation

- **Implementation Details**: See `nix/lib/README.md`
- **Test Specifications**: See `CLAUDE.md` in this directory
- **Project Overview**: See root `CLAUDE.md`
- **Vision & Roadmap**: See root `TODO.md`

---

## Contributing

When adding tests:
1. Follow TDD methodology (RED → GREEN → REFACTOR)
2. Use clear test naming conventions
3. Test happy path + edge cases + error cases
4. Document test suites in test file comments
5. Update test counts in this README
6. Add check to flake.nix

---

## Troubleshooting

### Test Fails to Build
```bash
# Check syntax
nix build .#checks.x86_64-linux.my-test --show-trace

# Evaluate test directly
nix eval .#checks.x86_64-linux.my-test --json
```

### Test Passes but Shouldn't
- Verify `expr` actually calls the function
- Check `expected` value is correct
- Ensure test isn't accidentally true

### Test Framework Error
- Verify test file returns attrset of tests
- Ensure each test has both `expr` and `expected`
- Check for typos in attribute names
