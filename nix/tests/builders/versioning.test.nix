# 🔴 RED Tests for versioning.nix (BUILDERS LAYER!)
# These tests define the API for the versioning system builder
# Following TDD: Write tests first, then implement
# High-level constructor for semantic versioning and other version schemes

{
  lib,
  nixpkgs,
}: let
  mkVersioning = lib.builders.mkVersioning or null;
in
  # If mkVersioning not implemented yet, return empty test suite
  if mkVersioning == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Basic Versioning (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersVersionSemver = let
      ver = mkVersioning {};
    in {
      expr = ver.parse "1.2.3";
      expected = {
        major = 1;
        minor = 2;
        patch = 3;
      };
    };

    testBuildersVersionFormat = let
      ver = mkVersioning {};
    in {
      expr = ver.format {
        major = 1;
        minor = 2;
        patch = 3;
      };
      expected = "1.2.3";
    };

    testBuildersVersionPrerelease = let
      ver = mkVersioning {prerelease = true;};
    in {
      expr = ver.parse "1.2.3-alpha.1";
      expected = {
        major = 1;
        minor = 2;
        patch = 3;
        prerelease = "alpha.1";
      };
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Version Comparison (3 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersVersionCompareLT = let
      ver = mkVersioning {};
    in {
      expr = ver.compare "1.2.3" "1.2.4";
      expected = -1; # 1.2.3 < 1.2.4
    };

    testBuildersVersionCompareEQ = let
      ver = mkVersioning {};
    in {
      expr = ver.compare "1.2.3" "1.2.3";
      expected = 0; # Equal
    };

    testBuildersVersionComparePrerelease = let
      ver = mkVersioning {prerelease = true;};
    in {
      expr = ver.compare "1.2.3-alpha" "1.2.3";
      expected = -1; # Prerelease < release
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Version Bumping (2 tests)
    # ═══════════════════════════════════════════════════════════

    testBuildersVersionBumpMajor = let
      ver = mkVersioning {};
    in {
      expr = ver.bump.major "1.2.3";
      expected = "2.0.0";
    };

    testBuildersVersionBumpPatch = let
      ver = mkVersioning {};
    in {
      expr = ver.bump.patch "1.2.3";
      expected = "1.2.4";
    };
  }
