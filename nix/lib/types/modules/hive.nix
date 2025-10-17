# Hive Module Types
#
# Pure module option types for divnix/hive: std-based NixOS deployment.
# Based on https://github.com/divnix/hive

{lib}: {
  # ===== Hive-Specific Types (std-based) =====

  # Hive cell (environment or functional grouping)
  hiveCell = lib.types.submodule {
    options = {
      cellBlocks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of block names in this cell";
        example = [ "web-servers" "databases" "monitoring" ];
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description of this cell";
      };

      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Tags for categorizing cells (e.g., production, staging)";
      };
    };
  };

  # Hive block (group of related hosts)
  hiveBlock = lib.types.attrsOf (lib.types.submodule {
    options = {
      # Standard NixOS options are available here
      networking = lib.mkOption {
        type = lib.types.submodule {
          options = {
            hostName = lib.mkOption {
              type = lib.types.str;
              description = "Host name";
            };
          };
        };
        description = "Networking configuration";
      };

      deployment = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            targetHost = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "SSH hostname or IP address";
            };

            targetPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              description = "SSH port";
            };

            targetUser = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "SSH user";
            };
          };
        });
        default = null;
        description = "Optional deployment configuration";
      };

      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Tags for categorizing hosts";
      };
    };
  });

  # Complete Hive configuration
  hiveConfig = lib.types.submodule {
    options = {
      cells = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;  # Each cell contains blocks
        description = "Hive cells organized by environment/function";
      };

      meta = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            nixpkgs = lib.mkOption {
              type = lib.types.raw;
              description = "Nixpkgs instance";
            };

            specialArgs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
              description = "Extra arguments passed to all hosts";
            };
          };
        });
        default = null;
        description = "Optional meta configuration";
      };
    };
  };

  # Cell name (follows std naming convention)
  hiveCellName = lib.types.strMatching "[a-z][a-z0-9-]*";

  # Block name (follows std naming convention)
  hiveBlockName = lib.types.strMatching "[a-z][a-z0-9-]*";

  # Deployment tag for selective deployments
  deploymentTag = lib.types.str;
}
