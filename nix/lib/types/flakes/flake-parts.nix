# flake-parts Flake Type
#
# Complete flake type definition for flake-parts: the modular flake composition
# framework that other flake types build on.
#
# Based on https://flake.parts/

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "flake-parts modular flake composition modules";
    moduleType = types.deferredModule;
    example = ''
      # Generic flake-parts module
      flake.modules.generic.myModule = {
        perSystem = { config, pkgs, ... }: {
          packages.myPackage = pkgs.hello;
          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.nodejs ];
          };
        };

        flake = {
          # Flake-wide outputs
        };
      };

      # Custom module class
      flake.modules.myClass.myModule = { config, ... }: {
        # Custom module structure
      };
    '';
    schema = {
      modules = mkOption {
        type = types.attrsOf (types.attrsOf types.deferredModule);
        description = "Modules organized by class (generic, nixos, homeManager, custom classes)";
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for flakeModules output
    flakeModules = {
      version = 1;
      doc = ''
        flake-parts modules that can be imported by other flakes.

        These are reusable modules that add functionality to flake-parts-based flakes.

        Example:
          outputs.flakeModules.myModule = {
            perSystem = { config, ... }: {
              # Per-system configuration
            };
            flake = {
              # Flake-wide configuration
            };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "flake-parts module";
          evalChecks = {
            isModule = builtins.isAttrs module || builtins.isFunction module;
            hasPerSystemOrFlake =
              if builtins.isAttrs module
              then (module ? perSystem || module ? flake || module ? options)
              else true; # Functions are evaluated later
          };
        }) output;
      };
    };

    # Schema for flakeModule (singular, backwards compat)
    flakeModule = {
      version = 1;
      doc = "Singular flake-parts module (backwards compatibility with older flakes)";
      inventory = output: {
        what = "flake-parts module";
        evalChecks = {
          isModule = builtins.isAttrs output || builtins.isFunction output;
          hasStructure =
            if builtins.isAttrs output
            then (output ? perSystem || output ? flake)
            else true;
        };
      };
    };

    # Schema for the flake.modules organization
    modules = {
      version = 1;
      doc = ''
        flake-parts flake.modules organization structure.

        Modules organized by class for semantic grouping:
          flake.modules.<class>.<name> = module;

        Example:
          flake.modules = {
            nixos.myServer = { /* ... */ };
            homeManager.myConfig = { /* ... */ };
            myCustomClass.myModule = { /* ... */ };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (className: classModules: {
          what = "module class: ${className}";
          children = builtins.mapAttrs (moduleName: module: {
            what = "module: ${className}.${moduleName}";
            evalChecks = {
              isModule = builtins.isAttrs module || builtins.isFunction module;
            };
          }) classModules;
        }) output;
      };
    };
  };
}
