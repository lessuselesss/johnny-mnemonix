# NixOS Module Types
#
# Pure module option types for NixOS system configuration.

{lib}: {
  # ===== NixOS-Specific Types =====

  # Path to a NixOS module file
  nixosModulePath = lib.types.path;

  # NixOS configuration file (typically in /etc/nixos)
  nixosConfigFile = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.path;
        description = "Path to the configuration file";
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable description";
        example = "SSH Server Configuration";
      };
    };
  };

  # System-level package list
  systemPackages = lib.types.listOf lib.types.package;

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
        description = "Systemd targets";
      };
    };
  };
}
