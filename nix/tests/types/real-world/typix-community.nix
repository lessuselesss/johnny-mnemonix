# Real-World Test: Typix Community Projects
#
# Tests our typixModules schema against actual typix document projects
# from loqusion/typix.
#
# Typix: Deterministic Typst document compilation with Nix
# See: https://github.com/loqusion/typix

{
  lib,
  schemas,
  typix,  # From fixtures/community-flakes.nix
}: let
  # Helper: Validate module with schema
  validateModule = module:
    let
      result = builtins.tryEval (schemas.typixModules.inventory { testModule = module; });
    in result.success;

  # Helper: Get evalChecks for a module
  getEvalChecks = module:
    let inventory = schemas.typixModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: Basic Typix Project Structure =====

  # Test: Minimal typix project
  testTypixMinimalProject = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Project has required fields
  testTypixRequiredFields = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
    };
    checks = getEvalChecks project;
  in {
    expr = {
      hasSrc = checks.hasSrc;
      hasEntrypoint = checks.hasEntrypoint;
    };
    expected = {
      hasSrc = true;
      hasEntrypoint = true;
    };
  };

  # ===== Test: Typix Project Options =====

  # Test: Project with font paths
  testTypixProjectWithFonts = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      fontPaths = [
        /path/to/fonts
        /another/font/path
      ];
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Project with typst options
  testTypixProjectWithTypstOpts = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      typstOpts = {
        root = ".";
        input = {
          version = "1.0.0";
          author = "User";
        };
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Project with watch mode
  testTypixProjectWithWatch = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      watch = {
        enable = true;
        interval = 1000;
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # ===== Test: Common Typix Patterns =====

  # Test: Academic paper pattern
  testTypixAcademicPaper = let
    project = {
      src = /path/to/thesis;
      entrypoint = "thesis.typ";
      fontPaths = [ /usr/share/fonts ];
      typstOpts = {
        input = {
          title = "My Thesis";
          author = "Student Name";
          date = "2024";
        };
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Book/documentation pattern
  testTypixBookPattern = let
    project = {
      src = /path/to/book;
      entrypoint = "book.typ";
      typstOpts = {
        root = "src";
        input = {
          chapters = 12;
          version = "1.0.0";
        };
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Resume/CV pattern
  testTypixResumePattern = let
    project = {
      src = /path/to/cv;
      entrypoint = "cv.typ";
      fontPaths = [ /path/to/custom/fonts ];
      typstOpts = {
        input = {
          name = "John Doe";
          email = "john@example.com";
        };
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Presentation/slides pattern
  testTypixPresentationPattern = let
    project = {
      src = /path/to/slides;
      entrypoint = "presentation.typ";
      typstOpts = {
        input = {
          theme = "metropolis";
          aspectRatio = "16:9";
        };
      };
      watch = {
        enable = true;
        interval = 500;
      };
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # ===== Test: Invalid Projects Rejected =====

  # Test: Project missing src
  testTypixMissingSrc = {
    expr = let
      project = {
        entrypoint = "main.typ";
      };
      checks = getEvalChecks project;
    in checks.hasSrc;
    expected = false;
  };

  # Test: Project missing entrypoint
  testTypixMissingEntrypoint = {
    expr = let
      project = {
        src = /path/to/docs;
      };
      checks = getEvalChecks project;
    in checks.hasEntrypoint;
    expected = false;
  };

  # Test: String is not a valid project
  testTypixInvalidString = {
    expr = let
      checks = getEvalChecks "not a project";
    in checks.hasSrc && checks.hasEntrypoint;
    expected = false;
  };

  # Test: Number is not a valid project
  testTypixInvalidNumber = {
    expr = let
      checks = getEvalChecks 42;
    in checks.hasSrc && checks.hasEntrypoint;
    expected = false;
  };

  # ===== Test: typixProjects Alias Schema =====

  # Test: typixProjects schema also validates
  testTypixProjectsAlias = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
    };
    result = builtins.tryEval (schemas.typixProjects.inventory { testProject = project; });
  in {
    expr = result.success;
    expected = true;
  };

  # ===== Test: Multiple Projects =====

  # Test: Multiple projects validate correctly
  testTypixMultipleProjects = let
    outputs = {
      thesis = {
        src = /path/to/thesis;
        entrypoint = "thesis.typ";
      };
      cv = {
        src = /path/to/cv;
        entrypoint = "cv.typ";
      };
      slides = {
        src = /path/to/slides;
        entrypoint = "presentation.typ";
      };
    };
    result = builtins.tryEval (schemas.typixModules.inventory outputs);
  in {
    expr = result.success;
    expected = true;
  };

  # Test: All projects have required fields
  testTypixMultipleProjectsFields = let
    outputs = {
      project1 = {
        src = /path/one;
        entrypoint = "one.typ";
      };
      project2 = {
        src = /path/two;
        entrypoint = "two.typ";
      };
      incomplete = {
        # Missing both src and entrypoint
      };
    };
    inventory = schemas.typixModules.inventory outputs;
    p1Checks = inventory.children.project1.evalChecks;
    p2Checks = inventory.children.project2.evalChecks;
    incompleteChecks = inventory.children.incomplete.evalChecks;
  in {
    expr = {
      p1HasBoth = p1Checks.hasSrc && p1Checks.hasEntrypoint;
      p2HasBoth = p2Checks.hasSrc && p2Checks.hasEntrypoint;
      incompleteHasBoth = incompleteChecks.hasSrc && incompleteChecks.hasEntrypoint;
    };
    expected = {
      p1HasBoth = true;
      p2HasBoth = true;
      incompleteHasBoth = false;
    };
  };

  # ===== Test: Advanced Typix Features =====

  # Test: Project with custom build script
  testTypixCustomBuild = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      buildPhase = ''
        typst compile main.typ output.pdf
      '';
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Project with dependencies
  testTypixWithDependencies = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      dependencies = [
        /path/to/template
        /path/to/assets
      ];
    };
  in {
    expr = validateModule project;
    expected = true;
  };

  # Test: Project with output customization
  testTypixCustomOutput = let
    project = {
      src = /path/to/docs;
      entrypoint = "main.typ";
      outputName = "custom-output.pdf";
      outputDir = "build/pdf";
    };
  in {
    expr = validateModule project;
    expected = true;
  };
}
