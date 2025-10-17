# Tests Cell - Johnny Declarative Decimal

**Cell Type**: `tests`
**Purpose**: Comprehensive test suite across all layers
**Blocks**: `unit.nix`, `integration.nix`, `e2e.nix`

---

## Phase 1: Requirements

### Cell Overview

The `tests` cell provides comprehensive test coverage following TDD methodology. Tests are organized by layer and scope:

- **Unit tests**: Individual functions in isolation
- **Integration tests**: Components working together
- **End-to-end tests**: Full system scenarios

### Testing Philosophy

**RED → GREEN → REFACTOR**:
1. 🔴 Write failing test (proves test works)
2. 🟢 Write minimal code to pass
3. 🔵 Refactor while keeping tests green

**Coverage Goals**:
- Primitives: 95%+ (core functionality)
- Composition: 90%+ (integration points)
- Builders: 85%+ (higher-level)
- Frameworks: 80%+ (end-to-end)

---

## Phase 2: Design

### Cell Structure

```
nix/tests/
├── CLAUDE.md                           # This file
├── unit.nix                            # Block: Unit test exports
├── integration.nix                     # Block: Integration test exports
├── e2e.nix                             # Block: End-to-end test exports
├── primitives/
│   ├── number-systems.test.nix         # 20+ tests
│   ├── fields.test.nix                 # 15+ tests
│   ├── constraints.test.nix            # 10+ tests
│   └── templates.test.nix              # 10+ tests
├── composition/
│   ├── identifiers.test.nix            # 15+ tests
│   ├── ranges.test.nix                 # 10+ tests
│   ├── hierarchies.test.nix            # 12+ tests
│   └── validators.test.nix             # 8+ tests
├── builders/
│   ├── johnny-decimal.test.nix         # 10+ tests
│   ├── versioning.test.nix             # 8+ tests
│   └── classification.test.nix         # 8+ tests
├── integration/
│   ├── two-pass-loading.test.nix       # 5+ tests
│   ├── self-validation.test.nix        # 5+ tests
│   └── framework-integration.test.nix  # 5+ tests
└── e2e/
    ├── home-manager.test.nix           # 3+ tests
    └── real-world-scenarios.test.nix   # 5+ tests
```

### Block Exports

#### unit.nix (Block)
```nix
{
  inputs,
  cell,
}: let
  lib = inputs.self.lib.${inputs.nixpkgs.system};
in {
  primitives = {
    number-systems = import ./primitives/number-systems.test.nix {inherit lib;};
    fields = import ./primitives/fields.test.nix {inherit lib;};
    constraints = import ./primitives/constraints.test.nix {inherit lib;};
    templates = import ./primitives/templates.test.nix {inherit lib;};
  };

  composition = {
    identifiers = import ./composition/identifiers.test.nix {inherit lib;};
    ranges = import ./composition/ranges.test.nix {inherit lib;};
    hierarchies = import ./composition/hierarchies.test.nix {inherit lib;};
    validators = import ./composition/validators.test.nix {inherit lib;};
  };

  builders = {
    johnny-decimal = import ./builders/johnny-decimal.test.nix {inherit lib;};
    versioning = import ./builders/versioning.test.nix {inherit lib;};
    classification = import ./builders/classification.test.nix {inherit lib;};
  };
}
```

### Test Format

All tests follow nixpkgs test format:

```nix
# Example test file
{lib}: let
  component = lib.primitives.numberSystems;
in {
  # Test naming: test<ComponentName><What><Expected>
  testNumberSystemsDecimalParse = {
    expr = component.parse component.decimal "42";
    expected = 42;
  };

  testNumberSystemsHexParse = {
    expr = component.parse component.hex "FF";
    expected = 255;
  };

  testNumberSystemsInvalidReturnsNull = {
    expr = component.parse component.decimal "invalid";
    expected = null;
  };
}
```

### Running Tests

```bash
# All tests
nix build .#checks.<system>.tests-all

# Specific layer
nix build .#checks.<system>.tests-primitives
nix build .#checks.<system>.tests-composition
nix build .#checks.<system>.tests-builders

# Specific test file
nix build .#checks.<system>.tests-primitives-number-systems
```

---

## Phase 3: Implementation

### TDD Workflow Example

#### Step 1: 🔴 RED - Write Failing Test

```nix
# nix/tests/primitives/number-systems.test.nix
{lib}: let
  ns = lib.primitives.numberSystems;
in {
  # Test that doesn't exist yet
  testNumberSystemsDecimalParse = {
    expr = ns.parse ns.decimal "42";
    expected = 42;
  };
}
```

Run: `nix build .#checks.<system>.tests-primitives-number-systems`
Result: **FAILS** - `ns.parse` is not defined

#### Step 2: 🟢 GREEN - Minimal Implementation

```nix
# nix/lib/primitives/number-systems.nix
{lib}: {
  decimal = {radix = 10; alphabet = "0123456789";};

  parse = sys: str:
    # Minimal implementation
    lib.toInt str;  # Simple, doesn't handle errors
}
```

Run: `nix build .#checks.<system>.tests-primitives-number-systems`
Result: **PASSES** ✓

#### Step 3: 🔴 RED - Add Edge Case Test

```nix
testNumberSystemsInvalidReturnsNull = {
  expr = ns.parse ns.decimal "invalid";
  expected = null;
};
```

Result: **FAILS** - throws error instead of returning null

#### Step 4: 🟢 GREEN - Handle Edge Case

```nix
parse = sys: str:
  let
    result = builtins.tryEval (lib.toInt str);
  in
    if result.success then result.value else null;
```

Result: **PASSES** ✓

#### Step 5: 🔵 REFACTOR - Improve Implementation

```nix
parse = sys: str:
  let
    # More robust parsing using alphabet
    charToValue = c: /* ... */;
    chars = lib.stringToCharacters str;
    values = map charToValue chars;
  in
    if builtins.all (v: v != null) values
    then /* convert to number */
    else null;
```

Run tests: **STILL PASSES** ✓

### Test Coverage Strategy

**Layer 1 (Primitives)**: Test every function, every parameter, every edge case
```nix
# For each function:
- Happy path (normal input)
- Edge cases (empty, null, boundary values)
- Error cases (invalid input)
- Type variations (where applicable)
```

**Layer 2 (Composition)**: Test integration between primitives
```nix
# For each composition:
- Components work together correctly
- Proper error propagation
- Expected outputs from varied inputs
- Round-trip tests (parse → format → parse)
```

**Layer 3 (Builders)**: Test defaults and customization
```nix
# For each builder:
- Default configuration works
- Each parameter can be customized
- Invalid configurations rejected
- Generated system is valid
```

**Integration**: Test cross-layer interactions
```nix
# For two-pass loading:
- Pass 1 parses with defaults
- Pass 2 validates with loaded config
- Self-consistency assertions
- Error messages on failure
```

**E2E**: Test realistic scenarios
```nix
# For home-manager:
- Full activation succeeds
- Directories created correctly
- Index generated properly
- Git integration works
```

### Test Organization Checklist

**Unit Tests (135+ total)**:
- [ ] primitives/number-systems.test.nix (20 tests)
- [ ] primitives/fields.test.nix (15 tests)
- [ ] primitives/constraints.test.nix (10 tests)
- [ ] primitives/templates.test.nix (10 tests)
- [ ] composition/identifiers.test.nix (15 tests)
- [ ] composition/ranges.test.nix (10 tests)
- [ ] composition/hierarchies.test.nix (12 tests)
- [ ] composition/validators.test.nix (8 tests)
- [ ] builders/johnny-decimal.test.nix (10 tests)
- [ ] builders/versioning.test.nix (8 tests)
- [ ] builders/classification.test.nix (8 tests)

**Integration Tests (15+ total)**:
- [ ] integration/two-pass-loading.test.nix (5 tests)
- [ ] integration/self-validation.test.nix (5 tests)
- [ ] integration/framework-integration.test.nix (5 tests)

**E2E Tests (8+ total)**:
- [ ] e2e/home-manager.test.nix (3 tests)
- [ ] e2e/real-world-scenarios.test.nix (5 tests)

---

## Next Steps

1. Create test files in parallel with implementation
2. Follow strict TDD: RED → GREEN → REFACTOR
3. Maintain high coverage throughout development
4. Run full test suite before commits
