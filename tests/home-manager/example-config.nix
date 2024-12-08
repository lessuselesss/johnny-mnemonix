_: {
  # Basic home-manager configuration
  home = {
    username = "test";
    homeDirectory = "/home/test";
    stateVersion = "24.11";
  };

  # Johnny-Mnemonix configuration
  johnny-mnemonix = {
    enable = true;
    baseDir = "/home/test/johnny-mnemonix";
    spacer = "_";
    areas = {
      # System - About the system.
      "00-09" = {
        name = "_System_";
        categories = {
          "00" = {
            name = "[Meta]";
            items = {
              "00.01" = {
                name = "Placeholder";
              };
              "00.02" = {
                name = "Placeholder";
              };
            };
          };
          "01" = {
            name = "[Home]";
            items = {
              "01.00" = {
                name = "Dotfiles";
                target = "/home/test/.dotfiles";
              };
              "01.01" = {
                name = "Applications";
                target = "/home/test/Applications";
              };
              "01.02" = {
                name = "Desktop";
                target = "/home/test/Desktop";
              };
              "01.03" = {
                name = "Documents";
                target = "/home/test/Documents";
              };
              "01.04" = {
                name = "Downloads";
                target = "/home/test/Downloads";
              };
              "01.05" = {
                name = "Movies";
                target = "/home/test/Movies";
              };
              "01.06" = {
                name = "Music";
                target = "/home/test/Music";
              };
              "01.07" = {
                name = "Pictures";
                target = "/home/test/Pictures";
              };
              "01.08" = {
                name = "Public";
                target = "/home/test/Public";
              };
              "01.09" = {
                name = "Templates";
                target = "/home/test/Templates";
              };
            };
          };
          "02" = {
            name = "[Cloud]";
            items = {
              "02.01" = {
                name = "Dropbox";
              };
              "02.02" = {
                name = "Google Drive";
              };
            };
          };
        };
      };

      # Projects - Short-term efforts in your work or life that you're working on now.
      "10-19" = {
        name = "_Projects_";
        categories = {
          "11" = {
            name = "[Maintaining]";
            items = {
              "11.01" = {
                name = "Johnny-Mnemonix";
                url = "https://github.com/lessuselesss/johnny-mnemonix";
                ref = "main";
                sparse = [
                  "/examples/*"
                ];
              };
              "11.02" = {
                name = "Forks";
              };
            };
          };
          "12" = {
            name = "[Pending]";
            items = {
              "12.01" = {
                name = "Waiting";
              };
              "12.02" = {
                name = "In Review";
              };
            };
          };
        };
      };

      # Areas - Long-term responsibilities you want to manage over time.
      "20-29" = {
        name = "_Areas_";
        categories = {
          "21" = {
            name = "[Personal]";
            items = {
              "21.01" = {
                name = "Health";
              };
              "21.02" = {
                name = "Finance";
              };
              "21.03" = {
                name = "Family";
              };
            };
          };
          "22" = {
            name = "[Professional]";
            items = {
              "22.01" = {
                name = "Career";
              };
              "22.02" = {
                name = "Skills";
              };
            };
          };
        };
      };

      # Topics or interests that may be useful in the future.
      "30-39" = {
        name = "_Resources_";
        categories = {
          "31" = {
            name = "[References]";
            items = {
              "31.01" = {
                name = "Technical";
              };
              "31.02" = {
                name = "Academic";
              };
            };
          };
          "32" = {
            name = "[Collections]";
            items = {
              "32.01" = {
                name = "Templates";
              };
              "32.02" = {
                name = "Checklists";
              };
            };
          };
        };
      };

      # Archive - Completed projects, references, and other resources that you no longer need to manage actively.
      "90-99" = {
        name = "_Archive_";
        categories = {
          "90" = {
            name = "[Completed]";
            items = {
              "90.01" = {
                name = "Projects";
              };
              "90.02" = {
                name = "References";
              };
            };
          };
          "91" = {
            name = "[Deprecated]";
            items = {
              "91.01" = {
                name = "Old Documents";
              };
              "91.02" = {
                name = "Legacy Files";
              };
            };
          };
        };
      };
    };
  };
}
