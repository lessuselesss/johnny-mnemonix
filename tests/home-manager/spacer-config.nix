{lib, ...}: {
  name = "spacer-config";

  nodes.machine = {pkgs, ...}: {
    imports = [../../modules/johnny-mnemonix.nix];
    environment.systemPackages = [pkgs.coreutils];
    home-manager.users.testuser = {
      johnny-mnemonix = {
        enable = true;
        baseDir = "/tmp/test-jm";
        spacer = "-";
      };
    };
  };

  testScript = let
    basePath = lib.escapeShellArg "/tmp/test-jm";
    testPaths = [
      "10-19-Personal"
      "10-19-Personal/11-Finance"
      "10-19-Personal/11-Finance/11.01-Budget"
    ];
  in ''
    machine.wait_for_unit("multi-user.target")

    ${lib.concatMapStrings (path: ''
        machine.succeed("test -d ${basePath}/${lib.escapeShellArg path}")
      '')
      testPaths}

    machine.fail("test -d ${basePath}/10-19 Personal")
  '';
}
