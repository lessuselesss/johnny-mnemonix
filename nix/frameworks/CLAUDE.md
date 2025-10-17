# Frameworks Cell - Johnny Declarative Decimal

**Cell Type**: `frameworks`
**Purpose**: Pre-built, opinionated frameworks for common use cases
**Blocks**: `configs.nix`

---

## Phase 1: Requirements

### Cell Overview

The `frameworks` cell provides complete, ready-to-use implementations of common organizational systems. Each framework combines the library layers with opinionated defaults and integrations (home-manager, flake-parts).

### User Stories

#### US-FW-1: Zero-Config Johnny Decimal
**As a** new user
**I want** to use classic Johnny Decimal with zero configuration
**So that** I can get started immediately

**Acceptance Criteria**:
- Single import line to enable
- Sensible defaults (base 10, 2 digits, span 10)
- Standard syntax (`[]`, `{}`, `()`)
- Home-manager integration included

#### US-FW-2: Framework Variants
**As a** user with specific needs
**I want** ready-made variants (hex, semver, etc.)
**So that** I don't have to configure from scratch

**Acceptance Criteria**:
- johnny-decimal-classic (standard)
- johnny-decimal-hex (hexadecimal)
- semver (semantic versioning)
- Each fully documented with examples

#### US-FW-3: Escape Hatches
**As a** power user
**I want** to override framework defaults
**So that** I can customize without rebuilding

**Acceptance Criteria**:
- All defaults overridable
- Access to underlying library
- Clear documentation of what's customizable

---

## Phase 2: Design

### Cell Structure

```
nix/frameworks/
├── CLAUDE.md                           # This file
├── configs.nix                         # Block: Framework exports
├── johnny-decimal-classic/
│   ├── CLAUDE.md                       # Framework-specific spec
│   ├── default.nix                     # Framework definition
│   ├── home-manager.nix                # HM module
│   └── flake-module.nix                # Flake-parts module
├── johnny-decimal-hex/
│   ├── CLAUDE.md
│   ├── default.nix
│   ├── home-manager.nix
│   └── flake-module.nix
└── semver/
    ├── CLAUDE.md
    ├── default.nix
    └── flake-module.nix
```

### Block Export

#### configs.nix (Block)
```nix
{
  inputs,
  cell,
}: {
  johnny-decimal-classic = import ./johnny-decimal-classic {
    inherit inputs cell;
  };

  johnny-decimal-hex = import ./johnny-decimal-hex {
    inherit inputs cell;
  };

  semver = import ./semver {
    inherit inputs cell;
  };
}
```

### Framework API

```nix
# Usage in user's flake.nix
{
  inputs.johnny-dd.url = "github:user/johnny-declarative-decimal";

  outputs = {johnny-dd, ...}: {
    # Option 1: Use framework directly
    homeConfigurations.user = {
      imports = [
        johnny-dd.frameworks.<system>.johnny-decimal-classic.homeManagerModule
      ];

      johnny-mnemonix.enable = true;
    };

    # Option 2: Override defaults
    homeConfigurations.user = {
      imports = [
        johnny-dd.frameworks.<system>.johnny-decimal-classic.homeManagerModule
      ];

      johnny-mnemonix = {
        enable = true;
        baseDir = "~/CustomWorkspace";
        _systemOverride = johnny-dd.lib.<system>.builders.mkJohnnyDecimal {
          base = 16;  # Override to hex
        };
      };
    };
  };
}
```

---

## Phase 3: Implementation

### TDD for Frameworks

Each framework requires integration tests:

```nix
# Test: Classic framework can be imported
testClassicImport = {
  expr = frameworks.johnny-decimal-classic ? homeManagerModule;
  expected = true;
};

# Test: Classic framework has correct defaults
testClassicDefaults = let
  sys = frameworks.johnny-decimal-classic.system;
in {
  expr = {
    base = sys.fields.category.system.radix;
    digits = sys.fields.category.width;
    span = sys.area.span;
  };
  expected = {
    base = 10;
    digits = 2;
    span = 10;
  };
};

# Test: Framework can be overridden
testClassicOverride = let
  custom = frameworks.johnny-decimal-classic.override {
    base = 16;
  };
in {
  expr = custom.system.fields.category.system.radix;
  expected = 16;
};

# Test: Home-manager activation
testHomeManagerActivation = let
  config = {
    imports = [frameworks.johnny-decimal-classic.homeManagerModule];
    johnny-mnemonix.enable = true;
  };
  result = evalHomeManager config;
in {
  expr = result.home.file."index.typ" ? source;
  expected = true;
};
```

### Implementation Checklist

**johnny-decimal-classic**:
- [ ] System definition using lib.builders.mkJohnnyDecimal
- [ ] Home-manager module wrapping johnny-mnemonix.nix
- [ ] Flake-parts module for config integration
- [ ] Override mechanism via passthru
- [ ] Documentation and examples
- [ ] 5+ integration tests

**johnny-decimal-hex**:
- [ ] System with base = 16
- [ ] Custom syntax for hex display
- [ ] Home-manager integration
- [ ] 3+ integration tests

**semver**:
- [ ] System using mkVersioning builder
- [ ] Prerelease and build metadata support
- [ ] Git tag integration
- [ ] 3+ integration tests

---

## Next Steps

1. See `johnny-decimal-classic/CLAUDE.md` for detailed classic framework spec
2. See `/nix/tests/integration/CLAUDE.md` for framework integration tests
3. Implement after lib cell is complete
