{
  description = "Johnny Mnemonix: Declarative document management using the Johnny Decimal system";

  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: {
    # Main module
    homeManagerModules.default = import ./modules/default.nix;

    # Library functions
    lib = import ./lib {inherit nixpkgs;};

    # Example configurations
    homeManagerModules.examples = {
      basic = import ./examples/basic;
      full = import ./examples/full;
    };

    # Development shell for contributors
    devShells.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt # Nix formatter
          nil # Nix LSP
        ];
      };
    };
  };
}
