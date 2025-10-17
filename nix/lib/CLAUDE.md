# Library Cell - Johnny Declarative Decimal

> **Quick Reference**: See [README.md](./README.md) for usage guide, examples, quick start, and complete API documentation.

**Cell Type**: `lib`
**Purpose**: Core library implementation across 3 layers
**Blocks**: `primitives.nix`, `composition.nix`, `builders.nix`
**Status**: ✅ Complete (126/126 tests passing)

---

## Phase 1: Requirements

### Cell Overview

The `lib` cell contains the foundational library code for johnny-declarative-decimal. It is organized into three layers that build upon each other, following the principle of progressive abstraction.

### User Stories

#### US-LIB-1: Primitive Operations
**As a** library user
**I want** atomic, composable primitives
**So that** I can build custom number systems from scratch

**Acceptance Criteria**:
- Number system operations (create, parse, format, validate)
- Field operations (constrained numbers with width/padding)
- Constraint predicates (range, enum, pattern, custom)
- Template operations (parse, render, validate)
- All operations are pure functions with no side effects

#### US-LIB-2: Composition Layer
**As a** library user
**I want** to combine primitives into higher-level structures
**So that** I don't have to reinvent composition patterns

**Acceptance Criteria**:
- Identifier composition from multiple fields
- Range derivation from fields
- Hierarchy tree construction
- Validator composition
- All compositions maintain referential transparency

#### US-LIB-3: Builder Layer
**As a** library user
**I want** convenient constructors for common patterns
**So that** I can quickly create standard systems

**Acceptance Criteria**:
- mkJohnnyDecimal builder
- mkVersioning builder
- mkClassification builder
- mkProjectSystem builder
- Sensible defaults with full customization

### Dependencies

**Required**:
- nixpkgs.lib (for string/list utilities)
- Nix builtins (for regex, type operations)

**No external dependencies** - this is a pure library

---

## Phase 2: Design

### Cell Structure

```
nix/lib/
├── CLAUDE.md                  # This file
├── primitives.nix             # Block: Layer 1 exports
├── primitives/
│   ├── CLAUDE.md              # Detailed primitives spec
│   ├── number-systems.nix     # Number system operations
│   ├── fields.nix             # Field operations
│   ├── constraints.nix        # Constraint predicates
│   └── templates.nix          # Template operations
├── composition.nix            # Block: Layer 2 exports
├── composition/
│   ├── CLAUDE.md              # Detailed composition spec
│   ├── identifiers.nix        # Multi-field identifiers
│   ├── ranges.nix             # Range derivation
│   ├── hierarchies.nix        # Tree structures
│   └── validators.nix         # Constraint composition
├── builders.nix               # Block: Layer 3 exports
└── builders/
    ├── CLAUDE.md              # Detailed builders spec
    ├── johnny-decimal.nix     # JD builder
    ├── versioning.nix         # Versioning builder
    └── classification.nix     # Classification builder
```

### Block Exports

#### primitives.nix (Block)
```nix
{
  inputs,
  cell,
}: {
  # Export all Layer 1 primitives
  numberSystems = import ./primitives/number-systems.nix;
  fields = import ./primitives/fields.nix;
  constraints = import ./primitives/constraints.nix;
  templates = import ./primitives/templates.nix;
}
```

#### composition.nix (Block)
```nix
{
  inputs,
  cell,
}: let
  primitives = cell.primitives;
in {
  # Export all Layer 2 compositions
  identifiers = import ./composition/identifiers.nix {inherit primitives;};
  ranges = import ./composition/ranges.nix {inherit primitives;};
  hierarchies = import ./composition/hierarchies.nix {inherit primitives;};
  validators = import ./composition/validators.nix {inherit primitives;};
}
```

#### builders.nix (Block)
```nix
{
  inputs,
  cell,
}: let
  primitives = cell.primitives;
  composition = cell.composition;
in {
  # Export all Layer 3 builders
  mkJohnnyDecimal = import ./builders/johnny-decimal.nix {inherit primitives composition;};
  mkVersioning = import ./builders/versioning.nix {inherit primitives composition;};
  mkClassification = import ./builders/classification.nix {inherit primitives composition;};
}
```

### API Contract

```nix
# From flake: inputs.self.lib.<system>
lib = {
  # Layer 1: Primitives
  primitives = {
    numberSystems = { mk, parse, format, validate, decimal, hex, binary, alphabetic };
    fields = { mk, parse, format, validate, range };
    constraints = { range, enum, pattern, custom };
    templates = { parse, render, validate };
  };

  # Layer 2: Composition
  composition = {
    identifiers = { mk, parse, format, validate };
    ranges = { mk, containing, contains };
    hierarchies = { mk, path, validate, leaves };
    validators = { mk, combine, required, unique };
  };

  # Layer 3: Builders
  builders = {
    mkJohnnyDecimal = {levels, base, digits, area_span} -> System;
    mkVersioning = {octets, separator, prerelease} -> System;
    mkClassification = {depth, digits_per_level, base} -> System;
  };
};
```

---

## Phase 3: Implementation

### TDD Strategy

Each layer follows strict TDD:

1. **RED**: Write test in `nix/tests/<layer>/<component>.test.nix`
2. **GREEN**: Implement in `nix/lib/<layer>/<component>.nix`
3. **REFACTOR**: Clean up while keeping tests green

### Layer Dependencies

```
builders.nix
    ↓ depends on
composition.nix
    ↓ depends on
primitives.nix
    ↓ depends on
nixpkgs.lib + builtins
```

**Critical**: Each layer ONLY depends on layers below it, never above.

### Implementation Order

#### Week 1: Primitives
1. Create `primitives/CLAUDE.md` with all test cases
2. Implement number-systems.nix (TDD)
3. Implement fields.nix (TDD)
4. Implement constraints.nix (TDD)
5. Implement templates.nix (TDD)
6. Create primitives.nix block export
7. Run tests: `nix build .#tests.<system>.primitives`

#### Week 2: Composition
1. Create `composition/CLAUDE.md` with all test cases
2. Implement identifiers.nix (TDD)
3. Implement ranges.nix (TDD)
4. Implement hierarchies.nix (TDD)
5. Implement validators.nix (TDD)
6. Create composition.nix block export
7. Run tests: `nix build .#tests.<system>.composition`

#### Week 3: Builders
1. Create `builders/CLAUDE.md` with all test cases
2. Implement johnny-decimal.nix (TDD)
3. Implement versioning.nix (TDD)
4. Implement classification.nix (TDD)
5. Create builders.nix block export
6. Run tests: `nix build .#tests.<system>.builders`

### Validation Checklist

**Layer 1 (Primitives)**:
- [ ] 20+ tests for number-systems.nix
- [ ] 15+ tests for fields.nix
- [ ] 10+ tests for constraints.nix
- [ ] 10+ tests for templates.nix
- [ ] All functions pure (no side effects)
- [ ] All edge cases covered
- [ ] Performance: <100ms for 1000 operations

**Layer 2 (Composition)**:
- [ ] 15+ tests for identifiers.nix
- [ ] 10+ tests for ranges.nix
- [ ] 12+ tests for hierarchies.nix
- [ ] 8+ tests for validators.nix
- [ ] All compositions use primitives correctly
- [ ] No direct nixpkgs.lib usage (only via primitives)

**Layer 3 (Builders)**:
- [ ] 10+ tests for johnny-decimal.nix
- [ ] 8+ tests for versioning.nix
- [ ] 8+ tests for classification.nix
- [ ] Sensible defaults for all parameters
- [ ] Full customization possible
- [ ] Clear error messages

---

## Related Documentation

- **Usage Guide & Examples**: See [README.md](./README.md) for comprehensive usage guide, API examples, and getting started
- **Primitives Layer Details**: See `primitives/CLAUDE.md` for Layer 1 implementation specs
- **Composition Layer Details**: See `composition/CLAUDE.md` for Layer 2 implementation specs
- **Builders Layer Details**: See `builders/CLAUDE.md` for Layer 3 implementation specs
- **Test Specifications**: See `../tests/README.md` for testing guide and running tests
- **Project Overview**: See root `CLAUDE.md` for overall project structure
- **Roadmap**: See root `TODO.md` for vision and future plans
