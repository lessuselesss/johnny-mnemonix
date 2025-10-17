# Layered Library: Practical Example

## The Same Task at Each Layer

Let's solve the same problem at each layer to show the tradeoffs.

**Goal**: Create a project numbering system like `ENG-24-001` (Department-Year-Sequence)

---

## Layer 1: Primitives (Maximum Control, Maximum Work)

```nix
let
  lib = johnny-declarative-decimal.lib.primitives;

  # Build number system
  alphabetic = lib.numberSystems.mk {
    radix = 26;
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  };

  decimal = lib.numberSystems.mk {
    radix = 10;
  };

  # Build fields
  deptField = lib.fields.mk {
    system = alphabetic;
    width = 3;
    padding = "none";
  };

  yearField = lib.fields.mk {
    system = decimal;
    width = 2;
    padding = "zeros";
  };

  seqField = lib.fields.mk {
    system = decimal;
    width = 3;
    padding = "zeros";
  };

  # Build parser manually
  parseProjectId = input: let
    parts = lib.strings.split "-" input;
    dept = lib.fields.parse deptField (builtins.elemAt parts 0);
    year = lib.fields.parse yearField (builtins.elemAt parts 1);
    seq = lib.fields.parse seqField (builtins.elemAt parts 2);
  in
    if builtins.length parts != 3 then null
    else {inherit dept year seq;};

  # Build formatter manually
  formatProjectId = {dept, year, seq}:
    lib.strings.concat [
      (lib.fields.format deptField dept)
      "-"
      (lib.fields.format yearField year)
      "-"
      (lib.fields.format seqField seq)
    ];

  # Build validator manually
  validateProjectId = {dept, year, seq}:
    lib.fields.validate deptField dept
    && lib.fields.validate yearField year
    && lib.fields.validate seqField seq
    && builtins.elem dept ["ENG" "DES" "OPS"];
in {
  inherit parseProjectId formatProjectId validateProjectId;
}
```

**Lines of code**: ~50
**Flexibility**: 100%
**Ease of use**: 20%
**Good for**: Building new abstractions, unusual requirements

---

## Layer 2: Composition (Moderate Control, Moderate Work)

```nix
let
  prim = johnny-declarative-decimal.lib.primitives;
  comp = johnny-declarative-decimal.lib.composition;

  # Build fields (same as above)
  alphabetic = prim.numberSystems.alphabetic;
  decimal = prim.numberSystems.decimal;

  fields = {
    dept = prim.fields.mk {system = alphabetic; width = 3;};
    year = prim.fields.mk {system = decimal; width = 2; padding = "zeros";};
    seq = prim.fields.mk {system = decimal; width = 3; padding = "zeros";};
  };

  # Use composition layer for identifier
  projectId = comp.identifiers.mk {
    octets = [fields.dept fields.year fields.seq];
    separator = "-";
  };

  # Use composition layer for validator
  validator = comp.validators.mk [
    (prim.constraints.enum ["ENG" "DES" "OPS"])  # For dept
    (prim.constraints.range {min = 0; max = 99})  # For year
    (prim.constraints.range {min = 0; max = 999})  # For seq
  ];
in {
  # Parser, formatter, validator come from composition
  parse = comp.identifiers.parse projectId;
  format = comp.identifiers.format projectId;
  validate = validator;
}
```

**Lines of code**: ~25
**Flexibility**: 80%
**Ease of use**: 60%
**Good for**: Custom systems, reusable patterns

---

## Layer 3: Builders (Opinionated, Easy)

```nix
let
  builders = johnny-declarative-decimal.lib.builders;

  # Use high-level builder
  system = builders.mkProjectSystem {
    department = {
      type = "alphabetic";
      width = 3;
      allowed = ["ENG" "DES" "OPS" "SAL" "MKT"];
    };
    year = {
      type = "decimal";
      width = 2;
      range = [0, 99];
    };
    sequence = {
      type = "decimal";
      width = 3;
      range = [1, 999];
    };
    separator = "-";
  };
in {
  # Everything generated from config
  inherit (system) parse format validate;
}
```

**Lines of code**: ~15
**Flexibility**: 50%
**Ease of use**: 85%
**Good for**: Standard patterns, quick prototypes

---

## Layer 4: Framework (Zero Config, Zero Flexibility)

```nix
{
  imports = [
    johnny-declarative-decimal.frameworks.project-numbering
  ];

  project-numbering = {
    enable = true;
    departments = ["ENG" "DES" "OPS" "SAL" "MKT"];
  };
}
```

**Lines of code**: ~5
**Flexibility**: 10%
**Ease of use**: 100%
**Good for**: Standard use cases, rapid deployment

---

## Escape Hatches (Critical!)

### Escape from Layer 4 to Layer 3

```nix
{
  imports = [
    johnny-declarative-decimal.frameworks.project-numbering
  ];

  # Override the system builder
  project-numbering.systemOverride = builders.mkProjectSystem {
    # ... custom config
  };
}
```

### Escape from Layer 3 to Layer 2

```nix
let
  # Start with builder
  base = builders.mkProjectSystem { ... };

  # But customize one part
  customValidator = comp.validators.mk [
    base.validator
    (prim.constraints.custom (val: /* custom logic */))
  ];
in {
  parse = base.parse;
  format = base.format;
  validate = customValidator;  # Custom!
}
```

### Escape from Layer 2 to Layer 1

```nix
let
  # Start with composition
  base = comp.identifiers.mk { ... };

  # But override parser for edge case
  customParse = input:
    if isEdgeCase input
    then handleEdgeCase input
    else comp.identifiers.parse base input;
in {
  parse = customParse;
  format = comp.identifiers.format base;
}
```

---

## Real Example: Evolution of a Project

### Week 1: Quick Start (Layer 4)

```nix
{
  imports = [johnny-dd.frameworks.johnny-decimal-classic];
  johnny-mnemonix.enable = true;
}
```

**Result**: Working system in minutes!

### Week 2: Customization (Layer 3)

```nix
let
  system = builders.mkJohnnyDecimal {
    base = 16;  # Hmm, want hexadecimal
    area_span = 16;
  };
in {
  johnny-mnemonix.system = system;
}
```

**Result**: Still easy, but now customized!

### Month 2: Special Requirements (Layer 2)

```nix
let
  # Need mixed: hex categories, decimal items
  fields = {
    category = prim.fields.mk {
      system = prim.numberSystems.hex;
      width = 2;
    };
    item = prim.fields.mk {
      system = prim.numberSystems.decimal;
      width = 2;
    };
  };

  identifier = comp.identifiers.mk {
    octets = [fields.category fields.item];
    separator = ":";  # Use : not .
  };
in {
  johnny-mnemonix.system = {inherit fields identifier;};
}
```

**Result**: Total control over structure!

### Month 6: Edge Cases (Layer 1)

```nix
let
  # Need custom alphabet (no vowels to avoid swear words)
  customAlpha = prim.numberSystems.mk {
    radix = 20;
    alphabet = "BCDFGHJKLMNPQRSTVWXZ";
  };

  # Custom parser for legacy IDs
  legacyParser = input:
    if builtins.match "OLD-.*" input != null
    then parseLegacyFormat input
    else prim.fields.parse myField input;
in {
  # Mix custom and standard
  system = {
    parse = legacyParser;  # Custom
    format = prim.fields.format myField;  # Standard
  };
}
```

**Result**: Handle anything!

---

## Anti-Pattern: Framework Lock-In

### Bad Framework (Locks You In)

```nix
# framework-bad.nix
{
  # No escape hatch!
  mkSystem = {departments}: {
    _internal = { /* hidden */ };
    # Can't override, can't extend, can't escape
  };
}
```

**Problem**: If you need something it doesn't support, you're stuck.

### Good Framework (Escape Hatches)

```nix
# framework-good.nix
{lib}: {
  mkSystem = {departments, overrides ? {}}: let
    # Build from library
    base = lib.builders.mkProjectSystem {inherit departments;};
  in
    # Allow overrides
    base // overrides // {
      # Expose internal library for escaping
      _lib = lib;
      _base = base;
    };
}
```

**Solution**: Always expose the layer below!

---

## Testing at Each Layer

### Layer 1: Unit Tests

```nix
{
  testNumberSystemParse = {
    expr = prim.numberSystems.parse prim.numberSystems.hex "FF";
    expected = 255;
  };

  testFieldFormat = {
    expr = prim.fields.format myField 42;
    expected = "042";
  };
}
```

### Layer 2: Integration Tests

```nix
{
  testIdentifierRoundTrip = let
    id = comp.identifiers.mk { ... };
    input = "ENG-24-001";
    parsed = comp.identifiers.parse id input;
    formatted = comp.identifiers.format id parsed;
  in {
    expr = formatted;
    expected = input;
  };
}
```

### Layer 3: Property Tests

```nix
{
  testBuilderDefaults = let
    system = builders.mkJohnnyDecimal {};
  in {
    expr = system.fields.category.width;
    expected = 2;  # Sane default
  };
}
```

### Layer 4: End-to-End Tests

```nix
{
  testFrameworkIntegration = let
    config = {
      imports = [frameworks.johnny-decimal-classic];
      johnny-mnemonix.enable = true;
    };
    result = evalConfig config;
  in {
    expr = result.home.file ? "index.typ";
    expected = true;
  };
}
```

---

## Documentation at Each Layer

### Layer 1: API Reference

```
primitives.numberSystems.mk :: {radix: Int, ?alphabet: String} -> NumberSystem

Creates a number system with the given radix and optional alphabet.

Examples:
  prim.numberSystems.mk {radix = 10;}
  prim.numberSystems.mk {radix = 16; alphabet = "0123456789ABCDEF";}
```

### Layer 2: Guides

```
How to Create Custom Identifiers

1. Define your fields using primitives.fields.mk
2. Combine them with composition.identifiers.mk
3. The identifier will have parse/format/validate automatically

See examples/ for complete examples.
```

### Layer 3: Recipes

```
Recipe: Hexadecimal Johnny Decimal

mkJohnnyDecimal {
  base = 16;
  area_span = 16;
}

This creates a system with hex categories (00-FF) and hex items,
with areas spanning 16 categories each.
```

### Layer 4: Tutorials

```
Getting Started with Johnny Decimal

1. Add to flake inputs: ...
2. Import the framework: ...
3. Enable in config: ...
4. You're done!
```

---

## Key Insights

1. **Layers insulate change**
   - Can rewrite Layer 1 without breaking Layer 3
   - Stable interfaces between layers

2. **Layers enable testing**
   - Test primitives thoroughly
   - Test composition logic
   - Integration tests at higher layers

3. **Layers match expertise**
   - Beginners: Layer 4 (framework)
   - Intermediate: Layer 3 (builders)
   - Advanced: Layer 2 (composition)
   - Expert: Layer 1 (primitives)

4. **Layers enable evolution**
   - Start simple (Layer 4)
   - Grow into complexity (Layer 1)
   - Not all-or-nothing

5. **Layers create ecosystem**
   - Anyone can build Layer 3 builders
   - Anyone can create Layer 4 frameworks
   - Layer 1-2 stay stable

---

## Conclusion

**Build johnny-declarative-decimal as a layered library, not a monolithic framework.**

This gives us:
- ✓ Easy for beginners (use the framework)
- ✓ Powerful for experts (use the primitives)
- ✓ Flexible for everyone (choose your layer)
- ✓ Extensible by community (build on the library)
- ✓ Testable at all levels
- ✓ Documented appropriately per layer

And we get inspiration from nix-std's philosophy (pure, composable)
without taking on its dependency or complexity.
