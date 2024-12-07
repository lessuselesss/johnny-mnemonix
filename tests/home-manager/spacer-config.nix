{
  pkgs,
  lib,
  ...
}: {
  name = "spacer-config";

  nodes.machine = {...}: {
    imports = [../../modules/johnny-mnemonix.nix];
    home-manager.users.testuser = {
      johnny-mnemonix = {
        enable = true;
        baseDir = "/tmp/test-jm";
        spacer = "-"; # Test with hyphen
        areas = {
          "10-19" = {
            name = "Personal";
            categories = {
              "11" = {
                name = "Finance";
                items = {
                  "11.01" = "Budget";
                };
              };
            };
          };
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Check directory names use correct spacer
    machine.succeed("test -d '/tmp/test-jm/10-19-Personal'")
    machine.succeed("test -d '/tmp/test-jm/10-19-Personal/11-Finance'")
    machine.succeed("test -d '/tmp/test-jm/10-19-Personal/11-Finance/11.01-Budget'")

    # Verify spaces aren't used
    machine.fail("test -d '/tmp/test-jm/10-19 Personal'")
  '';
}
