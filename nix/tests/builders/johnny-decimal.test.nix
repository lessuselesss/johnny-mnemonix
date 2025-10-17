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
  }
