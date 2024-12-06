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

  # Test domains
  testDomains = {
    "documents" = "Documents";
    "workspace" = "workspace";
    "personal/notes" = "personal/notes";
  };

  # Test user and permissions
  testUser = "testuser";
  testGroup = "users";
  testMode = "0755";

  # Helper to create domain configurations
  mkDomainConfigs = domains: {
    inherit domains;
    areas = {
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
    useDefaultStructure = true;
    permissions = {
      inherit testUser testGroup;
      dirMode = testMode;
    };
  };

  # Test shell commands
  shellPrefix = "jm";

  # Helper to check domain structure
  checkDomain = _domain: baseDir: ''
    # Check base directory exists
    machine.succeed("test -d ${baseDir}")

    # Check area structure
    machine.succeed("test -d ${baseDir}/10-19\\ Personal")
    machine.succeed("test -d ${baseDir}/10-19\\ Personal/11\\ Finance")
    machine.succeed("test -d ${baseDir}/10-19\\ Personal/11\\ Finance/11.01\\ Budget")
    machine.succeed("test -d ${baseDir}/10-19\\ Personal/11\\ Finance/11.02\\ Investments")
  '';

  # Helper to check permissions
  checkPerms = path: ''
    machine.succeed("test $(stat -c '%a' ${path}) = '755'")
    machine.succeed("test $(stat -c '%U' ${path}) = '${testUser}'")
    machine.succeed("test $(stat -c '%G' ${path}) = '${testGroup}'")
  '';

  # Test shell integration
  testShellCommands = baseDir: ''
    # Test basic navigation
    machine.succeed("su ${testUser} -c 'cd && ${shellPrefix} && pwd' | grep -q '${baseDir}'")
    machine.succeed("su ${testUser} -c 'cd && ${shellPrefix} && ${shellPrefix}-up && pwd' | grep -q '/home/${testUser}'")

    # Test number-based navigation
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix} && ${shellPrefix} 11 && pwd' "
      + "| grep -q '${baseDir}/10-19 Personal/11 Finance'"
    )
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix} && ${shellPrefix} 11.01 && pwd' "
      + "| grep -q '${baseDir}/10-19 Personal/11 Finance/11.01 Budget'"
    )

    # Test listing commands
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix}ls' | grep -q '10-19 Personal'"
    )
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix}l' | grep -q '10-19 Personal'"
    )
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix}ll ${baseDir}' | grep -q '10-19 Personal'"
    )
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix}la ${baseDir}' | grep -q '10-19 Personal'"
    )

    # Test find command
    machine.succeed(
      "su ${testUser} -c 'cd && ${shellPrefix}find Finance' "
      + "| grep -q '${baseDir}/10-19 Personal/11 Finance'"
    )

    # Test error cases
    machine.fail(
      "su ${testUser} -c 'cd && ${shellPrefix} nonexistent'"
    )
    machine.fail(
      "su ${testUser} -c 'cd && ${shellPrefix}find'"
    )
  '';

  # Helper to test shell integration for a domain
  checkShellIntegration = domain: baseDir: ''
    with subtest("Shell integration for ${domain}"):
        ${testShellCommands baseDir}
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
      };

      # Create test users
      users.users = {
        ${testUser} = {
          isNormalUser = true;
          home = "/home/${testUser}";
          group = testGroup;
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

        # Add all valid domain configurations with shell integration
        johnny-mnemonix =
          (mkDomainConfigs testDomains)
          // {
            shell = {
              enable = true;
              prefix = shellPrefix;
              aliases = true;
              functions = true;
            };
          };
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-${testUser}.service")

      # Test each valid domain configuration
      with subtest("Valid domain configurations"):
          ${concatStringsSep "\n" (mapAttrsToList (domain: baseDir: ''
          # Test ${domain} domain
          ${checkDomain domain baseDir}
          ${checkPerms baseDir}
          ${checkPerms "${baseDir}/10-19 Personal"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance/11.01 Budget"}
          ${checkPerms "${baseDir}/10-19 Personal/11 Finance/11.02 Investments"}

          # Test shell integration
          ${checkShellIntegration domain baseDir}
        '')
        testDomains)}
    '';
  }
