# Primitives: Number Systems
# Provides base conversion operations (decimal, hex, binary, custom bases)
#
# This module implements the foundational number system operations for converting
# between different bases. All functions are pure and return null on invalid input
# rather than throwing errors.
#
# API:
#   mk = {radix, alphabet} -> NumberSystem
#   parse = NumberSystem -> String -> Int | Null
#   format = NumberSystem -> Int -> String | Null
#   validate = NumberSystem -> String -> Bool
#   decimal, hex, binary = built-in number systems
#
# Examples:
#   numberSystems.parse numberSystems.hex "FF"  => 255
#   numberSystems.format numberSystems.binary 10  => "1010"
#   numberSystems.validate numberSystems.decimal "123"  => true

{lib}: let
  # Convert a character to its index in the given alphabet
  # Returns null if the character is not in the alphabet
  # Time complexity: O(n) where n is alphabet length
  charToIndex = alphabet: char: let
    chars = lib.stringToCharacters alphabet;
    indices = lib.imap0 (i: c: {inherit c i;}) chars;
    matches = builtins.filter (x: x.c == char) indices;
  in
    if matches == []
    then null
    else (builtins.head matches).i;

  # Convert an index to the corresponding character in the alphabet
  # Returns null if the index is out of bounds
  indexToChar = alphabet: index: let
    chars = lib.stringToCharacters alphabet;
    len = builtins.length chars;
  in
    if index < 0 || index >= len
    then null
    else builtins.elemAt chars index;
in {
  # Built-in number systems
  decimal = {
    radix = 10;
    alphabet = "0123456789";
  };

  hex = {
    radix = 16;
    alphabet = "0123456789ABCDEF";
  };

  binary = {
    radix = 2;
    alphabet = "01";
  };

  # Create a custom number system
  mk = {
    radix,
    alphabet,
  }: {
    inherit radix alphabet;
  };

  # Parse a string to an integer using the given number system
  # Returns null if the string is invalid (empty or contains invalid characters)
  #
  # Algorithm: Convert each character to its digit value, then compute the number
  # using Horner's method: result = (...((d1 * r + d2) * r + d3) * r + ...)
  # where r is the radix and d1, d2, d3 are digit values
  parse = system: str: let
    alphabet = system.alphabet;
    radix = system.radix;

    # Validate input
    isEmpty = str == "";

    # Convert string to list of digit values
    chars = lib.stringToCharacters str;
    values = map (c: charToIndex alphabet c) chars;

    # Check if all characters are valid (no nulls in values)
    allValid = builtins.all (v: v != null) values;

    # Convert digit values to final integer using Horner's method
    toNumber = digits:
      builtins.foldl'
      (acc: digit: acc * radix + digit)
      0
      digits;
  in
    if isEmpty || !allValid
    then null
    else toNumber values;

  # Format an integer as a string using the given number system
  # Returns null if the integer is negative (negative numbers not supported)
  #
  # Algorithm: Repeatedly divide by radix, collecting remainders as digits
  # Example: 42 in base 10 -> 42 % 10 = 2, 4 % 10 = 4 -> "42"
  format = system: n: let
    alphabet = system.alphabet;
    radix = system.radix;

    # Validate input
    isNegative = n < 0;
    isZero = n == 0;

    # Convert integer to list of digit indices using repeated division
    # Builds list from least significant to most significant digit
    toDigits = num: let
      go = n: acc:
        if n == 0
        then acc
        else go (n / radix) ([(lib.mod n radix)] ++ acc);
    in
      go num [];

    # Convert digit indices to their character representations
    digitsToString = digits:
      lib.concatStrings (map (d: indexToChar alphabet d) digits);
  in
    if isNegative
    then null
    else if isZero
    then indexToChar alphabet 0
    else digitsToString (toDigits n);

  # Validate that a string matches the number system's alphabet
  # Returns false for empty strings or strings containing invalid characters
  #
  # This function checks if the string could be successfully parsed, but doesn't
  # actually perform the parsing (more efficient for validation-only use cases)
  validate = system: str: let
    alphabet = system.alphabet;

    # Validate input
    isEmpty = str == "";

    # Check if all characters exist in the alphabet
    chars = lib.stringToCharacters str;
    allValid = builtins.all (c: charToIndex alphabet c != null) chars;
  in
    if isEmpty
    then false
    else allValid;
}
