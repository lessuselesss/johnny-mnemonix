# Johnny Declarative Decimal - Base Octets Configuration
#
# This module defines the foundational number system structure:
# - Number of octets in an identifier (e.g., 2 for XX.YY format)
# - Base number system for each octet (e.g., base 10 for decimal)
# - Number of digits per octet
#
# Example: Standard Johnny Decimal uses 2 octets, base 10, 2 digits each
#   Result: XX.YY format where X and Y are 0-9
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.johnny-declarative-decimal.base-octets = with lib; {
    # Number of octets in the identifier system
    # Default: 2 (results in format like XX.YY)
    num_octets = mkOption {
      type = types.int;
      default = 2;
      description = ''
        Number of octets (segments) in the identifier system.

        Examples:
        - 2: Standard Johnny Decimal (XX.YY)
        - 3: Extended system (XX.YY.ZZ)
        - 4: Deep hierarchy (WW.XX.YY.ZZ)
      '';
    };

    # Base number system for each octet
    # Maps octet index to base (default: all base 10)
    octet_bases = mkOption {
      type = types.attrsOf types.int;
      default = {
        "1" = 10;
        "2" = 10;
      };
      description = ''
        Base number system for each octet.

        Examples:
        - Base 10 (decimal): Standard 0-9 digits
        - Base 16 (hexadecimal): 0-9, A-F
        - Base 2 (binary): 0-1

        Keys are octet indices (1-indexed), values are the base.
      '';
    };

    # Number of digits per octet
    # Maps octet index to digit count
    octet_digits = mkOption {
      type = types.attrsOf types.int;
      default = {
        "1" = 2;
        "2" = 2;
      };
      description = ''
        Number of digits in each octet.

        Examples:
        - 2 digits in base 10: 00-99 (100 values)
        - 1 digit in base 10: 0-9 (10 values)
        - 3 digits in base 10: 000-999 (1000 values)

        Keys are octet indices (1-indexed), values are digit counts.
      '';
    };
  };

  config.johnny-declarative-decimal.base-octets = {
    # Default configuration validates itself:
    # This module is [01.01] which uses 2 octets, base 10, 2 digits each
    # 01 = category (first octet)
    # 01 = item (second octet)
  };

  # Expose configuration via flake outputs
  flake.johnny-declarative-decimal.config.base-octets =
    config.johnny-declarative-decimal.base-octets;
}
