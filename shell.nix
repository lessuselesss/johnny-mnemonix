{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [
    # Pre-commit and its dependencies
    pre-commit
    alejandra # Single formatter
    statix
    deadnix

    # Other development tools
    nil # Nix LSP
  ];

  shellHook = ''
    # Install pre-commit hooks
    pre-commit install

    echo "Development environment ready!"
    echo "Pre-commit hooks installed:"
    pre-commit list-hooks
  '';
}
