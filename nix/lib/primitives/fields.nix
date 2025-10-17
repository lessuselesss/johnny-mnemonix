# Primitives: Fields
# Provides constrained number fields with width and padding
#
# Fields wrap number systems with additional constraints:
# - Fixed or variable width
# - Padding modes (none, zeros, spaces)
# - Automatic range derivation
#
# API:
#   mk = {system, width, padding} -> Field
#   parse = Field -> String -> Int | Null
#   format = Field -> Int -> String | Null
#   validate = Field -> Int -> Bool
#   range = Field -> {min, max}
#
# Examples:
#   # 2-digit decimal field with zero padding
#   field = fields.mk {system = ns.decimal; width = 2; padding = "zeros";};
#   fields.format field 7  => "07"
#   fields.parse field "42"  => 42
#   fields.range field  => {min = 0; max = 99;}

{
  lib,
  numberSystems,
}: let
  # Calculate maximum value for a field with given radix and width
  # Formula: radix^width - 1
  # Example: radix=10, width=2 => 10^2 - 1 = 99
  # Returns null for variable width (unbounded)
  maxValueForWidth = radix: width:
    if width == "variable"
    then null
    else let
      # Calculate power using tail recursion
      power = n: exp:
        if exp == 0
        then 1
        else n * (power n (exp - 1));
    in
      (power radix width) - 1;

  # Pad a string to the left with a character to reach target width
  # Example: padLeft "0" 3 "42" => "042"
  padLeft = char: width: str: let
    len = builtins.stringLength str;
    needed = width - len;
    padding =
      if needed <= 0
      then ""
      else lib.concatStrings (lib.replicate needed char);
  in
    padding + str;

  # Strip leading padding characters from a string
  # Preserves at least one character (for "000" -> "0")
  # Example: stripLeading "0" "007" => "7"
  stripLeading = char: str: let
    chars = lib.stringToCharacters str;
    stripped = lib.dropWhile (c: c == char) chars;
  in
    if stripped == []
    then char # If all stripped, keep one (e.g., "000" -> "0")
    else lib.concatStrings stripped;
in {
  # Create a constrained field
  # Parameters:
  #   - system: NumberSystem (from number-systems.nix)
  #   - width: Int or "variable" (fixed width or unbounded)
  #   - padding: "none" | "zeros" | "spaces"
  # Returns: Field object
  mk = {
    system,
    width,
    padding,
  }: {
    inherit system width padding;
  };

  # Parse a string to an integer using field constraints
  # Returns null if:
  #   - String length doesn't match width (for fixed width)
  #   - String contains invalid characters
  # Automatically strips leading padding before parsing
  parse = field: str: let
    system = field.system;
    width = field.width;
    padding = field.padding;

    # Check width constraint
    strLen = builtins.stringLength str;
    widthValid =
      if width == "variable"
      then true
      else strLen == width || (padding == "none" && strLen <= width);

    # Strip padding if needed
    stripped =
      if padding == "zeros"
      then stripLeading "0" str
      else if padding == "spaces"
      then stripLeading " " str
      else str;

    # Parse using number system
    parsed = numberSystems.parse system stripped;
  in
    if !widthValid
    then null
    else parsed;

  # Format an integer to a string using field constraints
  # Returns null if:
  #   - Value is negative
  #   - Value too large to fit in fixed width
  # Automatically applies padding to reach target width
  format = field: n: let
    system = field.system;
    width = field.width;
    padding = field.padding;

    # Format using number system
    formatted = numberSystems.format system n;

    # Check if value fits in width
    fitsInWidth =
      if formatted == null
      then false
      else if width == "variable"
      then true
      else builtins.stringLength formatted <= width;

    # Apply padding
    padded =
      if formatted == null
      then null
      else if width == "variable" || padding == "none"
      then formatted
      else if padding == "zeros"
      then padLeft "0" width formatted
      else if padding == "spaces"
      then padLeft " " width formatted
      else formatted;
  in
    if !fitsInWidth
    then null
    else padded;

  # Validate that an integer satisfies field constraints
  # Returns true if:
  #   - Value is non-negative
  #   - Value fits within field width (for fixed width)
  # Does not format - just checks validity
  validate = field: n: let
    system = field.system;
    width = field.width;

    # Value must be non-negative
    isNegative = n < 0;

    # Check if value fits in width
    maxVal = maxValueForWidth system.radix width;
    inRange =
      if maxVal == null
      then true # Variable width, unbounded
      else n <= maxVal;
  in
    !isNegative && inRange;

  # Derive the valid range of values for a field
  # Returns: {min, max} where:
  #   - min: Always 0 (negative numbers not supported)
  #   - max: radix^width - 1 for fixed width, null for variable width
  # Example: 2-digit decimal => {min = 0; max = 99;}
  range = field: let
    system = field.system;
    width = field.width;
    maxVal = maxValueForWidth system.radix width;
  in {
    min = 0;
    max = maxVal;
  };
}
