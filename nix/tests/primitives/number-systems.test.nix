# =4 RED Tests for number-systems.nix
# These tests define the API for number system operations
# Following TDD: Write tests first, then implement

{
  lib,
  nixpkgs,
}: let
  ns = lib.primitives.numberSystems or null;
in
  # If numberSystems not implemented yet, return empty test suite
  if ns == null
  then {}
  else {
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    # Test Suite 1: Creation (2 tests)
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    testNumberSystemsDecimalCreation = {
      expr = ns.decimal;
      expected = {
        radix = 10;
        alphabet = "0123456789";
      };
    };

    testNumberSystemsCustomBase5 = {
      expr = (ns.mk {
          radix = 5;
          alphabet = "01234";
        })
        .radix;
      expected = 5;
    };

    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    # Test Suite 2: Parsing (6 tests)
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    testNumberSystemsDecimalParse = {
      expr = ns.parse ns.decimal "42";
      expected = 42;
    };

    testNumberSystemsHexParse = {
      expr = ns.parse ns.hex "FF";
      expected = 255;
    };

    testNumberSystemsBinaryParse = {
      expr = ns.parse ns.binary "1010";
      expected = 10;
    };

    testNumberSystemsParseEmpty = {
      expr = ns.parse ns.decimal "";
      expected = null;
    };

    testNumberSystemsParseInvalid = {
      expr = ns.parse ns.decimal "1G";
      expected = null;
    };

    testNumberSystemsParseLeadingZeros = {
      expr = ns.parse ns.decimal "007";
      expected = 7;
    };

    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    # Test Suite 3: Formatting (6 tests)
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    testNumberSystemsDecimalFormat = {
      expr = ns.format ns.decimal 42;
      expected = "42";
    };

    testNumberSystemsHexFormat = {
      expr = ns.format ns.hex 255;
      expected = "FF";
    };

    testNumberSystemsBinaryFormat = {
      expr = ns.format ns.binary 10;
      expected = "1010";
    };

    testNumberSystemsFormatZero = {
      expr = ns.format ns.decimal 0;
      expected = "0";
    };

    testNumberSystemsFormatNegative = {
      expr = ns.format ns.decimal (-5);
      expected = null;
    };

    testNumberSystemsFormatTooLarge = let
      base5 = ns.mk {
        radix = 5;
        alphabet = "01234";
      };
    in {
      expr = ns.format base5 30; # 30 in base-5 = "110"
      expected = "110";
    };

    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    # Test Suite 4: Validation (4 tests)
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    testNumberSystemsValidateDecimal = {
      expr = ns.validate ns.decimal "123";
      expected = true;
    };

    testNumberSystemsValidateInvalidHex = {
      expr = ns.validate ns.hex "GG";
      expected = false;
    };

    testNumberSystemsValidateEmpty = {
      expr = ns.validate ns.decimal "";
      expected = false;
    };

    testNumberSystemsValidateCaseSensitive = {
      expr = ns.validate ns.hex "ff"; # lowercase
      expected = false; # Alphabet is uppercase only
    };

    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
    # Test Suite 5: Round-trip (2 tests)
    # PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

    testNumberSystemsRoundTripDecimal = {
      expr = ns.parse ns.decimal (ns.format ns.decimal 42);
      expected = 42;
    };

    testNumberSystemsRoundTripHex = {
      expr = ns.parse ns.hex (ns.format ns.hex 255);
      expected = 255;
    };
  }
