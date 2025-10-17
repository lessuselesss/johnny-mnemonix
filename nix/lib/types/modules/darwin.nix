# nix-darwin Module Types
#
# Pure module option types for nix-darwin macOS system configuration.

{lib}: {
  # ===== nix-darwin-Specific Types =====

  # macOS-specific system configuration
  darwinConfiguration = lib.types.submodule {
    options = {
      system = lib.mkOption {
        type = lib.types.enum ["aarch64-darwin" "x86_64-darwin"];
        description = "macOS system architecture";
      };

      nixpkgs = lib.mkOption {
        type = lib.types.raw;
        description = "Nixpkgs instance";
      };
    };
  };

  # macOS Homebrew package management
  brewPackage = lib.types.str;

  brewCask = lib.types.str;

  brewTap = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Tap name (e.g., homebrew/cask)";
      };

      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Custom tap URL";
      };
    };
  };

  # macOS system preferences
  darwinDefaults = lib.types.attrsOf lib.types.anything;

  # macOS system service (launchd)
  darwinService = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      command = lib.mkOption {
        type = lib.types.str;
        description = "Command to run";
      };
      serviceConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
    };
  };
}
