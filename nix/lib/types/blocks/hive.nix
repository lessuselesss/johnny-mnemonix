# Hive Block Types
#
# std block type definitions for divnix/hive deployments.
# These define what hive blocks can export and what actions are available.
#
# Based on https://github.com/divnix/hive/tree/main/src/blockTypes

{lib}: let
  inherit (lib) mkOption types;
in {
  # ===== NixOS Configurations Block Type =====

  nixosConfigurations = {
    name = "nixosConfigurations";
    type = "nixosConfiguration";

    description = ''
      NixOS system configurations with deployment actions.

      Provides actions: switch, boot, test, build, dry-build, dry-activate,
      edit, repl, build-vm, build-vm-with-bootloader, list-generations.
    '';

    # Export structure
    exports = types.attrsOf (types.submodule {
      options = {
        config = mkOption {
          type = types.attrsOf types.anything;
          description = "NixOS configuration";
        };

        pkgs = mkOption {
          type = types.raw;
          description = "Nixpkgs instance";
        };

        extraModules = mkOption {
          type = types.listOf types.deferredModule;
          default = [];
          description = "Additional NixOS modules";
        };
      };
    });

    # Actions available via std CLI
    actions = {
      switch = "Deploy configuration and switch to it";
      boot = "Deploy configuration, activate on next boot";
      test = "Test configuration without making it default";
      build = "Build system configuration";
      dry-build = "Show what would be built";
      dry-activate = "Show what would be activated";
      edit = "Edit configuration";
      repl = "Open Nix REPL with configuration";
      build-vm = "Build VM for testing";
      build-vm-with-bootloader = "Build VM with bootloader";
      list-generations = "List system generations";
    };
  };

  # ===== Darwin Configurations Block Type =====

  darwinConfigurations = {
    name = "darwinConfigurations";
    type = "darwinConfiguration";

    description = ''
      macOS/Darwin system configurations with deployment actions.

      Similar to nixosConfigurations but for nix-darwin systems.
    '';

    exports = types.attrsOf (types.submodule {
      options = {
        config = mkOption {
          type = types.attrsOf types.anything;
          description = "Darwin configuration";
        };

        pkgs = mkOption {
          type = types.raw;
          description = "Nixpkgs instance";
        };

        extraModules = mkOption {
          type = types.listOf types.deferredModule;
          default = [];
          description = "Additional Darwin modules";
        };
      };
    });

    actions = {
      switch = "Deploy Darwin configuration and switch to it";
      build = "Build Darwin configuration";
      check = "Check Darwin configuration";
      activate = "Activate Darwin configuration";
    };
  };

  # ===== Home Configurations Block Type =====

  homeConfigurations = {
    name = "homeConfigurations";
    type = "homeConfiguration";

    description = ''
      home-manager user environment configurations.

      Provides actions for managing user home directories declaratively.
    '';

    exports = types.attrsOf (types.submodule {
      options = {
        config = mkOption {
          type = types.attrsOf types.anything;
          description = "home-manager configuration";
        };

        pkgs = mkOption {
          type = types.raw;
          description = "Nixpkgs instance";
        };

        extraModules = mkOption {
          type = types.listOf types.deferredModule;
          default = [];
          description = "Additional home-manager modules";
        };
      };
    });

    actions = {
      switch = "Build and activate home configuration";
      build = "Build home configuration";
      activate = "Activate home configuration";
      news = "Show home-manager news";
      packages = "List installed packages";
    };
  };

  # ===== Colmena Configurations Block Type =====

  colmenaConfigurations = {
    name = "colmenaConfigurations";
    type = "colmenaConfiguration";

    description = ''
      Colmena deployment configurations for managing multiple NixOS hosts.

      Provides actions for multi-host deployments via colmena.
    '';

    exports = types.attrsOf (types.submodule {
      options = {
        meta = mkOption {
          type = types.submodule {
            options = {
              nixpkgs = mkOption {
                type = types.raw;
                description = "Nixpkgs instance";
              };

              specialArgs = mkOption {
                type = types.attrsOf types.anything;
                default = {};
                description = "Extra arguments passed to all hosts";
              };
            };
          };
          description = "Colmena meta configuration";
        };

        nodes = mkOption {
          type = types.attrsOf types.deferredModule;
          description = "NixOS configurations for each host";
        };
      };
    });

    actions = {
      apply = "Deploy to all hosts";
      build = "Build configurations for all hosts";
      upload-keys = "Upload secret keys to hosts";
      exec = "Execute command on hosts";
      repl = "Open Nix REPL with colmena configuration";
    };
  };

  # ===== Disko Configurations Block Type =====

  diskoConfigurations = {
    name = "diskoConfigurations";
    type = "diskoConfiguration";

    description = ''
      Disko disk partitioning and formatting configurations.

      Provides actions for declarative disk management.
    '';

    exports = types.attrsOf (types.submodule {
      options = {
        disko = mkOption {
          type = types.attrsOf types.anything;
          description = "Disko configuration";
        };

        type = mkOption {
          type = types.str;
          description = "Disko configuration type";
        };
      };
    });

    actions = {
      format = "Format disks according to configuration";
      mount = "Mount filesystems";
      unmount = "Unmount filesystems";
      create = "Create disk partitions";
    };
  };
}
