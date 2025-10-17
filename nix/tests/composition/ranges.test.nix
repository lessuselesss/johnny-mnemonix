# 🔴 RED Tests for ranges.nix (COMPOSITION LAYER!)
# These tests define the API for range operations
# Following TDD: Write tests first, then implement
# Ranges define spans of identifiers (e.g., "10-19", "1.0-2.0")

{
  lib,
  nixpkgs,
}: let
  ranges = lib.composition.ranges or null;
  identifiers = lib.composition.identifiers or null;
  fields = lib.primitives.fields or null;
  ns = lib.primitives.numberSystems or null;
in
  # If ranges not implemented yet, return empty test suite
  if ranges == null || identifiers == null || fields == null || ns == null
  then {}
  else let
    # Helper: Create a 2-digit decimal field (for Johnny Decimal)
    mkField = fields.mk {
      system = ns.decimal;
      width = 2;
      padding = "zeros";
    };

    # Helper: Create a 2-part identifier (category.item)
    mkIdentifier = identifiers.mk {
      fields = [mkField mkField];
      separator = ".";
    };
  in {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Creation (2 tests)
    # ═══════════════════════════════════════════════════════════

    testRangesCreateSimple = let
      range = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
    in {
      expr = range.start;
      expected = [10 0];
    };

    testRangesCreateOpenEnded = let
      range = ranges.mk {
        start = [10 0];
        end = null; # Open-ended (10+)
      };
    in {
      expr = range.end;
      expected = null;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Contains (Single Identifier) (3 tests)
    # ═══════════════════════════════════════════════════════════

    testRangesContainsTrue = let
      range = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
    in {
      expr = ranges.contains range [15 5];
      expected = true;
    };

    testRangesContainsFalse = let
      range = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
    in {
      expr = ranges.contains range [20 0];
      expected = false;
    };

    testRangesContainsOpenEnded = let
      range = ranges.mk {
        start = [10 0];
        end = null; # Open-ended
      };
    in {
      expr = ranges.contains range [99 99];
      expected = true; # Always true for open-ended
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Containing (Range Containment) (3 tests)
    # ═══════════════════════════════════════════════════════════

    testRangesContainingTrue = let
      outer = ranges.mk {
        start = [10 0];
        end = [29 99];
      };
      inner = ranges.mk {
        start = [15 0];
        end = [19 99];
      };
    in {
      expr = ranges.containing outer inner;
      expected = true; # outer contains inner
    };

    testRangesContainingFalse = let
      range1 = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
      range2 = ranges.mk {
        start = [20 0];
        end = [29 99];
      };
    in {
      expr = ranges.containing range1 range2;
      expected = false; # Disjoint ranges
    };

    testRangesContainingPartial = let
      range1 = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
      range2 = ranges.mk {
        start = [15 0];
        end = [25 0];
      };
    in {
      expr = ranges.containing range1 range2;
      expected = false; # Overlap but not containment
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 4: Validation (2 tests)
    # ═══════════════════════════════════════════════════════════

    testRangesValidateGood = let
      range = ranges.mk {
        start = [10 0];
        end = [19 99];
      };
    in {
      expr = ranges.validate range;
      expected = true;
    };

    testRangesValidateBad = let
      range = ranges.mk {
        start = [19 99];
        end = [10 0]; # End before start!
      };
    in {
      expr = ranges.validate range;
      expected = false;
    };
  }
