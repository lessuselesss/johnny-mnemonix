# Composition: Validators
# Composes constraints into reusable validation pipelines
#
# COMPOSITION LAYER: Builds on constraints to create validation workflows.
#
# Validators provide a composable interface for combining multiple
# validation rules. This enables complex validation scenarios like:
# - "Value must be in range [0-99] AND in enum [10, 20, 30]"
# - "String must match pattern AND be in allowed list"
# - "Age must be >= 18 AND be valid integer"
#
# The validator abstraction allows building reusable validation pipelines
# that can be applied consistently across different values.
#
# API:
#   fromConstraint = Constraint -> Validator
#   combine = [Validator] -> Validator (AND logic)
#   check = Validator -> Value -> Bool
#
# Examples:
#   # Single constraint validator
#   ageValidator = validators.fromConstraint (
#     constraints.range {min = 0; max = 120;}
#   );
#   validators.check ageValidator 25  # => true
#
#   # Combined validators (all must pass)
#   strictValidator = validators.combine [
#     (validators.fromConstraint (constraints.range {min = 10; max = 50;}))
#     (validators.fromConstraint (constraints.enum [10 20 30 40 50]))
#   ];
#   validators.check strictValidator 25  # => false (not in enum)
#   validators.check strictValidator 30  # => true (in range AND in enum)

{
  lib,
  primitives,
}: let
  constraints = primitives.constraints;
in {
  # Create a validator from a constraint
  #
  # Wraps a constraint from the primitives layer into a validator interface.
  # This allows constraints to be used in composition patterns (combine, etc.)
  #
  # Parameters:
  #   - constraint: Constraint object from primitives.constraints
  #     Can be: range, enum, pattern, or custom constraint
  #
  # Returns: Validator object that can be used with check/combine
  #
  # Examples:
  #   rangeValidator = fromConstraint (constraints.range {min = 0; max = 99;});
  #   enumValidator = fromConstraint (constraints.enum ["foo" "bar"]);
  #   patternValidator = fromConstraint (constraints.pattern "^[A-Z]+$");
  fromConstraint = constraint: {
    type = "constraint";
    inherit constraint;
  };

  # Combine multiple validators into one (AND logic)
  #
  # Creates a composite validator where ALL sub-validators must pass.
  # This enables complex validation scenarios like:
  #   "Value must satisfy constraint A AND constraint B AND constraint C"
  #
  # Parameters:
  #   - validators: List of Validator objects from fromConstraint or combine
  #     Can be nested (combined validators can contain combined validators)
  #
  # Returns: Combined validator that passes only if all sub-validators pass
  #
  # Examples:
  #   # Range AND enum constraint
  #   strictNum = combine [
  #     (fromConstraint (constraints.range {min = 0; max = 100;}))
  #     (fromConstraint (constraints.enum [10 20 30 40 50]))
  #   ];
  #   check strictNum 30  # => true (in range AND in enum)
  #   check strictNum 25  # => false (in range but NOT in enum)
  #
  #   # Empty validator list always passes
  #   noRestrictions = combine [];
  #   check noRestrictions "anything"  # => true
  combine = validators: {
    type = "combined";
    inherit validators;
  };

  # Check if a value passes validation
  #
  # Applies a validator to a value and returns boolean result.
  # Handles both single constraint validators and combined validators,
  # recursively checking nested validators.
  #
  # Parameters:
  #   - validator: Validator object from fromConstraint or combine
  #   - value: The value to validate (type depends on constraint)
  #
  # Returns: true if validation passes, false otherwise
  #
  # Examples:
  #   # Single constraint
  #   ageValidator = fromConstraint (constraints.range {min = 18; max = 120;});
  #   check ageValidator 25  # => true
  #   check ageValidator 10  # => false
  #
  #   # Combined validators (AND logic)
  #   strictValidator = combine [
  #     (fromConstraint (constraints.range {min = 0; max = 100;}))
  #     (fromConstraint (constraints.enum [10 20 30 40 50]))
  #   ];
  #   check strictValidator 30  # => true (in range AND in enum)
  #   check strictValidator 25  # => false (in range but NOT in enum)
  #
  #   # Empty combined validator always passes
  #   check (combine []) 999  # => true
  check = validator: value: let
    validatorType = validator.type;
  in
    if validatorType == "constraint"
    then
      # Single constraint validator - delegate to primitives
      constraints.check validator.constraint value
    else if validatorType == "combined"
    then let
      # Combined validators - all must pass (AND logic)
      validatorsList = validator.validators;
      # Recursively check each validator
      results = map (v: check v value) validatorsList;
      # All results must be true
      allPass = builtins.all (r: r == true) results;
    in
      allPass
    else
      throw "Unknown validator type: ${validatorType}";
}
