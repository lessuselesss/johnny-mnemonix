# divnix/std Module Types
#
# Pure module option types for divnix/std: cell and block structured flakes.
# Based on https://std.divnix.com/

{lib}: {
  # ===== divnix/std-Specific Types =====

  # Cell name (directory name in nix/)
  cellName = lib.types.str;

  # Block type enumeration
  blockType = lib.types.enum [
    "functions" # Pure Nix functions
    "runnables" # Executable scripts/apps
    "installables" # Packages/derivations
    "pkgs" # Package sets
    "devshells" # Development shells
    "containers" # OCI containers
    "nixago" # Nixago configurations
    "data" # Data files
    "arion" # Arion compose
  ];

  # Cell block definition
  cellBlock = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Block name (e.g., 'primitives', 'composition')";
      };

      type = lib.mkOption {
        type = lib.types.enum [
          "functions"
          "runnables"
          "installables"
          "pkgs"
          "devshells"
          "containers"
          "nixago"
          "data"
          "arion"
        ];
        description = "Block type";
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description";
      };
    };
  };

  # Complete std cell definition
  stdCell = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Cell name (directory in nix/)";
      };

      blocks = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            type = lib.mkOption {
              type = lib.types.enum [
                "functions" "runnables" "installables" "pkgs"
                "devshells" "containers" "nixago" "data" "arion"
              ];
            };
            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        });
        description = "Blocks within this cell";
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description of this cell";
      };
    };
  };

  # std growOn configuration
  growOnConfig = lib.types.submodule {
    options = {
      cellsFrom = lib.mkOption {
        type = lib.types.path;
        default = ./nix;
        description = "Directory containing cells";
      };

      cellBlocks = lib.mkOption {
        type = lib.types.listOf lib.types.anything;
        description = "List of block type definitions";
      };
    };
  };

  # std harvest configuration
  harvestConfig = lib.types.submodule {
    options = {
      cells = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        description = "Cells to harvest outputs from";
      };

      harvests = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            cell = lib.mkOption { type = lib.types.str; };
            block = lib.mkOption { type = lib.types.str; };
            renamer = lib.mkOption {
              type = lib.types.nullOr (lib.types.functionTo lib.types.str);
              default = null;
            };
          };
        });
        description = "Harvest definitions";
      };
    };
  };
}
