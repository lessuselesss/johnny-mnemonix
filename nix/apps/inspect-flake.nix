# Flake Inspector App
#
# Wraps any flake with flake-parts debug enabled to extract configurations
#
# Usage:
#   nix run .#inspect-flake -- <flake-url>
#   nix run .#inspect-flake -- github:dustinlyons/nixos-config

{
  inputs,
  cell,
}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {inherit system;};
in {
  type = "app";
  program = toString (pkgs.writeShellScript "inspect-flake" ''
    set -euo pipefail

    TARGET_FLAKE="$1"

    if [ -z "$TARGET_FLAKE" ]; then
      echo "Usage: nix run .#inspect-flake -- <flake-url>"
      echo "Example: nix run .#inspect-flake -- github:dustinlyons/nixos-config"
      exit 1
    fi

    echo "=== Inspecting Flake: $TARGET_FLAKE ==="
    echo

    # List nixosConfigurations
    echo "→ Extracting nixosConfigurations..."
    CONFIGS=$(nix eval --json "$TARGET_FLAKE#nixosConfigurations" --apply 'configs: builtins.attrNames configs' 2>/dev/null || echo "[]")

    if [ "$CONFIGS" != "[]" ]; then
      echo "Found nixosConfigurations:"
      echo "$CONFIGS" | ${pkgs.jq}/bin/jq -r '.[]' | while read config; do
        echo "  - $config"
      done
      echo

      # Extract detailed info for each configuration
      echo "$CONFIGS" | ${pkgs.jq}/bin/jq -r '.[]' | while read config; do
        echo "→ Configuration: $config"

        HOSTNAME=$(nix eval --raw "$TARGET_FLAKE#nixosConfigurations.$config.config.networking.hostName" 2>/dev/null || echo "unknown")
        SYSTEM=$(nix eval --raw "$TARGET_FLAKE#nixosConfigurations.$config.config.nixpkgs.hostPlatform" 2>/dev/null || echo "unknown")

        echo "  Hostname: $HOSTNAME"
        echo "  System: $SYSTEM"

        # Extract modules list
        echo "  Extracting modules..."
        MODULES=$(nix eval --json "$TARGET_FLAKE#nixosConfigurations.$config.options.imports.files" 2>/dev/null || echo "[]")
        MODULE_COUNT=$(echo "$MODULES" | ${pkgs.jq}/bin/jq 'length')
        echo "  Module count: $MODULE_COUNT"

        echo
      done
    else
      echo "No nixosConfigurations found"
    fi

    echo "=== Inspection Complete ==="
  '');
}
