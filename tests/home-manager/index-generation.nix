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
  # Test basic index generation with markdown format
  test-index-markdown = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-index-md";
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
              };
            };
          };
        };
      };
    };
  };

  # Test index with Typst format
  test-index-typst = mkHomeConfig {
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
                "11.02" = {
                  name = "Git-Project";
                  url = "https://github.com/test/project.git";
                };
              };
            };
          };
        };
      };
    };
  };

  # Test index with plain text format
  test-index-txt = mkHomeConfig {
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

  # Test index with non-enhanced mode
  test-index-no-metadata = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-index-no-meta";
      spacer = " ";
      index = {
        enable = true;
        format = "md";
        enhanced = false;
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
              };
            };
          };
        };
      };
    };
  };

  # Test index generation disabled
  test-index-disabled = mkHomeConfig {
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

  # Test index with watch service
  test-index-watch-enabled = mkHomeConfig {
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

  # Test index with multiple areas and categories
  test-index-complex-structure = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-index-complex";
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
                "11.02" = {
                  name = "App-Two";
                  url = "https://github.com/test/app2.git";
                };
              };
            };
            "12" = {
              name = "Scripts";
              items = {
                "12.01" = {
                  name = "Deploy-Script";
                  target = "/opt/scripts/deploy";
                };
                "12.02" = {
                  name = "Backup-Script";
                  url = "https://github.com/test/backup.git";
                  target = "/opt/scripts/backup";
                };
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
            "22" = {
              name = "Professional";
              items = {
                "22.01" = "Career";
                "22.02" = {
                  name = "Skills";
                  target = "/mnt/learning/skills";
                };
              };
            };
          };
        };
        "30-39" = {
          name = "Resources";
          categories = {
            "31" = {
              name = "References";
              items = {
                "31.01" = {
                  name = "Technical-Docs";
                  url = "https://github.com/test/tech-docs.git";
                };
              };
            };
          };
        };
      };
    };
  };

  # Test index with git+symlink combination
  test-index-git-symlink = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-index-git-symlink";
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
                  name = "Combined-Repo";
                  url = "https://github.com/test/combined.git";
                  target = "/mnt/storage/repos/combined";
                  ref = "main";
                };
                "11.02" = {
                  name = "Another-Combo";
                  url = "git@github.com:test/another.git";
                  target = "/mnt/storage/repos/another";
                };
              };
            };
          };
        };
      };
    };
  };

  # Test index with custom spacer
  test-index-custom-spacer = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-index-spacer";
      spacer = "_";
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
                "11.01" = "Underscore-Project";
              };
            };
          };
        };
      };
    };
  };
}
