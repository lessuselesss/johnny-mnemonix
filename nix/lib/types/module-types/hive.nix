# Hive/Colmena Module Types
#
# Pure module option types for Hive (divnix Colmena): NixOS deployment tool.
# Based on https://colmena.cli.rs/ and divnix/hive

{lib}: {
  # ===== Hive/Colmena-Specific Types =====

  # Deployment node configuration
  hiveNode = lib.types.submodule {
    options = {
      deployment = lib.mkOption {
        type = lib.types.submodule {
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

            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Tags for selective deployment";
            };

            keys = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  text = lib.mkOption {
                    type = lib.types.str;
                    description = "Secret content";
                  };
                  destDir = lib.mkOption {
                    type = lib.types.path;
                    default = "/run/keys";
                    description = "Destination directory";
                  };
                  user = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                  };
                  group = lib.mkOption {
                    type = lib.types.str;
                    default = "root";
                  };
                  permissions = lib.mkOption {
                    type = lib.types.str;
                    default = "0600";
                  };
                };
              });
              default = {};
              description = "Deployment keys/secrets";
            };
          };
        };
        default = {};
        description = "Deployment-specific configuration";
      };

      networking = lib.mkOption {
        type = lib.types.submodule {
          options = {
            hostName = lib.mkOption {
              type = lib.types.str;
              description = "Node hostname";
            };
          };
        };
        description = "Networking configuration";
      };

      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Tags for categorizing nodes (e.g., production, staging, web)";
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description of this node";
      };
    };
  };

  # Complete Colmena configuration
  colmenaConfig = lib.types.submodule {
    options = {
      meta = lib.mkOption {
        type = lib.types.submodule {
          options = {
            nixpkgs = lib.mkOption {
              type = lib.types.raw;
              description = "Nixpkgs instance";
            };

            nodeNixpkgs = lib.mkOption {
              type = lib.types.attrsOf lib.types.raw;
              default = {};
              description = "Per-node nixpkgs overrides";
            };

            specialArgs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
              description = "Extra arguments passed to all nodes";
            };
          };
        };
        description = "Meta configuration";
      };

      defaults = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Default configuration for all nodes";
      };
    };
  };

  # Deployment tag for selective deployments
  deploymentTag = lib.types.str;

  # Deployment key/secret
  deploymentKey = lib.types.submodule {
    options = {
      text = lib.mkOption {
        type = lib.types.str;
        description = "Secret content";
      };

      destDir = lib.mkOption {
        type = lib.types.path;
        default = "/run/keys";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "root";
      };

      permissions = lib.mkOption {
        type = lib.types.str;
        default = "0600";
      };
    };
  };
}
