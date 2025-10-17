# 🔴 RED Tests for templates.nix
# These tests define the API for template operations
# Following TDD: Write tests first, then implement
# THIS IS THE FINAL BOSS OF PRIMITIVES! 💥

{
  lib,
  nixpkgs,
}: let
  templates = lib.primitives.templates or null;
in
  # If templates not implemented yet, return empty test suite
  if templates == null
  then {}
  else {
    # ═══════════════════════════════════════════════════════════
    # Test Suite 1: Template Parsing (3 tests)
    # ═══════════════════════════════════════════════════════════

    testTemplatesParseSimple = let
      template = templates.parse "{dept}-{year}-{seq}";
    in {
      expr = template ? placeholders;
      expected = true;
    };

    testTemplatesParseWithWidths = let
      template = templates.parse "{dept:3}-{year:2}-{seq:3}";
    in {
      expr = builtins.length template.placeholders;
      expected = 3;
    };

    testTemplatesExtractNames = let
      template = templates.parse "{dept}-{year}";
    in {
      expr = map (p: p.name) template.placeholders;
      expected = ["dept" "year"];
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 2: Rendering (4 tests)
    # ═══════════════════════════════════════════════════════════

    testTemplatesRenderSimple = let
      template = templates.parse "{dept}-{year}";
    in {
      expr = templates.render template {
        dept = "ENG";
        year = "24";
      };
      expected = "ENG-24";
    };

    testTemplatesRenderMissing = let
      template = templates.parse "{dept}-{year}";
    in {
      expr = templates.render template {dept = "ENG";}; # Missing year
      expected = null;
    };

    testTemplatesRenderWithWidth = let
      template = templates.parse "{dept:3}-{seq:3}";
    in {
      expr = templates.render template {
        dept = "ENG";
        seq = "001";
      };
      expected = "ENG-001";
    };

    testTemplatesRenderExtraFields = let
      template = templates.parse "{dept}";
    in {
      expr = templates.render template {
        dept = "ENG";
        extra = "ignored";
      };
      expected = "ENG";
    };

    # ═══════════════════════════════════════════════════════════
    # Test Suite 3: Extraction (3 tests)
    # ═══════════════════════════════════════════════════════════

    testTemplatesExtract = let
      template = templates.parse "{dept}-{year}-{seq}";
    in {
      expr = templates.extract template "ENG-24-001";
      expected = {
        dept = "ENG";
        year = "24";
        seq = "001";
      };
    };

    testTemplatesExtractMismatch = let
      template = templates.parse "{dept}-{year}";
    in {
      expr = templates.extract template "ENG_24"; # Wrong separator
      expected = null;
    };

    testTemplatesExtractValidateWidth = let
      template = templates.parse "{dept:3}-{seq:3}";
    in {
      expr = templates.extract template "EN-001"; # dept only 2 chars
      expected = null;
    };
  }
