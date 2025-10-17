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
  common = import ./module-types/common.nix {inherit lib;};

  # Import all module types (pure, class-specific)
  moduleTypes = {
    inherit common;
    flakeParts = import ./module-types/flake-parts.nix {inherit lib;};
    nixos = import ./module-types/nixos.nix {inherit lib;};
    homeManager = import ./module-types/home-manager.nix {inherit lib;};
    darwin = import ./module-types/nix-darwin.nix {inherit lib;};
    dendrix = import ./module-types/dendrix.nix {inherit lib;};
    systemManager = import ./module-types/system-manager.nix {inherit lib;};
    typix = import ./module-types/typix.nix {inherit lib;};
    jm = import ./module-types/jm.nix {inherit lib common;};
    std = import ./module-types/std.nix {inherit lib;};
    hive = import ./module-types/hive.nix {inherit lib;};
  };

  # Import all flake types (combined inputs + schemas)
  flakeTypes = {
    flakeParts = import ./flake-types/flake-parts.nix {inherit lib;};
    nixos = import ./flake-types/nixos.nix {inherit lib;};
    homeManager = import ./flake-types/home-manager.nix {inherit lib;};
    darwin = import ./flake-types/darwin.nix {inherit lib;};
    dendrix = import ./flake-types/dendrix.nix {inherit lib;};
    systemManager = import ./flake-types/system-manager.nix {inherit lib;};
    typix = import ./flake-types/typix.nix {inherit lib;};
    jm = import ./flake-types/jm.nix {inherit lib;};
    std = import ./flake-types/std.nix {inherit lib;};
    hive = import ./flake-types/hive.nix {inherit lib;};
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
