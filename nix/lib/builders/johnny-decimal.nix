# Builders: Johnny Decimal System Builder
# High-level constructor for creating complete Johnny Decimal systems
#
# BUILDERS LAYER: Combines primitives and composition into ready-to-use systems.
#
# This builder creates a complete Johnny Decimal identification system with
# sensible defaults while allowing full customization. It handles:
# - Classic 2-level JD (XX.YY for category.item)
# - Extended 3-level JD (XX.YY.ZZ for area.category.item)
# - Custom bases (decimal, hex, etc.)
# - Custom separators and digit widths
# - Validation and constraints
#
# API:
#   mkJohnnyDecimal = {levels, levelConfigs?, capacityFormula?, base, chars, separators, constraints} -> System
#
# Examples:
#   # Classic Johnny Decimal (XX.YY)
#   classic = mkJohnnyDecimal {};
#   classic.parse "10.05"  # => {category = 10; item = 5;}
#
#   # Hexadecimal JD
#   hex = mkJohnnyDecimal {base = 16;};
#   hex.parse "1A.3F"  # => {category = 26; item = 63;}
#
#   # 3-level extended
#   extended = mkJohnnyDecimal {levels = 3;};
#   extended.parse "10.05.02"  # => {area = 10; category = 5; item = 2;}
#
#   # Per-level configuration (mixed bases)
#   mixed = mkJohnnyDecimal {
#     levels = 3;
#     levelConfigs = [
#       {base = 10; chars = 2;}  # Decimal area
#       {base = 16; chars = 2;}  # Hex category
#       {base = 2; chars = 4;}   # Binary item
#     ];
#   };
#   mixed.parse "10.1A.1010"  # => {area = 10; category = 26; item = 10;}
#
#   # Capacity formula (n^n per level)
#   formula = mkJohnnyDecimal {
#     levels = 3;
#     base = 10;
#     capacityFormula = n: n * n;  # Level 1: 1, Level 2: 4, Level 3: 9
#   };
#   formula.format {area = 0; category = 3; item = 8;}  # => "0.3.8"
#
#   # With capacity constraints
#   constrained = mkJohnnyDecimal {
#     levels = 2;
#     levelConfigs = [
#       {base = 10; chars = 2; capacity = {min = 10; max = 19;};}  # Area 10-19 only
#       {base = 10; chars = 2; capacity = {min = 0; max = 99;};}   # Items 00-99
#     ];
#   };
#   constrained.validate "15.50"  # => true
#   constrained.validate "20.50"  # => false (category out of range)
{
  lib,
  primitives,
  composition,
}: let
  ns = primitives.numberSystems;
  inherit (primitives) fields;
in {
  # Create a Johnny Decimal system
  #
  # Parameters:
  #   - levels: Number of hierarchy levels (2 for XX.YY, 3 for XX.YY.ZZ)
  #     Default: 2 (classic category.item)
  #
  #   - levelConfigs: Per-level configuration (overrides base/chars if provided)
  #     Default: null (use base/chars instead)
  #     Format: [{ base = 10; chars = 2; capacity = {min = 0; max = 99}; } ...]
  #
  #   - capacityFormula: Function to calculate capacity per level (level -> capacity)
  #     Default: null (use levelConfigs or base/chars)
  #     Example: n: n * n  (level n has capacity n^n)
  #
  #   - base: Number base for all levels (used if levelConfigs is null)
  #     Default: 10 (decimal)
  #
  #   - chars: Characters per field for all levels (used if levelConfigs is null)
  #     Default: 2 (two-character fields)
  #
  #   - separators: List of separators between levels
  #     Default: ["."] (dot separator)
  #
  #   - constraints: Attrset of constraints per level
  #     Default: {} (no additional constraints beyond field width)
  #
  # Returns: System with parse, format, validate, identifiers
  mkJohnnyDecimal = {
    levels ? 2,
    levelConfigs ? null,
    capacityFormula ? null,
    base ? 10,
    chars ? 2,
    separators ? ["."],
    constraints ? {},
  }: let
    # Helper: Calculate minimum chars needed to represent 'capacity' values in 'base'
    # E.g., capacity 100 in base 10 needs 2 chars (00-99)
    #       capacity 256 in base 16 needs 2 chars (00-FF)
    calcCharsForCapacity = capacity: base:
      if capacity <= 0
      then 1
      else let
        # Calculate log_base(capacity) and ceil
        logCapacity =
          lib.fix (
            self: n: acc:
              if n < base
              then acc + 1
              else self (n / base) (acc + 1)
          )
          capacity
          0;
      in
        lib.max 1 logCapacity;

    # Helper: Convert capacityFormula to levelConfigs
    # Takes a formula (level -> capacity) and generates configs for each level
    formulaToConfigs = formula: levels: base:
      builtins.genList (i: let
        levelNum = i + 1; # Levels are 1-indexed
        capacity = formula levelNum;
        chars = calcCharsForCapacity capacity base;
      in {
        inherit base chars;
        capacity = {
          min = 0;
          max = capacity - 1;
        };
      })
      levels;

    # Determine final level configs (priority: levelConfigs > capacityFormula > legacy)
    finalLevelConfigs =
      if levelConfigs != null
      then levelConfigs
      else if capacityFormula != null
      then formulaToConfigs capacityFormula levels base
      else
        # Legacy mode: all levels same base/chars
        builtins.genList (_: {
          inherit base chars;
          capacity = null; # No capacity constraint in legacy mode
        })
        levels;

    # Create number system for a given base
    mkNumberSystem = base:
      if base == 10
      then ns.decimal
      else if base == 16
      then ns.hex
      else if base == 2
      then ns.binary
      else throw "Unsupported base: ${toString base}. Use 2, 10, or 16.";

    # Create fields for each level based on finalLevelConfigs
    levelFields = builtins.genList (i: let
      config = builtins.elemAt finalLevelConfigs i;
    in
      fields.mk {
        system = mkNumberSystem config.base;
        width = config.chars;
        padding = "zeros";
      })
    levels;

    # Level names based on number of levels
    levelNames =
      if levels == 2
      then ["category" "item"]
      else if levels == 3
      then ["area" "category" "item"]
      else if levels == 4
      then ["class" "area" "category" "item"]
      else if levels == 5
      then ["division" "class" "area" "category" "item"]
      else throw "Unsupported levels: ${toString levels}. Use 2-5.";

    # Parse a JD identifier string to components
    #
    # Parameters:
    #   - str: JD identifier string (e.g., "10.05" or "10.05.02")
    #
    # Returns: Attrset with named components, or null on failure
    #
    # Examples:
    #   parse "10.05"       # => {category = 10; item = 5;}
    #   parse "10.05.02"    # => {area = 10; category = 5; item = 2;}
    #   parse "invalid"     # => null
    parse = str: let
      # Split by separator
      sep = builtins.head separators;
      parts = lib.splitString sep str;

      # Parse each part using the corresponding level field
      parseValues =
        lib.imap0 (
          i: part:
            if i < levels
            then fields.parse (builtins.elemAt levelFields i) part
            else null
        )
        parts;

      # Check if all parts parsed successfully and count matches expected
      allValid = builtins.all (v: v != null) parseValues;
      correctCount = builtins.length parseValues == levels;
    in
      if allValid && correctCount
      then
        # Create attrset with level names as keys
        lib.listToAttrs (lib.imap0 (i: v: {
            name = builtins.elemAt levelNames i;
            value = v;
          })
          parseValues)
      else null;

    # Format components to JD identifier string
    #
    # Parameters:
    #   - components: Attrset with named components
    #
    # Returns: Formatted string, or null on failure
    #
    # Examples:
    #   format {category = 10; item = 5;}  # => "10.05"
    format = components: let
      # Extract values in order of level names
      values = builtins.map (name: components.${name} or null) levelNames;

      # Check all values present
      allPresent = builtins.all (v: v != null) values;

      # Format each value using the corresponding level field
      formatted =
        lib.imap0 (
          i: value:
            if value != null
            then fields.format (builtins.elemAt levelFields i) value
            else null
        )
        values;

      # Check all formatted successfully
      allFormatted = builtins.all (f: f != null) formatted;

      # Join with separator
      sep = builtins.head separators;
    in
      if allPresent && allFormatted
      then builtins.concatStringsSep sep formatted
      else null;

    # Validate a JD identifier string
    #
    # Parameters:
    #   - str: JD identifier string
    #
    # Returns: true if valid, false otherwise
    #
    # Examples:
    #   validate "10.05"     # => true
    #   validate "1.5"       # => false (missing padding)
    #   validate "invalid"   # => false
    validate = str: let
      # Try to parse
      parsed = parse str;

      # Check if parsing succeeded
      parseSuccess = parsed != null;

      # Check capacity constraints from level configs
      checkCapacityConstraints =
        if parseSuccess
        then let
          # Check each level's capacity constraint
          checkLevelCapacity = i: let
            name = builtins.elemAt levelNames i;
            value = parsed.${name};
            config = builtins.elemAt finalLevelConfigs i;
            capacity = config.capacity or null;
          in
            if capacity != null
            then value >= capacity.min && value <= capacity.max
            else true;

          results = builtins.genList checkLevelCapacity levels;
        in
          builtins.all (r: r) results
        else true;

      # Check user-provided constraints if any defined
      checkUserConstraints =
        if parseSuccess && constraints != {}
        then let
          # Check each level's constraints
          checkLevel = name: let
            value = parsed.${name};
            constraint = constraints.${name} or null;
          in
            if constraint != null
            then constraints.check (constraints.range constraint) value
            else true;

          results = builtins.map checkLevel levelNames;
        in
          builtins.all (r: r) results
        else true;
    in
      parseSuccess && checkCapacityConstraints && checkUserConstraints;

    # Create identifier definitions for each level
    # This exposes the underlying composition layer
    identifierDefs = lib.listToAttrs (
      lib.imap0 (i: name: {
        inherit name;
        value = builtins.elemAt levelFields i;
      })
      levelNames
    );
  in {
    # Core functions
    inherit parse format validate;

    # Identifier definitions (escape hatch to composition layer)
    identifiers = identifierDefs;

    # Escape hatches to lower layers
    # Allows advanced users to access primitives and composition directly
    # for custom extensions beyond what this builder provides
    inherit primitives composition;
  };
}
