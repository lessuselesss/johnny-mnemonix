# Real-World Test: NixOS Community Modules
#
# Tests our nixosModules schema against actual community NixOS modules
# from nixpkgs and popular community projects.

{
  lib,
  schemas,
  nixpkgs,      # From fixtures/community-flakes.nix
  impermanence, # Popular nixosModule
}: let
  # Helper: Validate module with schema
  validateModule = module:
    let
      result = builtins.tryEval (schemas.nixosModules.inventory { testModule = module; });
    in result.success;

  # Helper: Get evalChecks for a module
  getEvalChecks = module:
    let inventory = schemas.nixosModules.inventory { testModule = module; };
    in inventory.children.testModule.evalChecks;

in {
  # ===== Test: impermanence Module =====

  # Test: impermanence module validates correctly
  testImpermanenceModuleValid = {
    expr = validateModule impermanence.nixosModules.impermanence;
    expected = true;
  };

  # Test: impermanence module is importable
  testImpermanenceIsImportable = {
    expr = (getEvalChecks impermanence.nixosModules.impermanence).isImportable;
    expected = true;
  };

  # ===== Test: Sample nixpkgs Module Structure =====

  # Test: Function-based module (most common in nixpkgs)
  testNixpkgsFunctionModule = let
    # Typical nixpkgs module structure
    module = { config, lib, pkgs, ... }: {
      options = {
        services.myService.enable = lib.mkEnableOption "my service";
      };
      config = lib.mkIf config.services.myService.enable {
        systemd.services.myService = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.hello}/bin/hello";
          };
        };
      };
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Attrs-based module with options
  testNixpkgsAttrsModule = let
    module = {
      options = {};
      config = {};
      imports = [];
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # Test: Module with meta attribute
  testNixpkgsModuleWithMeta = let
    module = { config, lib, pkgs, ... }: {
      meta.maintainers = [ ];
      options = {};
      config = {};
    };
  in {
    expr = validateModule module;
    expected = true;
  };

  # ===== Test: Invalid Modules Rejected =====

  # Test: String is not a valid module
  testInvalidStringModule = {
    expr = let
      checks = getEvalChecks "not a module";
    in checks.isImportable;
    expected = false;
  };

  # Test: Number is not a valid module
  testInvalidNumberModule = {
    expr = let
      checks = getEvalChecks 42;
    in checks.isImportable;
    expected = false;
  };

  # Test: Attrs without options/config/imports fails structure check
  testInvalidAttrsModule = {
    expr = let
      module = { foo = "bar"; };
      checks = getEvalChecks module;
    in checks.hasValidStructure;
    expected = false;
  };
}
