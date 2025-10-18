# Unit Tests: Numeral-Name Patterns
#
# Tests the numeral-name pattern primitives from lib/primitives/numeral-name-patterns.nix
#
# TDD: These tests define the expected behavior of pattern formatting

{lib}: let
  patterns = lib.primitives.numeralNamePatterns;
in {
  # ===== Pre-built Pattern Tests =====

  # Test: Standard pattern (space-separated, natural case)
  testPatternStandardFormat = {
    expr = patterns.patterns.standard.format {
      numeral = "10";
      name = "Projects";
    };
    expected = "10 Projects";
  };

  # Test: Kebab pattern (dash-separated, lowercase)
  testPatternKebabFormat = {
    expr = patterns.patterns.kebab.format {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "10-web-projects";
  };

  # Test: Snake pattern (underscore-separated, lowercase)
  testPatternSnakeFormat = {
    expr = patterns.patterns.snake.format {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "10_web_projects";
  };

  # Test: Dotted pattern (dot-separated, lowercase)
  testPatternDottedFormat = {
    expr = patterns.patterns.dotted.format {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "10.web-projects";
  };

  # Test: Screaming snake case
  testPatternScreamingFormat = {
    expr = patterns.patterns.screaming.format {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "10_WEB_PROJECTS";
  };

  # Test: Compact pattern (no separator, lowercase)
  testPatternCompactFormat = {
    expr = patterns.patterns.compact.format {
      numeral = "10";
      name = "Projects";
    };
    expected = "10projects";
  };

  # Test: Pascal name-first pattern
  testPatternPascalNameFirstFormat = {
    expr = patterns.patterns.pascalNameFirst.format {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "WebProjects10";
  };

  # Test: Reverse pattern (name-first, space)
  testPatternReverseFormat = {
    expr = patterns.patterns.reverse.format {
      numeral = "10";
      name = "Projects";
    };
    expected = "Projects 10";
  };

  # ===== Case Transformation Tests =====

  # Test: kebab-case transformation
  testCasingKebab = {
    expr = patterns.casing.kebab "Web Projects API";
    expected = "web-projects-api";
  };

  # Test: snake_case transformation
  testCasingSnake = {
    expr = patterns.casing.snake "Web Projects API";
    expected = "web_projects_api";
  };

  # Test: PascalCase transformation
  testCasingPascal = {
    expr = patterns.casing.pascal "web projects api";
    expected = "WebProjectsApi";
  };

  # Test: camelCase transformation
  testCasingCamel = {
    expr = patterns.casing.camel "web projects api";
    expected = "webProjectsApi";
  };

  # Test: SCREAMING_SNAKE_CASE transformation
  testCasingScreamingSnake = {
    expr = patterns.casing.screamingSnake "web projects api";
    expected = "WEB_PROJECTS_API";
  };

  # ===== Custom Pattern Tests =====

  # Test: Custom pattern with custom separator
  testCustomPatternCustomSeparator = {
    expr = let
      customPattern = patterns.mkPattern {
        separator = "::";
        order = patterns.ordering.numeralFirst;
        nameCase = patterns.casing.pascal;
      };
    in customPattern.format {
      numeral = "10";
      name = "web projects";
    };
    expected = "10::WebProjects";
  };

  # Test: Custom pattern with name-first ordering
  testCustomPatternNameFirst = {
    expr = let
      customPattern = patterns.mkPattern {
        separator = "-";
        order = patterns.ordering.nameFirst;
        nameCase = patterns.casing.lower;
      };
    in customPattern.format {
      numeral = "10";
      name = "Projects";
    };
    expected = "projects-10";
  };

  # Test: Custom transformation function
  testCustomTransform = {
    expr = let
      # Custom: add prefix "jd_" to name
      customPattern = patterns.mkCustomPattern {
        separator = "_";
        transform = name: "jd_" + (patterns.casing.lower name);
      };
    in customPattern.format {
      numeral = "10";
      name = "Projects";
    };
    expected = "10_jd_projects";
  };

  # ===== Parsing Tests =====

  # Test: Parse standard pattern
  testParseStandard = {
    expr = patterns.patterns.standard.parse "10 Projects";
    expected = {
      numeral = "10";
      name = "Projects";
    };
  };

  # Test: Parse kebab pattern
  testParseKebab = {
    expr = patterns.patterns.kebab.parse "10-web-projects";
    expected = {
      numeral = "10";
      name = "web-projects";
    };
  };

  # Test: Parse name-first pattern
  testParseReverse = {
    expr = patterns.patterns.reverse.parse "Projects 10";
    expected = {
      numeral = "10";
      name = "Projects";
    };
  };

  # Test: Parse fails on invalid input
  testParseInvalid = {
    expr = patterns.patterns.standard.parse "NoNumbersHere";
    expected = null;
  };

  # ===== Contextual Pattern Tests =====

  # Test: Different patterns per level
  testContextualPattern = {
    expr = let
      ctx = patterns.mkContextualPattern {
        areaPattern = patterns.patterns.standard; # "10-19 Projects"
        categoryPattern = patterns.patterns.kebab; # "10-code"
        itemPattern = patterns.patterns.snake; # "10_web_app"
      };
    in {
      area = ctx.formatArea {numeral = "10-19"; name = "Projects";};
      category = ctx.formatCategory {numeral = "10"; name = "Code Projects";};
      item = ctx.formatItem {numeral = "01"; name = "Web App";};
    };
    expected = {
      area = "10-19 Projects";
      category = "10-code-projects";
      item = "01_web_app";
    };
  };

  # ===== Transformation Tests =====

  # Test: Transform from one pattern to another
  testTransformPatterns = {
    expr = patterns.transform {
      from = patterns.patterns.standard;
      to = patterns.patterns.kebab;
      str = "10 Web Projects";
    };
    expected = "10-web-projects";
  };

  # Test: Transform with parse failure returns null
  testTransformInvalidInput = {
    expr = patterns.transform {
      from = patterns.patterns.standard;
      to = patterns.patterns.kebab;
      str = "NoNumbers";
    };
    expected = null;
  };

  # ===== Validation Tests =====

  # Test: Validate correct format
  testValidateCorrect = {
    expr = patterns.validate patterns.patterns.kebab "10-projects";
    expected = true;
  };

  # Test: Validate incorrect format
  testValidateIncorrect = {
    expr = patterns.validate patterns.patterns.kebab "NoNumber";
    expected = false;
  };

  # ===== Convenience Function Tests =====

  # Test: Format by name
  testFormatByName = {
    expr = patterns.format "kebab" {
      numeral = "10";
      name = "Web Projects";
    };
    expected = "10-web-projects";
  };

  # Test: Parse by name
  testParseByName = {
    expr = patterns.parse "standard" "10 Projects";
    expected = {
      numeral = "10";
      name = "Projects";
    };
  };

  # ===== Composed Pattern Tests =====

  # Test: Compose multiple patterns (try each in order)
  testComposedPatternParsing = {
    expr = let
      composed = patterns.composePatterns [
        patterns.patterns.kebab
        patterns.patterns.snake
        patterns.patterns.standard
      ];
    in {
      # Should match first pattern
      kebab = composed.parse "10-projects";
      # Should match second pattern
      snake = composed.parse "10_projects";
      # Should match third pattern
      standard = composed.parse "10 Projects";
    };
    expected = {
      kebab = {numeral = "10"; name = "projects";};
      snake = {numeral = "10"; name = "projects";};
      standard = {numeral = "10"; name = "Projects";};
    };
  };

  # ===== Real-World Usage Tests =====

  # Test: Full Johnny Decimal ID formatting
  testRealWorldJohnnyDecimalID = {
    expr = let
      idPattern = patterns.mkPattern {
        separator = ".";
        order = patterns.ordering.numeralFirst;
        nameCase = patterns.casing.kebab;
      };
    in {
      simple = idPattern.format {numeral = "10.01"; name = "Web App";};
      complex = idPattern.format {numeral = "10.01"; name = "Web Application Server";};
    };
    expected = {
      simple = "10.01.web-app";
      complex = "10.01.web-application-server";
    };
  };

  # Test: Directory name formatting
  testRealWorldDirectoryNames = {
    expr = {
      linux = patterns.format "kebab" {numeral = "10"; name = "Web Projects";};
      windows = patterns.format "standard" {numeral = "10"; name = "Web Projects";};
      programmatic = patterns.format "snake" {numeral = "10"; name = "Web Projects";};
    };
    expected = {
      linux = "10-web-projects";
      windows = "10 Web Projects";
      programmatic = "10_web_projects";
    };
  };

  # Test: Variable name generation
  testRealWorldVariableNames = {
    expr = {
      constant = patterns.patterns.screaming.format {numeral = "10"; name = "max retries";};
      class = patterns.patterns.pascalNameFirst.format {numeral = "10"; name = "http client";};
      function = patterns.mkPattern {
        separator = "_";
        order = patterns.ordering.nameFirst;
        nameCase = patterns.casing.snake;
      } .format {numeral = "10"; name = "process request";};
    };
    expected = {
      constant = "10_MAX_RETRIES";
      class = "HttpClient10";
      function = "process_request_10";
    };
  };
}
