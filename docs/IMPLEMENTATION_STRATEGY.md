# Implementation Strategy: From Current to Ultimate Flexibility

## Current State Analysis

### What We Have Now (v0.1)

```nix
# name-number-hierarchy-signifiers.nix
{
  areaRangeEncapsulator = {open = "{"; close = "}";};
  categoryNumEncapsulator = {open = "("; close = ")";};
  idNumEncapsulator = {open = "["; close = "]";};
  numeralNameSeparator = " ";
  areaCategorySeparator = "__";
  categoryItemSeparator = "__";
}
```

**Capabilities**:
- ✓ Configurable syntax (encapsulators, separators)
- ✓ Fixed structure (area/category/item)
- ✓ Base 10 only
- ✓ 2 digits per field
- ✓ Area span of 10

**Limitations**:
- ✗ Cannot change number of octets
- ✗ Cannot change base system
- ✗ Cannot change field widths
- ✗ Cannot change area span
- ✗ Hardcoded validation logic

---

## Evolution Path

### Phase 1: Add Base Configuration (v0.2)

**Goal**: Separate structure from syntax

```nix
{
  # Structure definition
  structure = {
    octets = 2;
    base = 10;
    digits_per_octet = 2;
    area_span = 10;
  };

  # Syntax definition (existing)
  syntax = {
    # ... existing syntax config
  };
}
```

**Implementation**:
1. Add `structure` section to config file
2. Generate parsers from structure config
3. Keep existing syntax config
4. Maintain backward compatibility

**New Capabilities**:
- ✓ Configurable area span (5, 10, 15, 20, etc.)
- ✓ Configurable digit count (1, 2, 3, etc.)
- ✓ Different bases (2, 8, 10, 16)

---

### Phase 2: Add Field Types (v0.3)

**Goal**: Support mixed configurations

```nix
{
  # Define individual fields
  fields = {
    category = {
      base = 10;
      width = 2;
      role = "category";
    };
    item = {
      base = 10;
      width = 2;
      role = "item";
    };
  };

  # How fields compose
  identifier = {
    octets = ["category" "item"];
    separator = ".";
  };

  # How ranges derive
  area = {
    from = "category";
    span = 10;
  };
}
```

**Implementation**:
1. Define field type in Nix
2. Create field builder functions
3. Generate parser from field definitions
4. Support mixed radix

**New Capabilities**:
- ✓ Different bases per field
- ✓ Different widths per field
- ✓ Custom field roles

---

### Phase 3: Add Number System Types (v0.4)

**Goal**: Support custom alphabets

```nix
{
  # Define number systems
  number_systems = {
    decimal = {
      radix = 10;
      alphabet = "0123456789";
    };
    hex = {
      radix = 16;
      alphabet = "0123456789ABCDEF";
    };
    alpha = {
      radix = 26;
      alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      case_sensitive = false;
    };
  };

  # Use in fields
  fields = {
    department = {
      system = number_systems.alpha;
      width = 2;
    };
    project = {
      system = number_systems.decimal;
      width = 3;
    };
  };
}
```

**Implementation**:
1. Define NumberSystem type
2. Add alphabet validation
3. Generate converters (string ↔ value)
4. Update parsers to use alphabets

**New Capabilities**:
- ✓ Alphabetic fields (AA, AB, AC, ...)
- ✓ Hexadecimal fields (00-FF)
- ✓ Custom alphabets (DNA: ACGT)

---

### Phase 4: Add Hierarchy Configuration (v0.5)

**Goal**: Support arbitrary hierarchy depth

```nix
{
  # Define hierarchy levels
  hierarchy = {
    levels = {
      division = {
        identifier = ranges.division;
        name = "Division";
        contains = "department";
      };
      department = {
        identifier = fields.department;
        name = "Department";
        contains = "category";
        parent = "division";
      };
      category = {
        identifier = fields.category;
        name = "Category";
        contains = "item";
        parent = "department";
      };
      item = {
        identifier = identifiers.item_id;
        name = "Item";
        parent = "category";
      };
    };

    root = "division";
  };
}
```

**Implementation**:
1. Define Level type
2. Create hierarchy builder
3. Validate tree structure
4. Generate paths from tree

**New Capabilities**:
- ✓ 4+ level hierarchies
- ✓ Custom level names
- ✓ Flexible containment

---

### Phase 5: Add Constraint System (v0.6)

**Goal**: Declarative validation

```nix
{
  constraints = {
    # Type-based constraints
    type_checks = {
      category_is_number = {
        field = "category";
        type = "integer";
        range = [0, 99];
      };
    };

    # Relationship constraints
    relationships = {
      category_in_area = {
        rule = "category must be within area range";
        check = ''
          let
            cat = fields.category.value;
            area = ranges.area;
          in area.contains cat
        '';
      };
    };

    # Uniqueness constraints
    uniqueness = {
      no_duplicate_ids = {
        scope = "global";
        field = "item.id";
      };
    };

    # Custom constraints
    custom = {
      valid_department = {
        field = "department";
        validator = fields.department.value `elem` ["ENG", "DES", "OPS"];
      };
    };
  };
}
```

**Implementation**:
1. Define Constraint type
2. Create constraint evaluators
3. Collect constraints from config
4. Run in validation pipeline

**New Capabilities**:
- ✓ Declarative validation
- ✓ Custom business rules
- ✓ Clear error messages

---

### Phase 6: Add Template System (v0.7)

**Goal**: Flexible representation

```nix
{
  templates = {
    # Level templates
    area = {
      short = "{id}";
      normal = "[{id} {name}]";
      long = "[{id} - {name}] ({count} categories)";
    };

    category = {
      short = "{id}";
      normal = "({id} {name})";
    };

    item = {
      short = "{id}";
      normal = "<{id} {name}>";
      with_metadata = "<{id} {name}> @{module.path}";
    };

    # Path templates
    filesystem = "{area.name}/{category.id} {category.name}/{item.id} {item.name}";
    url = "{area.id}/{category.id}/{item.id}";
    filename = "[{item.id}]{area}__{category}__{item}.nix";

    # Index templates
    tree = ''
      {area.normal}
        {for category in area.categories}
          {category.normal}
            {for item in category.items}
              {item.normal}
            {endfor}
        {endfor}
    '';
  };
}
```

**Implementation**:
1. Define Template type
2. Create template parser
3. Add variable substitution
4. Support conditionals/loops

**New Capabilities**:
- ✓ Multiple representations
- ✓ Context-dependent display
- ✓ Custom formatting

---

## Concrete Usage Examples

### Example 1: Classic Johnny Decimal

```nix
johnny-declarative-decimal = {
  # Use quick config for simplicity
  quick = {
    levels = 3;          # Area, Category, Item
    base = 10;           # Decimal
    digits = 2;          # 00-99
    area_span = 10;      # Each area = 10 categories
  };

  # Or be explicit
  advanced = {
    fields = {
      category = { base = 10; width = 2; };
      item = { base = 10; width = 2; };
    };
    identifier = ["category" "item"];
    separator = ".";
    area = { from = "category"; span = 10; };
  };
}
```

### Example 2: Hexadecimal Programmer System

```nix
johnny-declarative-decimal = {
  number_systems = {
    hex = { radix = 16; alphabet = "0123456789ABCDEF"; };
  };

  fields = {
    module = { system = hex; width = 2; };  # 00-FF (256 modules)
    function = { system = hex; width = 2; };  # 00-FF (256 functions)
  };

  identifier = {
    octets = ["module" "function"];
    separator = ":";  # Like "3A:F2"
  };

  area = {
    from = "module";
    span = 16;  # 0x00-0x0F, 0x10-0x1F, etc.
  };

  syntax = {
    area = "[{id}] {name}";  # [00-0F] Core
    category = "({id}) {name}";  # (0A) Utils
    item = "<{id}> {name}";  # <0A:3F> Hash Function
  };
}
```

### Example 3: Departmental Project System

```nix
johnny-declarative-decimal = {
  number_systems = {
    alpha = { radix = 26; alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; };
    decimal = { radix = 10; };
  };

  fields = {
    department = {
      system = alpha;
      width = 3;  # ENG, DES, OPS, etc.
    };
    year = {
      system = decimal;
      width = 2;  # 24, 25, etc.
    };
    project = {
      system = decimal;
      width = 3;  # 001-999
    };
  };

  identifier = {
    octets = ["department" "year" "project"];
    separator = "-";  # ENG-24-001
  };

  hierarchy = {
    department = {
      id = fields.department;
      name = "Department";
    };
    fiscal_year = {
      id = fields.year;
      name = "Fiscal Year";
      parent = "department";
    };
    project = {
      id = identifier;
      name = "Project";
      parent = "fiscal_year";
    };
  };

  constraints = {
    valid_department = {
      field = "department";
      values = ["ENG" "DES" "OPS" "SAL" "MKT"];
    };
    current_year = {
      field = "year";
      range = [24, 30];  # Only 2024-2030
    };
  };
}
```

### Example 4: Deep Hierarchy (5 Levels)

```nix
johnny-declarative-decimal = {
  fields = {
    division = { base = 10; width = 1; };      # 0-9
    department = { base = 10; width = 1; };    # 0-9
    category = { base = 10; width = 2; };      # 00-99
    subcategory = { base = 10; width = 2; };   # 00-99
    item = { base = 10; width = 3; };          # 000-999
  };

  identifier = {
    octets = ["division" "department" "category" "subcategory" "item"];
    separator = ".";  # Like: 3.2.15.07.042
  };

  hierarchy = {
    levels = {
      division = {
        id = fields.division;
        contains = "department";
      };
      department = {
        id = fields.department;
        parent = "division";
        contains = "category";
      };
      category = {
        id = fields.category;
        parent = "department";
        contains = "subcategory";
      };
      subcategory = {
        id = fields.subcategory;
        parent = "category";
        contains = "item";
      };
      item = {
        id = identifier;
        parent = "subcategory";
      };
    };
  };
}
```

---

## Migration Strategy

### Backward Compatibility

```nix
{
  # Old format still works
  legacy = import ./name-number-hierarchy-signifiers.nix;

  # Automatically upgraded to new format
  upgraded = {
    fields = {
      category = { base = 10; width = 2; };
      item = { base = 10; width = 2; };
    };
    syntax = legacy;  # Use legacy syntax
  };
}
```

### Gradual Adoption

1. **Phase 1**: Keep existing config, add structure options
2. **Phase 2**: Migrate to field-based config
3. **Phase 3**: Add custom number systems
4. **Phase 4**: Define custom hierarchies
5. **Phase 5**: Add constraints
6. **Phase 6**: Customize templates

Users can stop at any phase that meets their needs.

---

## Technical Architecture

### Core Types (Nix)

```nix
{
  # Primitive types
  NumberSystem = {
    radix: Int;
    alphabet: String;
    ?case_sensitive: Bool;
  };

  Field = {
    system: NumberSystem;
    width: Int | {min: Int, max: Int};
    ?padding: "zeros" | "spaces" | "none";
    ?constraints: [Constraint];
  };

  Identifier = {
    octets: [Field];
    separator: String;
    ?format: Template;
  };

  Range = {
    from: Field;
    span: Int;
    ?format: Template;
  };

  Level = {
    id: Field | Identifier | Range;
    name: String;
    ?parent: String;
    ?contains: String;
    ?constraints: [Constraint];
  };

  # Composite types
  Hierarchy = {
    levels: {String: Level};
    root: String;
  };

  Syntax = {
    encapsulators: {String: {open: String, close: String}};
    separators: {String: String};
    templates: {String: Template};
  };

  Constraint = {
    name: String;
    rule: String;
    check: Expr;
    ?message: String;
  };

  # Configuration
  Config = {
    ?number_systems: {String: NumberSystem};
    ?fields: {String: Field};
    ?identifiers: {String: Identifier};
    ?ranges: {String: Range};
    hierarchy: Hierarchy;
    syntax: Syntax;
    ?constraints: [Constraint];
  };
}
```

### Generated Artifacts

From config, we generate:

1. **Parser**: Regex patterns from fields
2. **Validator**: Checks from constraints
3. **Formatter**: Display from templates
4. **Documentation**: Descriptions from structure
5. **Types**: TypeScript/Nix types from schema

---

## Implementation Priorities

### Must Have (MVP)
1. ✓ Field-based configuration
2. ✓ Custom number systems
3. ✓ Basic constraints (range, uniqueness)
4. ✓ Template syntax

### Should Have (v1.0)
5. Variable hierarchy depth
6. Advanced constraints
7. Multiple representations
8. Auto-generated docs

### Could Have (v2.0)
9. Variable width fields
10. Context-dependent parsing
11. Alternative formats
12. Visual editor

### Won't Have (For Now)
13. Full grammar-based parsing
14. Runtime reconfiguration
15. Graphical DSL
16. AI-suggested structures

---

## Success Metrics

1. **Expressiveness**: Can represent all common systems?
2. **Simplicity**: Is quick config truly quick?
3. **Power**: Can advanced users do advanced things?
4. **Safety**: Does validation catch errors?
5. **Performance**: Fast enough for large hierarchies?
6. **Documentation**: Self-documenting?

---

## Next Steps

1. Implement Phase 1 (base configuration)
2. Test with current modules
3. Implement Phase 2 (field types)
4. Migrate existing config to new format
5. Implement Phase 3 (number systems)
6. Create example configurations
7. Generate documentation
8. Gather feedback
9. Iterate
