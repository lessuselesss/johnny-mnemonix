# Primitives: Numeral-Name Patterns
#
# Layer 1: Core primitives for formatting identifiers with numbers and names.
#
# Provides composable primitives for creating any numeral-name convention:
# - Separators (space, dash, underscore, none)
# - Ordering (numeral-first, name-first)
# - Case transformations (kebab, snake, camel, pascal)
# - Composite patterns (mix multiple conventions)

{lib}: let
  # ===== Core Pattern Components =====

  # Separator types
  separators = {
    space = " ";
    dash = "-";
    underscore = "_";
    dot = ".";
    colon = ":";
    slash = "/";
    none = "";
  };

  # Case transformation functions
  casing = {
    # kebab-case: lowercase with dashes
    kebab = name: lib.toLower (lib.replaceStrings [" " "_"] ["-" "-"] name);

    # snake_case: lowercase with underscores
    snake = name: lib.toLower (lib.replaceStrings [" " "-"] ["_" "_"] name);

    # camelCase: first word lowercase, rest capitalized
    camel = name: let
      words = lib.splitString " " name;
      firstWord = lib.toLower (builtins.elemAt words 0);
      restWords = map (w: lib.toUpper (builtins.substring 0 1 w) + lib.toLower (builtins.substring 1 (builtins.stringLength w) w)) (lib.drop 1 words);
    in firstWord + lib.concatStrings restWords;

    # PascalCase: all words capitalized
    pascal = name: let
      words = lib.splitString " " name;
      capitalizedWords = map (w: lib.toUpper (builtins.substring 0 1 w) + lib.toLower (builtins.substring 1 (builtins.stringLength w) w)) words;
    in lib.concatStrings capitalizedWords;

    # SCREAMING_SNAKE_CASE: uppercase with underscores
    screamingSnake = name: lib.toUpper (lib.replaceStrings [" " "-"] ["_" "_"] name);

    # lowercase: just lowercase, preserve separators
    lower = name: lib.toLower name;

    # UPPERCASE: just uppercase, preserve separators
    upper = name: lib.toUpper name;

    # identity: no transformation
    identity = name: name;
  };

  # Ordering strategies
  ordering = {
    # numeral-first: "10 Projects" or "10-projects"
    numeralFirst = {numeral, name, separator}: "${numeral}${separator}${name}";

    # name-first: "Projects 10" or "projects-10"
    nameFirst = {numeral, name, separator}: "${name}${separator}${numeral}";

    # numeral-only: just the numeral
    numeralOnly = {numeral, ...}: numeral;

    # name-only: just the name
    nameOnly = {name, ...}: name;
  };

  # ===== Pattern Constructors =====

  # Make a basic pattern
  mkPattern = {
    separator ? separators.space,
    order ? ordering.numeralFirst,
    nameCase ? casing.identity,
  }: {
    inherit separator order nameCase;

    # Format a numeral-name pair using this pattern
    format = {numeral, name}:
      order {
        inherit numeral;
        name = nameCase name;
        inherit separator;
      };

    # Parse a formatted string back to components (best effort)
    parse = str: let
      parts = lib.splitString separator str;
      hasNumeral = lib.any (p: builtins.match "[0-9]+" p != null) parts;
    in
      if !hasNumeral
      then null
      else if order == ordering.numeralFirst
      then {
        numeral = builtins.elemAt parts 0;
        name = lib.concatStringsSep separator (lib.drop 1 parts);
      }
      else {
        numeral = builtins.elemAt parts (builtins.length parts - 1);
        name = lib.concatStringsSep separator (lib.take (builtins.length parts - 1) parts);
      };
  };

  # ===== Pre-built Common Patterns =====

  patterns = {
    # Standard: "10 Projects" (space-separated, natural)
    standard = mkPattern {
      separator = separators.space;
      order = ordering.numeralFirst;
      nameCase = casing.identity;
    };

    # Kebab: "10-projects" (dash-separated, lowercase)
    kebab = mkPattern {
      separator = separators.dash;
      order = ordering.numeralFirst;
      nameCase = casing.kebab;
    };

    # Snake: "10_projects" (underscore-separated, lowercase)
    snake = mkPattern {
      separator = separators.underscore;
      order = ordering.numeralFirst;
      nameCase = casing.snake;
    };

    # Dotted: "10.projects" (dot-separated, lowercase)
    dotted = mkPattern {
      separator = separators.dot;
      order = ordering.numeralFirst;
      nameCase = casing.lower;
    };

    # Camel: "10Projects" (no separator, camelCase - but first is number)
    # Note: This is a bit unusual since numbers can't start an identifier in most languages
    camelNumFirst = mkPattern {
      separator = separators.none;
      order = ordering.numeralFirst;
      nameCase = casing.pascal; # Use Pascal since number comes first
    };

    # Pascal with prefix: "Project10" (name-first, PascalCase)
    pascalNameFirst = mkPattern {
      separator = separators.none;
      order = ordering.nameFirst;
      nameCase = casing.pascal;
    };

    # Screaming: "10_PROJECTS" (underscore, uppercase)
    screaming = mkPattern {
      separator = separators.underscore;
      order = ordering.numeralFirst;
      nameCase = casing.screamingSnake;
    };

    # Compact: "10projects" (no separator, lowercase)
    compact = mkPattern {
      separator = separators.none;
      order = ordering.numeralFirst;
      nameCase = casing.lower;
    };

    # Reverse: "Projects 10" (name-first, natural)
    reverse = mkPattern {
      separator = separators.space;
      order = ordering.nameFirst;
      nameCase = casing.identity;
    };
  };

  # ===== Advanced Pattern Combinators =====

  # Create a context-aware pattern (different patterns for different levels)
  mkContextualPattern = {
    areaPattern ? patterns.standard,
    categoryPattern ? patterns.standard,
    itemPattern ? patterns.standard,
  }: {
    formatArea = areaPattern.format;
    formatCategory = categoryPattern.format;
    formatItem = itemPattern.format;

    parseArea = areaPattern.parse;
    parseCategory = categoryPattern.parse;
    parseItem = itemPattern.parse;
  };

  # Create a pattern with custom transformation
  mkCustomPattern = {
    separator ? separators.space,
    order ? ordering.numeralFirst,
    transform ? (x: x), # Custom transformation function
  }:
    mkPattern {
      inherit separator order;
      nameCase = transform;
    };

  # Compose multiple patterns (try each in order)
  composePatterns = patternList: {
    format = args: (builtins.elemAt patternList 0).format args;

    parse = str: let
      tryParse = pattern:
        let result = pattern.parse str;
        in if result != null then result else null;

      results = map tryParse patternList;
      validResults = builtins.filter (r: r != null) results;
    in
      if builtins.length validResults > 0
      then builtins.elemAt validResults 0
      else null;
  };

in {
  # Export primitives
  inherit separators casing ordering;

  # Export constructors
  inherit mkPattern mkContextualPattern mkCustomPattern composePatterns;

  # Export pre-built patterns
  inherit patterns;

  # ===== Convenience Functions =====

  # Quick format with a named pattern
  format = patternName: args:
    if patterns ? ${patternName}
    then patterns.${patternName}.format args
    else throw "Unknown pattern: ${patternName}";

  # Quick parse with a named pattern
  parse = patternName: str:
    if patterns ? ${patternName}
    then patterns.${patternName}.parse str
    else throw "Unknown pattern: ${patternName}";

  # Validate that a string matches a pattern
  validate = pattern: str:
    pattern.parse str != null;

  # Transform from one pattern to another
  transform = {from, to, str}:
    let parsed = from.parse str;
    in if parsed != null then to.format parsed else null;
}
