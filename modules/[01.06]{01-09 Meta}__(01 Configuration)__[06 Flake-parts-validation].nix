# Johnny Declarative Decimal - Flake-parts Module Validation Configuration
#
# This module defines validation rules for flake-parts modules
# (the modules within this flake, including these configuration modules).
#
# Validates:
# - Filename format conformance (flat or directory hierarchy)
# - Self-consistency (filename matches declared IDs)
# - Module collision detection
# - Proper flake-parts structure
#
# This module validates itself and all sibling modules.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.flake-parts-validation = with lib; {
    # Enable validation of flake-parts modules
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to validate flake-parts modules against johnny-declarative-decimal rules";
    };

    # Supported module formats
    allowed_formats = mkOption {
      type = types.listOf (types.enum ["flat" "directory" "simple"]);
      default = ["flat" "directory" "simple"];
      description = ''
        Allowed module organization formats:

        - flat: Self-describing filenames like [01.01]{Area}__(Cat)__[Item].nix
        - directory: Hierarchy like modules/{Area}/(Cat)/[Item].nix
        - simple: Non-JD modules like modules/my-module.nix
      '';
    };

    # Filename validation rules
    filename_validation = mkOption {
      type = types.submodule {
        options = {
          require_self_describing = mkOption {
            type = types.bool;
            default = true;
            description = "Whether JD modules must use self-describing filenames";
          };

          validate_syntax_conformance = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to validate filenames match syntax config";
          };

          check_id_consistency = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to validate ID consistency:
              - [10.01] prefix must match [01 ...] item number
              - Category from [10.01] must match (10 ...) category
              - Category must fall within area range
            '';
          };
        };
      };
      default = {
        require_self_describing = true;
        validate_syntax_conformance = true;
        check_id_consistency = true;
      };
      description = "Rules for validating module filenames";
    };

    # Collision detection
    collision_detection = mkOption {
      type = types.submodule {
        options = {
          check_duplicate_ids = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to check for duplicate item IDs across modules";
          };

          check_conflicting_paths = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to check for path conflicts between modules";
          };

          fail_on_collision = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to fail build on detected collisions (vs warning)";
          };
        };
      };
      default = {
        check_duplicate_ids = true;
        check_conflicting_paths = true;
        fail_on_collision = true;
      };
      description = "Rules for detecting and handling collisions";
    };

    # Module structure validation
    module_structure = mkOption {
      type = types.submodule {
        options = {
          require_flake_parts_format = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to require all modules use flake-parts format";
          };

          validate_exports = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to validate modules properly export their configuration";
          };

          check_circular_dependencies = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to check for circular module dependencies";
          };
        };
      };
      default = {
        require_flake_parts_format = false;
        validate_exports = true;
        check_circular_dependencies = true;
      };
      description = "Rules for validating module internal structure";
    };
  };

  config.johnny-declarative-decimal.flake-parts-validation = {
    # Default configuration validates itself:
    # This module [01.06] validates its own filename format:
    # - Uses flat self-describing format
    # - ID 01.06 is consistent (category 01, item 06)
    # - Category 01 falls within area 01-09
    # - Filename uses syntax from 01.04 Syntax config
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.flake-parts-validation =
    config.johnny-declarative-decimal.flake-parts-validation;
}
