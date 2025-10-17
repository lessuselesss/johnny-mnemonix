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

    # Test index generation with markdown format (default)
    indexMarkdown = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-index";
        spacer = " ";
        index = {
          enable = true;
          format = "md";
          enhanced = true;
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = {
                    name = "Web-App";
                    url = "https://github.com/test/webapp.git";
                  };
                  "11.02" = {
                    name = "CLI-Tool";
                    target = "/tmp/storage/cli";
                  };
                  "11.03" = {
                    name = "Combined";
                    url = "https://github.com/test/combined.git";
                    target = "/tmp/storage/combined";
                  };
                };
              };
            };
          };
        };
      };
    };

    # Test index generation with Typst format
    indexTypst = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-index-typ";
        spacer = " ";
        index = {
          enable = true;
          format = "typ";
          enhanced = true;
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = "Simple-Project";
                };
              };
            };
          };
        };
      };
    };

    # Test index generation with plain text format
    indexText = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-index-txt";
        spacer = " ";
        index = {
          enable = true;
          format = "txt";
          enhanced = false;
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = "Project-One";
                  "11.02" = "Project-Two";
                };
              };
            };
          };
        };
      };
    };

    # Test index disabled
    indexDisabled = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-no-index";
        spacer = " ";
        index = {
          enable = false;
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = "Project";
                };
              };
            };
          };
        };
      };
    };

    # Test index with watch service enabled
    indexWatch = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-index-watch";
        spacer = " ";
        index = {
          enable = true;
          format = "md";
          enhanced = true;
          watch = {
            enable = true;
            interval = 2;
          };
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = "Watched-Project";
                };
              };
            };
          };
        };
      };
    };

    # Test index with multiple areas for comprehensive tree structure
    indexMultiArea = mkHomeConfig {
      config = {
        enable = true;
        baseDir = "/tmp/test-index-multi";
        spacer = " ";
        index = {
          enable = true;
          format = "md";
          enhanced = true;
        };
        areas = {
          "10-19" = {
            name = "Projects";
            categories = {
              "11" = {
                name = "Code";
                items = {
                  "11.01" = "App-One";
                  "11.02" = "App-Two";
                };
              };
              "12" = {
                name = "Scripts";
                items = {
                  "12.01" = "Deploy-Script";
                };
              };
            };
          };
          "20-29" = {
            name = "Areas";
            categories = {
              "21" = {
                name = "Personal";
                items = {
                  "21.01" = "Health";
                  "21.02" = "Finance";
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
