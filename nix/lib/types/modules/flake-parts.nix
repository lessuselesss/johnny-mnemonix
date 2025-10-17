# flake-parts Module Types
#
# Pure module option types for flake-parts: modular flake composition framework.
# Based on https://flake.parts/

{lib}: {
  # ===== flake-parts-Specific Types =====

  # flake-parts module (perSystem + flake)
  flakePartsModule = lib.types.deferredModule;

  # Per-system configuration
  perSystemConfig = lib.types.submodule {
    options = {
      packages = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = {};
        description = "Packages exposed in this system";
      };

      apps = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum ["app"];
              default = "app";
            };
            program = lib.mkOption {
              type = lib.types.str;
              description = "Path to executable";
            };
          };
        });
        default = {};
        description = "Applications exposed in this system";
      };

      devShells = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = {};
        description = "Development shells for this system";
      };

      checks = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = {};
        description = "Checks/tests for this system";
      };

      formatter = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Formatter package";
      };
    };
  };

  # Flake-wide configuration
  flakeConfig = lib.types.submodule {
    options = {
      modules = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.deferredModule);
        default = {};
        description = "Module organization by class";
      };
    };
  };

  # flake-parts options module
  optionsModule = lib.types.submodule {
    options = {
      perSystem = lib.mkOption {
        type = lib.types.deferredModule;
        description = "Per-system options";
      };

      flake = lib.mkOption {
        type = lib.types.deferredModule;
        description = "Flake-wide options";
      };
    };
  };
}
