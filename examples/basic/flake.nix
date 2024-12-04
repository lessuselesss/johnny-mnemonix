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
          home.username = "user1";
          home.homeDirectory = "/home/user1";
          home.stateVersion = "24.11";

          johnny-mnemonix = {
            enable = true;
            areas = {
              "10-19" = {
                name = "Projects";
                categories = {
                  "11" = {
                    name = "Home Renovation";
                    items = {
                      "11.01" = "Kitchen Remodel";
                      "11.02" = "Bathroom Update";
                      "11.03" = "Paint Living Room";
                    };
                  };
                  "12" = {
                    name = "Learning";
                    items = {
                      "12.01" = "Nix Course";
                      "12.02" = "Spanish Language";
                    };
                  };
                };
              };
              "20-29" = {
                name = "Areas";
                categories = {
                  "21" = {
                    name = "Health";
                    items = {
                      "21.01" = "Exercise Routine";
                      "21.02" = "Meal Planning";
                      "21.03" = "Medical Records";
                    };
                  };
                  "22" = {
                    name = "Finance";
                    items = {
                      "22.01" = "Budget";
                      "22.02" = "Investments";
                      "22.03" = "Tax Documents";
                    };
                  };
                };
              };
              "30-39" = {
                name = "Resources";
                categories = {
                  "31" = {
                    name = "Programming";
                    items = {
                      "31.01" = "Nix Documentation";
                      "31.02" = "Git Cheatsheet";
                      "31.03" = "Design Patterns";
                    };
                  };
                  "32" = {
                    name = "Reading List";
                    items = {
                      "32.01" = "Technical Books";
                      "32.02" = "Articles to Read";
                    };
                  };
                };
              };
              "90-99" = {
                name = "Archive";
                categories = {
                  "91" = {
                    name = "Completed Projects";
                    items = {
                      "91.01" = "2023 Tax Return";
                      "91.02" = "Old Resume Versions";
                      "91.03" = "Past Project Documentation";
                    };
                  };
                  "92" = {
                    name = "Reference Materials";
                    items = {
                      "92.01" = "Old Meeting Notes";
                      "92.02" = "Previous Contracts";
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
