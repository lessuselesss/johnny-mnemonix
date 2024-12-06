{
  description = "Declarative document management using the Johnny Decimal system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: For Typst integration
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add pre-commit-hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    typix,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    # Home Manager module
    homeManagerModules.default = import ./modules/johnny-mnemonix.nix;
    homeManagerModules.johnny-mnemonix = self.homeManagerModules.default;

    # Development shell for contributors
    devShells = forAllSystems (system: {
      default = let
        pkgs = nixpkgs.legacyPackages.${system};
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
            # Check that flake.nix is valid
            flake-check = {
              enable = true;
              name = "flake-check";
              entry = "${pkgs.nix}/bin/nix flake check";
              pass_filenames = false;
            };
          };
        };
      in
        pkgs.mkShell {
          inherit (pre-commit-check) shellHook;
          buildInputs = with pkgs; [
            nixfmt # Nix formatter
            nil # Nix LSP
            statix # Nix linter
            deadnix # Find dead Nix code
          ];
        };
    });

    # For testing the module
    checks = forAllSystems (system: {
      # We'll add tests later
    });
  };
}
