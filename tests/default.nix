{
  pkgs,
  lib,
  home-manager,
  ...
}: let
  # Helper to create a minimal home-manager configuration
  mkHomeConfig = {config ? {}, ...}:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../modules/johnny-mnemonix.nix
        {
          home = {
            username = "testuser";
            homeDirectory = "/home/testuser";
            stateVersion = "23.11";
          };
          johnny-mnemonix = config;
        }
      ];
    };

  # Test cases
  tests = {
    # Test basic configuration
    basic = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test";
        spacer = " ";
        areas = {
          "10-19" = {
            name = "Test";
            categories = {
              "11" = {
                name = "Category";
                items = {
                  "11.01" = {name = "Item";};
                };
              };
            };
          };
        };
      };
    };

    # Test with Git repository
    withGit = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test";
        spacer = " ";
        areas = {
          "10-19" = {
            name = "Test";
            categories = {
              "11" = {
                name = "Category";
                items = {
                  "11.01" = {
                    name = "Item";
                    url = "https://github.com/example/repo.git";
                    ref = "main";
                  };
                };
              };
            };
          };
        };
      };
    };

    # Test with symlinks
    withSymlinks = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test";
        spacer = " ";
        areas = {
          "10-19" = {
            name = "Test";
            categories = {
              "11" = {
                name = "Category";
                items = {
                  "11.01" = {
                    name = "Item";
                    target = "/some/target/path";
                  };
                };
              };
            };
          };
        };
      };
    };

    # Test XDG paths
    withXdg = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test";
        spacer = " ";
        xdg = {
          stateHome = "/home/testuser/.local/state";
          cacheHome = "/home/testuser/.cache";
          configHome = "/home/testuser/.config";
        };
        areas = {
          "10-19" = {
            name = "Test";
            categories = {
              "11" = {
                name = "Category";
                items = {
                  "11.01" = {name = "Item";};
                };
              };
            };
          };
        };
      };
    };
  };
in {
  # Run the tests
  test =
    pkgs.runCommand "test-johnny-mnemonix" {
      nativeBuildInputs = [pkgs.git];
    } ''
      echo "Running johnny-mnemonix tests..."

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: config: ''
          echo "Testing ${name}..."
          if ! ${config.activationPackage}/activate; then
            echo "Test ${name} failed!"
            exit 1
          fi
        '')
        tests)}

      echo "All tests passed!"
      touch $out
    '';
}
