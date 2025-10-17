# Johnny Declarative Decimal - Nix Module Validation Configuration
#
# This module defines validation rules for user's Nix modules
# (e.g., home-manager modules that declare johnny-declarative-decimal areas).
#
# Validates:
# - Module structure conformance
# - Proper use of johnny-declarative-decimal configuration
# - Path conflict detection
# - Naming convention compliance
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.nix-module-validation = with lib; {
    # Enable validation of user modules
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to validate user Nix modules against johnny-declarative-decimal rules";
    };

    # Validation strictness level
    strictness = mkOption {
      type = types.enum ["permissive" "standard" "strict"];
      default = "standard";
      description = ''
        Validation strictness level:

        - permissive: Warnings only, never fail
        - standard: Fail on structure violations, warn on style issues
        - strict: Fail on any deviation from conventions
      '';
    };

    # Path validation rules
    path_validation = mkOption {
      type = types.submodule {
        options = {
          check_conflicts = mkOption {
            type = types.bool;
            default = true;
            description = "Check for path conflicts between modules";
          };

          allow_absolute_paths = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to allow absolute paths in module definitions";
          };

          check_home_directory = mkOption {
            type = types.bool;
            default = true;
            description = "Validate that paths are within home directory";
          };
        };
      };
      default = {
        check_conflicts = true;
        allow_absolute_paths = false;
        check_home_directory = true;
      };
      description = "Rules for validating paths declared by modules";
    };

    # Structure validation rules
    structure_validation = mkOption {
      type = types.submodule {
        options = {
          require_area_definition = mkOption {
            type = types.bool;
            default = true;
            description = "Whether modules must define at least one area";
          };

          enforce_hierarchy_depth = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enforce proper hierarchy depth (area->category->item)";
          };

          validate_number_ranges = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to validate category numbers fall within area ranges";
          };
        };
      };
      default = {
        require_area_definition = true;
        enforce_hierarchy_depth = true;
        validate_number_ranges = true;
      };
      description = "Rules for validating module structure";
    };

    # Naming convention validation
    naming_validation = mkOption {
      type = types.submodule {
        options = {
          enforce_naming_rules = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enforce naming rules from name-space config";
          };

          check_reserved_names = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to check for reserved name usage";
          };

          validate_character_set = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to validate allowed characters in names";
          };
        };
      };
      default = {
        enforce_naming_rules = true;
        check_reserved_names = true;
        validate_character_set = true;
      };
      description = "Rules for validating naming conventions";
    };
  };

  config.johnny-declarative-decimal.nix-module-validation = {
    # Default configuration validates itself:
    # This module defines validation rules for user Nix modules
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.nix-module-validation =
    config.johnny-declarative-decimal.nix-module-validation;
}
