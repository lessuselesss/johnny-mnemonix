# 🔴 RED Tests for hierarchies.nix (COMPOSITION LAYER!)
# These tests define the API for multi-level hierarchy navigation
# Following TDD: Write tests first, then implement
# Hierarchies define multi-level structures like Area→Category→Item

{
  lib,
  nixpkgs,
}: let
  hierarchies = lib.composition.hierarchies or null;
  identifiers = lib.composition.identifiers or null;
  fields = lib.primitives.fields or null;
  ns = lib.primitives.numberSystems or null;
in
  # If hierarchies not implemented yet, return empty test suite
  if hierarchies == null || identifiers == null || fields == null || ns == null
  then {}
  else let
    # Helper: Create a 2-digit decimal field
    mkField = fields.mk {
      system = ns.decimal;
      width = 2;
      padding = "zeros";
    };

    # Helper: Create a 3-level Johnny Decimal hierarchy
    # Level 0: Area (single field: XX)
    # Level 1: Category (two fields: XX.YY)
    # Level 2: Item (three fields: XX.YY.ZZ)
    mkJDHierarchy = hierarchies.mk {
      levels = [
        # Level 0: Area
        (identifiers.mk {
          fields = [mkField];
          separator = "";
        })
        # Level 1: Category
        (identifiers.mk {
          fields = [mkField mkField];
          separator = ".";
        })
        # Level 2: Item
        (identifiers.mk {
          fields = [mkField mkField mkField];
          separator = ".";
        })
      ];
      levelNames = ["area" "category" "item"];
    };
  in {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Creation (2 tests)
    # ═══════════════════════════════════════════════════════════

    testHierarchiesCreate = let
      hierarchy = mkJDHierarchy;
    in {
      expr = builtins.length hierarchy.levels;
      expected = 3;
    };

    testHierarchiesLevelNames = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchy.levelNames;
      expected = ["area" "category" "item"];
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Level Detection (2 tests)
    # ═══════════════════════════════════════════════════════════

    testHierarchiesLevelArea = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.level hierarchy [10];
      expected = 0; # Area level
    };

    testHierarchiesLevelItem = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.level hierarchy [10 5 3];
      expected = 2; # Item level
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Parent Navigation (3 tests)
    # ═══════════════════════════════════════════════════════════

    testHierarchiesParentFromItem = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.parent hierarchy [10 5 3];
      expected = [10 5]; # Category
    };

    testHierarchiesParentFromCategory = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.parent hierarchy [10 5];
      expected = [10]; # Area
    };

    testHierarchiesParentFromRoot = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.parent hierarchy [10];
      expected = null; # No parent (already at root)
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 4: Path Generation (2 tests)
    # ═══════════════════════════════════════════════════════════

    testHierarchiesPathSimple = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.path hierarchy [10 5 3];
      expected = "10 / 10.05 / 10.05.03";
    };

    testHierarchiesPathArea = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.path hierarchy [10];
      expected = "10";
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 5: Validation (3 tests)
    # ═══════════════════════════════════════════════════════════

    testHierarchiesValidateGood = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.validate hierarchy [10 5 3];
      expected = true;
    };

    testHierarchiesValidateTooShort = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.validate hierarchy [];
      expected = false; # Empty path
    };

    testHierarchiesValidateTooLong = let
      hierarchy = mkJDHierarchy;
    in {
      expr = hierarchies.validate hierarchy [10 5 3 7];
      expected = false; # 4 levels, but hierarchy only has 3
    };
  }
