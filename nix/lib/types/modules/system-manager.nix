# system-manager Module Types
#
# Pure module option types for system-manager: NixOS-style configuration
# for any Linux distribution (not just NixOS).
# Based on https://github.com/numtide/system-manager

{lib}: {
  # ===== system-manager-Specific Types =====

  # System configuration (NixOS-like but for any Linux)
  systemConfig = lib.types.submodule {
    options = {
      hostname = lib.mkOption {
        type = lib.types.str;
        description = "System hostname";
      };

      system = lib.mkOption {
        type = lib.types.enum ["x86_64-linux" "aarch64-linux" "i686-linux"];
        description = "System architecture";
      };

      nixpkgs = lib.mkOption {
        type = lib.types.raw;
        description = "Nixpkgs instance";
      };
    };
  };

  # System service configuration
  systemService = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable this service";
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = "Service description";
      };

      wantedBy = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["multi-user.target"];
        description = "Systemd targets that want this service";
      };

      serviceConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Systemd service configuration";
      };
    };
  };

  # System package (installed via nix)
  systemPackage = lib.types.package;

  # System file configuration
  systemFile = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        description = "Target file path";
      };

      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Source file";
      };

      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Inline content";
      };

      mode = lib.mkOption {
        type = lib.types.str;
        default = "0644";
        description = "File permissions";
      };
    };
  };
}
