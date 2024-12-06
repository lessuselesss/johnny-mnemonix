{pkgs, ...}: let
  inherit
    (import "${pkgs.path}/nixos/lib/testing-python.nix" {
      inherit (pkgs) system;
      inherit pkgs;
    })
    makeTest
    ;

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
      };
    };
  };

  # Test user details
  testUser = "test";
  testGroup = "testgroup";
  testMode = "0750"; # More restrictive mode for testing
  otherUser = "other";
  otherGroup = "othergroup";

  # Helper function to check permissions
  checkPerms = dirPath: ''
    # Check directory exists
    machine.succeed("test -d '${dirPath}'")

    # Check ownership
    machine.succeed(
        "stat -c '%U %G' '${dirPath}' | "
        + "grep -q '^${testUser} ${testGroup}$'"
    )

    # Check mode
    machine.succeed(
        "stat -c '%a' '${dirPath}' | "
        + "grep -q '^${testMode}$'"
    )

    # Check user permissions (owner should have rwx)
    machine.succeed("su ${testUser} -c 'test -r \"${dirPath}\"'")  # read
    machine.succeed("su ${testUser} -c 'test -w \"${dirPath}\"'")  # write
    machine.succeed("su ${testUser} -c 'test -x \"${dirPath}\"'")  # execute

    # Check group permissions (group should have r-x for 750)
    machine.succeed("su ${testUser} -g ${testGroup} -c 'test -r \"${dirPath}\"'")  # read
    machine.fail("su ${testUser} -g ${testGroup} -c 'test -w \"${dirPath}\"'")     # no write
    machine.succeed("su ${testUser} -g ${testGroup} -c 'test -x \"${dirPath}\"'")  # execute

    # Check other permissions (others should have no access for 750)
    machine.fail("su ${otherUser} -c 'test -r \"${dirPath}\"'")  # no read
    machine.fail("su ${otherUser} -c 'test -w \"${dirPath}\"'")  # no write
    machine.fail("su ${otherUser} -c 'test -x \"${dirPath}\"'")  # no execute
  '';
in
  makeTest {
    name = "johnny-mnemonix";

    nodes.machine = {pkgs, ...}: {
      imports = [
        "${pkgs.home-manager}/nixos/home-manager.nix"
      ];

      # Create test groups
      users.groups = {
        ${testGroup} = {};
        ${otherGroup} = {};
      };

      # Create test users
      users.users = {
        ${testUser} = {
          isNormalUser = true;
          home = "/home/${testUser}";
          group = testGroup;
          shell = pkgs.bash;
        };
        ${otherUser} = {
          isNormalUser = true;
          home = "/home/${otherUser}";
          group = otherGroup;
          shell = pkgs.bash;
        };
      };

      # Enable both shells for testing
      programs.bash.enable = true;
      programs.zsh.enable = true;

      home-manager.users.${testUser} = {...}: {
        imports = [../modules/johnny-mnemonix.nix];

        home = {
          username = testUser;
          homeDirectory = "/home/${testUser}";
          stateVersion = "23.11";
        };

        # Enable the module with test configuration
        johnny-mnemonix = {
          enable = true;
          baseDir = "/home/${testUser}/Documents";
          areas = testConfig;

          # Test custom permissions
          permissions = {
            dirMode = testMode;
            user = testUser;
            group = testGroup;
          };

          # Test cleanup options
          cleanup = {
            enable = true;
            backup = true;
          };
        };
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-${testUser}.service")

      # Test base directory permissions
      with subtest("Base directory permissions"):
          ${checkPerms "/home/${testUser}/Documents"}

      # Test area directory permissions
      with subtest("Area directory permissions"):
          ${checkPerms "/home/${testUser}/Documents/10-19 Personal"}

      # Test category directory permissions
      with subtest("Category directory permissions"):
          ${checkPerms "/home/${testUser}/Documents/10-19 Personal/11 Finance"}

      # Test item directory permissions
      with subtest("Item directory permissions"):
          ${checkPerms "/home/${testUser}/Documents/10-19 Personal/11 Finance/11.01 Budget"}
          ${checkPerms "/home/${testUser}/Documents/10-19 Personal/11 Finance/11.02 Investments"}

      # Test file creation in directories
      with subtest("File operations"):
          # Owner should be able to create files
          machine.succeed("su ${testUser} -c 'touch /home/${testUser}/Documents/test.txt'")
          machine.succeed("su ${testUser} -c 'rm /home/${testUser}/Documents/test.txt'")

          # Group should not be able to create files (750)
          machine.fail("su ${testUser} -g ${testGroup} -c 'touch /home/${testUser}/Documents/test.txt'")

          # Others should not be able to create files
          machine.fail("su ${otherUser} -c 'touch /home/${testUser}/Documents/test.txt'")

      # Test directory traversal
      with subtest("Directory traversal"):
          # Owner should be able to list directory contents
          machine.succeed("su ${testUser} -c 'ls /home/${testUser}/Documents/10-19 Personal/11 Finance'")

          # Group should be able to list directory contents
          machine.succeed("su ${testUser} -g ${testGroup} -c 'ls /home/${testUser}/Documents/10-19 Personal/11 Finance'")

          # Others should not be able to list directory contents
          machine.fail("su ${otherUser} -c 'ls /home/${testUser}/Documents/10-19 Personal/11 Finance'")
    '';
  }
