# Config Cell (`config`)

**Cell Type**: System configuration
**Purpose**: Self-validating configuration modules
**Blocks**: `modules.nix`
**Status**: ⏳ Planned (two-pass loading design complete, implementation pending)

---

## Overview

The `config` cell contains **self-validating configuration modules** that define the system's operational syntax and structure. These modules demonstrate a key feature of johnny-declarative-decimal: **configurations that use the organizational system they define**.

### Key Concept: Self-Validation

Configuration modules are named using Johnny Decimal format (e.g., `[01.04]{...}__...__.nix`) and collectively define the syntax used to parse those very filenames. This creates a two-pass loading system:

1. **Pass 1 (Bootstrap)**: Parse modules with default syntax
2. **Pass 2 (Validate)**: Re-parse with actual syntax from config, verify consistency

---

## Two-Pass Loading

```
┌──────────────────┐
│  defaultSyntax   │ ◄── Hardcoded in flake.nix
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Pass 1: Bootstrap                                │
│                                                  │
│ 1. Load all modules with defaultSyntax          │
│ 2. Filter config modules (01.01-01.07)          │
│ 3. Evaluate to extract actualSyntax (from 01.04)│
│ 4. Extract other configs (base, octets, etc.)   │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Pass 2: Validate                                 │
│                                                  │
│ 1. Re-parse all modules with actualSyntax       │
│ 2. Verify config modules match their own names  │
│ 3. Assert consistency or fail with clear error  │
│ 4. Export validated configuration                │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│ Export to System │
└──────────────────┘
```

---

## Directory Structure

```
nix/config/
├── README.md                        # This file
├── CLAUDE.md                        # Configuration specifications
│
├── modules.nix                      # Block: Config module exports
│
└── [01.01-01.07]/                   # Configuration modules
    ├── [01.01]{01-09 Meta}__(01 Configuration)__[01 Base-System].nix
    ├── [01.02]{01-09 Meta}__(01 Configuration)__[02 Number-System].nix
    ├── [01.03]{01-09 Meta}__(01 Configuration)__[03 Octets].nix
    ├── [01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix
    ├── [01.05]{01-09 Meta}__(01 Configuration)__[05 Area-Span].nix
    ├── [01.06]{01-09 Meta}__(01 Configuration)__[06 Constraints].nix
    └── [01.07]{01-09 Meta}__(01 Configuration)__[07 Extensions].nix
```

---

## Configuration Modules

### 01.01 - Base System
**Purpose**: Define the foundational numbering system

**Exports**:
```nix
{
  baseSystem = {
    radix = 10;                          # Decimal
    alphabet = "0123456789";
    name = "decimal";
  };
}
```

**Self-Validation**: Module name `[01.01]` must parse correctly with its own `baseSystem`.

---

### 01.02 - Number System
**Purpose**: Define number system per hierarchy level

**Exports**:
```nix
{
  numberSystems = {
    area = { radix = 10; alphabet = "0123456789"; };
    category = { radix = 10; alphabet = "0123456789"; };
    item = { radix = 10; alphabet = "0123456789"; };
  };
}
```

**Use Cases**:
- Uniform: All levels use same base (e.g., all decimal)
- Mixed radix: Different bases per level (e.g., hex areas, decimal items)

---

### 01.03 - Octets
**Purpose**: Define number of components per level

**Exports**:
```nix
{
  octets = {
    area = 2;        # 2 digits (00-99)
    category = 2;    # 2 digits (00-99)
    item = 2;        # 2 digits (00-99)
  };

  levels = 3;        # Area.Category.Item (N₁.N₂.N₃)
}
```

**Flexibility**:
- Classic JD: 2 octets per level
- Extended: 3, 4, or more octets
- Variable: Different octet counts per level

---

### 01.04 - Syntax (Critical!)
**Purpose**: Define all visual syntax elements

**Exports**:
```nix
{
  syntax = {
    idNumEncapsulator = { open = "["; close = "]"; };       # [01.04]
    areaEncapsulator = { open = "{"; close = "}"; };        # {01-09 Meta}
    categoryEncapsulator = { open = "("; close = ")"; };    # (01 Configuration)
    itemEncapsulator = { open = "["; close = "]"; };        # [04 Syntax]

    separators = {
      numeralToName = " ";          # "01 Configuration"
      hierarchyLevels = "__";       # Between area, category, item
      octets = ".";                 # "01.04"
      rangeSpan = "-";              # "01-09"
    };
  };
}
```

**Self-Validation Critical**: Pass 2 re-parses THIS module's filename using THIS module's syntax definition.

---

### 01.05 - Area Span
**Purpose**: Define grouping of categories into areas

**Exports**:
```nix
{
  areaSpan = 10;  # Categories 10-19 = Area "10-19"
                  # Categories 20-29 = Area "20-29", etc.
}
```

**Calculation**:
- Area range: `floor(category / areaSpan) * areaSpan` to `floor(category / areaSpan) * areaSpan + areaSpan - 1`
- Example: Category 15 → Area 10-19 (floor(15/10)*10 = 10, 10+10-1 = 19)

---

### 01.06 - Constraints
**Purpose**: Define validation rules for IDs

**Exports**:
```nix
{
  constraints = {
    area = {
      range = { min = 0; max = 99; };
      enum = null;  # Allow all in range
    };

    category = {
      range = { min = 0; max = 99; };
      custom = value: value % 10 != 0;  # Example: No multiples of 10
    };

    item = {
      range = { min = 0; max = 99; };
    };
  };
}
```

**Use Cases**:
- Range validation
- Allowed value enums
- Custom validation functions
- Business logic enforcement

---

### 01.07 - Extensions
**Purpose**: Optional features and customizations

**Exports**:
```nix
{
  extensions = {
    prefixes = {
      enable = true;
      allowed = ["PRJ" "DOC" "REF"];  # PRJ-10.05
    };

    suffixes = {
      enable = true;
      allowed = ["DRAFT" "FINAL" "ARCHIVE"];  # 10.05-DRAFT
    };

    metadata = {
      enable = true;
      fields = ["created" "modified" "owner" "tags"];
    };
  };
}
```

**Future-Proofing**: Space for additional features without breaking existing config.

---

## How Self-Validation Works

### Example: Validating 01.04 Syntax Module

**Filename**: `[01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix`

**Pass 1 (Bootstrap)**:
```nix
# Parse with defaultSyntax from flake.nix
parsed = parseWithDefault "[01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix";
# => {category = "01"; item = "04"; areaRange = "01-09"; ...}

# Load module, extract syntax definition
syntaxModule = import parsed.path;
actualSyntax = syntaxModule.syntax;
```

**Pass 2 (Validate)**:
```nix
# Re-parse with actualSyntax from module
reparse = parseWithActual "[01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix" actualSyntax;
# => {category = "01"; item = "04"; ...}

# Validate: Does actualSyntax parse its own filename?
assert parsed == reparse;  # Must be identical!

# If mismatch, fail with clear error:
# "Config module 01.04 defines syntax that cannot parse its own filename!"
```

---

## Benefits of Self-Validation

### 1. Dogfooding
Config modules use the system they define, proving it works.

### 2. Consistency Guarantee
Impossible to have config/structure mismatch - they're validated against each other.

### 3. Early Error Detection
Syntax errors caught at build time, not runtime.

### 4. Living Documentation
Config modules serve as working examples of the system.

### 5. Refactoring Confidence
Change syntax? Tests immediately show if config needs updating.

---

## Implementation Status

### Completed
- ✅ Two-pass loading design
- ✅ Self-validation algorithm
- ✅ Configuration module specifications
- ✅ Error handling strategy

### In Progress
- ⏳ Module template files
- ⏳ Default syntax definition
- ⏳ Parser integration

### Planned
- ⏳ Full 01.01-01.07 module suite
- ⏳ Integration tests for two-pass loading
- ⏳ Performance optimization (< 5s for 100 modules)

---

## Usage

### In a Flake

```nix
{
  inputs.johnny-dd.url = "github:youruser/johnny-mnemonix";

  outputs = { johnny-dd, ... }: let
    # Two-pass loading happens automatically
    config = johnny-dd.config.x86_64-linux.modules;
  in {
    # Use validated config
    inherit (config) syntax baseSystem octets;

    # Pass to frameworks or use directly
    homeConfigurations.user = {
      johnny-mnemonix = {
        inherit (config) syntax;
        # ... rest of config
      };
    };
  };
}
```

### Customizing Config

```nix
# Override a config module
{
  config = johnny-dd.config.x86_64-linux.modules.override {
    "01.04" = {
      syntax = {
        # Use different encapsulators
        idNumEncapsulator = { open = "<"; close = ">"; };
      };
    };
  };
}
```

---

## Performance

**Target**: < 5 seconds for two-pass loading of 100 modules

**Optimization Strategies**:
- Lazy evaluation (only load what's needed)
- Parallel parsing where possible
- Cache parsed results between passes
- Memoization of expensive operations

---

## Error Handling

### Pass 1 Errors
```
ERROR: Failed to parse config module with defaultSyntax
  File: [01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix
  Reason: Invalid octets format (expected N.N)
  → Check filename format matches defaultSyntax
```

### Pass 2 Errors
```
ERROR: Config module fails self-validation
  Module: 01.04 Syntax
  Issue: actualSyntax cannot parse its own filename

  Expected encapsulator: "["
  Found in filename: "<"

  → Update module filename OR update syntax definition
```

### Missing Module Errors
```
ERROR: Critical config module missing
  Expected: [01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix
  Required by: Two-pass loading (syntax definition)

  → Create module or disable two-pass validation
```

---

## Testing

### Unit Tests
```nix
# Test: Default syntax parses correctly
testDefaultSyntaxParsing = {
  expr = parseWithDefault "[01.04]{...}__...__.nix";
  expected = {category = 1; item = 4;};
};

# Test: Two-pass loading succeeds
testTwoPassLoading = let
  result = twoPassLoad configModules;
in {
  expr = result.validated;
  expected = true;
};

# Test: Self-validation detects mismatch
testSelfValidationFails = let
  badConfig = {
    filename = "[01.04]...";
    syntax = {idNumEncapsulator = {open = "<";};}; # Mismatch!
  };
in {
  expr = validate badConfig;
  expected = false;
};
```

---

## Related Documentation

- **Two-Pass Loading Spec**: See `CLAUDE.md` in this directory
- **Library Documentation**: See `nix/lib/README.md`
- **Framework Integration**: See `nix/frameworks/README.md`
- **Project Overview**: See root `CLAUDE.md`

---

## Contributing

To add a new config module:

1. **Create module file** with proper JD naming
2. **Implement export** matching specification
3. **Add to modules.nix block**
4. **Test two-pass loading** succeeds
5. **Verify self-validation** passes
6. **Document** in this README

---

## Next Steps

1. Implement default syntax in flake.nix
2. Create 01.01-01.07 module templates
3. Implement two-pass parser
4. Add integration tests
5. Performance testing and optimization

---

## Status Summary

**Current**: ⏳ Planned (design complete, implementation pending)

**Timeline**: Phase 2 (after library complete, alongside framework development)

**Priority**: High (enables self-validating configurations - key differentiator)
