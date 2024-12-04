{pkgs ? import <nixpkgs> {}}: let
  # Improved structure generation with chunking
  generateLargeStructure = count: let
    # Generate in chunks of 100 to avoid memory issues
    chunkSize = 100;
    chunks = builtins.ceil (count / chunkSize);

    # Generate a single chunk
    generateChunk = offset: size:
      builtins.listToAttrs (builtins.genList (n: {
          name = "area-${toString (offset + n)}";
          value = {
            categories = generateCategories (offset + n) (size / 10);
          };
        })
        size);

    # Generate categories with limited items
    generateCategories = areaNum: size:
      builtins.listToAttrs (builtins.genList (n: {
          name = "cat-${toString n}";
          value = {
            items = generateItems n 5; # Limit items per category
          };
        })
        size);

    # Generate a reasonable number of items
    generateItems = catNum: size:
      builtins.listToAttrs (builtins.genList (n: {
          name = "item-${toString n}";
          value = "Test Item ${toString n}";
        })
        size);

    # Combine chunks
    combineChunks = chunks: offset:
      if chunks == 0
      then {}
      else
        generateChunk (offset * chunkSize) (
          if chunks == 1
          then count - (offset * chunkSize)
          else chunkSize
        )
        // combineChunks (chunks - 1) (offset + 1);
  in
    combineChunks chunks 0;
in {
  name = "johnny-mnemonix-performance";

  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [../../modules];

    johnny-mnemonix = {
      enable = true;
      areas = generateLargeStructure 1000;
    };
  };

  # Improved test script with better metrics
  testScript = ''
    import time
    import resource

    def measure_performance():
        start_time = time.time()
        start_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

        machine.wait_for_unit("home-manager-test.service")

        end_time = time.time()
        end_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

        duration = end_time - start_time
        memory_used = (end_memory - start_memory) / 1024  # Convert to MB

        print(f"Performance Metrics:")
        print(f"Time taken: {duration:.2f}s")
        print(f"Memory used: {memory_used:.2f}MB")

        # Fail if performance thresholds are exceeded
        assert duration < 5.0, f"Time threshold exceeded: {duration:.2f}s > 5.0s"
        assert memory_used < 512, f"Memory threshold exceeded: {memory_used:.2f}MB > 512MB"

    measure_performance()
  '';
}
