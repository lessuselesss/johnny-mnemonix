# 🔴 RED Tests for johnny-decimal.nix (BUILDERS LAYER!)
# These tests define the API for the Johnny Decimal builder
# Following TDD: Write tests first, then implement
# High-level constructor for complete JD systems
{
  lib,
  nixpkgs,
}: let
  mkJohnnyDecimal = lib.builders.mkJohnnyDecimal or null;
in
  # If mkJohnnyDecimal not implemented yet, return empty test suite
  if mkJohnnyDecimal == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Basic Builder (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersJDClassic = let
      jd = mkJohnnyDecimal {};
    in {
      expr = jd.identifiers ? category && jd.identifiers ? item;
      expected = true;
    };

    testBuildersJDParse = let
      jd = mkJohnnyDecimal {};
    in {
      expr = jd.parse "10.05";
      expected = {
        category = 10;
        item = 5;
      };
    };

    testBuildersJDFormat = let
      jd = mkJohnnyDecimal {};
    in {
      expr = jd.format {
        category = 10;
        item = 5;
      };
      expected = "10.05";
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Customization (4 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersJDHex = let
      jd = mkJohnnyDecimal {base = 16;};
    in {
      expr = jd.parse "1A.3F";
      expected = {
        category = 26;
        item = 63;
      };
    };

    testBuildersJDExtended = let
      jd = mkJohnnyDecimal {levels = 3;};
    in {
      expr = jd.parse "10.05.02";
      expected = {
        area = 10;
        category = 5;
        item = 2;
      };
    };

    testBuildersJDCustomSeparators = let
      jd = mkJohnnyDecimal {separators = ["-"];};
    in {
      expr = jd.parse "10-05";
      expected = {
        category = 10;
        item = 5;
      };
    };

    testBuildersJDCustomDigits = let
      jd = mkJohnnyDecimal {digits = 3;};
    in {
      expr = jd.parse "010.005";
      expected = {
        category = 10;
        item = 5;
      };
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Validation & Constraints (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersJDValidateCorrect = let
      jd = mkJohnnyDecimal {};
    in {
      expr = jd.validate "10.05";
      expected = true;
    };

    testBuildersJDValidateIncorrect = let
      jd = mkJohnnyDecimal {};
    in {
      expr = jd.validate "1.5"; # Missing zero padding
      expected = false;
    };

    testBuildersJDConstraints = let
      jd = mkJohnnyDecimal {
        constraints = {
          category = {
            min = 10;
            max = 19;
          }; # Only area 10-19
        };
      };
    in {
      expr = jd.validate "10.05" && !(jd.validate "20.05");
      expected = true;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 4: Per-Level Configuration (10 tests)
    # ═══════════════════════════════════════════════════════════

    # Test: levelConfigs with explicit per-level settings
    testBuildersJDLevelConfigs = let
      jd = mkJohnnyDecimal {
        levels = 2;
        levelConfigs = [
          {
            base = 10;
            chars = 2;
            capacity = {
              min = 0;
              max = 99;
            };
          }
          {
            base = 16;
            chars = 2;
            capacity = {
              min = 0;
              max = 255;
            };
          }
        ];
      };
    in {
      # Category in decimal (00-99), item in hex (00-FF)
      expr = jd.parse "10.3F";
      expected = {
        category = 10;
        item = 63;
      };
    };

    # Test: Format with per-level configs
    testBuildersJDLevelConfigsFormat = let
      jd = mkJohnnyDecimal {
        levels = 2;
        levelConfigs = [
          {
            base = 10;
            chars = 2;
          }
          {
            base = 16;
            chars = 2;
          }
        ];
      };
    in {
      expr = jd.format {
        category = 10;
        item = 63;
      };
      expected = "10.3F";
    };

    # Test: capacityFormula (n^n formula)
    testBuildersJDCapacityFormula = let
      jd = mkJohnnyDecimal {
        levels = 3;
        base = 10;
        capacityFormula = n: n * n; # Level 1: 1, Level 2: 4, Level 3: 9
      };
      # Level 1: capacity 1 (1 digit), Level 2: capacity 4 (1 digit), Level 3: capacity 9 (1 digit)
    in {
      expr = jd.parse "0.3.8";
      expected = {
        area = 0;
        category = 3;
        item = 8;
      };
    };

    # Test: capacityFormula validates capacity constraints
    testBuildersJDCapacityFormulaValidation = let
      jd = mkJohnnyDecimal {
        levels = 3;
        base = 10;
        capacityFormula = n: n * n; # Level 1: 0-0, Level 2: 0-3, Level 3: 0-8
      };
    in {
      # Valid: within capacity
      expr =
        (jd.validate "0.3.8")
        &&
        # Invalid: exceeds level 2 capacity (max 3)
        !(jd.validate "0.4.8")
        &&
        # Invalid: exceeds level 3 capacity (max 8)
        !(jd.validate "0.3.9");
      expected = true;
    };

    # Test: Mixed bases per level
    testBuildersJDMixedBases = let
      jd = mkJohnnyDecimal {
        levels = 3;
        levelConfigs = [
          {
            base = 10;
            chars = 2;
          } # Decimal area
          {
            base = 16;
            chars = 2;
          } # Hex category
          {
            base = 2;
            chars = 4;
          } # Binary item
        ];
      };
    in {
      expr = jd.parse "10.1A.1010";
      expected = {
        area = 10;
        category = 26;
        item = 10;
      };
    };

    # Test: Mixed char widths per level
    testBuildersJDMixedChars = let
      jd = mkJohnnyDecimal {
        levels = 3;
        levelConfigs = [
          {
            base = 10;
            chars = 1;
          } # 1-digit area
          {
            base = 10;
            chars = 2;
          } # 2-digit category
          {
            base = 10;
            chars = 3;
          } # 3-digit item
        ];
      };
    in {
      expr = jd.parse "5.42.123";
      expected = {
        area = 5;
        category = 42;
        item = 123;
      };
    };

    # Test: Format with mixed chars
    testBuildersJDMixedCharsFormat = let
      jd = mkJohnnyDecimal {
        levels = 3;
        levelConfigs = [
          {
            base = 10;
            chars = 1;
          }
          {
            base = 10;
            chars = 2;
          }
          {
            base = 10;
            chars = 3;
          }
        ];
      };
    in {
      expr = jd.format {
        area = 5;
        category = 42;
        item = 123;
      };
      expected = "5.42.123";
    };

    # Test: Capacity constraint validation with levelConfigs
    testBuildersJDCapacityConstraintValidation = let
      jd = mkJohnnyDecimal {
        levels = 2;
        levelConfigs = [
          {
            base = 10;
            chars = 2;
            capacity = {
              min = 10;
              max = 19;
            };
          } # Categories 10-19 only
          {
            base = 10;
            chars = 2;
            capacity = {
              min = 0;
              max = 99;
            };
          } # Items 00-99
        ];
      };
    in {
      expr =
        (jd.validate "15.50")
        &&
        # Valid category
        !(jd.validate "20.50")
        &&
        # Category too high
        !(jd.validate "09.50"); # Category too low
      expected = true;
    };

    # Test: Backward compatibility - legacy base parameter
    testBuildersJDBackwardCompatBase = let
      jd = mkJohnnyDecimal {
        levels = 2;
        base = 16;
        chars = 2;
      };
    in {
      # Should work with legacy parameters (no levelConfigs)
      expr = jd.parse "1A.3F";
      expected = {
        category = 26;
        item = 63;
      };
    };

    # Test: Backward compatibility - legacy chars parameter
    testBuildersJDBackwardCompatChars = let
      jd = mkJohnnyDecimal {
        levels = 2;
        base = 10;
        chars = 3;
      };
    in {
      # Should work with legacy parameters
      expr = jd.parse "010.005";
      expected = {
        category = 10;
        item = 5;
      };
    };

    # Test: identifierDefs exposes per-level fields
    testBuildersJDIdentifierDefs = let
      jd = mkJohnnyDecimal {
        levels = 2;
        levelConfigs = [
          {
            base = 10;
            chars = 2;
          }
          {
            base = 16;
            chars = 2;
          }
        ];
      };
    in {
      # Identifiers should have category and item fields
      expr =
        (jd.identifiers ? category)
        && (jd.identifiers ? item)
        && (jd.identifiers.category.width == 2)
        && (jd.identifiers.item.width == 2);
      expected = true;
    };
  }
