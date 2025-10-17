# NixOS Flake Type
#
# Complete flake type definition for NixOS system configuration:
# 1. Module input structure (flake-parts flake.modules.nixos)
# 2. Output validation (flake-schemas for nixosModules/nixosConfigurations)

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====
  # Defines how to write modules for flake.modules.nixos

  moduleInput = {
    description = "NixOS system configuration modules";
    moduleType = types.deferredModule;
    example = ''
      flake.modules.nixos.myServer = { config, pkgs, ... }: {
        services.nginx.enable = true;
        networking.firewall.allowedTCPPorts = [ 80 443 ];
      };
    '';
  };

  # ===== Part 2: Output Schemas =====
  # Validates flake outputs: nixosModules and nixosConfigurations

  schemas = {
    # Schema for nixosModules output
    nixosModules = {
      version = 1;
      doc = ''
        NixOS modules that can be imported into NixOS system configurations.

        Example:
          outputs.nixosModules.myModule = { config, pkgs, ... }: {
            # NixOS module options and config
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "NixOS module";
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

    # Schema for nixosConfigurations output
    nixosConfigurations = {
      version = 1;
      doc = ''
        Complete NixOS system configurations ready to build and deploy.

        Example:
          outputs.nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./configuration.nix ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: config: {
          what = "NixOS system configuration";
          forSystems = [config.pkgs.system];
          evalChecks = {
            hasConfig = config ? config;
            hasPkgs = config ? pkgs;
            hasSystem = config.pkgs ? system;
          };
        }) output;
      };
    };
  };
}
