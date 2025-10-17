# Composition: Identifiers
# Combines multiple fields into multi-part identifiers with separators
#
# COMPOSITION LAYER: This component builds on the primitives layer,
# combining multiple field definitions into structured identifiers.
#
# Identifiers are composed of multiple fields joined by a separator:
# - Johnny Decimal: "10.01" (category.item)
# - Semantic Version: "1.20.300" (major.minor.patch)
# - Date: "2024-01-15" (year-month-day)
#
# API:
#   mk = {fields, separator} -> Identifier
#   parse = Identifier -> String -> [Int] | Null
#   format = Identifier -> [Int] -> String | Null
#   validate = Identifier -> [Int] -> Bool
#
# Examples:
#   # Johnny Decimal identifier
#   jd = identifiers.mk {
#     fields = [
#       (fields.mk {system = ns.decimal; width = 2; padding = "zeros";})
#       (fields.mk {system = ns.decimal; width = 2; padding = "zeros";})
#     ];
#     separator = ".";
#   };
#   identifiers.format jd [10 1]  => "10.01"
#   identifiers.parse jd "10.01"  => [10 1]

{
  lib,
  primitives,
}: let
  fields = primitives.fields;
in {
  # Create a multi-field identifier definition
  #
  # Combines multiple field specifications with a separator to create
  # a structured identifier format. Each field can have different constraints
  # (width, padding, number system).
  #
  # Parameters:
  #   - fields: List of Field objects (from primitives.fields.mk)
  #   - separator: String to join fields (e.g., ".", "-", ":")
  #
  # Returns: Identifier object that can be used with parse/format/validate
  #
  # Example:
  #   mk {
  #     fields = [field1 field2 field3];
  #     separator = ".";
  #   }
  mk = {
    fields,
    separator,
  }: {
    inherit fields separator;
  };

  # Parse a string into component values
  #
  # Splits the string on separators and parses each part using its
  # corresponding field definition. This is the inverse of format.
  #
  # Algorithm:
  #   1. Split string on separator
  #   2. Validate we have correct number of parts
  #   3. Parse each part using fields.parse with corresponding field
  #   4. Return list of integers, or null if any part fails
  #
  # Returns: List of integers [val1, val2, ...], or null if:
  #   - Wrong number of parts after splitting
  #   - Any part fails field parsing (invalid chars, wrong width, etc.)
  #
  # Example:
  #   parse jdIdentifier "10.01"  => [10 1]
  #   parse jdIdentifier "10-01"  => null (wrong separator)
  #   parse jdIdentifier "10.1"   => null (second part wrong width)
  parse = identifier: str: let
    fieldsSpec = identifier.fields;
    separator = identifier.separator;

    # Split string on separator
    parts = lib.splitString separator str;

    # Check if we have the right number of parts
    numParts = builtins.length parts;
    numFields = builtins.length fieldsSpec;
    correctCount = numParts == numFields;

    # Parse each part using corresponding field
    parsePart = idx: let
      part = builtins.elemAt parts idx;
      field = builtins.elemAt fieldsSpec idx;
    in
      fields.parse field part;

    # Parse all parts
    parsed =
      if correctCount
      then lib.genList parsePart numFields
      else [];

    # Check if any parsing failed (returned null)
    hasNull = builtins.any (p: p == null) parsed;
  in
    if !correctCount || hasNull
    then null
    else parsed;

  # Format component values into a string
  #
  # Formats each integer value using its corresponding field definition,
  # then joins all parts with the separator. This is the inverse of parse.
  #
  # Algorithm:
  #   1. Validate we have correct number of values
  #   2. Format each value using fields.format with corresponding field
  #   3. Join formatted parts with separator
  #   4. Return string, or null if any part fails
  #
  # Returns: Formatted string (e.g., "10.01"), or null if:
  #   - Wrong number of values
  #   - Any value fails field formatting (out of range, negative, etc.)
  #
  # Example:
  #   format jdIdentifier [10 1]    => "10.01"
  #   format jdIdentifier [10 100]  => null (100 doesn't fit in 2 digits)
  #   format jdIdentifier [10]      => null (missing second value)
  format = identifier: values: let
    fieldsSpec = identifier.fields;
    separator = identifier.separator;

    # Check if we have the right number of values
    numValues = builtins.length values;
    numFields = builtins.length fieldsSpec;
    correctCount = numValues == numFields;

    # Format each value using corresponding field
    formatValue = idx: let
      value = builtins.elemAt values idx;
      field = builtins.elemAt fieldsSpec idx;
    in
      fields.format field value;

    # Format all values
    formatted =
      if correctCount
      then lib.genList formatValue numFields
      else [];

    # Check if any formatting failed (returned null)
    hasNull = builtins.any (f: f == null) formatted;
  in
    if !correctCount || hasNull
    then null
    else builtins.concatStringsSep separator formatted;

  # Validate that component values satisfy all field constraints
  #
  # Checks each value against its corresponding field's constraints
  # without actually formatting. Faster than trying format and checking
  # for null when you only need validation.
  #
  # Algorithm:
  #   1. Validate we have correct number of values
  #   2. Validate each value using fields.validate with corresponding field
  #   3. Return true only if all validations pass
  #
  # Returns: true if all values satisfy their field constraints, false otherwise
  #
  # Example:
  #   validate jdIdentifier [10 1]    => true
  #   validate jdIdentifier [10 100]  => false (100 out of range)
  #   validate jdIdentifier [10]      => false (wrong count)
  validate = identifier: values: let
    fieldsSpec = identifier.fields;

    # Check if we have the right number of values
    numValues = builtins.length values;
    numFields = builtins.length fieldsSpec;
    correctCount = numValues == numFields;

    # Validate each value using corresponding field
    validateValue = idx: let
      value = builtins.elemAt values idx;
      field = builtins.elemAt fieldsSpec idx;
    in
      fields.validate field value;

    # Validate all values
    validations =
      if correctCount
      then lib.genList validateValue numFields
      else [false];

    # Check if all validations passed
    allValid = builtins.all (v: v == true) validations;
  in
    correctCount && allValid;
}
