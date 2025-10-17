# Types Layer Tests

Comprehensive testing of the types layer against real-world community flakes and modules.

## Quick Start

```bash
# Run all types tests
nix build .#checks.x86_64-linux.types-unit
nix build .#checks.x86_64-linux.types-integration
nix build .#checks.x86_64-linux.types-real-world

# Run specific test suite
nix build .#checks.x86_64-linux.types-unit-common
nix build .#checks.x86_64-linux.types-unit-nixos
nix build .#checks.x86_64-linux.types-real-world-dogfood
```

## Test Structure

### Level 1: Unit Tests (`unit/`)

Tests individual module type definitions in isolation:
- Each module type validates correct inputs
- Each module type rejects invalid inputs
- Edge cases are handled properly

**Fast, pure, no external dependencies**

### Level 2: Integration Tests (`integration/`)

Tests the complete type system working together:
- Module types work in real module definitions
- Flake types integrate with flake-parts
- Schemas validate flake outputs correctly
- types.nix aggregation works

**Moderate speed, may import small test modules**

### Level 3: Real-World Tests (`real-world/`)

Tests against actual community flakes and modules:
- Validates compatibility with established patterns
- Catches edge cases from production usage
- Ensures our types don't break existing workflows

**Slower, imports external flakes via fetchGit/fetchFromGitHub**

## Test Methodology

### TDD Approach

All tests follow RED → GREEN → REFACTOR:

1. **🔴 RED**: Write failing test showing what should work
2. **🟢 GREEN**: Fix type definition to pass test
3. **🔵 REFACTOR**: Improve type definition while keeping tests green

### Test Format

```nix
{
  lib,
  types,  # From lib.types.moduleTypes or lib.types.flakeTypes
}: {
  # Test name clearly states what's being tested
  testDescriptiveName = {
    expr = /* test expression */;
    expected = /* expected result */;
  };
}
```

## Real-World Test Targets

See [TESTING.md](../../lib/types/TESTING.md) for complete list of community flakes we test against.

### Summary

- **Standard**: nixpkgs, home-manager, nix-darwin
- **Custom**: dendrix, system-manager, typix, colmena
- **Dogfood**: Our own johnny-mnemonix and std usage
- **Meta**: flake-parts examples

## Running Tests

### All Tests

```bash
nix flake check
```

### Specific Test Level

```bash
# Unit tests only
nix build .#checks.x86_64-linux.types-unit

# Integration tests only
nix build .#checks.x86_64-linux.types-integration

# Real-world tests only
nix build .#checks.x86_64-linux.types-real-world
```

### Individual Test File

```bash
# Test common JD types
nix build .#checks.x86_64-linux.types-unit-common

# Test NixOS module types
nix build .#checks.x86_64-linux.types-unit-nixos

# Dogfood test (our own usage)
nix build .#checks.x86_64-linux.types-real-world-dogfood
```

## Writing New Tests

### 1. Identify Test Level

- **Unit**: Testing a single type definition? → `unit/`
- **Integration**: Testing types working together? → `integration/`
- **Real-World**: Testing against community flake? → `real-world/`

### 2. Create Test File

```nix
# nix/tests/types/unit/my-new-test.nix
{
  lib,
  types,
}: {
  testMyFeature = {
    expr = /* test code */;
    expected = /* expected value */;
  };
}
```

### 3. Add to Flake Checks

```nix
# In flake.nix or test aggregation file
checks = {
  types-unit-my-new-test = import ./tests/types/unit/my-new-test.nix {
    inherit lib;
    types = self.lib.${system}.types.moduleTypes;
  };
};
```

### 4. Run Test

```bash
nix build .#checks.x86_64-linux.types-unit-my-new-test
```

## Test Coverage Goals

- **Unit Tests**: 100% coverage of all type definitions
- **Integration Tests**: All flake type + schema combinations
- **Real-World Tests**: Minimum 3 community flakes per type

## External Dependencies

Some tests require fetching community flakes. These are defined in `fixtures/community-flakes.nix`:

```nix
{
  nixpkgs = fetchFromGitHub { /* ... */ };
  homeManager = fetchFromGitHub { /* ... */ };
  # etc.
}
```

**Note**: Real-world tests may be slower due to network fetching. They're cached after first run.

## Contributing

When adding new type definitions:

1. Write unit tests first (TDD!)
2. Write integration tests showing usage
3. Identify at least one real-world project to test against
4. Update this README if adding new test patterns

## Related Documentation

- **Testing Strategy**: [../../lib/types/TESTING.md](../../lib/types/TESTING.md)
- **Types Documentation**: [../../lib/types/CLAUDE.md](../../lib/types/CLAUDE.md)
- **Project Tests**: [../README.md](../README.md)
