# Johnny Any-Decimal System: Design Exploration

## Core Abstraction

At its deepest level, we're modeling a **hierarchical identifier space** with:
- **Numerical structure** (how things are numbered)
- **Semantic meaning** (what the numbers represent)
- **Visual syntax** (how to make structure obvious)
- **Human labels** (names for everything)

## Fundamental Building Blocks (Bottom-Up)

### 1. Base Number System (Foundation)
The radix and alphabet for counting:

```nix
base_systems = {
  decimal = { radix = 10; alphabet = "0123456789"; };
  hex = { radix = 16; alphabet = "0123456789ABCDEF"; };
  alphabetic = { radix = 26; alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; };
  roman = { radix = null; alphabet = "IVXLCDM"; rules = custom_roman; };
}
```

### 2. Field/Octet (Constrained Number)
A number with constraints from a specific base:

```nix
field_types = {
  category = {
    base = decimal;
    width = { min = 2; max = 2; };  # Fixed width
    value_range = { min = 0; max = 99; };
    padding = "leading_zeros";
  };

  project_code = {
    base = alphabetic;
    width = { min = 2; max = 4; };  # Variable width
    value_range = null;  # Any valid value
    padding = "none";
  };
}
```

### 3. Identifier (Composite)
Multiple fields combined:

```nix
identifier_types = {
  item_id = {
    fields = [
      { name = "category"; type = field_types.category; }
      { name = "item"; type = field_types.category; }
    ];
    separator = ".";
    format = "{category}.{item}";  # Template
  };

  project_id = {
    fields = [
      { name = "dept"; type = field_types.project_code; }
      { name = "year"; type = field_types.category; }
      { name = "seq"; type = field_types.category; }
    ];
    separator = "-";
    format = "{dept}-{year}-{seq}";  # Like "ENG-24-01"
  };
}
```

### 4. Range (Derived)
A span of values from a field:

```nix
range_types = {
  area_range = {
    from_field = field_types.category;
    span = 10;  # Each range covers 10 values
    format = "{start}-{end}";

    # Alternative: explicit ranges
    # values = [[0,9], [10,19], [20,29]];
  };

  decade_range = {
    from_field = field_types.year;
    span = 10;
    format = "{start}s";  # Like "20s" for 20-29
  };
}
```

### 5. Level (Hierarchy Component)
A tier in the hierarchy with its identifier:

```nix
levels = {
  area = {
    identifier_type = range_types.area_range;
    name = { type = "string"; max_length = 50; };
    cardinality = "many";  # Can have multiple areas
    contains = "category";  # What this level contains
  };

  category = {
    identifier_type = field_types.category;
    name = { type = "string"; };
    cardinality = "many";
    parent = "area";
    contains = "item";

    # Constraint: must be within parent's range
    constraints = [
      { rule = "in_parent_range"; ref = "area"; }
    ];
  };

  item = {
    identifier_type = identifier_types.item_id;
    name = { type = "string"; };
    cardinality = "many";
    parent = "category";
  };
}
```

### 6. Syntax (Visual Representation)
How to represent each level visually:

```nix
syntax = {
  encapsulators = {
    area = { open = "["; close = "]"; };
    category = { open = "("; close = ")"; };
    item = { open = "<"; close = ">"; };
  };

  templates = {
    area = "{encap_open}{id} {name}{encap_close}";
    category = "{encap_open}{id} {name}{encap_close}";
    item = "{encap_open}{id} {name}{encap_close}";
  };

  separators = {
    hierarchy = " / ";  # Between levels in display
    module_hierarchy = "__";  # In flat filenames
    octet = ".";  # Within identifiers
    range = "-";  # Within range specs
    numeral_name = " ";  # Between ID and name
  };
}
```

## Top-Down Configuration Approaches

### Approach 1: Declarative Schema (Most Intuitive)

```nix
{
  # Start with intent
  system = {
    name = "Software Projects Organization";
    purpose = "Organize code projects by department and type";
  };

  # Define the conceptual structure
  hierarchy = {
    depth = 3;
    levels = {
      area = {
        meaning = "Department or broad category";
        examples = ["10-19 Engineering", "20-29 Design"];
      };
      category = {
        meaning = "Project type within department";
        examples = ["10 Backend", "11 Frontend"];
      };
      item = {
        meaning = "Specific project instance";
        examples = ["10.01 Auth-Service", "10.02 API-Gateway"];
      };
    };
  };

  # Define numbering simply
  numbering = {
    category = "00-99";  # Pattern implies base10, 2 digits, 0-99
    item = "00-99";
    area = {
      derived_from = "category";
      group_size = 10;  # Areas span 10 categories
    };
  };

  # Define how to display
  display = {
    area = "[{range} {name}]";
    category = "({id} {name})";
    item = "<{id} {name}>";

    full_path = "{area}/{category}/{item}";
    filename = "[{item.id}]{area}__{category}__{item}.nix";
  };

  # Validation happens automatically based on structure
}
```

### Approach 2: Type-Based (Most Rigorous)

```nix
{
  # Define types first
  types = {
    bases = {
      decimal = { radix = 10; digits = "0123456789"; };
    };

    fields = {
      decimal_2digit = {
        base = types.bases.decimal;
        width = 2;
        padding = "zeros";
      };
    };

    identifiers = {
      category_item = {
        structure = [
          { name = "cat"; type = types.fields.decimal_2digit; }
          { name = "item"; type = types.fields.decimal_2digit; }
        ];
        separator = ".";
      };
    };
  };

  # Then apply types to hierarchy
  hierarchy = {
    area = {
      id = { type = "range"; from = types.fields.decimal_2digit; span = 10; };
      name = { type = "string"; };
    };
    category = {
      id = { type = types.fields.decimal_2digit; };
      name = { type = "string"; };
      constraints = ["must_be_in_parent_range"];
    };
    item = {
      id = { type = types.identifiers.category_item; };
      name = { type = "string"; };
    };
  };
}
```

### Approach 3: Template Language (Most Compact)

```
SYSTEM "Software Projects"

STRUCTURE:
  Area(1:∞) ⊃ Category(1:∞) ⊃ Item(1:∞)

NUMBERING:
  Category: ℕ₁₀[00..99]
  Item: ℕ₁₀[00..99]
  Area: range(Category, span=10)

IDENTIFIERS:
  Item: {Category}.{Item}

SYNTAX:
  Area: [{Area.range} {Area.name}]
  Category: ({Category.id} {Category.name})
  Item: <{Item.id} {Item.name}>

FILENAME:
  [{Item.id}]{Area}__{Category}__{Item}.nix

CONSTRAINTS:
  Category.id ∈ Area.range
  Filename.item.cat = Category.id
  Filename.item.num = Item.id.item
```

### Approach 4: Compositional (Most Flexible)

```nix
{
  # Build up from primitives
  primitives = {
    # Define number systems
    decimal = numberSystem { radix = 10; };
    hex = numberSystem { radix = 16; };

    # Define fields
    d2 = field decimal { width = 2; pad = "zeros"; };
    d3 = field decimal { width = 3; pad = "zeros"; };

    # Compose identifiers
    cat_item = identifier [d2 d2] { separator = "."; };

    # Derive ranges
    area = range d2 { span = 10; };
  };

  # Define hierarchy relationships
  structure = hierarchy {
    area = level primitives.area "Areas";
    category = level primitives.d2 "Categories" {
      parent = area;
      constraint = in_range area;
    };
    item = level primitives.cat_item "Items" {
      parent = category;
    };
  };

  # Apply syntax
  representation = syntax structure {
    area = template "[{id} {name}]";
    category = template "({id} {name})";
    item = template "<{id} {name}>";
  };
}
```

## Advanced Capabilities

### Mixed Radix Systems

```nix
{
  # Different bases for different octets
  identifier = {
    fields = [
      { name = "dept"; base = alphabetic; width = 2; }  # AA-ZZ
      { name = "year"; base = decimal; width = 2; }     # 00-99
      { name = "seq"; base = hex; width = 3; }          # 000-FFF
    ];
    # Results in IDs like: "EN-24-A3F"
  };
}
```

### Variable Width Fields

```nix
{
  field = {
    base = decimal;
    width = { min = 1; max = 4; };  # 1-9999
    padding = "none";
  };
}
```

### Dynamic Ranges

```nix
{
  area_ranges = {
    type = "custom";
    values = [
      { start = 0; end = 9; name_prefix = "Meta"; }
      { start = 10; end = 29; name_prefix = "Projects"; }
      { start = 30; end = 39; name_prefix = "Archive"; }
    ];
  };
}
```

### Conditional Syntax

```nix
{
  syntax = {
    item = {
      template = if item.is_archived
        then "~{id} {name}~"
        else "<{id} {name}>";
    };
  };
}
```

## Key Design Principles

### 1. Separation of Concerns
- **What** (structure) is separate from **how** (syntax)
- Numbers separate from meaning separate from display

### 2. Composability
- Small pieces that combine
- Ranges derive from fields
- Identifiers compose from fields

### 3. Validation Layers
- **Lexical**: Does syntax match?
- **Structural**: Do octets parse?
- **Semantic**: Do values satisfy constraints?
- **Referential**: Are IDs consistent across hierarchy?

### 4. Progressive Disclosure
- Simple cases should be simple
- Complex cases should be possible
- Defaults handle common patterns

## Recommended Implementation

### Core Types (Nix)

```nix
{
  # Foundation
  numberSystem = { radix, alphabet, ?rules };

  # Building blocks
  field = { base, width, ?constraints, ?padding };
  identifier = { fields, separator, ?template };
  range = { from, span, ?format };

  # Structure
  level = { identifier, name, ?parent, ?constraints };
  hierarchy = { levels, relationships };

  # Presentation
  syntax = { encapsulators, separators, templates };

  # Validation
  constraint = { rule, refs, ?message };
  validation = { constraints, strictness };
}
```

### Configuration Schema

```nix
johnny-any-decimal = {
  # Quick start for simple cases
  quick = {
    levels = 3;
    base = 10;
    digits_per_level = 2;
    area_span = 10;
  };

  # Or full control for complex cases
  advanced = {
    number_systems = { ... };
    fields = { ... };
    identifiers = { ... };
    hierarchy = { ... };
    syntax = { ... };
    validation = { ... };
  };
};
```

## Example Systems

### Classic Johnny Decimal
```nix
{ quick = { levels = 3; base = 10; digits_per_level = 2; area_span = 10; }; }
```

### Hexadecimal Variant
```nix
{
  fields = {
    cat = { base = hex; width = 2; };
    item = { base = hex; width = 2; };
  };
  # Results in IDs like: 0A.FF
}
```

### Departmental System
```nix
{
  identifier = {
    fields = [
      { name = "dept"; base = alphabetic; width = 3; }  # ENG
      { name = "year"; base = decimal; width = 2; }     # 24
      { name = "project"; base = decimal; width = 3; }  # 001
    ];
    # Results in: ENG-24-001
  };
}
```

### Deep Hierarchy (4+ levels)
```nix
{
  levels = {
    division = { id = range { ... }; };
    department = { id = field { ... }; parent = division; };
    category = { id = field { ... }; parent = department; };
    subcategory = { id = field { ... }; parent = category; };
    item = { id = identifier { ... }; parent = subcategory; };
  };
  # Results in: DIV.DEPT.CAT.SUBCAT.ITEM
}
```

## Questions for Validation

1. **Can this express standard Johnny Decimal?** ✓
2. **Can this handle different bases?** ✓
3. **Can this handle mixed radix?** ✓
4. **Can this handle variable width?** ✓
5. **Can this handle arbitrary depth?** ✓
6. **Can this handle custom alphabets?** ✓
7. **Is it intuitive for simple cases?** ✓
8. **Is it powerful for complex cases?** ✓
9. **Can it self-validate?** ✓
10. **Can it generate documentation?** ✓

## Next Steps

1. Implement core type system in Nix
2. Create builder functions for common patterns
3. Add validation at each composition level
4. Generate parsers from configuration
5. Generate documentation from configuration
