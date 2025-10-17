# nix-darwin Flake Type
#
# Complete flake type definition for nix-darwin macOS system configuration:
# 1. Module input structure (flake-parts flake.modules.darwin)
# 2. Output validation (flake-schemas for darwinModules/darwinConfigurations)

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== Part 1: Module Input Structure =====

  moduleInput = {
    description = "nix-darwin macOS system configuration modules";
    moduleType = types.deferredModule;
    example = ''
      flake.modules.darwin.myMac = { config, pkgs, ... }: {
        services.nix-daemon.enable = true;
        homebrew.enable = true;
        homebrew.casks = [ "firefox" "iterm2" ];
      };
    '';
  };

  # ===== Part 2: Output Schemas =====

  schemas = {
    # Schema for darwinModules output
    darwinModules = {
      version = 1;
      doc = ''
        nix-darwin modules for macOS system configuration.

        Example:
          outputs.darwinModules.myModule = { config, pkgs, ... }: {
            # nix-darwin module options and config
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "nix-darwin module";
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

    # Schema for darwinConfigurations output
    darwinConfigurations = {
      version = 1;
      doc = ''
        Complete nix-darwin macOS system configurations.

        Example:
          outputs.darwinConfigurations.myMac = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [ ./darwin-configuration.nix ];
          };
      '';
      inventory = output: {
        children = builtins.mapAttrs (name: config: {
          what = "nix-darwin configuration";
          forSystems = [config.pkgs.system];
          evalChecks = {
            hasConfig = config ? config;
            hasPkgs = config ? pkgs;
            hasSystem = config.pkgs ? system;
            isDarwin = builtins.match ".*-darwin" config.pkgs.system != null;
          };
        }) output;
      };
    };
  };
}
