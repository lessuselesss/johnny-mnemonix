{
  description = "A Nix home-manager module for managing directory structures";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit system;
        });
  in {
    # Define the module
    homeManagerModules = {
      default = import ./modules/johnny-mnemonix.nix;
      johnny-mnemonix = import ./modules/johnny-mnemonix.nix;
    };

    # For backwards compatibility
    homeManagerModule = self.homeManagerModules.default;

    # Simple test that evaluates the module
    checks = forAllSystems ({
      pkgs,
      system,
    }: {
      moduleEval = pkgs.runCommand "test-johnny-mnemonix" {} ''
        echo "Testing module evaluation..."
        ${pkgs.nix}/bin/nix-instantiate --eval --expr '
          with import ${nixpkgs} { system = "${system}"; };
          let
            hmLib = import ${home-manager}/modules/lib/stdlib-extended.nix lib;
          in
          lib.evalModules {
            modules = [
              { _module.args = { inherit pkgs lib; }; }
              ${./modules/johnny-mnemonix.nix}
              {
                config = {
                  home = {
                    username = "test";
                    homeDirectory = "/home/test";
                    stateVersion = "23.11";
                  };
                  johnny-mnemonix = {
                    enable = true;
                    baseDir = "/tmp/test";
                    spacer = " ";
                    areas = {};
                  };
                };
              }
            ];
          }
        ' > $out
      '';
    });

    # Development shell
    devShells = forAllSystems ({pkgs, ...}: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          nixpkgs-fmt
          statix # Add statix
          deadnix # Add deadnix
          pre-commit
        ];
        shellHook = ''
          pre-commit install
        '';
      };
    });
  };
}
