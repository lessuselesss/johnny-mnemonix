# Expressiveness Analysis: Johnny Any-Decimal Systems

## The Core Insight

We're not just configuring a numbering system. We're defining:

1. **An algebraic structure** (how numbers compose)
2. **A semantic model** (what they mean)
3. **A visual grammar** (how they're displayed)
4. **A validation system** (what's correct)

All of these need to work together coherently.

## The Expressiveness Hierarchy

### Level 0: Fixed System (No Configuration)
```nix
# Classic Johnny Decimal - hardcoded
# Areas: 00-09, 10-19, ..., 90-99 (ranges of 10)
# Categories: 00-99
# Items: XX.YY
```

**Expressiveness**: 1/10
**Flexibility**: 0/10
**Simplicity**: 10/10

---

### Level 1: Parameterized System
```nix
{
  area_span = 10;        # How many categories per area
  category_width = 2;    # Digits in category number
  item_width = 2;        # Digits in item number
  base = 10;            # Number base
}
```

**Expressiveness**: 3/10
**Flexibility**: 3/10
**Simplicity**: 9/10

Can express:
- ✓ Different area spans (5, 10, 20, etc.)
- ✓ Different digit widths (1, 2, 3 digits)
- ✓ Different bases (binary, octal, decimal, hex)

Cannot express:
- ✗ Mixed radix (different bases per field)
- ✗ Variable width fields
- ✗ Non-numeric identifiers
- ✗ Custom hierarchy depths

---

### Level 2: Field-Based System
```nix
{
  fields = {
    category = { base = 10; width = 2; };
    item = { base = 10; width = 2; };
  };

  identifier = {
    octets = ["category" "item"];
    separator = ".";
  };

  area = {
    from = "category";
    span = 10;
  };
}
```

**Expressiveness**: 5/10
**Flexibility**: 5/10
**Simplicity**: 7/10

Can express:
- ✓ Different bases per field
- ✓ Different widths per field
- ✓ Custom separators
- ✓ Derived ranges

Cannot express:
- ✗ Variable width within field
- ✗ Arbitrary hierarchy depth
- ✗ Complex identifier patterns
- ✗ Conditional syntax

---

### Level 3: Type-Based Compositional
```nix
{
  # Define primitive types
  number_systems = {
    dec = { radix = 10; };
    hex = { radix = 16; };
    alpha = { radix = 26; alphabet = "A-Z"; };
  };

  # Compose into fields
  fields = {
    dept = field number_systems.alpha { width = 2; };
    year = field number_systems.dec { width = 2; };
    seq = field number_systems.dec { width = 3; };
  };

  # Compose into identifiers
  identifiers = {
    project_id = compose [fields.dept fields.year fields.seq]
      { separator = "-"; };
  };

  # Define hierarchy
  hierarchy = tree {
    root = level identifiers.project_id;
  };
}
```

**Expressiveness**: 8/10
**Flexibility**: 8/10
**Simplicity**: 5/10

Can express:
- ✓ Mixed radix systems
- ✓ Custom alphabets
- ✓ Complex compositions
- ✓ Arbitrary separators

Cannot express:
- ✗ Variable width (still fixed)
- ✗ Context-dependent parsing
- ✗ Alternative representations

---

### Level 4: Grammar-Based (Maximum Flexibility)
```nix
{
  # Define grammar for identifiers
  grammar = {
    terminals = {
      DEPT = { pattern = "[A-Z]{2,4}"; };
      YEAR = { pattern = "[0-9]{2}"; };
      SEQ = { pattern = "[0-9]{1,4}"; };  # Variable width!
    };

    rules = {
      project_id = seq(DEPT, "-", YEAR, "-", SEQ);
      alt_format = seq(YEAR, "/", DEPT, "/", SEQ);  # Alternative
    };

    # Can parse either format
    identifier = choice(project_id, alt_format);
  };

  # Validation rules
  constraints = {
    unique_ids = no_duplicates("identifier");
    year_range = range_check("YEAR", 0, 99);
    dept_whitelist = enum("DEPT", ["ENG", "DES", "OPS"]);
  };

  # Semantic meaning
  semantics = {
    DEPT = { meaning = "Department code"; };
    YEAR = { meaning = "Year of creation"; };
    SEQ = { meaning = "Sequential number"; };
  };
}
```

**Expressiveness**: 10/10
**Flexibility**: 10/10
**Simplicity**: 3/10

Can express:
- ✓ Variable width fields
- ✓ Alternative formats
- ✓ Context-dependent parsing
- ✓ Complex validation
- ✓ Semantic annotations

---

## Real-World Examples

### Example 1: Library Classification (Dewey Decimal)

```nix
{
  # Dewey: 3 digits + decimal point + variable extension
  # Like: 512.73 (Galois Theory)

  grammar = {
    main_class = { base = 10; width = 3; range = [0, 999]; };
    division = { base = 10; width = { min = 1; max = 6; }; };
  };

  identifier = {
    format = "{main_class}.{division}";
    example = "512.73";
  };

  hierarchy = {
    class = { digits = 1; name = "Main Class"; };      # 5 = Science
    division = { digits = 2; name = "Division"; };     # 51 = Mathematics
    section = { digits = 3; name = "Section"; };       # 512 = Algebra
    subsection = { variable = true; name = "Topic"; }; # .73 = Galois
  };
}
```

### Example 2: Chemical Classification (CAS Registry)

```nix
{
  # CAS: Variable-Variable-Check
  # Like: 7732-18-5 (Water)

  fields = {
    substance = { base = 10; width = { min = 2; max = 7; }; };
    sequence = { base = 10; width = 2; };
    check = { base = 10; width = 1; computed = true; };
  };

  identifier = {
    format = "{substance}-{sequence}-{check}";
    check_algorithm = "cas_check_digit";
  };
}
```

### Example 3: Semver (Semantic Versioning)

```nix
{
  # Semver: MAJOR.MINOR.PATCH[-prerelease][+build]

  fields = {
    major = { base = 10; width = { min = 1; max = null; }; };
    minor = { base = 10; width = { min = 1; max = null; }; };
    patch = { base = 10; width = { min = 1; max = null; }; };
    prerelease = { base = "alphanum"; optional = true; };
    build = { base = "alphanum"; optional = true; };
  };

  identifier = {
    format = "{major}.{minor}.{patch}[-{prerelease}][+{build}]";
  };

  validation = {
    ordering = {
      major > minor > patch > prerelease;
      build = "ignored";
    };
  };
}
```

### Example 4: ISBN (Book Identifiers)

```nix
{
  # ISBN-13: 978-0-306-40615-7

  fields = {
    prefix = { base = 10; width = 3; values = [978, 979]; };
    group = { base = 10; width = { min = 1; max = 5; }; };  # Variable!
    publisher = { base = 10; width = { min = 1; max = 7; }; };
    title = { base = 10; width = { min = 1; max = 6; }; };
    check = { base = 10; width = 1; computed = true; };
  };

  # Width depends on prefix - context sensitive!
  width_rules = {
    "978-0" = { publisher = 2; title = 7; };
    "978-1" = { publisher = 4; title = 5; };
    # ... lookup table
  };

  identifier = {
    format = "{prefix}-{group}-{publisher}-{title}-{check}";
    check_algorithm = "isbn13_check";
  };
}
```

## Design Space Analysis

### Axis 1: Width Constraints

```
Fixed Width         Variable Width        Computed Width
    |                     |                      |
    v                     v                      v
[00-99]             [0-9999]              f(context)

Pros:               Pros:                 Pros:
- Predictable       - Flexible            - Optimal
- Sortable          - No limit            - Context-aware
- Aligned           - Natural             - Efficient

Cons:               Cons:                 Cons:
- Restrictive       - Complex sort        - Complex parsing
- Wastes space      - Alignment hard      - Needs lookup
```

### Axis 2: Base Systems

```
Single Base         Mixed Radix           Custom Alphabet
    |                     |                      |
    v                     v                      v
base=10             [10,26,16]           "ACGT" (DNA)

Pros:               Pros:                 Pros:
- Simple            - Flexible            - Domain-specific
- Familiar          - Optimized           - Meaningful
- Standard          - Dense               - Validated

Cons:               Cons:                 Cons:
- May be wrong      - Complex             - Custom parser
  choice            - Unfamiliar          - Special rules
```

### Axis 3: Hierarchy Structure

```
Fixed Depth         Variable Depth        DAG
    |                     |                 |
    v                     v                 v
Area>Cat>Item       1-N levels          Multiple parents

Pros:               Pros:                 Pros:
- Predictable       - Flexible            - Realistic
- Simple            - Extensible          - Cross-cutting
- Fast parse        - Future-proof        - Rich semantics

Cons:               Cons:                 Cons:
- Restrictive       - Complex             - Very complex
- May not fit       - Validation hard     - Ambiguous paths
```

### Axis 4: Syntax Flexibility

```
Fixed Syntax        Templated             Grammar-Based
    |                     |                      |
    v                     v                      v
"00.00"            "{a}.{b}"            EBNF grammar

Pros:               Pros:                 Pros:
- Fast              - Configurable        - Arbitrary
- Simple            - Clear               - Extensible
- Unambiguous       - Validated           - Precise

Cons:               Cons:                 Cons:
- Inflexible        - Limited             - Overkill?
- May not match     - Parsing manual      - Complex
```

## Recommended Approach: Progressive Complexity

### Layer 1: Quick Start (Covers 80% of cases)
```nix
{
  quick = {
    levels = 3;
    base = 10;
    digits = 2;
    area_span = 10;
  };
}
```

### Layer 2: Field Configuration (Covers 95% of cases)
```nix
{
  fields = {
    category = { base = 10; width = 2; };
    item = { base = 10; width = 2; };
  };
  area = { from = "category"; span = 10; };
}
```

### Layer 3: Full Grammar (Covers 100% of cases)
```nix
{
  grammar = {
    terminals = { ... };
    rules = { ... };
  };
  validation = { ... };
  semantics = { ... };
}
```

## The Goldilocks Zone

For Johnny Decimal and most organizational systems, **Layer 2** (Field Configuration) is the sweet spot:

```nix
{
  # Define what you can count with
  number_systems = {
    decimal = { radix = 10; };
    hex = { radix = 16; };
    alpha = { radix = 26; alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; };
  };

  # Define your fields
  fields = {
    category = {
      system = decimal;
      width = 2;
      padding = "zeros";
    };
    item = {
      system = decimal;
      width = 2;
      padding = "zeros";
    };
  };

  # Compose into identifiers
  identifiers = {
    item_id = {
      octets = ["category" "item"];
      separator = ".";
    };
  };

  # Define derived structures
  ranges = {
    area = {
      from = fields.category;
      span = 10;
    };
  };

  # Define hierarchy
  hierarchy = {
    area = {
      id = ranges.area;
      name = "string";
      contains = ["category"];
    };
    category = {
      id = fields.category;
      name = "string";
      contains = ["item"];
      constraints = ["in_parent_area"];
    };
    item = {
      id = identifiers.item_id;
      name = "string";
    };
  };

  # Define visual syntax
  syntax = {
    area = "[{id} {name}]";
    category = "({id} {name})";
    item = "<{id} {name}>";
    filename = "[{item.id}]{area}__{category}__{item}.nix";
  };
}
```

## Key Insights

1. **Composability Matters**
   - Small pieces (fields) → Medium pieces (identifiers) → Large pieces (hierarchy)
   - Each level can be validated independently
   - Each level can have defaults

2. **Separation of Concerns**
   - **Structure** (what): Fields, identifiers, hierarchy
   - **Meaning** (why): Semantic roles, constraints
   - **Representation** (how): Syntax, templates, separators

3. **Validation Levels**
   - **Lexical**: Does it match the pattern?
   - **Syntactic**: Can it be parsed?
   - **Semantic**: Does it make sense?
   - **Referential**: Is it consistent?

4. **The Power of Defaults**
   - Simple cases should need minimal config
   - Complex cases should be possible
   - Explicit overrides when needed

5. **Self-Description**
   - Configuration should generate parser
   - Configuration should generate validator
   - Configuration should generate documentation

## Next Implementation Steps

1. Define core types in Nix
2. Create builder functions for common patterns
3. Generate parsers from field definitions
4. Generate validators from constraints
5. Generate documentation from semantics
6. Test with various real-world systems
