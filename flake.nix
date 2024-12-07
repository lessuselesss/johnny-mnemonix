{
  description = "Johnny Mnemonix - A Johnny Decimal-based Declaritive Document Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    inherit (inputs.nixpkgs) lib;
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = lib.genAttrs supportedSystems;
    pkgsForSystem = system: inputs.nixpkgs.legacyPackages.${system};
  in {
    # Home Manager modules
    homeManagerModules = rec {
      johnny-mnemonix = ./modules/johnny-mnemonix.nix;
      default = johnny-mnemonix;
    };

    # Development shell for working on the module
    devShells = forAllSystems (system: let
      pkgs = pkgsForSystem system;
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          alejandra # don't replace with nixfmt-*
          nil
          pre-commit
          deadnix
          statix
          gnupg
          pinentry-curses
        ];

        # Set up GPG for git commit signing
        shellHook = ''
          export GPG_TTY=$(tty)
          ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
        '';
      };
    });

    # Tests for the module
    checks = forAllSystems (system: let
      pkgs = pkgsForSystem system;
    in {
      # Basic module test
      basic-test = pkgs.runCommand "basic-test" {} ''
        echo "Testing basic module functionality..."
        touch $out
      '';
    });
  };
}
