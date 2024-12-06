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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    typix,
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
      in
        pkgs.mkShell {
          buildInputs = with pkgs; [
            nixfmt # Nix formatter
            nil # Nix LSP
          ];
        };
    });

    # For testing the module
    checks = forAllSystems (system: {
      # We'll add tests later
    });
  };
}
