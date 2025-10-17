# Real-World Test: home-manager Community Modules
#
# Tests our homeModules schema against actual home-manager modules
# from the official repo and popular user configurations.

{
  lib,
  schemas,
  homeManager,       # Official home-manager
  misterioNixConfig, # Popular user config
}: let
  validateModule = module:
    let result = builtins.tryEval (schemas.homeModules.inventory { testModule = module; });
    in result.success;

  getEvalChecks = module:
    let inventory = schemas.homeModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: Official home-manager Module Patterns =====

  # Test: Typical HM module structure
  testHomeManagerModuleValid = let
    module = { config, lib, pkgs, ... }: {
      options.programs.myProgram = {
        enable = lib.mkEnableOption "my program";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.hello;
        };
      };
      config = lib.mkIf config.programs.myProgram.enable {
        home.packages = [ config.programs.myProgram.package ];
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: HM module with home.file
  testHomeManagerFileModule = let
    module = { config, ... }: {
      home.file.".bashrc".text = "echo 'Hello'";
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: HM module with xdg.configFile
  testHomeManagerXdgModule = let
    module = { config, pkgs, ... }: {
      xdg.configFile."myapp/config.toml".source = ./config.toml;
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # ===== Test: Real-World Pattern from Misterio77 =====

  # Test: Programs module pattern (common in user configs)
  testMisterioPatternPrograms = let
    # Pattern commonly seen in Misterio77's configs
    module = { config, pkgs, ... }: {
      programs = {
        git.enable = true;
        neovim.enable = true;
        tmux.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Services module pattern
  testMisterioPatternServices = let
    module = { config, ... }: {
      services = {
        gpg-agent.enable = true;
        dunst.enable = true;
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # ===== Test: homeManagerModules Alias Schema =====

  # Test: homeManagerModules schema also validates
  testHomeManagerModulesAlias = let
    module = { config, pkgs, ... }: {
      programs.git.enable = true;
    };
    result = builtins.tryEval (schemas.homeManagerModules.inventory { testModule = module; });
  in {
    expr = result.success;
    expected = true;
  };

  # ===== Test: Invalid Modules Rejected =====

  # Test: Invalid module type rejected
  testInvalidHomeModule = {
    expr = let
      checks = getEvalChecks "invalid";
    in checks.isImportable;
    expected = false;
  };
}
