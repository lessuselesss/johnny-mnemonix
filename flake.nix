{
  description = "Declarative document management using the Johnny Decimal system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    module = import ./modules/johnny-mnemonix.nix;
  in {
    # Development shell for contributors
    devShells = forAllSystems (system: {
      default = let
        pkgs = nixpkgs.legacyPackages.${system};
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
            flake-check = {
              enable = true;
              name = "flake-check";
              entry = "${pkgs.nix}/bin/nix flake show";
              pass_filenames = false;
            };
            tests = {
              enable = true;
              name = "tests";
              entry = "${pkgs.nix}/bin/nix eval .#checks.${system}.vm-test";
              pass_filenames = false;
            };
          };
        };
      in
        pkgs.mkShell {
          inherit (pre-commit-check) shellHook;
          buildInputs = with pkgs; [
            alejandra
            nil
            statix
            deadnix
          ];
        };
    });

    # Example configuration template
    templates.default = {
      path = ./tests/home-manager;
      description = "Example Johnny-Mnemonix configuration";
    };

    # Home Manager configurations
    homeConfigurations.lessuseless = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        module
        {
          home = {
            username = "lessuseless";
            homeDirectory = "/Users/lessuseless";
            stateVersion = "23.11";
          };
        }
      ];
    };

    # Tests and checks
    checks = forAllSystems (system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          statix.enable = true;
          deadnix.enable = true;
          nil.enable = true;
        };
      };
      vm-test = nixpkgs.legacyPackages.${system}.callPackage ./tests {};
    });
  };
}
