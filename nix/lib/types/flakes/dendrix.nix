# Dendrix Flake Type
#
# Complete flake type definition for dendrix dendritic aspect-oriented configuration:
# 1. Module input structure (flake-parts flake.modules.dendrix)
# 2. Output validation (flake-schemas for dendrixModules)
#
# Based on https://vic.github.io/dendrix/

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "Dendrix dendritic aspect-oriented configuration modules";
    moduleType = types.deferredModule;
    aspectOriented = true;
    example = ''
      # Organize modules by semantic aspects
      flake.modules.dendrix.networking = { config, ... }: {
        # Networking configuration
      };

      flake.modules.dendrix.graphics = { config, ... }: {
        # Graphics/display configuration
      };

      flake.modules.dendrix.development = { config, ... }: {
        # Development environment
      };

      # Import from dendrix community distribution
      flake.modules.dendrix.neovim = inputs.dendrix.vic.home.neovim;
    '';
    schema = {
      aspects = mkOption {
        type = types.attrsOf types.deferredModule;
        description = "Aspect modules organized by semantic concern";
      };
      imports = mkOption {
        type = types.listOf (types.either types.path types.deferredModule);
        default = [];
        description = "Import-tree for repository and aspect imports";
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for dendrixModules output
    dendrixModules = {
      version = 1;
      doc = ''
        Dendrix dendritic aspect-oriented configuration modules.

        Modules are organized by aspect (semantic concern) rather than
        traditional hierarchical structure.

        Example:
          outputs.dendrixModules = {
            networking = { /* networking aspect */ };
            graphics = { /* graphics aspect */ };
            development = { /* development aspect */ };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (aspect: module: {
          what = "dendrix aspect module: ${aspect}";
          evalChecks = {
            isImportable = builtins.isFunction module || builtins.isAttrs module;
            hasValidAspectName = builtins.match "^[a-z][a-z0-9-]*$" aspect != null;
            hasModuleStructure =
              if builtins.isFunction module
              then true
              else (module ? imports || module ? exports || module ? config);
          };
        }) output;
      };
    };
  };
}
