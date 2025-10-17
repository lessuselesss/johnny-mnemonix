# 🔴 RED Tests for validators.nix (COMPOSITION LAYER!)
# These tests define the API for validator composition
# Following TDD: Write tests first, then implement
# THE FINAL COMPOSITION COMPONENT! 💥

{
  lib,
  nixpkgs,
}: let
  validators = lib.composition.validators or null;
  constraints = lib.primitives.constraints or null;
in
  # If validators not implemented yet, return empty test suite
  if validators == null || constraints == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Creation from Constraints (2 tests)
    # ═══════════════════════════════════════════════════════════

    testValidatorsFromRange = let
      constraint = constraints.range {
        min = 0;
        max = 99;
      };
      validator = validators.fromConstraint constraint;
    in {
      expr = validators.check validator 50;
      expected = true;
    };

    testValidatorsFromEnum = let
      constraint = constraints.enum ["ENG" "DES" "OPS"];
      validator = validators.fromConstraint constraint;
    in {
      expr = validators.check validator "ENG";
      expected = true;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Combining Validators (3 tests)
    # ═══════════════════════════════════════════════════════════

    testValidatorsCombineAllPass = let
      v1 = validators.fromConstraint (constraints.range {
        min = 0;
        max = 100;
      });
      v2 = validators.fromConstraint (constraints.range {
        min = 10;
        max = 50;
      });
      combined = validators.combine [v1 v2];
    in {
      expr = validators.check combined 25;
      expected = true; # Satisfies both ranges
    };

    testValidatorsCombineOneFails = let
      v1 = validators.fromConstraint (constraints.range {
        min = 0;
        max = 100;
      });
      v2 = validators.fromConstraint (constraints.range {
        min = 10;
        max = 50;
      });
      combined = validators.combine [v1 v2];
    in {
      expr = validators.check combined 75;
      expected = false; # Satisfies v1 but not v2
    };

    testValidatorsCombineEmpty = let
      combined = validators.combine [];
    in {
      expr = validators.check combined "anything";
      expected = true; # No validators = always pass
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Validation with Results (3 tests)
    # ═══════════════════════════════════════════════════════════

    testValidatorsCheckPass = let
      validator = validators.fromConstraint (constraints.range {
        min = 0;
        max = 99;
      });
    in {
      expr = validators.check validator 50;
      expected = true;
    };

    testValidatorsCheckFail = let
      validator = validators.fromConstraint (constraints.range {
        min = 0;
        max = 99;
      });
    in {
      expr = validators.check validator 100;
      expected = false;
    };

    testValidatorsCheckCombined = let
      v1 = validators.fromConstraint (constraints.range {
        min = 0;
        max = 100;
      });
      v2 = validators.fromConstraint (constraints.enum ["foo" "bar"]);
      combined = validators.combine [v1 v2];
    in {
      # Different types - numeric range and string enum
      # This tests that validators work on their respective types
      expr = validators.check v1 50 && validators.check v2 "foo";
      expected = true;
    };
  }
