{
  description = "Basic Johnny Mnemonix configuration example";

  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    johnny-mnemonix.url = "path:../../";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    johnny-mnemonix,
  }: {
    homeConfigurations."example" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        johnny-mnemonix.homeManagerModules.default
        {
          home.username = "example";
          home.homeDirectory = "/home/example";
          home.stateVersion = "23.11";

          johnny-mnemonix = {
            enable = true;
            areas = {
              "10-19" = {
                name = "Personal";
                categories = {
                  "11" = {
                    name = "Finance";
                    items = {
                      "11.01" = "Budget";
                      "11.02" = "Investments";
                    };
                  };
                };
              };
            };
          };
        }
      ];
    };
  };
}
