{
  description = "Johnny Mnemonix - Personal Knowledge Management";

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
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        git
        alejandra
        nil
        statix
        deadnix
      ];
    };

    checks.${system} = {
      vm-test = import ./tests {
        inherit pkgs;
      };
    };

    homeConfigurations.lessuseless = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./modules/johnny-mnemonix.nix
        {
          home = {
            username = "lessuseless";
            homeDirectory = "/Users/lessuseless";
            stateVersion = "23.11";
          };

          programs.zsh = {
            enable = true;
            enableCompletion = true;
            enableAutosuggestions = true;
            enableSyntaxHighlighting = true;
            initExtraFirst = ''
              # Source johnny-mnemonix functions
              if [ -f $HOME/.local/share/johnny-mnemonix/shell-functions.sh ]; then
                source $HOME/.local/share/johnny-mnemonix/shell-functions.sh
              fi
            '';
          };

          johnny-mnemonix = {
            enable = true;
            baseDir = "/Users/lessuseless/Documents";
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
  };
}
