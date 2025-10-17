# Johnny Declarative Decimal - Name-space Configuration
#
# This module defines the terminology and naming conventions:
# - Names for each hierarchy level (area, category, item, etc.)
# - Plural forms for documentation
# - Allowed characters in names
# - Name formatting rules
#
# Example: Standard Johnny Decimal
#   Level 1: "Area" (plural: "Areas")
#   Level 2: "Category" (plural: "Categories")
#   Level 3: "Item" (plural: "Items")
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.name-space = with lib; {
    # Terminology for hierarchy levels
    level_names = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          singular = mkOption {
            type = types.str;
            description = "Singular form of the level name";
          };
          plural = mkOption {
            type = types.str;
            description = "Plural form of the level name";
          };
          description_template = mkOption {
            type = types.str;
            default = "A {singular} in the hierarchy";
            description = "Template for describing this level";
          };
        };
      });
      default = {
        "1" = {
          singular = "Area";
          plural = "Areas";
          description_template = "A broad {singular} of organization spanning multiple categories";
        };
        "2" = {
          singular = "Category";
          plural = "Categories";
          description_template = "A {singular} within an area";
        };
        "3" = {
          singular = "Item";
          plural = "Items";
          description_template = "An {singular} within a category";
        };
      };
      description = ''
        Names for each level of the hierarchy.

        Standard Johnny Decimal uses:
        - Level 1: Area (e.g., "10-19 Projects")
        - Level 2: Category (e.g., "10 Code")
        - Level 3: Item (e.g., "10.01 My-Project")

        Can be customized to use different terminology:
        - Domain/Subdomain/Topic
        - Division/Department/Project
        - etc.
      '';
    };

    # Name formatting rules
    name_formatting = mkOption {
      type = types.submodule {
        options = {
          allowed_chars = mkOption {
            type = types.str;
            default = "a-zA-Z0-9 _-";
            description = "Regex character class for allowed characters in names";
          };

          case_style = mkOption {
            type = types.enum ["preserve" "lower" "upper" "title" "kebab" "snake" "camel"];
            default = "preserve";
            description = ''
              Preferred case style for names:
              - preserve: Keep user-provided case
              - lower: all lowercase
              - upper: ALL UPPERCASE
              - title: Title Case
              - kebab: kebab-case
              - snake: snake_case
              - camel: camelCase
            '';
          };

          max_length = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Maximum length for names (null = unlimited)";
          };

          word_separator = mkOption {
            type = types.str;
            default = "-";
            description = "Preferred separator for multi-word names";
          };
        };
      };
      default = {
        allowed_chars = "a-zA-Z0-9 _-";
        case_style = "preserve";
        max_length = null;
        word_separator = "-";
      };
      description = "Rules for formatting and validating names";
    };

    # Reserved names (cannot be used)
    reserved_names = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["index" "readme" "config"];
      description = "Names that cannot be used for items (reserved keywords)";
    };
  };

  config.johnny-declarative-decimal.name-space = {
    # Default configuration validates itself:
    # This module is in "01-09 Meta" area, "01 Configuration" category
    # Names use Title Case with spaces and hyphens
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.name-space =
    config.johnny-declarative-decimal.name-space;
}
