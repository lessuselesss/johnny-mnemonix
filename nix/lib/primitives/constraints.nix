# Primitives: Constraints
# Provides validation predicates for values
#
# Constraints are composable validation rules that check if values
# satisfy specific conditions (range, enum, pattern, custom predicates).
#
# API:
#   range = {min, max} -> Constraint
#   enum = [values] -> Constraint
#   pattern = regex -> Constraint
#   custom = predicate -> Constraint
#   check = Constraint -> Value -> Bool
#
# Examples:
#   ageConstraint = constraints.range {min = 0; max = 120;};
#   constraints.check ageConstraint 25  => true
#
#   deptConstraint = constraints.enum ["ENG" "DES" "OPS"];
#   constraints.check deptConstraint "ENG"  => true

{lib}: {
  # Create a range constraint (inclusive bounds)
  # Validates that a value is within [min, max]
  #
  # Parameters:
  #   - min: Minimum value (inclusive)
  #   - max: Maximum value (inclusive)
  #
  # Example:
  #   ageConstraint = range {min = 0; max = 120;};
  #   check ageConstraint 25  => true
  #   check ageConstraint 150 => false
  range = {
    min,
    max,
  }: {
    type = "range";
    inherit min max;
  };

  # Create an enum constraint (allowed values)
  # Validates that a value is in the allowed list
  #
  # Parameters:
  #   - values: List of allowed values
  #
  # Example:
  #   deptConstraint = enum ["ENG" "DES" "OPS"];
  #   check deptConstraint "ENG" => true
  #   check deptConstraint "MKT" => false
  enum = values: {
    type = "enum";
    inherit values;
  };

  # Create a pattern constraint (regex matching)
  # Validates that a value matches the regex pattern
  #
  # Parameters:
  #   - regex: POSIX extended regular expression
  #
  # Example:
  #   codeConstraint = pattern "^[A-Z]{3}$";  # 3 uppercase letters
  #   check codeConstraint "ENG" => true
  #   check codeConstraint "eng" => false
  pattern = regex: {
    type = "pattern";
    inherit regex;
  };

  # Create a custom constraint (arbitrary predicate)
  # Validates using a custom predicate function
  #
  # Parameters:
  #   - predicate: Function (value -> bool)
  #
  # Example:
  #   evenConstraint = custom (x: (x / 2) * 2 == x);
  #   check evenConstraint 42 => true
  #   check evenConstraint 43 => false
  custom = predicate: {
    type = "custom";
    inherit predicate;
  };

  # Check if a value satisfies a constraint
  # Dispatches to the appropriate validation logic based on constraint type
  #
  # Parameters:
  #   - constraint: A constraint object (from range, enum, pattern, or custom)
  #   - value: The value to validate
  #
  # Returns: true if constraint is satisfied, false otherwise
  # Throws: Error if constraint type is unknown
  check = constraint: value: let
    constraintType = constraint.type;
  in
    if constraintType == "range"
    then let
      min = constraint.min;
      max = constraint.max;
    in
      # Check inclusive bounds
      value >= min && value <= max
    else if constraintType == "enum"
    then let
      values = constraint.values;
    in
      # Check membership in allowed list
      builtins.elem value values
    else if constraintType == "pattern"
    then let
      regex = constraint.regex;
      match = builtins.match regex value;
    in
      # Check if regex matched (returns list) or failed (returns null)
      match != null
    else if constraintType == "custom"
    then let
      predicate = constraint.predicate;
    in
      # Apply custom predicate function
      predicate value
    else
      # Unknown constraint type - programming error
      throw "Unknown constraint type: ${constraintType}";
}
