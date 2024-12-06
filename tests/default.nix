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
    toUpper
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

  # Test domains
  testDomains = {
    documents = "/home/${testUser}/Documents";
    pictures = "/home/${testUser}/Pictures";
    downloads = "/home/${testUser}/Downloads";
  };

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

  # Helper function to check domain setup
  checkDomain = domain: baseDir: ''
    # Check XDG user directory is set correctly
    machine.succeed(
        "grep -q 'XDG_${toUpper domain}_DIR=\"${baseDir}\"' "
        + "/home/${testUser}/.config/user-dirs.dirs"
    )

    # Check shell alias works for the domain
    machine.succeed(
        "su ${testUser} -c 'source ~/.bashrc && jd && pwd' | "
        + "grep -q '${baseDir}'"
    )
    machine.succeed(
        "su ${testUser} -c 'source ~/.zshrc && jd && pwd' | "
        + "grep -q '${baseDir}'"
    )

    # Check default structure if enabled
    machine.succeed("test -d '${baseDir}/00-09 System'")
    machine.succeed("test -d '${baseDir}/00-09 System/01 User Directories'")
    machine.succeed("test -d '${baseDir}/00-09 System/01 User Directories/01.01 Documents'")
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

      # Test different domain configurations
      home-manager.users.${testUser} = {...}: {
        imports = [../modules/johnny-mnemonix.nix];

        home = {
          username = testUser;
          homeDirectory = "/home/${testUser}";
          stateVersion = "23.11";
        };

        # Test Documents domain (default)
        johnny-mnemonix = {
          enable = true;
          domain = "documents";
          areas = testConfig;
          useDefaultStructure = true;
          permissions = {
            dirMode = testMode;
            user = testUser;
            group = testGroup;
          };
        };

        # Test Pictures domain
        johnny-mnemonix-pictures = {
          enable = true;
          domain = "pictures";
          areas = testConfig;
          useDefaultStructure = true;
          permissions = {
            dirMode = testMode;
            user = testUser;
            group = testGroup;
          };
        };

        # Test Downloads domain
        johnny-mnemonix-downloads = {
          enable = true;
          domain = "downloads";
          areas = testConfig;
          useDefaultStructure = true;
          permissions = {
            dirMode = testMode;
            user = testUser;
            group = testGroup;
          };
        };
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-${testUser}.service")

      # Test each domain configuration
      with subtest("Domain configurations"):
          ${concatStringsSep "\n" (mapAttrsToList (domain: baseDir: ''
          # Test ${domain} domain
          ${checkDomain domain baseDir}
          ${checkPerms baseDir}
          ${checkPerms "${baseDir}/10-19 Personal"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance/11.01 Budget"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance/11.02 Investments"}
        '')
        testDomains)}

      # Test file operations in each domain
      with subtest("File operations across domains"):
          ${concatStringsSep "\n" (mapAttrsToList (_: baseDir: ''
          # Owner should be able to create files
          machine.succeed("su ${testUser} -c 'touch ${baseDir}/test.txt'")
          machine.succeed("su ${testUser} -c 'rm ${baseDir}/test.txt'")

          # Group should not be able to create files (750)
          machine.fail("su ${testUser} -g ${testGroup} -c 'touch ${baseDir}/test.txt'")

          # Others should not be able to create files
          machine.fail("su ${otherUser} -c 'touch ${baseDir}/test.txt'")
        '')
        testDomains)}
    '';
  }
