{
  description = "Johnny Mnemonix - Declaritive Document Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsForSystem = system: nixpkgs.legacyPackages.${system};
  in {
    homeManagerModules.default = ./modules/johnny-mnemonix.nix;

    devShells = forAllSystems (system: {
      default = let
        pkgs = pkgsForSystem system;
      in
        pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            alejandra
            nil
            statix
            deadnix
          ];
        };
    });

    checks = forAllSystems (system: {
      vm-test = import ./tests {
        pkgs = pkgsForSystem system;
      };
    });

    homeConfigurations = forAllSystems (system: let
      pkgs = pkgsForSystem system;
    in {
      example = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./modules/johnny-mnemonix.nix
          {
            home = {
              username = "example";
              homeDirectory = "/home/example";
              stateVersion = "24.05";
            };

            programs.zsh.enable = true;

            johnny-mnemonix = {
              enable = true;
              baseDir = "~/Documents";
              shell = {
                enable = true;
                prefix = "jm";
                aliases = true;
                functions = true;
              };
            };
          }
        ];
      };
    });
  };
}
