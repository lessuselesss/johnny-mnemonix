# Numeral-Name Patterns - Demonstration

This document demonstrates practical usage of the numeral-name pattern system.

## Quick Start

```nix
{ lib }:
let
  patterns = lib.primitives.numeralNamePatterns;
in {
  # Simple formatting with pre-built patterns
  examples = {
    standard = patterns.format "standard" { numeral = "10"; name = "Projects"; };
    # => "10 Projects"

    kebab = patterns.format "kebab" { numeral = "10"; name = "Web Projects"; };
    # => "10-web-projects"

    snake = patterns.format "snake" { numeral = "10"; name = "Web Projects"; };
    # => "10_web_projects"

    screaming = patterns.format "screaming" { numeral = "10"; name = "max retries"; };
    # => "10_MAX_RETRIES"
  };
}
```

## Use Case 1: Directory Names

Create consistent directory naming across different operating systems:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;

  # Choose pattern based on OS
  dirPattern = if pkgs.stdenv.isDarwin
    then patterns.patterns.standard    # "10 Projects" (macOS friendly)
    else patterns.patterns.kebab;      # "10-projects" (Linux friendly)
in {
  projectDirs = map (p: dirPattern.format p) [
    { numeral = "10"; name = "Code Projects"; }
    { numeral = "20"; name = "Design Work"; }
    { numeral = "30"; name = "Documentation"; }
  ];
  # macOS: ["10 Projects", "20 Design Work", "30 Documentation"]
  # Linux: ["10-code-projects", "20-design-work", "30-documentation"]
}
```

## Use Case 2: Variable Naming

Generate consistent variable names for code:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;
in {
  constants = patterns.patterns.screaming.format {
    numeral = "10";
    name = "max retries";
  };
  # => "10_MAX_RETRIES"

  classNames = patterns.patterns.pascalNameFirst.format {
    numeral = "10";
    name = "http client";
  };
  # => "HttpClient10"

  functionNames = patterns.mkPattern {
    separator = "_";
    order = patterns.ordering.nameFirst;
    nameCase = patterns.casing.snake;
  } |> (p: p.format {
    numeral = "10";
    name = "process request";
  });
  # => "process_request_10"
}
```

## Use Case 3: Johnny Decimal IDs

Format complete Johnny Decimal identifiers with custom separators:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;

  # Custom JD pattern: "10.01.web-app"
  jdPattern = patterns.mkPattern {
    separator = ".";
    order = patterns.ordering.numeralFirst;
    nameCase = patterns.casing.kebab;
  };
in {
  jdIds = [
    (jdPattern.format { numeral = "10.01"; name = "Web App"; })
    (jdPattern.format { numeral = "10.02"; name = "CLI Tool"; })
    (jdPattern.format { numeral = "20.01"; name = "User Guide"; })
  ];
  # => ["10.01.web-app", "10.02.cli-tool", "20.01.user-guide"]
}
```

## Use Case 4: Contextual Patterns (Per-Level)

Use different patterns for different hierarchy levels:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;

  ctx = patterns.mkContextualPattern {
    areaPattern = patterns.patterns.standard;    # "10-19 Projects"
    categoryPattern = patterns.patterns.kebab;   # "10-code"
    itemPattern = patterns.patterns.snake;       # "01_web_app"
  };
in {
  workspace = {
    area = ctx.formatArea {
      numeral = "10-19";
      name = "Projects";
    };
    # => "10-19 Projects"

    category = ctx.formatCategory {
      numeral = "10";
      name = "Code Projects";
    };
    # => "10-code-projects"

    item = ctx.formatItem {
      numeral = "01";
      name = "Web App";
    };
    # => "01_web_app"
  };
}
```

## Use Case 5: Parsing and Transformation

Convert between different naming conventions:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;
in {
  # Parse a standard name
  parsed = patterns.patterns.standard.parse "10 Projects";
  # => { numeral = "10"; name = "Projects"; }

  # Transform from one pattern to another
  kebabized = patterns.transform {
    from = patterns.patterns.standard;
    to = patterns.patterns.kebab;
    str = "10 Web Projects";
  };
  # => "10-web-projects"

  # Validate format
  isValid = patterns.validate patterns.patterns.kebab "10-projects";
  # => true

  isInvalid = patterns.validate patterns.patterns.kebab "NoNumber";
  # => false
}
```

## Use Case 6: Custom Transformation

Create patterns with custom name transformations:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;

  # Custom: add "jd_" prefix
  prefixedPattern = patterns.mkCustomPattern {
    separator = "_";
    transform = name: "jd_" + (patterns.casing.lower name);
  };
in {
  prefixed = prefixedPattern.format {
    numeral = "10";
    name = "Projects";
  };
  # => "10_jd_projects"
}
```

## Use Case 7: Pattern Composition (Fallback)

Try multiple patterns when parsing:

```nix
let
  patterns = lib.primitives.numeralNamePatterns;

  # Accept multiple formats
  flexibleParser = patterns.composePatterns [
    patterns.patterns.kebab
    patterns.patterns.snake
    patterns.patterns.standard
  ];
in {
  # Will match whichever pattern fits
  result1 = flexibleParser.parse "10-projects";    # => { numeral = "10"; name = "projects"; }
  result2 = flexibleParser.parse "10_projects";    # => { numeral = "10"; name = "projects"; }
  result3 = flexibleParser.parse "10 Projects";    # => { numeral = "10"; name = "Projects"; }
}
```

## Use Case 8: Real-World NixOS Configuration

Organize NixOS modules with consistent naming:

```nix
{ lib, pkgs, ... }:
let
  patterns = lib.primitives.numeralNamePatterns;

  # Module naming convention
  modulePattern = patterns.patterns.kebab;

  # Generate module paths
  mkModulePath = { numeral, name }:
    ./modules + "/${modulePattern.format { inherit numeral name; }}.nix";
in {
  imports = [
    (mkModulePath { numeral = "10"; name = "networking"; })
    (mkModulePath { numeral = "20"; name = "graphics"; })
    (mkModulePath { numeral = "30"; name = "development"; })
  ];
  # => [ ./modules/10-networking.nix
  #      ./modules/20-graphics.nix
  #      ./modules/30-development.nix ]
}
```

## API Summary

### Pre-built Patterns

- `standard`: "10 Projects" (space-separated, natural)
- `kebab`: "10-web-projects" (dash-separated, lowercase)
- `snake`: "10_web_projects" (underscore-separated, lowercase)
- `dotted`: "10.web-projects" (dot-separated, lowercase)
- `camelNumFirst`: "10WebProjects" (no separator, PascalCase)
- `pascalNameFirst`: "WebProjects10" (name-first, PascalCase)
- `screaming`: "10_WEB_PROJECTS" (underscore, uppercase)
- `compact`: "10projects" (no separator, lowercase)
- `reverse`: "Projects 10" (name-first, natural)

### Core Functions

- `format patternName { numeral, name }`: Format with named pattern
- `parse patternName str`: Parse with named pattern
- `validate pattern str`: Check if string matches pattern
- `transform { from, to, str }`: Convert between patterns

### Constructors

- `mkPattern { separator, order, nameCase }`: Create custom pattern
- `mkCustomPattern { separator, transform }`: Create with custom transform
- `mkContextualPattern { areaPattern, categoryPattern, itemPattern }`: Per-level patterns
- `composePatterns [patterns]`: Try multiple patterns in order

### Building Blocks

- `separators.*`: 7 separator types
- `casing.*`: 8 case transformations
- `ordering.*`: 4 ordering strategies

### Pattern Methods

Each pattern object has:
- `.format { numeral, name }`: Format a numeral-name pair
- `.parse str`: Parse a formatted string (returns `{ numeral, name }` or `null`)

## Performance Notes

All operations are **O(1)** or **O(n)** where n is string length. No recursive evaluation, no expensive computations.

Safe to use with:
- Thousands of identifiers
- Build-time path generation
- Large attribute set mapping

## See Also

- **Tests**: `../../../tests/primitives/numeral-name-patterns.test.nix` - 31 comprehensive tests
- **Implementation**: `./numeral-name-patterns.nix` - Full source code
- **Primitives Export**: `../primitives.nix` - How to access from lib
