# Library Cell (`lib`)

**Cell Type**: Pure functional library
**Purpose**: Core library implementation for johnny-declarative-decimal
**Blocks**: `primitives.nix`, `composition.nix`, `builders.nix`
**Status**: ✅ Complete (126/126 tests passing)

---

## Overview

The `lib` cell contains the complete foundational library for creating declarative organizational systems using structured identifiers. It provides a three-layer architecture that progresses from atomic operations to high-level constructors.

This is a **pure functional library** with:
- No side effects
- Referential transparency
- Full composability
- Escape hatches at every layer

---

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: BUILDERS (High-level constructors)                 │
│ - mkJohnnyDecimal: Classic JD systems (N₁.N₂ or N₁.N₂.N₃)  │
│ - mkVersioning: Semantic versioning (MAJOR.MINOR.PATCH)     │
│ - mkClassification: Hierarchical systems (N₁.N₂...Nₖ)      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ Layer 2: COMPOSITION (Structured systems)                   │
│ - identifiers: Multi-field identifier composition           │
│ - ranges: Range operations and containment                   │
│ - hierarchies: Multi-level tree navigation                  │
│ - validators: Constraint composition                         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│ Layer 1: PRIMITIVES (Atomic operations)                     │
│ - numberSystems: Base conversion (decimal, hex, binary)     │
│ - fields: Constrained fields with width/padding             │
│ - constraints: Validation predicates                         │
│ - templates: Template parsing and rendering                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Using Builders (Recommended)

```nix
# In your flake.nix
{
  inputs.johnny-declarative-decimal.url = "github:youruser/johnny-mnemonix";

  outputs = { self, johnny-declarative-decimal, ... }: {
    # Access the library
    myJD = johnny-declarative-decimal.lib.x86_64-linux.builders.mkJohnnyDecimal {
      levels = 2;  # Classic XX.YY format
      base = 10;   # Decimal
    };
  };
}
```

### Quick Examples

#### Johnny Decimal System
```nix
jd = mkJohnnyDecimal {};
jd.parse "10.05"  # => {category = 10; item = 5;}
jd.format {category = 10; item = 5;}  # => "10.05"
jd.validate "10.05"  # => true
```

#### Semantic Versioning
```nix
semver = mkVersioning {};
semver.parse "1.2.3"  # => {major = 1; minor = 2; patch = 3;}
semver.compare "1.2.3" "1.2.4"  # => -1 (less than)
semver.bump.major "1.2.3"  # => "2.0.0"
```

#### Classification System
```nix
cls = mkClassification {depth = 3;};
cls.path [10 5 2]  # => "10 / 10.05 / 10.05.02"
cls.navigate.parent [10 5 2]  # => [10 5]
cls.navigate.ancestors [10 5 2]  # => [[10] [10 5]]
```

---

## Directory Structure

```
nix/lib/
├── README.md                    # This file
├── CLAUDE.md                    # Implementation specification
│
├── primitives.nix               # Block: Layer 1 exports
├── primitives/
│   ├── CLAUDE.md                # Primitives specification
│   ├── number-systems.nix       # Base conversion (20 tests)
│   ├── fields.nix               # Constrained fields (15 tests)
│   ├── constraints.nix          # Validation predicates (10 tests)
│   └── templates.nix            # Template operations (10 tests)
│
├── composition.nix              # Block: Layer 2 exports
├── composition/
│   ├── CLAUDE.md                # Composition specification
│   ├── identifiers.nix          # Multi-field IDs (15 tests)
│   ├── ranges.nix               # Range operations (10 tests)
│   ├── hierarchies.nix          # Tree navigation (12 tests)
│   └── validators.nix           # Constraint composition (8 tests)
│
├── builders.nix                 # Block: Layer 3 exports
└── builders/
    ├── CLAUDE.md                # Builders specification
    ├── johnny-decimal.nix       # JD builder (10 tests)
    ├── versioning.nix           # Versioning builder (8 tests)
    └── classification.nix       # Classification builder (8 tests)
```

---

## Layer 1: Primitives (55/55 tests)

**Purpose**: Atomic, composable building blocks

### Components

#### `numberSystems` (20 tests)
Base conversion operations for different number systems.

```nix
ns = lib.primitives.numberSystems;

# Built-in systems
ns.decimal   # {radix = 10; alphabet = "0123456789";}
ns.hex       # {radix = 16; alphabet = "0123456789ABCDEF";}
ns.binary    # {radix = 2; alphabet = "01";}

# Custom system
base5 = ns.mk {radix = 5; alphabet = "01234";};

# Operations
ns.parse ns.decimal "42"  # => 42
ns.format ns.hex 255      # => "FF"
ns.validate ns.binary "1010"  # => true
```

#### `fields` (15 tests)
Constrained fields with width and padding.

```nix
fields = lib.primitives.fields;

# Create field
twoDigit = fields.mk {
  system = ns.decimal;
  width = 2;
  padding = "zeros";
};

fields.format twoDigit 5   # => "05"
fields.parse twoDigit "07" # => 7
fields.validate twoDigit 99 # => true
fields.range twoDigit      # => {min = 0; max = 99;}
```

#### `constraints` (10 tests)
Validation predicates for values.

```nix
constraints = lib.primitives.constraints;

rangeCheck = constraints.range {min = 0; max = 99;};
enumCheck = constraints.enum ["ENG" "DES" "OPS"];
patternCheck = constraints.pattern "^[A-Z]{3}$";

constraints.check rangeCheck 50  # => true
constraints.check enumCheck "ENG"  # => true
```

#### `templates` (10 tests)
Template parsing and rendering.

```nix
templates = lib.primitives.templates;

tmpl = templates.parse "{dept}-{year}-{seq}";
templates.render tmpl {dept = "ENG"; year = "24"; seq = "001";}
# => "ENG-24-001"

templates.extract tmpl "ENG-24-001"
# => {dept = "ENG"; year = "24"; seq = "001";}
```

---

## Layer 2: Composition (45/45 tests)

**Purpose**: Combine primitives into structured systems

### Components

#### `identifiers` (15 tests)
Multi-field identifier composition.

```nix
identifiers = lib.composition.identifiers;

jdId = identifiers.mk {
  fields = [twoDigitField twoDigitField];
  separator = ".";
};

identifiers.parse jdId "10.05"
# => {field0 = 10; field1 = 5;}

identifiers.format jdId {field0 = 10; field1 = 5;}
# => "10.05"
```

#### `ranges` (10 tests)
Range operations for identifier spans.

```nix
ranges = lib.composition.ranges;

r = ranges.mk {start = [10 0]; end = [19 99];};
ranges.contains r [15 5]  # => true (15.05 in range)
ranges.validate r  # => true
```

#### `hierarchies` (12 tests)
Multi-level tree navigation.

```nix
hierarchies = lib.composition.hierarchies;

jdHierarchy = hierarchies.mk {
  levels = [areaId categoryId itemId];
  levelNames = ["area" "category" "item"];
};

hierarchies.level jdHierarchy [10 5 3]  # => 2 (item level)
hierarchies.parent jdHierarchy [10 5 3] # => [10 5]
hierarchies.path jdHierarchy [10 5 3]
# => "10 / 10.05 / 10.05.03"
```

#### `validators` (8 tests)
Constraint composition with AND logic.

```nix
validators = lib.composition.validators;

v1 = validators.fromConstraint (constraints.range {min = 0; max = 100;});
v2 = validators.fromConstraint (constraints.enum [10 20 30 40 50]);
combined = validators.combine [v1 v2];

validators.check combined 30  # => true (in range AND in enum)
validators.check combined 25  # => false (in range but NOT in enum)
```

---

## Layer 3: Builders (26/26 tests)

**Purpose**: High-level constructors for complete systems

### Components

#### `mkJohnnyDecimal` (10 tests)
Classic Johnny Decimal system builder.

**Parameters**:
- `levels`: 2 for N₁.N₂, 3 for N₁.N₂.N₃ (default: 2)
- `base`: 10, 16, 2 (default: 10)
- `digits`: Digits per field (default: 2)
- `separators`: Level separators (default: ["."])
- `constraints`: Per-level constraints (default: {})

**Returns**: `{parse, format, validate, identifiers, primitives, composition}`

```nix
# Classic (N₁.N₂)
classic = mkJohnnyDecimal {};
classic.parse "10.05"  # => {category = 10; item = 5;}

# Extended (N₁.N₂.N₃)
extended = mkJohnnyDecimal {levels = 3;};
extended.parse "10.05.02"  # => {area = 10; category = 5; item = 2;}

# Hexadecimal
hex = mkJohnnyDecimal {base = 16;};
hex.parse "1A.3F"  # => {category = 26; item = 63;}

# With constraints
constrained = mkJohnnyDecimal {
  constraints = {category = {min = 10; max = 19;};};
};
```

#### `mkVersioning` (8 tests)
Semantic versioning and version schemes.

**Parameters**:
- `octets`: Number of components (default: 3 for major.minor.patch)
- `separator`: Component separator (default: ".")
- `prerelease`: Support -alpha tags (default: true)
- `buildMetadata`: Support +build metadata (default: true)
- `constraints`: Per-component constraints

**Returns**: `{parse, format, compare, bump, primitives, composition}`

```nix
semver = mkVersioning {};

# Parsing
semver.parse "1.2.3"  # => {major = 1; minor = 2; patch = 3;}
semver.parse "1.2.3-alpha.1"
# => {major = 1; minor = 2; patch = 3; prerelease = "alpha.1";}

# Comparison
semver.compare "1.2.3" "1.2.4"  # => -1 (less than)
semver.compare "1.2.3" "1.2.3"  # => 0 (equal)
semver.compare "1.2.4" "1.2.3"  # => 1 (greater than)

# Bumping
semver.bump.major "1.2.3"  # => "2.0.0"
semver.bump.minor "1.2.3"  # => "1.3.0"
semver.bump.patch "1.2.3"  # => "1.2.4"
```

#### `mkClassification` (8 tests)
Hierarchical classification systems.

**Parameters**:
- `depth`: Number of levels (default: 3)
- `digits_per_level`: Digits at each level (default: 2)
- `base`: Number base (default: 10)
- `separators`: Level separators (default: ["."])
- `levelNames`: Names for each level

**Returns**: `{hierarchy, navigate, validate, path, identifiers, primitives, composition}`

```nix
cls = mkClassification {depth = 3;};

# Path generation
cls.path [10 5 2]  # => "10 / 10.05 / 10.05.02"

# Navigation
cls.navigate.parent [10 5 2]     # => [10 5]
cls.navigate.ancestors [10 5 2]  # => [[10] [10 5]]

# Validation
cls.validate [10 5 2]  # => true

# Dewey Decimal style
dewey = mkClassification {
  depth = 3;
  levelNames = ["class" "division" "section"];
};
```

---

## N Notation

This library uses **N notation** (N₁, N₂, N₃...Nₖ) to represent identifier components:

- **N₁**: First component (1 field)
- **N₁.N₂**: Two components (2 fields)
- **N₁.N₂.N₃**: Three components (3 fields)
- **N₁.N₂...Nₖ**: k components (arbitrary depth)

**Why N notation?**
- Emphasizes extensibility (not limited to 2 or 3 levels)
- More mathematical/formal than XX, YY, ZZ
- Language-agnostic (not tied to English "X, Y, Z")
- Clearer semantics: "the nth component"

---

## Escape Hatches

Every layer provides escape hatches to access lower layers:

```nix
# From builders
jd = mkJohnnyDecimal {};
jd.primitives     # Access primitives layer
jd.composition    # Access composition layer
jd.identifiers    # Access identifier definitions

# From composition
id = lib.composition.identifiers.mk {...};
id.primitives     # Can access primitives if needed

# Direct primitive access
lib.primitives.numberSystems.decimal
lib.primitives.fields.mk {...}
```

This allows:
- Progressive disclosure of complexity
- Advanced users can drop down when needed
- Custom extensions beyond builder capabilities

---

## Testing

All components developed using **strict TDD** (RED → GREEN → REFACTOR):

- **126 total tests** across all layers
- **100% passing rate**
- Tests located in `nix/tests/` cell

Run tests:
```bash
# All lib tests
nix build .#checks.x86_64-linux.lib-all

# Specific layer
nix build .#checks.x86_64-linux.primitives-all
nix build .#checks.x86_64-linux.composition-all
nix build .#checks.x86_64-linux.builders-all

# Specific component
nix build .#checks.x86_64-linux.primitives-number-systems
nix build .#checks.x86_64-linux.builders-johnny-decimal
```

---

## Usage Patterns

### Pattern 1: Use Builders (Recommended for most cases)

```nix
# Simple and convenient
jd = mkJohnnyDecimal {};
jd.parse "10.05"
```

### Pattern 2: Use Composition (For custom structures)

```nix
# More control
myId = lib.composition.identifiers.mk {
  fields = [customField1 customField2];
  separator = "-";
};
```

### Pattern 3: Use Primitives (For maximum flexibility)

```nix
# Full control, manual assembly
myField = lib.primitives.fields.mk {
  system = lib.primitives.numberSystems.hex;
  width = 4;
  padding = "zeros";
};
```

### Pattern 4: Mix Layers (Use escape hatches)

```nix
# Start with builder, customize with lower layers
jd = mkJohnnyDecimal {};

# Access underlying field for custom validation
categoryField = jd.identifiers.category;
customValidation = lib.primitives.constraints.custom (v: v % 10 == 0);
```

---

## Design Principles

1. **Pure Functions**: No side effects, referential transparency
2. **Composability**: Functions combine naturally
3. **Layering**: Clear dependencies (builders ← composition ← primitives)
4. **Fail-Safe**: Invalid inputs return `null`, not errors
5. **Escape Hatches**: Every layer exposes its dependencies
6. **Documentation**: Examples for every function
7. **Testing**: TDD methodology throughout

---

## Performance

- **Fast**: Pure functions with minimal allocations
- **Efficient**: < 300ms for 1000 operations (builders layer)
- **Lazy**: Only evaluates what's needed
- **Cacheable**: Pure functions enable Nix caching

---

## Integration

### In a Flake

```nix
{
  description = "My project using johnny-declarative-decimal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    johnny-dd.url = "github:youruser/johnny-mnemonix";
  };

  outputs = { self, nixpkgs, johnny-dd }: {
    # Use in your outputs
    lib = johnny-dd.lib.x86_64-linux;

    # Example: Create custom JD system
    mySystem = johnny-dd.lib.x86_64-linux.builders.mkJohnnyDecimal {
      levels = 3;
      base = 10;
    };
  };
}
```

### In Home Manager

```nix
{ inputs, ... }:
{
  imports = [ inputs.johnny-dd.homeManagerModules.default ];

  # Access library in config
  home.packages = let
    jd = inputs.johnny-dd.lib.x86_64-linux.builders.mkJohnnyDecimal {};
  in [
    # Use jd in package definitions
  ];
}
```

---

## Related Documentation

- **Implementation Specs**: See `CLAUDE.md` files in each subdirectory
- **Test Specs**: See `nix/tests/CLAUDE.md`
- **Project Overview**: See root `CLAUDE.md`
- **Vision & Roadmap**: See root `TODO.md`

---

## Contributing

See individual `CLAUDE.md` files for:
- Detailed API specifications
- Implementation guidelines
- Test case definitions
- Design decisions

---

## Status

✅ **Complete** - All 126 tests passing

**Next Steps**:
- Integration tests
- Refactor johnny-mnemonix home-manager module to use library
- Begin frameworks layer
