# 🔴 RED Tests for identifiers.nix (COMPOSITION LAYER!)
# These tests define the API for multi-field identifiers
# Following TDD: Write tests first, then implement
# Identifiers combine multiple fields with separators (e.g., "10.01", "v1.2.3")

{
  lib,
  nixpkgs,
}: let
  identifiers = lib.composition.identifiers or null;
  fields = lib.primitives.fields or null;
  ns = lib.primitives.numberSystems or null;
in
  # If identifiers not implemented yet, return empty test suite
  if identifiers == null || fields == null || ns == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Creation (3 tests)
    # ═══════════════════════════════════════════════════════════

    testIdentifiersCreateSimple = let
      # Create 2-part identifier: "10.01"
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifier.separator;
      expected = ".";
    };

    testIdentifiersCreateTriple = let
      # Create 3-part identifier: "10.05.03"
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = builtins.length identifier.fields;
      expected = 3;
    };

    testIdentifiersCreateVersion = let
      # Create version identifier: "1.2.3"
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifier.separator;
      expected = ".";
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Parsing (4 tests)
    # ═══════════════════════════════════════════════════════════

    testIdentifiersParseSimple = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.parse identifier "10.01";
      expected = [10 1];
    };

    testIdentifiersParseTriple = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.parse identifier "10.05.03";
      expected = [10 5 3];
    };

    testIdentifiersParseVersion = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.parse identifier "1.20.300";
      expected = [1 20 300];
    };

    testIdentifiersParseInvalid = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.parse identifier "10-01"; # Wrong separator
      expected = null;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Formatting (4 tests)
    # ═══════════════════════════════════════════════════════════

    testIdentifiersFormatSimple = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.format identifier [10 1];
      expected = "10.01";
    };

    testIdentifiersFormatTriple = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.format identifier [10 5 3];
      expected = "10.05.03";
    };

    testIdentifiersFormatVersion = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.format identifier [1 20 300];
      expected = "1.20.300";
    };

    testIdentifiersFormatInvalid = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.format identifier [10 100]; # 100 doesn't fit in 2 digits
      expected = null;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 4: Validation (2 tests)
    # ═══════════════════════════════════════════════════════════

    testIdentifiersValidateGood = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.validate identifier [10 1];
      expected = true;
    };

    testIdentifiersValidateBad = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
    in {
      expr = identifiers.validate identifier [10 100]; # 100 out of range
      expected = false;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 5: Round-trip (2 tests)
    # ═══════════════════════════════════════════════════════════

    testIdentifiersRoundTrip = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
          (fields.mk {
            system = ns.decimal;
            width = 2;
            padding = "zeros";
          })
        ];
        separator = ".";
      };
      values = [10 1];
    in {
      expr = identifiers.parse identifier (identifiers.format identifier values);
      expected = values;
    };

    testIdentifiersRoundTripVersion = let
      identifier = identifiers.mk {
        fields = [
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
          (fields.mk {
            system = ns.decimal;
            width = "variable";
            padding = "none";
          })
        ];
        separator = ".";
      };
      values = [1 20 300];
    in {
      expr = identifiers.parse identifier (identifiers.format identifier values);
      expected = values;
    };
  }
