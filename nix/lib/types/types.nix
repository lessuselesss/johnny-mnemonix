# Types Block - Johnny Declarative Decimal
#
# divnix/std block that exports the complete type system:
# - moduleTypes: NixOS module option types for each flake class
# - flakeTypes: Complete flake type definitions (inputs + schemas)

{
  inputs,
  cell,
}: let
  inherit (inputs.nixpkgs) lib;

  # Import common JD types first
  common = import ./modules/common.nix {inherit lib;};

  # Import all module types (pure, class-specific)
  moduleTypes = {
    inherit common;
    flakeParts = import ./modules/flake-parts.nix {inherit lib;};
    nixos = import ./modules/nixos.nix {inherit lib;};
    homeManager = import ./modules/home-manager.nix {inherit lib;};
    darwin = import ./modules/darwin.nix {inherit lib;};
    dendrix = import ./modules/dendrix.nix {inherit lib;};
    systemManager = import ./modules/system-manager.nix {inherit lib;};
    typix = import ./modules/typix.nix {inherit lib;};
    jm = import ./modules/jm.nix {inherit lib common;};
    std = import ./modules/std.nix {inherit lib;};
    hive = import ./modules/hive.nix {inherit lib;};
  };

  # Import all flake types (combined inputs + schemas)
  flakeTypes = {
    flakeParts = import ./flakes/flake-parts.nix {inherit lib;};
    nixos = import ./flakes/nixos.nix {inherit lib;};
    homeManager = import ./flakes/home-manager.nix {inherit lib;};
    darwin = import ./flakes/darwin.nix {inherit lib;};
    dendrix = import ./flakes/dendrix.nix {inherit lib;};
    systemManager = import ./flakes/system-manager.nix {inherit lib;};
    typix = import ./flakes/typix.nix {inherit lib;};
    jm = import ./flakes/jm.nix {inherit lib;};
    std = import ./flakes/std.nix {inherit lib;};
    hive = import ./flakes/hive.nix {inherit lib;};
  };

  # Aggregate all flake schemas for easy export
  allSchemas = lib.foldl' (acc: flakeType:
    acc // flakeType.schemas
  ) {} (builtins.attrValues flakeTypes);

  # Aggregate all module inputs for flake-parts integration
  allModuleInputs = builtins.mapAttrs (name: flakeType:
    flakeType.moduleInput
  ) flakeTypes;

in {
  # Export module types (for use in modules/configurations)
  inherit moduleTypes;

  # Export complete flake types (inputs + schemas)
  inherit flakeTypes;

  # Convenience: All schemas in one place
  schemas = allSchemas;

  # Convenience: All module inputs in one place
  moduleInputs = allModuleInputs;

  # Helper: Get schemas by category
  schemasByCategory = {
    meta = {
      inherit (allSchemas)
        flakeModules
        flakeModule
        modules;
    };

    standard = {
      inherit (allSchemas)
        nixosModules
        nixosConfigurations
        homeModules
        homeManagerModules
        homeConfigurations
        darwinModules
        darwinConfigurations;
    };

    custom = {
      inherit (allSchemas)
        dendrixModules
        systemManagerModules
        smModules
        typixModules
        typixProjects
        jmModules
        jmConfigurations
        stdModules
        stdCells
        hiveModules
        hive;
    };
  };

  # Helper: Get module inputs by category
  moduleInputsByCategory = {
    meta = {
      inherit (allModuleInputs)
        flakeParts;
    };

    standard = {
      inherit (allModuleInputs)
        nixos
        homeManager
        darwin;
    };

    custom = {
      inherit (allModuleInputs)
        dendrix
        systemManager
        typix
        jm
        std
        hive;
    };
  };
}
