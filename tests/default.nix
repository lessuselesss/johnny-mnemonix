{ lib, ... }:
let
  inherit (lib) nixosTest;
in
nixosTest {
  name = "johnny-mnemonix";

  nodes.machine = { pkgs, ... }: {
    imports = [
      "${pkgs.home-manager}/nixos/home-manager.nix"
    ];

    users.users.test = {
      isNormalUser = true;
      home = "/home/test";
    };

    home-manager.users.test = {
      imports = [ ../modules/johnny-mnemonix.nix ];

      home = {
        username = "test";
        homeDirectory = "/home/test";
        stateVersion = "23.11";
      };

      johnny-mnemonix = {
        enable = true;
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

    machine.succeed("test -d /home/test/Documents")
    machine.succeed("test -d '/home/test/Documents/10-19 Personal'")
    machine.succeed("test -d '/home/test/Documents/10-19 Personal/11 Finance'")
    machine.succeed("test -d '/home/test/Documents/10-19 Personal/11 Finance/11.01 Budget'")

    machine.succeed("su - test -c 'source ~/.bashrc && jd'")
    machine.succeed("su - test -c 'source ~/.zshrc && jd'")

    machine.succeed("test -L /home/test/.config/user-dirs.dirs")
  '';
}
