# Johnny Declarative Decimal - Numbers, Ranges, and Rules Configuration
#
# This module defines what each octet represents and how they combine:
# - Octet roles (range identifier, category, item, etc.)
# - Range formation rules (e.g., how areas span categories)
# - Validation constraints for number placement
#
# Example: Standard Johnny Decimal
#   Octet 1: Category (part of area range)
#   Octet 2: Item identifier
#   Areas: Ranges of 10 categories (00-09, 10-19, etc.)
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.numbers-ranges-rules = with lib; {
    # Define the role of each octet
    octet_roles = mkOption {
      type = types.attrsOf (types.enum ["range" "category" "item" "sub-item"]);
      default = {
        "1" = "category";  # First octet is category number
        "2" = "item";      # Second octet is item identifier
      };
      description = ''
        Role of each octet in the hierarchy.

        Roles:
        - "range": Part of a range identifier (e.g., area span)
        - "category": Category identifier within an area
        - "item": Item identifier within a category
        - "sub-item": Sub-item for deeper hierarchies

        In standard Johnny Decimal:
        - Octet 1 (category): 10 in 10.01
        - Octet 2 (item): 01 in 10.01
      '';
    };

    # Define how ranges are formed from octets
    area_range_config = mkOption {
      type = types.submodule {
        options = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to use area ranges";
          };

          span_size = mkOption {
            type = types.int;
            default = 10;
            description = ''
              Number of categories per area range.

              Examples:
              - 10: Areas span 10 categories (00-09, 10-19, 20-29, etc.)
              - 20: Areas span 20 categories (00-19, 20-39, etc.)
              - 5: Areas span 5 categories (00-04, 05-09, etc.)
            '';
          };

          based_on_octet = mkOption {
            type = types.int;
            default = 1;
            description = "Which octet index defines the range (usually the category octet)";
          };
        };
      };
      default = {
        enabled = true;
        span_size = 10;
        based_on_octet = 1;
      };
      description = ''
        Configuration for area range formation.

        In standard Johnny Decimal, areas are ranges of 10 categories:
        - 00-09 is one area
        - 10-19 is another area
        - etc.
      '';
    };

    # Validation constraints
    validation_rules = mkOption {
      type = types.submodule {
        options = {
          require_leading_zeros = mkOption {
            type = types.bool;
            default = true;
            description = "Whether numbers must have leading zeros (01 vs 1)";
          };

          category_must_match_area = mkOption {
            type = types.bool;
            default = true;
            description = "Whether category number must fall within its area range";
          };

          enforce_sequential_allocation = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enforce sequential allocation of IDs";
          };
        };
      };
      default = {
        require_leading_zeros = true;
        category_must_match_area = true;
        enforce_sequential_allocation = false;
      };
      description = "Validation rules for number assignment and usage";
    };
  };

  config.johnny-declarative-decimal.numbers-ranges-rules = {
    # Default configuration validates itself:
    # This module is [01.02] in area 01-09
    # Category 01 falls within area range 01-09 (span of 10 starting at 00)
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.numbers-ranges-rules =
    config.johnny-declarative-decimal.numbers-ranges-rules;
}
