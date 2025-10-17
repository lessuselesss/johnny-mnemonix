# home-manager Flake Type
#
# Complete flake type definition for home-manager user environment configuration:
# 1. Module input structure (flake-parts flake.modules.homeManager)
# 2. Output validation (flake-schemas for homeModules/homeConfigurations)

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "home-manager user environment configuration modules";
    moduleType = types.deferredModule;
    example = ''
      flake.modules.homeManager.myConfig = { config, pkgs, ... }: {
        programs.git = {
          enable = true;
          userName = "user";
          userEmail = "user@example.com";
        };
      };
    '';
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for homeModules output (also homeManagerModules)
    homeModules = {
      version = 1;
      doc = ''
        home-manager modules that can be imported into user configurations.

        Example:
          outputs.homeModules.myModule = { config, pkgs, ... }: {
            # home-manager module options and config
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "home-manager module";
          evalChecks = {
            isImportable = builtins.isFunction module || builtins.isAttrs module;
            hasValidStructure =
              if builtins.isFunction module
              then true
              else (module ? options || module ? config || module ? imports);
          };
        }) output;
      };
    };

    # Alias for homeManagerModules (common alternative name)
    homeManagerModules = {
      version = 1;
      doc = "Alias for homeModules";
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "home-manager module";
          evalChecks = {
            isImportable = builtins.isFunction module || builtins.isAttrs module;
          };
        }) output;
      };
    };

    # Schema for homeConfigurations output
    homeConfigurations = {
      version = 1;
      doc = ''
        Complete home-manager user environment configurations.

        Example:
          outputs.homeConfigurations.myUser = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            modules = [ ./home.nix ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: config: {
          what = "home-manager configuration";
          evalChecks = {
            hasActivationPackage = config ? activationPackage;
            hasConfig = config ? config;
          };
        }) output;
      };
    };
  };
}
