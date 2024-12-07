{
  pkgs,
  lib,
  ...
}: let
  # Mock home-manager configuration
  mockConfig = {
    home.homeDirectory = "/home/test";
    xdg.cacheHome = "/home/test/.cache";

    johnny-mnemonix = {
      enable = true;
      baseDir = "/home/test/Documents";
      areas = {
        "10-19" = {
          name = "Test";
          categories = {
            "11" = {
              name = "Cache Test";
              items = {
                "11.01" = "Test Dir";
              };
            };
          };
        };
      };
    };
  };

  # Test that cache operations work
  testCache = pkgs.writeShellScript "test-cache" ''
    set -e

    # Use mock config values with escaped paths
    export HOME=${lib.escapeShellArg mockConfig.home.homeDirectory}
    export XDG_CACHE_HOME=${lib.escapeShellArg mockConfig.xdg.cacheHome}

    # Setup test environment
    mkdir -p $HOME/.cache/johnny-mnemonix
    mkdir -p $HOME/Documents

    # Test cache initialization
    cache=$(read_cache)
    if [ "$cache" != "{}" ]; then
      echo "❌ Cache initialization failed"
      exit 1
    fi

    # Test cache writing
    test_path="/home/test/Documents/test"
    test_hash="abc123"
    cache_directory_hash "$test_path" "$test_hash"

    # Test cache reading
    cached_hash=$(get_cached_hash "$test_path")
    if [ "$cached_hash" != "$test_hash" ]; then
      echo "❌ Cache read/write failed"
      exit 1
    fi

    echo "✅ Cache tests passed"
  '';
in {
  name = "johnny-mnemonix-cache-tests";

  test = ''
    # Run cache tests
    ${testCache}
  '';
}
