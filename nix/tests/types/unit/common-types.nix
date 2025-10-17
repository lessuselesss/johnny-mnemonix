# Unit Tests: Common Johnny Decimal Types
#
# Tests the shared JD type definitions from module-types/common.nix
#
# TDD: These tests were written FIRST to define what the types should accept/reject,
# then the type definitions were implemented to pass them.

{
  lib,
  types,  # lib.types.moduleTypes.common
}: {
  # ===== jdIdentifier Type Tests =====

  # Test: Valid JD identifier (XX.YY format)
  testJdIdentifierValid = {
    expr = lib.types.check types.jdIdentifier "10.05";
    expected = true;
  };

  # Test: Valid JD identifier with zeros
  testJdIdentifierZeros = {
    expr = lib.types.check types.jdIdentifier "00.00";
    expected = true;
  };

  # Test: Invalid - single digit category
  testJdIdentifierInvalidSingleDigitCategory = {
    expr = lib.types.check types.jdIdentifier "1.05";
    expected = false;
  };

  # Test: Invalid - single digit item
  testJdIdentifierInvalidSingleDigitItem = {
    expr = lib.types.check types.jdIdentifier "10.5";
    expected = false;
  };

  # Test: Invalid - missing separator
  testJdIdentifierInvalidNoSeparator = {
    expr = lib.types.check types.jdIdentifier "1005";
    expected = false;
  };

  # Test: Invalid - wrong separator
  testJdIdentifierInvalidWrongSeparator = {
    expr = lib.types.check types.jdIdentifier "10-05";
    expected = false;
  };

  # ===== jdAreaRange Type Tests =====

  # Test: Valid area range
  testJdAreaRangeValid = {
    expr = lib.types.check types.jdAreaRange "10-19";
    expected = true;
  };

  # Test: Valid area range with zeros
  testJdAreaRangeZeros = {
    expr = lib.types.check types.jdAreaRange "00-09";
    expected = true;
  };

  # Test: Invalid - wrong separator
  testJdAreaRangeInvalidSeparator = {
    expr = lib.types.check types.jdAreaRange "10.19";
    expected = false;
  };

  # Test: Invalid - single digit
  testJdAreaRangeInvalidSingleDigit = {
    expr = lib.types.check types.jdAreaRange "1-9";
    expected = false;
  };

  # ===== jdCategory Type Tests =====

  # Test: Valid category
  testJdCategoryValid = {
    expr = lib.types.check types.jdCategory "10";
    expected = true;
  };

  # Test: Invalid - single digit
  testJdCategoryInvalidSingleDigit = {
    expr = lib.types.check types.jdCategory "1";
    expected = false;
  };

  # Test: Invalid - three digits
  testJdCategoryInvalidThreeDigits = {
    expr = lib.types.check types.jdCategory "100";
    expected = false;
  };

  # ===== jdItemDef Type Tests =====

  # Test: Valid item with just name
  testJdItemDefMinimal = {
    expr = lib.types.check types.jdItemDef {
      name = "Test Item";
    };
    expected = true;
  };

  # Test: Valid item with git URL
  testJdItemDefWithGit = {
    expr = lib.types.check types.jdItemDef {
      name = "Project";
      url = "git@github.com:user/repo.git";
      ref = "main";
    };
    expected = true;
  };

  # Test: Valid item with sparse checkout
  testJdItemDefWithSparse = {
    expr = lib.types.check types.jdItemDef {
      name = "Docs";
      url = "https://github.com/user/repo.git";
      sparse = ["docs/" "*.md"];
    };
    expected = true;
  };

  # Test: Valid item with symlink target
  testJdItemDefWithTarget = {
    expr = lib.types.check types.jdItemDef {
      name = "Link";
      target = /mnt/storage/project;
    };
    expected = true;
  };

  # Test: Invalid - missing name
  testJdItemDefInvalidNoName = {
    expr = lib.types.check types.jdItemDef {
      url = "git@github.com:user/repo.git";
    };
    expected = false;
  };

  # ===== jdCategoryDef Type Tests =====

  # Test: Valid category with string items
  testJdCategoryDefStringItems = {
    expr = lib.types.check types.jdCategoryDef {
      name = "Code";
      items = {
        "10.01" = "Website";
        "10.02" = "CLI Tool";
      };
    };
    expected = true;
  };

  # Test: Valid category with structured items
  testJdCategoryDefStructuredItems = {
    expr = lib.types.check types.jdCategoryDef {
      name = "Projects";
      items = {
        "10.01" = {
          name = "App";
          url = "git@github.com:user/app.git";
        };
      };
    };
    expected = true;
  };

  # Test: Valid category with mixed items
  testJdCategoryDefMixedItems = {
    expr = lib.types.check types.jdCategoryDef {
      name = "Mixed";
      items = {
        "10.01" = "Simple";
        "10.02" = {
          name = "Complex";
          url = "git@github.com:user/complex.git";
        };
      };
    };
    expected = true;
  };

  # ===== jdAreaDef Type Tests =====

  # Test: Valid area with categories
  testJdAreaDefValid = {
    expr = lib.types.check types.jdAreaDef {
      name = "Projects";
      categories = {
        "10" = {
          name = "Code";
          items = {
            "10.01" = "Website";
          };
        };
      };
    };
    expected = true;
  };

  # Test: Valid empty area
  testJdAreaDefEmpty = {
    expr = lib.types.check types.jdAreaDef {
      name = "Empty Area";
      categories = {};
    };
    expected = true;
  };

  # ===== jdSyntax Type Tests =====

  # Test: Valid syntax with defaults
  testJdSyntaxDefaults = {
    expr = lib.types.check types.jdSyntax {};
    expected = true;
  };

  # Test: Valid syntax with custom encapsulators
  testJdSyntaxCustomEncapsulators = {
    expr = lib.types.check types.jdSyntax {
      idNumEncapsulator = {open = "<"; close = ">";};
      areaEncapsulator = {open = "["; close = "]";};
      categoryEncapsulator = {open = "{"; close = "}";};
    };
    expected = true;
  };

  # Test: Valid syntax with custom separators
  testJdSyntaxCustomSeparators = {
    expr = lib.types.check types.jdSyntax {
      numeralNameSep = "-";
      hierarchySep = "/";
      octetSep = ":";
      rangeSep = "..";
    };
    expected = true;
  };

  # Test: Invalid - wrong encapsulator structure
  testJdSyntaxInvalidEncapsulator = {
    expr = lib.types.check types.jdSyntax {
      idNumEncapsulator = "wrong";  # Should be {open, close}
    };
    expected = false;
  };
}
