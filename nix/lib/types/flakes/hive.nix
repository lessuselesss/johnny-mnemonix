# Hive Flake Type
#
# Complete flake type definition for divnix/hive: std-based NixOS deployment.
#
# Based on https://github.com/divnix/hive

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "divnix/hive NixOS deployment modules using std cell/block architecture";
    moduleType = types.deferredModule;
    example = ''
      # Define hive cells with deployment targets
      flake.modules.hive.prod = {
        # Cell: prod (production environment)
        cellBlocks = [
          "web-servers"
          "databases"
          "monitoring"
        ];

        # Block definitions
        web-servers = {
          web01 = {
            # NixOS configuration for web01
            networking.hostName = "web01";
            services.nginx.enable = true;
          };
          web02 = {
            networking.hostName = "web02";
            services.nginx.enable = true;
          };
        };

        databases = {
          db01 = {
            networking.hostName = "db01";
            services.postgresql.enable = true;
          };
        };
      };

      flake.modules.hive.staging = {
        # Cell: staging environment
        cellBlocks = [ "apps" ];

        apps = {
          app01 = {
            networking.hostName = "app01-staging";
            services.nginx.enable = true;
          };
        };
      };
    '';
    schema = {
      cells = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            cellBlocks = mkOption {
              type = types.listOf types.str;
              description = "List of block names in this cell";
            };
          };
        });
        description = "Hive deployment cells organized by environment/function";
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for hiveModules output
    hiveModules = {
      version = 1;
      doc = ''
        divnix/hive deployment modules using std cell/block architecture.

        Hive organizes NixOS deployments into cells (environments/functions)
        and blocks (groups of related hosts).

        Example:
          outputs.hiveModules = {
            prod = {
              cellBlocks = [ "web-servers" "databases" ];
              web-servers = {
                web01 = { services.nginx.enable = true; };
              };
            };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (cellName: cellConfig: {
          what = "hive cell: ${cellName}";
          evalChecks = {
            isCell = builtins.isAttrs cellConfig;
            hasCellBlocks = cellConfig ? cellBlocks;
            cellBlocksIsList =
              if cellConfig ? cellBlocks
              then builtins.isList cellConfig.cellBlocks
              else false;
            hasValidCellName =
              let match = builtins.match "[a-z][a-z0-9-]*" cellName;
              in match != null;
          };
        }) output;
      };
    };

    # Schema for complete hive output
    hive = {
      version = 1;
      doc = ''
        Complete divnix/hive deployment configuration.

        Hive uses std's cell/block architecture to organize deployments.

        Example:
          outputs.hive = {
            cells = {
              prod = { /* production cell */ };
              staging = { /* staging cell */ };
            };
            colmenaHive = { /* optional: colmena compatibility */ };
          };
      '';
      inventory = output: {
        what = "hive deployment configuration";
        evalChecks = {
          hasCells = output ? cells;
          cellsIsAttrs =
            if output ? cells
            then builtins.isAttrs output.cells
            else false;
          hasNodes =
            if output ? cells
            then builtins.length (builtins.attrNames output.cells) > 0
            else false;
        };
      };
    };
  };
}
