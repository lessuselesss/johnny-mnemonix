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
#   mkJohnnyDecimal = {levels, base, digits, separators, constraints} -> System
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

{
  lib,
  primitives,
  composition,
}: let
  ns = primitives.numberSystems;
  fields = primitives.fields;
  constraints = primitives.constraints;
in {
  # Create a Johnny Decimal system
  #
  # Parameters:
  #   - levels: Number of hierarchy levels (2 for XX.YY, 3 for XX.YY.ZZ)
  #     Default: 2 (classic category.item)
  #   - base: Number base (10 for decimal, 16 for hex, etc.)
  #     Default: 10 (decimal)
  #   - digits: Digits per field
  #     Default: 2 (two-digit fields)
  #   - separators: List of separators between levels
  #     Default: ["."] (dot separator)
  #   - constraints: Attrset of constraints per level
  #     Default: {} (no additional constraints beyond field width)
  #
  # Returns: System with parse, format, validate, identifiers
  mkJohnnyDecimal = {
    levels ? 2,
    base ? 10,
    digits ? 2,
    separators ? ["."],
    constraints ? {},
  }: let
    # Create number system for the specified base
    numberSystem =
      if base == 10
      then ns.decimal
      else if base == 16
      then ns.hex
      else if base == 2
      then ns.binary
      else
        throw "Unsupported base: ${toString base}. Use 2, 10, or 16.";

    # Create a field for this JD system
    mkField = fields.mk {
      system = numberSystem;
      width = digits;
      padding = "zeros";
    };

    # Level names based on number of levels
    levelNames =
      if levels == 2
      then ["category" "item"]
      else if levels == 3
      then ["area" "category" "item"]
      else throw "Unsupported levels: ${toString levels}. Use 2 or 3.";

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

      # Parse each part using the field
      parseValues = builtins.map (fields.parse mkField) parts;

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

      # Format each value
      formatted = builtins.map (fields.format mkField) values;

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

      # Check constraints if any defined
      checkConstraints =
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
          builtins.all (r: r == true) results
        else true;
    in
      parseSuccess && checkConstraints;

    # Create identifier definitions for each level
    # This exposes the underlying composition layer
    identifierDefs = lib.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = mkField;
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

