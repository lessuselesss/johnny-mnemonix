{
  pkgs,
  lib,
  ...
}: let
  # Helper to create test files with specific content
  mkTestFile = name: content: ''
    echo "${content}" > "${name}"
  '';

  # Initial configuration
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
                "11.01" = {
                  name = "Budget";
                };
              };
            };
          };
        };
      };
    };
  };

  # Updated configuration with renamed category
  renamedConfig = {
    johnny-mnemonix = {
      enable = true;
      baseDir = "/tmp/test-jm";
      areas = {
        "10-19" = {
          name = "Personal";
          categories = {
            "11" = {
              name = "Money"; # Renamed from "Finance"
              items = {
                "11.01" = {
                  name = "Budget";
                };
              };
            };
          };
        };
      };
    };
  };

  # Test assertions
  assertStateFile = query: ''
    state_content=$(cat /tmp/test-jm/.johnny-mnemonix-state.json)
    if ! echo "$state_content" | ${pkgs.jq}/bin/jq -e "${query}" > /dev/null; then
      echo "State file assertion failed!"
      echo "Expected query: ${query}"
      echo "Got content: $state_content"
      exit 1
    fi
  '';

  assertDirExists = dir: ''
    if [ ! -d "${dir}" ]; then
      echo "Directory ${dir} does not exist!"
      exit 1
    fi
  '';

  assertDirNotExists = dir: ''
    if [ -d "${dir}" ]; then
      echo "Directory ${dir} should not exist!"
      exit 1
    fi
  '';

  assertContentPreserved = dir: content: ''
    if [ "$(cat ${dir}/test.txt)" != "${content}" ]; then
      echo "Content in ${dir}/test.txt was not preserved!"
      echo "Expected: ${content}"
      echo "Got: $(cat ${dir}/test.txt)"
      exit 1
    fi
  '';
in {
  name = "state-tracking";

  nodes.machine = {pkgs, ...}: {
    imports = [../../modules/johnny-mnemonix.nix];
    home-manager.users.testuser = lib.mkMerge [
      initialConfig
      # We'll apply renamedConfig later in the test
    ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Create initial structure and add some content
    machine.succeed('''
      # Create test content
      mkdir -p "/tmp/test-jm/10-19 Personal/11 Finance/11.01 Budget"
      ${mkTestFile "/tmp/test-jm/10-19 Personal/11 Finance/11.01 Budget/test.txt" "test content"}

      # Initial build
      home-manager switch
    ''')

    # Verify initial state
    machine.succeed('''
      ${assertDirExists "/tmp/test-jm/10-19 Personal/11 Finance"}
      ${assertStateFile ".[].path | select(contains(\\\"Finance\\\")) | length > 0"}
    ''')

    # Apply configuration with renamed category
    machine.succeed('''
      # Update home-manager configuration
      ${lib.generators.toJSON {} renamedConfig} > /tmp/renamed-config.json
      home-manager switch -I johnny-mnemonix-config=/tmp/renamed-config.json

      # Verify directory structure after rename
      ${assertDirExists "/tmp/test-jm/10-19 Personal/11 Money"}
      ${assertDirNotExists "/tmp/test-jm/10-19 Personal/11 Finance"}
      ${assertContentPreserved "/tmp/test-jm/10-19 Personal/11 Money/11.01 Budget" "test content"}

      # Verify state file updates
      ${assertStateFile ".[].path | select(contains(\\\"Money\\\")) | length > 0"}
    ''')

    # Test content hash matching
    machine.succeed('''
      # Create directory with identical content
      mkdir -p "/tmp/test-jm/10-19 Personal/11 Test"
      cp -r "/tmp/test-jm/10-19 Personal/11 Money/11.01 Budget"/* "/tmp/test-jm/10-19 Personal/11 Test/"

      # Verify hash matching works
      ${assertStateFile ".[].path | select(contains(\\\"Test\\\")) | length > 0"}
      ${assertStateFile "to_entries | map(select(.value == .[\\\"Money\\\"].hash)) | length == 2"}
    ''')

    # Test conflict handling
    machine.succeed('''
      # Create conflicting content
      mkdir -p "/tmp/test-jm/10-19 Personal/11 Conflict"
      ${mkTestFile "/tmp/test-jm/10-19 Personal/11 Conflict/test.txt" "different content"}

      # Verify different content produces different hash
      ${assertStateFile "to_entries | map(.value) | unique | length == 3"}
    ''')
  '';
}
