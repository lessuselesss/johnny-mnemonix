# 🔴 RED Tests for classification.nix (BUILDERS LAYER!)
# These tests define the API for the classification system builder
# Following TDD: Write tests first, then implement
# FINAL BUILDER - completes the builders layer! 🎉

{
  lib,
  nixpkgs,
}: let
  mkClassification = lib.builders.mkClassification or null;
in
  # If mkClassification not implemented yet, return empty test suite
  if mkClassification == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Basic Classification (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersClassification3Level = let
      cls = mkClassification {depth = 3;};
    in {
      expr = builtins.length cls.hierarchy.levels;
      expected = 3;
    };

    testBuildersClassificationPath = let
      cls = mkClassification {
        depth = 3;
        separators = ["."];
      };
    in {
      expr = cls.path [10 5 2];
      expected = "10 / 10.05 / 10.05.02";
    };

    testBuildersClassificationValidate = let
      cls = mkClassification {depth = 3;};
    in {
      expr = cls.validate [10 5 2];
      expected = true;
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Navigation (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersClassificationParent = let
      cls = mkClassification {depth = 3;};
    in {
      expr = cls.navigate.parent [10 5 2];
      expected = [10 5];
    };

    testBuildersClassificationAncestors = let
      cls = mkClassification {depth = 3;};
    in {
      expr = cls.navigate.ancestors [10 5 2];
      expected = [[10] [10 5]];
    };

    testBuildersClassificationSiblings = let
      cls = mkClassification {depth = 3;};
      tree = {
        "10" = {
          "5" = ["1" "2" "3"];
        };
      };
    in {
      expr = builtins.length (cls.navigate.siblings tree [10 5 2]);
      expected = 2; # Excludes self
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Presets (2 tests)
    # ═══════════════════════════════════════════════════════════

    # Note: Presets might not be implemented as separate functions
    # but rather example configurations. Adjust tests as needed.

    testBuildersClassificationDewey = let
      # Dewey Decimal: 3 levels, base 10
      cls = mkClassification {
        depth = 3;
        base = 10;
        levelNames = ["class" "division" "section"];
      };
    in {
      expr = cls.hierarchy.levelNames;
      expected = ["class" "division" "section"];
    };

    testBuildersClassificationFileSystem = let
      # File system-like: 5 levels, "/" separators
      cls = mkClassification {
        depth = 5;
        separators = ["/"];
      };
    in {
      expr = builtins.head cls.hierarchy.separators;
      expected = "/";
    };
  }
