# Johnny Declarative Decimal - Syntax Configuration
#
# This module defines the visual syntax for representing the hierarchy:
# - Encapsulators for different elements (areas, categories, items)
# - Separators between hierarchy levels
# - Separators between numbers and names
#
# This replaces the previous name-number-hierarchy-signifiers.nix
# and validates itself using its own defined syntax.
#
# Example: Standard syntax
#   Area: {10-19 Projects}
#   Category: (10 Code)
#   Item: [10.01 My-Project]
#   Full: [10.01]{10-19 Projects}__(10 Code)__[01 My-Project]
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.syntax = with lib; {
    # Encapsulators for area ranges
    area_range_encapsulator = mkOption {
      type = types.submodule {
        options = {
          open = mkOption {
            type = types.str;
            default = "{";
            description = "Opening character for area ranges";
          };
          close = mkOption {
            type = types.str;
            default = "}";
            description = "Closing character for area ranges";
          };
        };
      };
      default = {
        open = "{";
        close = "}";
      };
      description = ''
        Encapsulation characters for area ranges.

        Creates patterns like: {10-19 Projects}

        Alternative examples:
        - Brackets: [10-19 Projects]
        - Angles: <10-19 Projects>
        - Parens: (10-19 Projects)
      '';
    };

    # Encapsulators for category numbers
    category_num_encapsulator = mkOption {
      type = types.submodule {
        options = {
          open = mkOption {
            type = types.str;
            default = "(";
            description = "Opening character for category numbers";
          };
          close = mkOption {
            type = types.str;
            default = ")";
            description = "Closing character for category numbers";
          };
        };
      };
      default = {
        open = "(";
        close = ")";
      };
      description = ''
        Encapsulation characters for category numbers.

        Creates patterns like: (10 Code)

        Alternative examples:
        - Brackets: [10 Code]
        - Braces: {10 Code}
        - Angles: <10 Code>
      '';
    };

    # Encapsulators for item ID numbers
    id_num_encapsulator = mkOption {
      type = types.submodule {
        options = {
          open = mkOption {
            type = types.str;
            default = "[";
            description = "Opening character for item IDs";
          };
          close = mkOption {
            type = types.str;
            default = "]";
            description = "Closing character for item IDs";
          };
        };
      };
      default = {
        open = "[";
        close = "]";
      };
      description = ''
        Encapsulation characters for item ID numbers.

        Creates patterns like: [10.01 My-Project]

        Alternative examples:
        - Angles: <10.01 My-Project>
        - Parens: (10.01 My-Project)
        - Braces: {10.01 My-Project}
      '';
    };

    # Separator between numbers and names
    numeral_name_separator = mkOption {
      type = types.str;
      default = " ";
      description = ''
        Separator between numbers and names.

        Used in:
        - Area ranges: "10-19 Projects" (space between range and name)
        - Categories: "10 Code" (space between number and name)
        - Items: "10.01 My-Project" (space between ID and name)

        Examples:
        - Space: "10 Code"
        - Underscore: "10_Code"
        - Hyphen: "10-Code"
        - Colon: "10:Code"
      '';
    };

    # Separator between area and category in hierarchy
    area_category_separator = mkOption {
      type = types.str;
      default = "__";
      description = ''
        Separator between area and category in flat filename format.

        Creates: {10-19 Projects}__(10 Code)
        The "__" separates area from category.

        Examples:
        - Double underscore: "__"
        - Slash: "/"
        - Pipe: "|"
        - Arrow: "->"
      '';
    };

    # Separator between category and item in hierarchy
    category_item_separator = mkOption {
      type = types.str;
      default = "__";
      description = ''
        Separator between category and item in flat filename format.

        Creates: (10 Code)__[01 My-Project]
        The "__" separates category from item.

        Examples:
        - Double underscore: "__"
        - Slash: "/"
        - Pipe: "|"
        - Arrow: "->"
      '';
    };

    # Octet separator (between octet numbers in IDs)
    octet_separator = mkOption {
      type = types.str;
      default = ".";
      description = ''
        Separator between octets in item IDs.

        Creates: 10.01 (category.item)

        Examples:
        - Dot: "10.01"
        - Hyphen: "10-01"
        - Slash: "10/01"
        - Colon: "10:01"
      '';
    };

    # Range separator (for area ranges)
    range_separator = mkOption {
      type = types.str;
      default = "-";
      description = ''
        Separator in area range specifications.

        Creates: 10-19 (range from 10 to 19)

        Examples:
        - Hyphen: "10-19"
        - To: "10to19"
        - Double dot: "10..19"
        - Tilde: "10~19"
      '';
    };
  };

  config.johnny-declarative-decimal.syntax = {
    # Default configuration validates itself:
    # This module uses the syntax it defines:
    # [01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax]
    # - Area range: {01-09 Meta} (braces, space separator)
    # - Category: (01 Configuration) (parens, space separator)
    # - Item: [04 Syntax] (brackets, space separator)
    # - Hierarchy separators: __ between levels
    # - Octet separator: . in 01.04
    # - Range separator: - in 01-09
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.syntax =
    config.johnny-declarative-decimal.syntax;

  # Export in legacy format for backward compatibility
  flake.johnny-declarative-decimal.legacy-syntax-config = {
    areaRangeEncapsulator = config.johnny-declarative-decimal.syntax.area_range_encapsulator;
    categoryNumEncapsulator = config.johnny-declarative-decimal.syntax.category_num_encapsulator;
    idNumEncapsulator = config.johnny-declarative-decimal.syntax.id_num_encapsulator;
    numeralNameSeparator = config.johnny-declarative-decimal.syntax.numeral_name_separator;
    areaCategorySeparator = config.johnny-declarative-decimal.syntax.area_category_separator;
    categoryItemSeparator = config.johnny-declarative-decimal.syntax.category_item_separator;
  };
}
