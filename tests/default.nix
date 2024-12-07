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

  # Test SSH key setup
  testSshKey = ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
    NhAAAAAwEAAQAAAYEAzAdo3L/CeWXC7c4JGhOT9t9DtxGEkgBZSPYJjBKbHMVYKOT1AAAA
    wQDAH2Ec
    -----END OPENSSH PRIVATE KEY-----
  '';

  testSshKeyPub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA... test@example.com";

  # Test configuration with all item types
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

              # Named directory without Git
              "11.02" = {
                name = "Templates";
              };

              # Git repository with HTTPS
              "11.03" = {
                name = "nix-core";
                url = "https://github.com/nixos/nix";
                ref = "master";
              };

              # Git repository with SSH and sparse checkout
              "11.04" = {
                name = "nixpkgs-docs";
                url = "git@github.com:NixOS/nixpkgs.git";
                ref = "master";
                sparse = ["README.md" "LICENSE"];
              };

              # Symlink test
              "11.05" = {
                name = "Pictures";
                target = "/home/testuser/Pictures";
              };
            };
          };
        };
      };
    };
  };

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

      # Enable SSH daemon for testing
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };

      # Create test user
      users.users.${testUser} = {
        isNormalUser = true;
        home = "/home/${testUser}";
        group = testGroup;
        openssh.authorizedKeys.keys = [testSshKeyPub];
      };

      # Enable home-manager
      home-manager.users.${testUser} = {...}: {
        imports = [../modules/johnny-mnemonix.nix];

        home = {
          username = testUser;
          homeDirectory = "/home/${testUser}";
          stateVersion = "23.11";

          # Ensure SSH is available
          packages = with pkgs; [
            openssh
            git
          ];
        };

        johnny-mnemonix = testConfig;
      };
    };

    testScript = ''
      # Wait for system to be ready
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("home-manager-${testUser}.service")

      # Set up SSH environment
      with subtest("SSH Setup"):
          # Create SSH directory
          machine.succeed("mkdir -p /home/${testUser}/.ssh")
          machine.succeed("chmod 700 /home/${testUser}/.ssh")

          # Add test SSH key
          machine.succeed(
              f"echo '{testSshKey}' > /home/${testUser}/.ssh/id_rsa"
          )
          machine.succeed("chmod 600 /home/${testUser}/.ssh/id_rsa")
          machine.succeed(
              f"echo '{testSshKeyPub}' > /home/${testUser}/.ssh/id_rsa.pub"
          )

          # Set ownership
          machine.succeed(f"chown -R ${testUser}:${testGroup} /home/${testUser}/.ssh")

          # Start SSH agent
          machine.succeed(
              f"su ${testUser} -c 'eval $(ssh-agent) && ssh-add /home/${testUser}/.ssh/id_rsa'"
          )

      with subtest("Directory Types"):
          # Test string-based directory
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.01\\ Budget"
          )

          # Test named directory without Git
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02\\ Templates"
          )
          # Verify it's not a Git repository
          machine.fail(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02\\ Templates/.git"
          )

          # Test Git repository with HTTPS
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03\\ nix-core"
          )
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03\\ nix-core/.git"
          )

          # Test Git repository with SSH and sparse checkout
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.04\\ nixpkgs-docs"
          )
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.04\\ nixpkgs-docs/.git"
          )

      with subtest("Directory Permissions"):
          # Check permissions for string-based directory
          machine.succeed(
              f"test $(stat -c '%a' '/home/{testUser}/Documents/10-19 Personal/11 Projects/11.01 Budget') = '{testMode}'"
          )

          # Check permissions for named directory
          machine.succeed(
              f"test $(stat -c '%a' '/home/{testUser}/Documents/10-19 Personal/11 Projects/11.02 Templates') = '{testMode}'"
          )

          # Check permissions for Git repositories
          machine.succeed(
              f"test $(stat -c '%a' '/home/{testUser}/Documents/10-19 Personal/11 Projects/11.03 nix-core') = '{testMode}'"
          )
          machine.succeed(
              f"test $(stat -c '%a' '/home/{testUser}/Documents/10-19 Personal/11 Projects/11.04 nixpkgs-docs') = '{testMode}'"
          )

      with subtest("Git Repository Content"):
          # Verify HTTPS repository content
          machine.succeed(
              "test -f '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.03 nix-core/README.md'"
          )

          # Verify sparse checkout
          machine.succeed(
              "test -f '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.04 nixpkgs-docs/README.md'"
          )
          machine.succeed(
              "test -f '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.04 nixpkgs-docs/LICENSE'"
          )
          # Verify other files are not present
          machine.fail(
              "test -d '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.04 nixpkgs-docs/nixos'"
          )

      with subtest("Symlinks"):
          # Create target directory
          machine.succeed("mkdir -p /home/${testUser}/Pictures")
          machine.succeed(f"chown ${testUser}:${testGroup} /home/${testUser}/Pictures")

          # Verify symlink creation
          machine.succeed(
              "test -L '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.05 Pictures'"
          )

          # Verify symlink target
          machine.succeed(
              "test $(readlink '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.05 Pictures') = '/home/${testUser}/Pictures'"
          )

          # Verify symlink permissions
          machine.succeed(
              f"test $(stat -c '%U' '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.05 Pictures') = '{testUser}'"
          )
          machine.succeed(
              f"test $(stat -c '%G' '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.05 Pictures') = '{testGroup}'"
          )

      with subtest("Git Repository Configuration"):
          # Check remote URL
          machine.succeed(
              "cd '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.03 nix-core' "
              + "&& git remote get-url origin | grep -q 'https://github.com/nixos/nix'"
          )

          # Check branch
          machine.succeed(
              "cd '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.03 nix-core' "
              + "&& git symbolic-ref --short HEAD | grep -q 'master'"
          )

      with subtest("Idempotency"):
          # Run home-manager switch again
          machine.succeed("su ${testUser} -c 'home-manager switch'")

          # Verify all directories still exist
          machine.succeed("test -d '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.01 Budget'")
          machine.succeed("test -d '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.02 Templates'")
          machine.succeed("test -d '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.03 nix-core/.git'")
          machine.succeed("test -d '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.04 nixpkgs-docs/.git'")
          machine.succeed("test -L '/home/${testUser}/Documents/10-19 Personal/11 Projects/11.05 Pictures'")
    '';
  }
