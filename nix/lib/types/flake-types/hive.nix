# Hive/Colmena Flake Type
#
# Complete flake type definition for Hive (divnix Colmena): NixOS deployment tool.
#
# Based on https://colmena.cli.rs/ and divnix/hive

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "Hive/Colmena NixOS deployment configuration modules";
    moduleType = types.deferredModule;
    example = ''
      # Define deployment nodes
      flake.modules.hive.prod-web01 = {
        deployment = {
          targetHost = "web01.example.com";
          targetPort = 22;
          tags = [ "production" "web" ];
        };
        networking.hostName = "web01";

        # NixOS configuration for this node
        services.nginx.enable = true;
      };

      flake.modules.hive.staging-app02 = {
        deployment = {
          targetHost = "app02.staging.example.com";
          tags = [ "staging" "app" ];
        };
        networking.hostName = "app02";
      };
    '';
    schema = {
      nodes = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            deployment = mkOption {
              type = types.submodule {
                options = {
                  targetHost = mkOption { type = types.nullOr types.str; };
                  targetPort = mkOption { type = types.nullOr types.port; default = null; };
                  tags = mkOption { type = types.listOf types.str; default = []; };
                };
              };
            };
          };
        });
      };
      meta = mkOption {
        type = types.submodule {
          options = {
            nixpkgs = mkOption { type = types.raw; };
            specialArgs = mkOption {
              type = types.attrsOf types.anything;
              default = {};
            };
          };
        };
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for hiveModules output
    hiveModules = {
      version = 1;
      doc = ''
        Hive/Colmena deployment node configuration modules.

        Modules define deployment targets and their NixOS configurations.

        Example:
          outputs.hiveModules = {
            prod-web01 = {
              deployment.targetHost = "web01.example.com";
              services.nginx.enable = true;
            };
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (nodeName: nodeConfig: {
          what = "hive deployment node: ${nodeName}";
          evalChecks = {
            isNode = builtins.isAttrs nodeConfig;
            hasDeployment = nodeConfig ? deployment;
            hasValidDeployment =
              if nodeConfig ? deployment
              then (nodeConfig.deployment ? targetHost || nodeConfig.deployment ? tags)
              else false;
            hasNetworking = nodeConfig ? networking;
            hasHostname =
              if nodeConfig ? networking
              then nodeConfig.networking ? hostName
              else false;
          };
        }) output;
      };
    };

    # Alias for colmenaModules
    colmenaModules = {
      version = 1;
      doc = "Alias for hiveModules";
      inventory = output: {
        children = builtins.mapAttrs (name: node: {
          what = "colmena deployment node";
          evalChecks = {
            isNode = builtins.isAttrs node;
            hasDeployment = node ? deployment;
          };
        }) output;
      };
    };

    # Schema for complete hive (colmena.nix format)
    hive = {
      version = 1;
      doc = ''
        Complete Hive/Colmena deployment configuration.

        Example:
          outputs.hive = {
            meta = {
              nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
            };
            defaults = { /* shared config */ };
            node1 = { /* node config */ };
            node2 = { /* node config */ };
          };
      '';
      inventory = output: {
        what = "hive deployment configuration";
        evalChecks = {
          hasMeta = output ? meta;
          hasNodes =
            let
              keys = builtins.attrNames output;
              nodeKeys = builtins.filter (k: k != "meta" && k != "defaults") keys;
            in builtins.length nodeKeys > 0;
          metaHasNixpkgs =
            if output ? meta
            then output.meta ? nixpkgs
            else false;
        };
      };
    };
  };
}
