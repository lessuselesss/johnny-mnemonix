# Home Manager Module Types
#
# Pure module option types for home-manager user environment configuration.

{lib}: {
  # ===== Home Manager-Specific Types =====

  # User home directory path
  homeDirectory = lib.types.path;

  # XDG configuration file
  xdgConfigFile = lib.types.attrsOf (lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to source file";
      };

      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Inline content";
      };

      onChange = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Script to run on file changes";
      };
    };
  });

  # Dotfile configuration
  dotfile = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Dotfile name (e.g., .bashrc)";
      };

      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Source path";
      };

      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Inline content";
      };
    };
  };

  # User package list
  homePackages = lib.types.listOf lib.types.package;

  # Home file
  homeFile = lib.types.attrsOf (lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      executable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
      };
    };
  });
}
