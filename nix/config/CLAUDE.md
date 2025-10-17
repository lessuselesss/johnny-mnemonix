# Config Cell - Johnny Declarative Decimal

> **Quick Reference**: See [README.md](./README.md) for two-pass loading details, self-validation explanation, and configuration module specifications.

**Cell Type**: `config`
**Purpose**: System configuration modules (01.01-01.07)
**Blocks**: `modules.nix`
**Status**: ⏳ Planned (two-pass loading design complete, implementation pending)

---

## Phase 1: Requirements

### Cell Overview

The `config` cell contains the self-describing configuration modules (01.01 through 01.07) that define the johnny-declarative-decimal system itself. These modules are special because they:

1. Use Johnny Decimal naming themselves
2. Define the rules they're named by
3. Must pass two-pass validation

### User Stories

#### US-CFG-1: Self-Validating Bootstrap
**As a** system designer
**I want** config modules to validate themselves
**So that** the system proves its own correctness

**Acceptance Criteria**:
- Config modules use JD naming in filenames
- Pass 1: Parse with default syntax
- Pass 2: Re-parse with loaded syntax
- Self-consistency assertion passes

#### US-CFG-2: Modular Configuration
**As a** user
**I want** to understand each aspect of configuration separately
**So that** I can learn and customize incrementally

**Acceptance Criteria**:
- 01.01: Base octets and number systems
- 01.02: Ranges and validation rules
- 01.03: Namespace and terminology
- 01.04: Visual syntax
- 01.05-07: Validation and indexing rules

---

## Phase 2: Design

### Cell Structure

```
nix/config/
├── CLAUDE.md                           # This file
├── modules.nix                         # Block: Config module exports
└── move from /modules/[01.01-01.07]*.nix to here
```

### Module Migration

The config modules currently in `/modules/` should be moved here:
- `/modules/[01.01]{...}__[01 Base-Octets].nix` → `/nix/config/01-01-base-octets.nix`
- `/modules/[01.02]{...}__[02 Numbers-Ranges-Rules].nix` → `/nix/config/01-02-numbers-ranges-rules.nix`
- `/modules/[01.03]{...}__[03 Name-space].nix` → `/nix/config/01-03-name-space.nix`
- `/modules/[01.04]{...}__[04 Syntax].nix` → `/nix/config/01-04-syntax.nix`
- `/modules/[01.05]{...}__[05 Nix-module-validation].nix` → `/nix/config/01-05-nix-module-validation.nix`
- `/modules/[01.06]{...}__[06 Flake-parts-validation].nix` → `/nix/config/01-06-flake-parts-validation.nix`
- `/modules/[01.07]{...}__[07 Indexor-rules].nix` → `/nix/config/01-07-indexor-rules.nix`

### Block Export

#### modules.nix (Block)
```nix
{
  inputs,
  cell,
}: {
  # All config modules exported for flake-parts integration
  base-octets = import ./01-01-base-octets.nix;
  numbers-ranges-rules = import ./01-02-numbers-ranges-rules.nix;
  name-space = import ./01-03-name-space.nix;
  syntax = import ./01-04-syntax.nix;
  nix-module-validation = import ./01-05-nix-module-validation.nix;
  flake-parts-validation = import ./01-06-flake-parts-validation.nix;
  indexor-rules = import ./01-07-indexor-rules.nix;
}
```

---

## Phase 3: Implementation

### Two-Pass Loading Integration

```nix
# In flake.nix

# Pass 1: Bootstrap with defaults
let
  defaultSyntax = {
    idNumEncapsulator = {open = "["; close = "]";};
    # ... all defaults
  };

  # Parse config modules with defaults
  pass1ConfigModules = parseWithSyntax defaultSyntax (
    importConfigCell inputs.self.config.${system}
  );

  # Evaluate to get actualSyntax
  actualSyntax = (evalModules {
    modules = [pass1ConfigModules.syntax];
  }).config.johnny-declarative-decimal.syntax;

# Pass 2: Validate with actualSyntax
  pass2ConfigModules = parseWithSyntax actualSyntax (
    importConfigCell inputs.self.config.${system}
  );

  # Assert self-consistency
  assert validateSelfConsistency pass2ConfigModules;
in
  # Export validated config
  pass2ConfigModules
```

### TDD for Config Modules

```nix
# Test: Config modules parse with default syntax
testConfigParsePass1 = {
  expr = (parseWithDefaultSyntax configModules).all (m: m.parsed);
  expected = true;
};

# Test: Config modules define valid syntax
testConfigDefinesSyntax = {
  expr = configModules.syntax.config.johnny-declarative-decimal.syntax ? idNumEncapsulator;
  expected = true;
};

# Test: Config modules reparse with their own syntax
testConfigSelfValidates = {
  expr = (pass2Validate configModules).valid;
  expected = true;
};

# Test: Config modules export to flake outputs
testConfigExports = {
  expr = flake.johnny-declarative-decimal.config ? syntax;
  expected = true;
};
```

### Implementation Checklist

- [ ] Move config modules from /modules to /nix/config
- [ ] Rename to simple names (01-01-base-octets.nix)
- [ ] Update flake-parts integration
- [ ] Implement two-pass loading in flake.nix
- [ ] Add self-validation assertions
- [ ] 4+ tests for two-pass loading
- [ ] Clear error messages on validation failure

---

## Related Documentation

- **Configuration Guide**: See [README.md](./README.md) for two-pass loading algorithm, self-validation benefits, and module specs
- **Library Documentation**: See `../lib/README.md` for library used by configuration modules
- **Test Guide**: See `../tests/README.md` for two-pass loading tests
- **Project Overview**: See root `CLAUDE.md` for overall project structure

---

## Next Steps

1. Complete library layer (✅ Complete - 126/126 tests)
2. Implement two-pass loading in root flake.nix
3. Create 01.01-01.07 configuration modules
4. Implement self-validation algorithm
5. Add integration tests for two-pass loading
6. Performance optimization (< 5s target)
