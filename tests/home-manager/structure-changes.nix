{
  pkgs,
  lib,
  ...
}: let
  initialConfig = {
    johnny-mnemonix = {
      enable = true;
      baseDir = "/tmp/test-jm";
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

  updatedConfig = {
    johnny-mnemonix = {
      enable = true;
      baseDir = "/tmp/test-jm";
      areas = {
        "10-19" = {
          name = "Personal";
          categories = {
            "11" = {
              name = "Money";
              items = {
                "11.02" = {
                  name = "Budget";
                  target = "/tmp/test-jm/10-19 Personal/11 Finance/11.01 Budget";
                };
              };
            };
          };
        };
      };
    };
  };

  # Test helpers
  assertFileContains = file: content: ''
    if ! grep -q "${content}" "${file}"; then
      echo "Expected to find '${content}' in ${file}"
      exit 1
    fi
  '';

  assertDirExists = dir: ''
    if [ ! -d "${dir}" ]; then
      echo "Expected directory ${dir} to exist"
      exit 1
    fi
  '';
in {
  name = "structure-changes";

  nodes.machine = {pkgs, ...}: {
    imports = [../../modules/johnny-mnemonix.nix];
    home-manager.users.testuser = lib.mkMerge [
      initialConfig
      # Apply initial config, then updated config
      (lib.mkAfter updatedConfig)
    ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Check structure changes log
    ${assertFileContains "/tmp/test-jm/.structure-changes" "Renamed: Finance -> Money"}
    ${assertFileContains "/tmp/test-jm/.structure-changes" "Moved: 11.01 Budget -> 11.02 Budget"}

    # Verify directory structure
    ${assertDirExists "/tmp/test-jm/10-19 Personal"}
    ${assertDirExists "/tmp/test-jm/10-19 Personal/11 Money"}
    ${assertDirExists "/tmp/test-jm/10-19 Personal/11 Money/11.02 Budget"}

    # Check symlink
    machine.succeed("test -L '/tmp/test-jm/10-19 Personal/11 Money/11.02 Budget'")
  '';
}
