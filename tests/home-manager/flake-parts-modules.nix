{
  pkgs,
  lib,
  home-manager,
  ...
}: let
  mkHomeConfig = {config ? {}, ...}:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../../modules/johnny-mnemonix.nix
        {
          _module.args = {
            # Simulate the parsed JD module
            jdAreasFromModules = {
              "10-19" = {
                name = "Projects";
                categories = {
                  "10" = {
                    name = "Code";
                    items = {
                      "10.19" = "Test-Project";
                    };
                  };
                };
              };
            };
            # Simulate the simple path module
            managedPathNames = ["test-simple-module"];
          };
          home = {
            username = "testuser";
            homeDirectory = "/home/testuser";
            stateVersion = "23.11";
          };
          johnny-mnemonix = config;
        }
      ];
    };
in {
  # Test that JD module areas are used when no manual config
  test-jd-module-only = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-jd-only";
      spacer = " ";
      areas = {};
    };
  };

  # Test that manual config merges with JD module areas
  test-merged-areas = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-merged";
      spacer = " ";
      areas = {
        # Add a different area
        "20-29" = {
          name = "Personal";
          categories = {
            "21" = {
              name = "Finance";
              items = {
                "21.01" = "Budget";
              };
            };
          };
        };
        # Override the JD module area
        "10-19" = {
          name = "My Projects";  # Different name
          categories = {
            "10" = {
              name = "Development";  # Different name
              items = {
                "10.19" = "My-Test-Project";  # Override item name
                "10.20" = "Additional-Project";  # Add new item
              };
            };
          };
        };
      };
    };
  };

  # Test path conflict detection with simple modules
  test-path-conflicts = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/home/testuser";
      spacer = " ";
      areas = {
        # This would create ~/test-simple-module but it conflicts with the simple module
        "10-19" = {
          name = "Test";
          categories = {
            "10" = {
              name = "Category";
              items = {
                # This path would be: /home/testuser/10-19 Test/10 Category/10.01 test-simple-module
                # Which is different from ~/test-simple-module, so no conflict
                "10.01" = "no-conflict";
              };
            };
          };
        };
      };
    };
  };

  # Test flake-parts packages are accessible
  test-packages-exposed = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-packages";
      spacer = " ";
      areas = {};
    };
  };
}
