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

  # Updated test configuration with both HTTPS and SSH URLs
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

              # HTTPS repository
              "11.02" = {
                name = "nix-core";
                url = "https://github.com/nixos/nix";
                ref = "master";
              };

              # SSH repository
              "11.03" = {
                name = "nixpkgs-docs";
                url = "git@github.com:NixOS/nixpkgs.git";
                ref = "master";
                sparse = ["README.md" "LICENSE"];
              };

              # Another SSH repository
              "11.04" = {
                name = "private-repo";
                url = "git@github.com:lessuselesss/private-repo.git";
                ref = "main";
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

      # Test HTTPS cloning
      with subtest("HTTPS Repository Cloning"):
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.02\\ nix-core/.git"
          )

      # Test SSH cloning
      with subtest("SSH Repository Cloning"):
          # Check if SSH repositories were cloned
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03\\ nixpkgs-docs/.git"
          )
          machine.succeed(
              "test -d /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.04\\ private-repo/.git"
          )

          # Verify SSH configuration
          machine.succeed(
              f"su ${testUser} -c 'ssh-keygen -F github.com || ssh-keyscan github.com >> /home/${testUser}/.ssh/known_hosts'"
          )

      # Test Git operations with SSH
      with subtest("Git Operations with SSH"):
          # Try fetching updates
          machine.succeed(
              f"su ${testUser} -c 'cd /home/${testUser}/Documents/10-19\\ Personal/11\\ Projects/11.03\\ nixpkgs-docs && git fetch'"
          )

      # ... (previous tests remain) ...
    '';
  }
