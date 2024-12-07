{pkgs ? import <nixpkgs> {}}: let
  # Create a wrapper script to ensure cached-nix-shell is available
  ensureCachedShell = pkgs.writeShellScriptBin "ensure-cached-shell" ''
    if ! command -v cached-nix-shell &> /dev/null; then
      echo "Installing cached-nix-shell..."
      nix-env -iA nixpkgs.cached-nix-shell
    fi
  '';
in
  pkgs.mkShell {
    packages = with pkgs; [
      # Development environment setup helper
      ensureCachedShell

      # Pre-commit and its dependencies
      pre-commit
      alejandra # Single formatter
      statix
      deadnix

      # Other development tools
      nil # Nix LSP
    ];

    shellHook = ''
      # Ensure cached-nix-shell is installed
      ensure-cached-shell

      # Install pre-commit hooks
      pre-commit install

      echo "Development environment ready!"
      echo "Pre-commit hooks installed:"
      pre-commit list-hooks

      # Use cached-nix-shell for subsequent loads
      if [ -z "$CACHED_NIX_SHELL" ]; then
        export CACHED_NIX_SHELL=1
        exec cached-nix-shell "$SHELL_NIX" "$@"
      fi
    '';
  }
