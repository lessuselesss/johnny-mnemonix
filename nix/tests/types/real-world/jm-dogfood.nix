# Real-World Test: Johnny-Mnemonix Dogfooding
#
# Tests that our own johnny-mnemonix configuration modules validate
# correctly against the jmModules schema we've defined.
#
# This is critical dogfooding - we must practice what we preach!

{
  lib,
  schemas,
  self,  # Our own flake
}: let
  # Helper: Validate module with schema
  validateModule = module:
    let
      result = builtins.tryEval (schemas.jmModules.inventory { testModule = module; });
    in result.success;

  # Helper: Get evalChecks for a module
  getEvalChecks = module:
    let inventory = schemas.jmModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: Our Own Configuration Modules =====

  # Test: Basic JM workspace configuration validates
  testJMDogfoodBasicWorkspace = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {
            "10" = {
              name = "Code";
              items = {
                "10.01" = "Website";
                "10.02" = "CLI-Tool";
              };
            };
          };
        };
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # Test: Workspace has valid JD structure
  testJMDogfoodValidJDStructure = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {};
        };
      };
    };
    checks = getEvalChecks workspace;
  in {
    expr = {
      hasBaseDir = checks.hasBaseDir;
      hasAreas = checks.hasAreas;
      areasAreValid = checks.areasAreValid;
    };
    expected = {
      hasBaseDir = true;
      hasAreas = true;
      areasAreValid = true;
    };
  };

  # ===== Test: Johnny Decimal Filename Pattern =====

  # Test: JD filename pattern matches
  testJMDogfoodJDFilename = let
    moduleName = "[10.05]{10-19 Projects}__(10 Code)__[05 Library]";
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {};
    };
    inventory = schemas.jmModules.inventory { "${moduleName}" = workspace; };
    checks = inventory.children."${moduleName}".evalChecks;
  in {
    expr = checks.hasJDFilename;
    expected = true;
  };

  # Test: Non-JD filename doesn't match
  testJMDogfoodNonJDFilename = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {};
    };
    inventory = schemas.jmModules.inventory { "workspace" = workspace; };
    checks = inventory.children.workspace.evalChecks;
  in {
    expr = checks.hasJDFilename;
    expected = false;
  };

  # ===== Test: Our Config Module Structure =====

  # Test: Config module with all features
  testJMDogfoodFullConfig = let
    config = {
      baseDir = "/home/user/Deterministic Workspace";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {
            "10" = {
              name = "Code";
              items = {
                "10.01" = {
                  name = "Website";
                  url = "git@github.com:user/website.git";
                  ref = "main";
                };
                "10.02" = {
                  name = "CLI-Tool";
                  target = "/mnt/storage/projects/cli-tool";
                };
              };
            };
          };
        };
      };
      syntax = {
        idNumEncapsulator = { open = "["; close = "]"; };
        areaEncapsulator = { open = "{"; close = "}"; };
        categoryEncapsulator = { open = "("; close = ")"; };
      };
      spacer = " ";
      index = {
        enable = true;
        format = "md";
        enhanced = true;
      };
      typix = {
        enable = true;
        autoCompileOnActivation = true;
      };
    };
  in {
    expr = validateModule config;
    expected = true;
  };

  # ===== Test: Git Integration =====

  # Test: Item with git URL
  testJMDogfoodGitItem = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {
            "10" = {
              name = "Code";
              items = {
                "10.01" = {
                  name = "MyRepo";
                  url = "git@github.com:user/repo.git";
                  ref = "develop";
                  sparse = [ "docs/" "src/" ];
                };
              };
            };
          };
        };
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # Test: Item with git + symlink combination
  testJMDogfoodGitSymlink = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {
            "10" = {
              name = "Code";
              items = {
                "10.01" = {
                  name = "BigRepo";
                  url = "git@github.com:user/big-repo.git";
                  target = "/mnt/storage/repos/big-repo";
                };
              };
            };
          };
        };
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # ===== Test: Syntax Customization =====

  # Test: Custom syntax configuration
  testJMDogfoodCustomSyntax = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {};
      syntax = {
        idNumEncapsulator = { open = "<"; close = ">"; };
        areaEncapsulator = { open = "["; close = "]"; };
        categoryEncapsulator = { open = "{"; close = "}"; };
        idNameSeparator = " - ";
        hierarchySeparators = { area = " / "; category = " / "; };
        octetSeparator = ":";
        rangeSeparator = "..";
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # ===== Test: Index & Typix Integration =====

  # Test: Index configuration
  testJMDogfoodIndexConfig = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {};
      index = {
        enable = true;
        format = "pdf";
        enhanced = true;
        watch = {
          enable = true;
          interval = 2;
        };
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # Test: Typix configuration
  testJMDogfoodTypixConfig = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {};
      typix = {
        enable = true;
        autoCompileOnActivation = true;
        watch = {
          enable = true;
          interval = 5;
        };
      };
    };
  in {
    expr = validateModule workspace;
    expected = true;
  };

  # ===== Test: Multiple Workspaces =====

  # Test: Multiple workspace configurations
  testJMDogfoodMultipleWorkspaces = let
    outputs = {
      personal = {
        baseDir = "/home/user/Personal";
        areas = {
          "10-19" = { name = "Life"; categories = {}; };
        };
      };
      work = {
        baseDir = "/home/user/Work";
        areas = {
          "20-29" = { name = "Projects"; categories = {}; };
        };
      };
    };
    result = builtins.tryEval (schemas.jmModules.inventory outputs);
  in {
    expr = result.success;
    expected = true;
  };

  # ===== Test: Invalid Configurations Rejected =====

  # Test: Invalid area range format
  testJMDogfoodInvalidAreaRange = {
    expr = let
      workspace = {
        baseDir = "/home/user/Documents";
        areas = {
          "invalid" = {  # Should be XX-YY format
            name = "Bad";
            categories = {};
          };
        };
      };
      checks = getEvalChecks workspace;
    in checks.areasAreValid;
    expected = false;
  };

  # Test: Missing baseDir
  testJMDogfoodMissingBaseDir = {
    expr = let
      workspace = {
        areas = {
          "10-19" = { name = "Projects"; categories = {}; };
        };
      };
      checks = getEvalChecks workspace;
    in checks.hasBaseDir;
    expected = false;
  };

  # Test: String is not a valid config
  testJMDogfoodInvalidString = {
    expr = let
      checks = getEvalChecks "not a config";
    in checks.hasBaseDir && checks.hasAreas;
    expected = false;
  };

  # ===== Test: jmConfigurations Alias =====

  # Test: jmConfigurations schema validates same content
  testJMDogfoodConfigurationsAlias = let
    workspace = {
      baseDir = "/home/user/Documents";
      areas = {
        "10-19" = { name = "Projects"; categories = {}; };
      };
    };
    result = builtins.tryEval (schemas.jmConfigurations.inventory { workspace = workspace; });
  in {
    expr = result.success;
    expected = true;
  };
}
