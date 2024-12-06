{pkgs, ...}: let
  inherit
    (import "${pkgs.path}/nixos/lib/testing-python.nix" {
      inherit (pkgs) system;
      inherit pkgs;
    })
    makeTest
    ;

  inherit
    (pkgs.lib)
    mapAttrsToList
    concatStringsSep
    ;

  # Test configuration with both regular and git items
  testConfig = {
    enable = true;
    baseDir = "/home/testuser/Documents";
    areas = {
      "10-19" = {
        name = "Personal";
        categories = {
          "11" = {
            name = "Projects";
            items = {
              # Regular string item
              "11.01" = "Budget";

              # Git repository item
              "11.02" = {
                url = "https://github.com/nixos/nix";
                ref = "master";
              };

              # Git repository with sparse checkout
              "11.03" = {
                url = "https://github.com/NixOS/nixpkgs";
                ref = "master";
                sparse = ["README.md" "LICENSE"];
              };
            };
          };
        };
      };
    };
  };

  # Test user setup
  testUser = "testuser";
  testGroup = "users";
  testMode = "0755";
in
  makeTest {
    name = "johnny-mnemonix";

    nodes.machine = {pkgs, ...}: {
      imports = [
        "${pkgs.home-manager}/nixos/home-manager.nix"
      ];

      # Create test user
      users.users.${testUser} = {
        isNormalUser = true;
        home = "/home/${testUser}";
        group = testGroup;
      };

      # Enable home-manager
      home-manager.users.${testUser} = {...}: {
        imports = [../modules/johnny-mnemonix.nix];

        home = {
          username = testUser;
          homeDirectory = "/home/${testUser}";
          stateVersion = "23.11";
        };

        johnny-mnemonix = testConfig;
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-${testUser}.service")

      with subtest("Basic directory structure"):
          # Check regular directory
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal")
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects")
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.01\\ Budget")

      with subtest("Git repository cloning"):
          # Check if git repos were cloned
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02")
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/.git")

          # Verify git repo contents
          machine.succeed(
              "test -f /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/README.md"
          )

      with subtest("Sparse checkout"):
          # Check sparse checkout repo
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03")
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03/.git")

          # Verify only specified files exist
          machine.succeed(
              "test -f /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03/README.md"
          )
          machine.succeed(
              "test -f /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03/LICENSE"
          )

          # Verify other files don't exist
          machine.fail(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03/nixos"
          )

      with subtest("Git repository configuration"):
          # Check remote URL
          machine.succeed(
              "cd /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02 "
              + "&& git remote get-url origin | grep -q 'https://github.com/nixos/nix'"
          )

          # Check branch
          machine.succeed(
              "cd /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02 "
              + "&& git symbolic-ref --short HEAD | grep -q 'master'"
          )

      with subtest("Permissions and Ownership"):
          # Check base directory
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents) = '{testGroup}'"
          )

          # Check area directory
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal) = '{testGroup}'"
          )

          # Check category directory
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects) = '{testGroup}'"
          )

          # Check regular item directory
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.01\\ Budget) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.01\\ Budget) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.01\\ Budget) = '{testGroup}'"
          )

          # Check git repository directories
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02) = '{testGroup}'"
          )

          # Check sparse checkout repository
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03) = '{testGroup}'"
          )

          # Check git internal directories
          machine.succeed(
              f"test $(stat -c '%a' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/.git) = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%U' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/.git) = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' /home/{testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/.git) = '{testGroup}'"
          )

      with subtest("Idempotency"):
          # Run home-manager switch again
          machine.succeed("su ${testUser} -c 'home-manager switch'")

          # Verify repositories are still intact
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02/.git")
          machine.succeed("test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03/.git")
    '';
  }
