{
  description = "Full Johnny Mnemonix configuration example";

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
          home.username = "user1";
          home.homeDirectory = "/home/user1";
          home.stateVersion = "24.11";

          johnny-mnemonix = {
            enable = true;
            baseDir = "/home/example/Documents";

            areas = {
              "10-19" = {
                name = "Personal";
                categories = {
                  "11" = {
                    name = "Finance";
                    items = {
                      "11.01" = "Budget";
                      "11.02" = "Investments";
                      "11.03" = "Tax Records";
                      "11.04" = "Insurance";
                    };
                  };
                  "12" = {
                    name = "Health";
                    items = {
                      "12.01" = "Medical Records";
                      "12.02" = "Fitness Plans";
                      "12.03" = "Diet Plans";
                    };
                  };
                };
              };

              "20-29" = {
                name = "Work";
                categories = {
                  "21" = {
                    name = "Projects";
                    items = {
                      "21.01" = "Current Project";
                      "21.02" = "Project Archive";
                      "21.03" = "Project Templates";
                    };
                  };
                  "22" = {
                    name = "Admin";
                    items = {
                      "22.01" = "Contracts";
                      "22.02" = "Timesheets";
                      "22.03" = "Expenses";
                    };
                  };
                };
              };

              "30-39" = {
                name = "Archive";
                categories = {
                  "31" = {
                    name = "Old Projects";
                    items = {
                      "31.01" = "2023 Projects";
                      "31.02" = "2022 Projects";
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
