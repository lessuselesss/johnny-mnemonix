# system-manager Flake Type
#
# Complete flake type definition for system-manager: NixOS-style configuration
# for any Linux distribution.
#
# Based on https://github.com/numtide/system-manager

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "system-manager modules for managing any Linux distribution";
    moduleType = types.deferredModule;
    alias = "sm";
    example = ''
      flake.modules.systemManager.myHost = { config, pkgs, ... }: {
        system.hostname = "myhost";
        environment.systemPackages = with pkgs; [ vim git curl ];
        systemd.services.myService = {
          enable = true;
          description = "My custom service";
        };
      };
    '';
    schema = {
      system = mkOption {
        type = types.submodule {
          options = {
            hostname = mkOption { type = types.str; };
            packages = mkOption {
              type = types.listOf types.package;
              default = [];
            };
          };
        };
      };
    };
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for systemManagerModules output
    systemManagerModules = {
      version = 1;
      doc = ''
        system-manager modules for NixOS-style Linux system configuration.

        Works on any Linux distribution, not just NixOS.

        Example:
          outputs.systemManagerModules.myModule = { config, pkgs, ... }: {
            environment.systemPackages = [ pkgs.htop ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "system-manager module";
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

    # Alias for smModules
    smModules = {
      version = 1;
      doc = "Alias for systemManagerModules";
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "system-manager module";
          evalChecks = {
            isImportable = builtins.isFunction module || builtins.isAttrs module;
          };
        }) output;
      };
    };
  };
}
