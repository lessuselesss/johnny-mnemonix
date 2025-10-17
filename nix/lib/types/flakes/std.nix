# divnix/std Flake Type
#
# Complete flake type definition for divnix/std: cell and block structured flakes.
#
# Based on https://std.divnix.com/

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "divnix/std cell and block structured flake modules";
    moduleType = types.anything; # std uses different module structure
    cellBased = true;
    example = ''
      # Define cells and blocks via flake-parts
      flake.modules.std.lib = {
        cellBlocks = [
          (std.blockTypes.functions "primitives")
          (std.blockTypes.functions "composition")
          (std.blockTypes.functions "builders")
        ];
      };

      flake.modules.std.packages = {
        cellBlocks = [
          (std.blockTypes.installables "packages")
          (std.blockTypes.runnables "apps")
        ];
      };
    '';
    schema = {
      cells = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            cellBlocks = mkOption {
              type = types.listOf types.anything;
              description = "Block types in this cell";
            };
          };
        });
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for stdModules output
    stdModules = {
      version = 1;
      doc = ''
        divnix/std cell and block structured flake modules.

        std organizes flakes into cells (organizational units) and blocks
        (typed collections within cells).

        Example:
          outputs.stdModules = {
            lib = {
              cellBlocks = [
                (std.blockTypes.functions "primitives")
                (std.blockTypes.functions "composition")
              ];
            };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (cellName: cellConfig: {
          what = "std cell: ${cellName}";
          evalChecks = {
            isCell = builtins.isAttrs cellConfig;
            hasBlocks = cellConfig ? cellBlocks;
            blocksArelist =
              if cellConfig ? cellBlocks
              then builtins.isList cellConfig.cellBlocks
              else false;
          };
        }) output;
      };
    };

    # Alias for stdCells
    stdCells = {
      version = 1;
      doc = "Alias for stdModules (emphasizes cell structure)";
      inventory = output: {
        children = builtins.mapAttrs (name: cell: {
          what = "std cell";
          evalChecks = {
            isCell = builtins.isAttrs cell;
          };
        }) output;
      };
    };
  };
}
