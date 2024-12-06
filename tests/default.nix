{lib, ...}: let
  inherit (lib) nixosTest;

  # Test configuration with multiple areas and categories
  testConfig = {
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
        "12" = {
          name = "Health";
          items = {
            "12.01" = "Medical Records";
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
          };
        };
      };
    };
  };
in
  nixosTest {
    name = "johnny-mnemonix";

    nodes.machine = {pkgs, ...}: {
      imports = [
        "${pkgs.home-manager}/nixos/home-manager.nix"
      ];

      # Create test user
      users.users.test = {
        isNormalUser = true;
        home = "/home/test";
        shell = pkgs.bash;
      };

      # Enable both shells for testing
      programs.bash.enable = true;
      programs.zsh.enable = true;

      home-manager.users.test = {
        imports = [../modules/johnny-mnemonix.nix];

        home = {
          username = "test";
          homeDirectory = "/home/test";
          stateVersion = "23.11";
        };

        # Enable the module with test configuration
        johnny-mnemonix = {
          enable = true;
          baseDir = "/home/test/Documents"; # Explicitly set for testing
          areas = testConfig;
        };
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-test.service")

      # Test base directory creation
      machine.succeed("test -d /home/test/Documents")

      # Test area directories
      with subtest("Area directories"):
          machine.succeed("test -d '/home/test/Documents/10-19 Personal'")
          machine.succeed("test -d '/home/test/Documents/20-29 Work'")

      # Test category directories
      with subtest("Category directories"):
          machine.succeed("test -d '/home/test/Documents/10-19 Personal/11 Finance'")
          machine.succeed("test -d '/home/test/Documents/10-19 Personal/12 Health'")
          machine.succeed("test -d '/home/test/Documents/20-29 Work/21 Projects'")

      # Test item directories
      with subtest("Item directories"):
          machine.succeed("test -d '/home/test/Documents/10-19 Personal/11 Finance/11.01 Budget'")
          machine.succeed("test -d '/home/test/Documents/10-19 Personal/11 Finance/11.02 Investments'")
          machine.succeed("test -d '/home/test/Documents/10-19 Personal/12 Health/12.01 Medical Records'")
          machine.succeed("test -d '/home/test/Documents/20-29 Work/21 Projects/21.01 Current Project'")

      # Test shell aliases
      with subtest("Shell aliases"):
          # Test bash alias
          machine.succeed("su - test -c 'source ~/.bashrc && jd && pwd' | grep -q '/home/test/Documents'")
          # Test zsh alias
          machine.succeed("su - test -c 'source ~/.zshrc && jd && pwd' | grep -q '/home/test/Documents'")

      # Test XDG compliance
      with subtest("XDG configuration"):
          machine.succeed("test -L /home/test/.config/user-dirs.dirs")
          machine.succeed("grep -q 'XDG_DOCUMENTS_DIR=\"/home/test/Documents\"' /home/test/.config/user-dirs.dirs")

      # Test directory permissions
      with subtest("Directory permissions"):
          machine.succeed("test -O /home/test/Documents")  # Test ownership
          machine.succeed("stat -c %a /home/test/Documents | grep -q '755'")  # Test permissions
    '';
  }
