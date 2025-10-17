# Types Cell - Johnny Declarative Decimal

**Cell Type**: `types`
**Purpose**: Configuration type definitions and specifications
**Blocks**: `types.nix` (planned)
**Status**: ⏳ Specification Complete, Implementation Pending

---

## Overview

The `types` cell defines all configuration types/scopes that johnny-declarative-decimal can manage. Each type represents a different domain where Johnny Decimal organization can be applied:

- **nixos**: System configuration
- **nixos-dendrix**: divnix/std-based system organization
- **nixos-darwin**: macOS system configuration
- **home-manager**: User environment (current implementation)
- **hm-dirs**: Declarative directory structures with multiple bases
- **jd-office**: Office/workspace management
- **typix**: Typst document organization
- **permanence**: Configuration reconciliation for impermanence
- **fuse**: Virtual filesystem layer (exploratory)

---

## Comprehensive Specification

**See: @nix/types/CLAUDE_TYPES_CELL.nix**

The complete kiro.dev-style specifications for all configuration types are defined in `CLAUDE_TYPES_CELL.nix`. This file contains:

### For Each Configuration Type:

1. **Phase 1: Requirements**
   - Purpose and base directory
   - User stories with acceptance criteria
   - Constraints and dependencies

2. **Phase 2: Design**
   - Directory structure examples
   - API contract
   - Integration approach
   - Module format and conventions

3. **Phase 3: Implementation (TDD)**
   - Test strategy (RED → GREEN → REFACTOR)
   - Concrete test examples with assertions
   - Implementation phases
   - Test count per component

### TDD Methodology

All types follow strict Test-Driven Development:

```
🔴 RED:     Write failing test (proves test works, clarifies requirements)
    ↓
🟢 GREEN:   Minimal implementation to pass (simplest code that works)
    ↓
🔵 REFACTOR: Improve while keeping tests green (clean up, optimize)
```

Each test example in CLAUDE_TYPES_CELL.nix includes:
- **RED**: The failing test assertion
- **GREEN**: The minimal implementation that makes it pass
- **Context**: What the test validates and why it matters

---

## Configuration Type Summary

### System-Level Types

| Type | Purpose | Base Dir | Tests | Status |
|------|---------|----------|-------|--------|
| `nixos` | NixOS system config | `/etc/nixos` | 26 | ⏳ Planned |
| `nixos-dendrix` | divnix/std cells | `nix/` | 36 | ⏳ Planned |
| `nixos-darwin` | macOS system | `~/.nixpkgs` | 19 | ⏳ Planned |

### User-Level Types

| Type | Purpose | Base Dir | Tests | Status |
|------|---------|----------|-------|--------|
| `home-manager` | User environment | `$HOME` | Existing | ✅ Implemented |
| `hm-dirs` | Multi-base directories | Configurable | 23 | ⏳ Planned |
| `jd-office` | Office workspace | `$OFFICE` | 33 | ⏳ Planned |
| `typix` | Typst documents | Configurable | 35 | ⏳ Planned |

### Advanced Types

| Type | Purpose | Base Dir | Tests | Status |
|------|---------|----------|-------|--------|
| `permanence` | Config reconciliation | All bases | 62 | ⏳ Planned |
| `fuse` | Virtual filesystem | Mount points | TBD | 🔬 Exploratory |

**Total Test Coverage**: 234+ tests (excluding exploratory FUSE)

---

## Implementation Order

Following the kiro.dev specifications in CLAUDE_TYPES_CELL.nix:

### Phase 4: Core System Types
1. **nixos** - Foundation for system configuration (26 tests)
2. **nixos-dendrix** - divnix/std integration (36 tests)
3. **nixos-darwin** - macOS variant (19 tests)

### Phase 5: Enhanced User Types
4. **home-manager** - Refactor existing with library (integration tests)
5. **hm-dirs** - Multiple base directories (23 tests)
6. **jd-office** - Workspace management (33 tests)
7. **typix** - Document organization (35 tests)

### Phase 6: Advanced Features
8. **permanence** - Reconciliation tool (62 tests)

### Phase 7: Exploratory
9. **fuse** - Virtual filesystem (PoC → validate → iterate)

---

## Using This Specification

### For Implementation:

1. **Read CLAUDE_TYPES_CELL.nix** for the type you're implementing
2. **Start with Phase 1** (Requirements): Understand user stories
3. **Review Phase 2** (Design): Understand structure and API
4. **Follow Phase 3** (Implementation): Use TDD methodology

### TDD Workflow:

```nix
# Example from CLAUDE_TYPES_CELL.nix:

# 🔴 RED: Write the failing test
test_nixos_parse_filename = {
  expr = parseNixOSFilename "20.01 SSH.nix";
  expected = {category = 20; item = 1; name = "SSH";};
};

# Run: nix build .#checks.<system>.test_nixos_parse_filename
# Result: FAILS (parseNixOSFilename not defined)

# 🟢 GREEN: Minimal implementation
parseNixOSFilename = filename: let
  match = builtins.match "([0-9]{2})\\.([0-9]{2}) ([^.]+)\\.nix" filename;
in {
  category = lib.toInt (builtins.elemAt match 0);
  item = lib.toInt (builtins.elemAt match 1);
  name = builtins.elemAt match 2;
};

# Run: nix build .#checks.<system>.test_nixos_parse_filename
# Result: PASSES ✓

# 🔵 REFACTOR: Improve (if needed, keeping tests green)
```

### For Planning:

- **Test Estimates**: Use test counts to estimate effort
- **Dependencies**: Later types depend on earlier ones (nixos → nixos-dendrix)
- **Complexity**: More tests = more complex type
- **Risk Assessment**: Exploratory types (fuse) have unknown scope

---

## Cell Structure (Planned)

```
nix/types/
├── CLAUDE.md                           # This file
├── CLAUDE_TYPES_CELL.nix              # Comprehensive specifications
├── types.nix                          # Block: Type definitions
├── common/
│   ├── filename-parser.nix            # Shared filename parsing
│   ├── validation.nix                 # Shared validation logic
│   └── directory-generator.nix        # Shared directory creation
├── nixos.nix                          # NixOS type handler
├── nixos-dendrix.nix                  # divnix/std NixOS handler
├── nixos-darwin.nix                   # macOS handler
├── home-manager.nix                   # HM handler (wraps existing)
├── hm-dirs.nix                        # Multi-base dirs handler
├── jd-office.nix                      # Office workspace handler
├── typix.nix                          # Typst documents handler
├── permanence.nix                     # Reconciliation tool
└── fuse.nix                           # Virtual filesystem (future)
```

---

## Key Design Principles

From CLAUDE_TYPES_CELL.nix specifications:

1. **Layered Architecture**
   - Types build on johnny-declarative-decimal library
   - Common functionality shared across types
   - Each type can override/extend common behavior

2. **TDD at Every Level**
   - Write tests before implementation
   - All specifications include concrete test examples
   - Maintain high test coverage (95%+ on critical paths)

3. **User-Centric Design**
   - User stories drive requirements
   - Clear acceptance criteria
   - Focus on solving real problems

4. **Escape Hatches**
   - Users can drop down to library if type too constraining
   - Types are conveniences, not cages
   - Power users can mix approaches

5. **Validation First**
   - Validate early, fail fast
   - Clear error messages
   - Self-documenting configurations

---

## Related Documentation

- **Type Specifications**: @nix/types/CLAUDE_TYPES_CELL.nix (comprehensive specs)
- **Library Documentation**: ../lib/README.md (underlying library used by all types)
- **Current Implementation**: ../../modules/johnny-mnemonix.nix (home-manager type)
- **Vision Document**: ../../TODO.md (future plans and exploratory features)
- **Project Overview**: ../../CLAUDE.md (overall project structure)

---

## Next Steps

1. **Current**: Complete library layer (✅ 126/126 tests)
2. **Phase 2**: Refactor johnny-mnemonix to use library
3. **Phase 3**: Design type system architecture (this cell)
4. **Phase 4**: Implement core system types (nixos, dendrix, darwin)
5. **Phase 5**: Implement enhanced user types (hm-dirs, jd-office, typix)
6. **Phase 6**: Implement advanced types (permanence)
7. **Phase 7**: Explore FUSE if validated need

---

## Contributing

When implementing a configuration type:

1. **Start with CLAUDE_TYPES_CELL.nix** - Read the full specification
2. **Understand the user stories** - Why does this type exist?
3. **Review the design** - How should it work?
4. **Follow TDD** - Write tests from spec, implement to pass
5. **Update this file** - Mark type as implemented, add notes

When adding a new configuration type:

1. **Add to CLAUDE_TYPES_CELL.nix** following the established format
2. **Include all three phases** (Requirements, Design, Implementation/TDD)
3. **Provide concrete test examples** with RED-to-GREEN flow
4. **Update the summary table** in this file
5. **Document in TODO.md** if exploratory/future work

---

**Remember**: Types are conveniences built on the library. The library (primitives → composition → builders) is the foundation. Types provide opinionated workflows for specific use cases. 🎯
