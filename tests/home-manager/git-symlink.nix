{
  pkgs,
  lib,
  home-manager,
  ...
}: let
  mkHomeConfig = {config ? {}, ...}:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../../modules/johnny-mnemonix.nix
        {
          home = {
            username = "testuser";
            homeDirectory = "/home/testuser";
            stateVersion = "23.11";
          };
          johnny-mnemonix = config;
        }
      ];
    };
in {
  # Test git + symlink combination
  test-git-symlink = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-docs";
      spacer = " ";
      areas = {
        "10-19" = {
          name = "Projects";
          categories = {
            "11" = {
              name = "Code";
              items = {
                "11.01" = {
                  name = "My Repo";
                  url = "https://github.com/example/repo.git";
                  target = "/tmp/git-storage/repo";
                  ref = "main";
                };
              };
            };
          };
        };
      };
    };
  };
}
