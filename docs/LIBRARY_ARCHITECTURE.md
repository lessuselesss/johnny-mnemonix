# Library Architecture: Libraries vs Frameworks

## The Core Question

Based on Tomas Petricek's insights:
- **Libraries**: You call them (provide primitives, user controls flow)
- **Frameworks**: They call you (provide structure, framework controls flow)

**What should johnny-declarative-decimal be?**

## Current Problem

We're building something that tries to be both:
```nix
# Framework-like (opinionated, controls structure)
johnny-mnemonix.areas = {
  "10-19" = { ... };  # You fit into our structure
};

# Library-like (flexible, you control)
parseJDFilename filename;  # You call our functions
```

This creates tension between **flexibility** and **ease-of-use**.

## Petricek's Library Layers Applied

### Bad Approach (Monolithic Framework)
```
┌─────────────────────────────────┐
│  Johnny Decimal Framework       │  ← One size fits all
│  - Fixed structure              │  ← Can't escape it
│  - Opinionated                  │  ← Take it or leave it
└─────────────────────────────────┘
```

### Good Approach (Layered Library)
```
┌─────────────────────────────────────────┐
│ Layer 4: Frameworks (Optional)          │  ← Quick start, opinions
│  - johnny-decimal-classic               │
│  - semver-framework                     │
│  - isbn-framework                       │
├─────────────────────────────────────────┤
│ Layer 3: Domain Builders                │  ← Convenience
│  - mkJohnnyDecimal                      │
│  - mkVersioning                         │
│  - mkClassification                     │
├─────────────────────────────────────────┤
│ Layer 2: Composition                    │  ← Derived operations
│  - mkIdentifier                         │
│  - mkRange                              │
│  - mkHierarchy                          │
│  - mkValidator                          │
├─────────────────────────────────────────┤
│ Layer 1: Primitives                     │  ← Core building blocks
│  - mkNumberSystem                       │
│  - mkField                              │
│  - parseField                           │
│  - validateConstraint                   │
└─────────────────────────────────────────┘
```

**Users can drop down to any layer they need!**

## Concrete Design

### Layer 1: Primitives (Pure Library)

The atomic operations that do ONE thing well:

```nix
# lib/primitives.nix
{
  # Number system operations
  numberSystems = {
    # Create a number system
    mk = {radix, alphabet ? null}: {
      inherit radix alphabet;
      # ... validation
    };

    # Parse string to value in this system
    parse = sys: str: /* ... */;

    # Format value to string in this system
    format = sys: value: /* ... */;

    # Validate value in this system
    validate = sys: value: /* ... */;

    # Built-in systems
    decimal = mk {radix = 10;};
    hex = mk {radix = 16; alphabet = "0123456789ABCDEF";};
    binary = mk {radix = 2;};
    octal = mk {radix = 8;};
    alphabetic = mk {radix = 26; alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";};
  };

  # Field operations (a constrained number)
  fields = {
    # Create a field
    mk = {system, width, padding ? "zeros"}: {
      inherit system width padding;
    };

    # Parse string to field value
    parse = field: str: /* ... */;

    # Format field value to string
    format = field: value: /* ... */;

    # Validate field value
    validate = field: value: /* ... */;

    # Get range of valid values
    range = field: {
      min = 0;
      max = field.system.radix ^ field.width - 1;
    };
  };

  # Constraint operations
  constraints = {
    # Basic constraint types
    range = {min, max}: value:
      value >= min && value <= max;

    enum = allowed: value:
      builtins.elem value allowed;

    pattern = regex: value:
      builtins.match regex value != null;

    custom = predicate: value:
      predicate value;
  };

  # String template operations
  templates = {
    # Parse template string
    parse = template: /* extract {variable} placeholders */;

    # Render template with context
    render = template: context: /* substitute variables */;

    # Validate template
    validate = template: /* check syntax */;
  };
}
```

**Key Properties**:
- ✓ Pure functions
- ✓ No global state
- ✓ No dependencies
- ✓ Highly testable
- ✓ Composable

### Layer 2: Composition (Library)

Build complex things from primitives:

```nix
# lib/composition.nix
{primitives}: let
  inherit (primitives) numberSystems fields constraints templates;
in {
  # Identifiers (multiple fields combined)
  identifiers = {
    mk = {octets, separator}: {
      inherit octets separator;
    };

    parse = id: str:
      let parts = lib.splitString id.separator str;
      in lib.zipListsWith (field: part: fields.parse field part) id.octets parts;

    format = id: values:
      lib.concatStringsSep id.separator
        (lib.zipListsWith fields.format id.octets values);

    validate = id: str:
      let parsed = parse id str;
      in lib.all (x: x != null) parsed;
  };

  # Ranges (derived from fields)
  ranges = {
    mk = {from, span}: {
      inherit from span;
    };

    # Get range that contains a value
    containing = range: value:
      let bucket = value / range.span;
      in {
        start = bucket * range.span;
        end = (bucket + 1) * range.span - 1;
      };

    # Check if value is in range
    contains = range: rangeValue: value:
      value >= rangeValue.start && value <= rangeValue.end;
  };

  # Hierarchies (levels with relationships)
  hierarchies = {
    mk = {levels, root}: {
      inherit levels root;
    };

    # Get path from root to leaf
    path = hierarchy: leaf:
      let
        getParent = level: hierarchy.levels.${level}.parent or null;
        buildPath = acc: level:
          if level == null then acc
          else buildPath ([level] ++ acc) (getParent level);
      in buildPath [] leaf;

    # Validate hierarchy is acyclic
    validate = hierarchy: /* check for cycles */;

    # Get all leaves
    leaves = hierarchy: /* find levels with no children */;
  };

  # Validators (compose constraints)
  validators = {
    mk = constraintList: value:
      lib.all (c: c value) constraintList;

    combine = validators:
      value: lib.all (v: v value) validators;

    # Common validator patterns
    required = field: value: value != null;
    unique = seen: value: !(builtins.elem value seen);
    referential = ref: value: /* check reference exists */;
  };
}
```

**Key Properties**:
- ✓ Built from Layer 1
- ✓ Still pure functions
- ✓ Domain-agnostic
- ✓ Reusable across systems

### Layer 3: Domain Builders (Library + Opinion)

High-level builders for common patterns:

```nix
# lib/builders.nix
{primitives, composition}: {
  # Quick builder for johnny-decimal-like systems
  mkJohnnyDecimal = {
    levels ? 3,
    base ? 10,
    digits ? 2,
    area_span ? 10,
  }: let
    sys = primitives.numberSystems.mk {radix = base;};
    field = primitives.fields.mk {
      system = sys;
      width = digits;
      padding = "zeros";
    };
  in {
    fields = {
      category = field;
      item = field;
    };

    identifier = composition.identifiers.mk {
      octets = [field field];
      separator = ".";
    };

    area = composition.ranges.mk {
      from = field;
      span = area_span;
    };

    hierarchy = composition.hierarchies.mk {
      levels = {
        area = {id = "range"; contains = "category";};
        category = {id = field; parent = "area"; contains = "item";};
        item = {id = "identifier"; parent = "category";};
      };
      root = "area";
    };
  };

  # Builder for versioning systems
  mkVersioning = {
    octets ? 3,  # major.minor.patch
    separator ? ".",
    prerelease ? false,
  }: /* ... */;

  # Builder for classification systems
  mkClassification = {
    depth,
    digits_per_level,
    base ? 10,
  }: /* ... */;

  # Builder from template string
  fromTemplate = template:
    /* parse template and infer structure */;

  # Builder from examples
  fromExamples = examples:
    /* infer structure from example IDs */;
}
```

**Key Properties**:
- ✓ Opinionated (good defaults)
- ✓ Convenient (less boilerplate)
- ✓ Still flexible (all parameters)
- ✓ Built on lower layers

### Layer 4: Frameworks (Optional)

Complete, opinionated solutions:

```nix
# frameworks/johnny-decimal-classic.nix
{builders}: {
  # The classic Johnny Decimal system
  system = builders.mkJohnnyDecimal {
    levels = 3;
    base = 10;
    digits = 2;
    area_span = 10;
  };

  # Standard syntax
  syntax = {
    area = "[{id} {name}]";
    category = "({id} {name})";
    item = "<{id} {name}>";
  };

  # Home-manager integration
  homeManagerModule = /* ... */;

  # Flake-parts integration
  flakeModule = /* ... */;
}

# frameworks/semver.nix
{builders}: {
  system = builders.mkVersioning {
    octets = 3;
    separator = ".";
    prerelease = true;
    build_metadata = true;
  };

  # Semver-specific rules
  constraints = /* ... */;

  # Git integration
  gitHooks = /* ... */;
}
```

**Key Properties**:
- ✓ Complete solutions
- ✓ Integration with ecosystems
- ✓ Best practices baked in
- ✗ Less flexible (by design)

## Should We Use nix-std?

**Analysis**:

### Pros of nix-std:
- ✓ Functional abstractions (functor, monad, semigroup)
- ✓ No nixpkgs dependency
- ✓ Well-tested utilities

### Cons of nix-std:
- ✗ Adds external dependency
- ✗ May be overkill for our needs
- ✗ Nix already has `lib` from nixpkgs (and we're using home-manager anyway)
- ✗ Functional abstractions might obscure intent

### Our Actual Needs:
1. String manipulation ✓ (builtins + nixpkgs.lib)
2. List operations ✓ (builtins + nixpkgs.lib)
3. Number parsing/formatting ✓ (can implement simply)
4. Pattern matching ✓ (builtins.match)
5. Validation logic ✓ (pure functions)

**Recommendation: Build our own minimal library**

Why:
1. **Simplicity**: Our needs are specific and bounded
2. **Control**: We control the API exactly
3. **Transparency**: No magic, clear what's happening
4. **Dependencies**: Already have nixpkgs.lib
5. **Learning**: Building it teaches the domain

## Proposed Structure

```
lib/
  primitives/
    number-systems.nix    # Base radix operations
    fields.nix            # Constrained numbers
    constraints.nix       # Validation predicates
    templates.nix         # String templating

  composition/
    identifiers.nix       # Multi-field IDs
    ranges.nix           # Derived ranges
    hierarchies.nix      # Level relationships
    validators.nix       # Constraint composition

  builders/
    johnny-decimal.nix   # JD-specific builder
    versioning.nix       # Semver-like builder
    classification.nix   # Dewey-like builder

  default.nix            # Export all layers

frameworks/
  johnny-decimal-classic.nix
  semver.nix

modules/
  home-manager.nix       # HM integration
  flake-parts.nix       # Flake-parts integration
```

## Usage Patterns

### Pattern 1: Use the Framework (Easiest)
```nix
{
  imports = [
    johnny-declarative-decimal.frameworks.johnny-decimal-classic
  ];

  johnny-mnemonix.enable = true;
}
```

### Pattern 2: Use the Builder (Flexible)
```nix
let
  mySystem = johnny-declarative-decimal.lib.builders.mkJohnnyDecimal {
    base = 16;  # Hexadecimal!
    area_span = 16;
  };
in {
  # Use the system
}
```

### Pattern 3: Use Composition (Very Flexible)
```nix
let
  lib = johnny-declarative-decimal.lib;

  mySystem = {
    fields = {
      dept = lib.primitives.fields.mk {
        system = lib.primitives.numberSystems.alphabetic;
        width = 3;
      };
      year = lib.primitives.fields.mk {
        system = lib.primitives.numberSystems.decimal;
        width = 2;
      };
    };

    identifier = lib.composition.identifiers.mk {
      octets = [mySystem.fields.dept mySystem.fields.year];
      separator = "-";
    };
  };
in {
  # Use custom system
}
```

### Pattern 4: Use Primitives (Maximum Control)
```nix
let
  prim = johnny-declarative-decimal.lib.primitives;

  # Build everything from scratch
  myField = prim.fields.mk {
    system = prim.numberSystems.mk {
      radix = 7;  # Base 7!
      alphabet = "ABCDEFG";
    };
    width = 3;
  };
in {
  # Total control
}
```

## Migration Path

1. **Phase 1**: Extract current parsing/validation into primitives
2. **Phase 2**: Build composition layer
3. **Phase 3**: Create builders for common patterns
4. **Phase 4**: Package current system as "classic framework"
5. **Phase 5**: Users can choose their layer

## Benefits of This Approach

1. **Flexibility**: Users escape to lower layers as needed
2. **Simplicity**: Simple cases are simple (use framework)
3. **Power**: Complex cases are possible (use primitives)
4. **Testability**: Each layer tested independently
5. **Documentation**: Clear layers, clear docs
6. **Extensibility**: Add new frameworks, builders without touching primitives
7. **Reusability**: Primitives useful beyond johnny-decimal

## Comparison to Alternatives

### If we used nix-std:
```nix
# Would look like this (functional style)
functor.map parseField (string.split "." input)
```

### Our approach:
```nix
# Looks like this (domain style)
lib.identifiers.parse myIdentifier input
```

Our approach is **more readable** for the domain, even if less "theoretically pure."

## Decision: Build Our Own Layered Library

**Reasoning**:
1. ✓ Fits our domain perfectly
2. ✓ Clear, simple, transparent
3. ✓ No extra dependencies
4. ✓ Follows Petricek's layering principles
5. ✓ Supports both framework and library use cases
6. ✓ Easier to maintain and understand

**What we'll borrow from nix-std's philosophy**:
- Pure functions
- Composability
- Minimal dependencies
- Good test coverage

**What we won't borrow**:
- Heavy functional abstractions
- Typeclass-style interfaces (Nix doesn't have types anyway)
