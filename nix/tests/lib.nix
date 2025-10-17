# Test Library - Test Runner Utilities
# Provides helper functions for running tests using nixpkgs lib.runTests

{lib}: {
  # Run tests and create a derivation that fails if any tests fail
  # Usage: runTests "my-component" testSuite
  runTests = name: tests: let
    # Run the tests using lib.runTests
    results = lib.runTests tests;

    # Check if all tests passed
    allPassed = builtins.all (r: r.expected == r.result) results;

    # Format test results for display
    formatResult = result:
      if result.expected == result.result
      then " ${result.name}"
      else ''
         ${result.name}
          Expected: ${builtins.toJSON result.expected}
          Got:      ${builtins.toJSON result.result}
      '';

    resultSummary = builtins.concatStringsSep "\n" (map formatResult results);

    passCount = builtins.length (builtins.filter (r: r.expected == r.result) results);
    failCount = builtins.length (builtins.filter (r: r.expected != r.result) results);
    totalCount = builtins.length results;
  in
    # Create a derivation that represents the test run
    lib.trivial.pipe results [
      # If all passed, create a success derivation
      (r:
        if allPassed
        then
          builtins.trace ''

            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
             ${name}: All tests passed (${toString totalCount}/${toString totalCount})
            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
          ''
          lib.runCommand "test-${name}-success" {} ''
            echo "Test suite: ${name}" > $out
            echo "Status: SUCCESS" >> $out
            echo "Passed: ${toString passCount}/${toString totalCount}" >> $out
            echo "" >> $out
            echo "${resultSummary}" >> $out
          ''
        else
          builtins.trace ''

            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
             ${name}: Tests failed (${toString passCount}/${toString totalCount} passed)
            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
            ${resultSummary}
            PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP
          ''
          lib.runCommand "test-${name}-failure" {} ''
            echo "Test suite: ${name}" > $out
            echo "Status: FAILURE" >> $out
            echo "Passed: ${toString passCount}/${toString totalCount}" >> $out
            echo "" >> $out
            echo "${resultSummary}" >> $out
            exit 1
          '')
    ];

  # Run a test suite and return just the pass/fail status
  # Useful for quick checks
  quickTest = name: tests: let
    results = lib.runTests tests;
    allPassed = builtins.all (r: r.expected == r.result) results;
  in allPassed;

  # Combine multiple test suites into one
  # Usage: combineTests [suite1 suite2 suite3]
  combineTests = testSuites:
    builtins.foldl' (acc: suite: acc // suite) {} testSuites;

  # Create a test that should fail (for testing error cases)
  # Usage: shouldFail "description" (expr that should throw)
  shouldFail = description: expr: {
    inherit description;
    expected = null;
    result = let
      attempt = builtins.tryEval expr;
    in
      if attempt.success then attempt.value else null;
  };
}
