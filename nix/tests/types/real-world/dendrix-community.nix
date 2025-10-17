# Real-World Test: Dendrix Community Modules
#
# Tests our dendrixModules schema against actual dendrix aspect-oriented
# modules from vic/dendrix.
#
# Dendrix: Dendritic aspect-oriented configuration
# See: https://vic.github.io/dendrix

{
  lib,
  schemas,
  dendrix,  # From fixtures/community-flakes.nix
}: let
  # Helper: Validate module with schema
  validateModule = module:
    let
      result = builtins.tryEval (schemas.dendrixModules.inventory { testModule = module; });
    in result.success;

  # Helper: Get evalChecks for a module
  getEvalChecks = module:
    let inventory = schemas.dendrixModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: Dendrix Aspect Module Structure =====

  # Test: Aspect with imports and exports
  testDendrixAspectModuleValid = let
    module = {
      imports = [];
      exports = {
        services.nginx.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Aspect module is importable
  testDendrixAspectIsImportable = let
    module = {
      imports = [];
      exports = {};
    };
    checks = getEvalChecks module;
  in {
    expr = checks.isImportable;
    expected = true;
  };

  # ===== Test: Aspect Naming Conventions =====

  # Test: Valid aspect name (lowercase-hyphen)
  testDendrixValidAspectName = let
    aspectName = "web-server";
    checks = schemas.dendrixModules.inventory { "${aspectName}" = {}; };
  in {
    expr = checks.children."${aspectName}".evalChecks.hasValidAspectName;
    expected = true;
  };

  # Test: Invalid aspect name (PascalCase)
  testDendrixInvalidAspectNamePascal = let
    aspectName = "WebServer";
    checks = schemas.dendrixModules.inventory { "${aspectName}" = {}; };
  in {
    expr = checks.children."${aspectName}".evalChecks.hasValidAspectName;
    expected = false;
  };

  # Test: Invalid aspect name (snake_case)
  testDendrixInvalidAspectNameSnake = let
    aspectName = "web_server";
    checks = schemas.dendrixModules.inventory { "${aspectName}" = {}; };
  in {
    expr = checks.children."${aspectName}".evalChecks.hasValidAspectName;
    expected = false;
  };

  # ===== Test: Aspect Module Patterns =====

  # Test: Aspect with repository imports
  testDendrixAspectWithRepoImports = let
    module = {
      imports = [
        { repository = "base"; aspect = "networking"; }
        { repository = "desktop"; aspect = "graphics"; }
      ];
      exports = {
        networking.firewall.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Aspect with nested exports
  testDendrixAspectNestedExports = let
    module = {
      imports = [];
      exports = {
        programs.git = {
          enable = true;
          userName = "user";
          userEmail = "user@example.com";
        };
        services.gpg-agent.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Aspect with conditional exports
  testDendrixAspectConditionalExports = let
    module = {
      imports = [];
      exports = {
        programs.neovim.enable = true;
      };
      conditions = {
        isWorkstation = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # ===== Test: Invalid Aspects Rejected =====

  # Test: String is not a valid aspect
  testDendrixInvalidStringAspect = {
    expr = let
      checks = getEvalChecks "not an aspect";
    in checks.isImportable;
    expected = false;
  };

  # Test: Number is not a valid aspect
  testDendrixInvalidNumberAspect = {
    expr = let
      checks = getEvalChecks 42;
    in checks.isImportable;
    expected = false;
  };

  # Test: Aspect without imports or exports
  testDendrixInvalidEmptyAspect = {
    expr = let
      module = { foo = "bar"; };
      checks = getEvalChecks module;
    in checks.hasValidStructure;
    expected = false;
  };

  # ===== Test: Common Dendrix Patterns =====

  # Test: Networking aspect pattern
  testDendrixNetworkingAspect = let
    module = {
      imports = [];
      exports = {
        networking = {
          networkmanager.enable = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [ 22 80 443 ];
          };
        };
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Graphics aspect pattern
  testDendrixGraphicsAspect = let
    module = {
      imports = [];
      exports = {
        services.xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Development aspect pattern
  testDendrixDevelopmentAspect = let
    module = {
      imports = [
        { repository = "base"; aspect = "git"; }
      ];
      exports = {
        programs.vscode.enable = true;
        programs.neovim.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # ===== Test: Aspect Composition =====

  # Test: Multiple aspects compose correctly
  testDendrixMultipleAspects = let
    outputs = {
      networking = {
        imports = [];
        exports = { networking.networkmanager.enable = true; };
      };
      graphics = {
        imports = [];
        exports = { services.xserver.enable = true; };
      };
      development = {
        imports = [
          { repository = "base"; aspect = "networking"; }
        ];
        exports = { programs.git.enable = true; };
      };
    };
    result = builtins.tryEval (schemas.dendrixModules.inventory outputs);
  in {
    expr = result.success;
    expected = true;
  };

  # Test: All aspects have valid names
  testDendrixMultipleAspectsNaming = let
    outputs = {
      "web-server" = { imports = []; exports = {}; };
      "database-server" = { imports = []; exports = {}; };
      "monitoring-agent" = { imports = []; exports = {}; };
    };
    inventory = schemas.dendrixModules.inventory outputs;
    checks = builtins.mapAttrs (name: child: child.evalChecks.hasValidAspectName) inventory.children;
  in {
    expr = builtins.all (check: check == true) (builtins.attrValues checks);
    expected = true;
  };
}
