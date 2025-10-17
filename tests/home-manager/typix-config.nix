{
  pkgs,
  lib,
  home-manager,
  typix ? null,
  ...
}: let
  mkHomeConfig = {config ? {}, ...}:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          _module.args = {inherit typix;};
        }
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
  # Test Typix basic configuration
  test-typix-basic = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-docs";
      spacer = " ";
      typix = {
        enable = true;
        autoCompileOnActivation = true;
        watch = {
          enable = false;
        };
      };
      areas = {
        "10-19" = {
          name = "Documents";
          categories = {
            "11" = {
              name = "Writing";
              items = {
                "11.01" = "Papers";
              };
            };
          };
        };
      };
    };
  };

  # Test Typix with watch service
  test-typix-watch = mkHomeConfig {
    config = {
      enable = true;
      baseDir = "/tmp/test-docs";
      spacer = " ";
      typix = {
        enable = true;
        autoCompileOnActivation = false;
        watch = {
          enable = true;
          interval = 3;
        };
      };
      areas = {
        "10-19" = {
          name = "Documents";
          categories = {
            "11" = {
              name = "Writing";
              items = {
                "11.01" = "Papers";
              };
            };
          };
        };
      };
    };
  };
}
