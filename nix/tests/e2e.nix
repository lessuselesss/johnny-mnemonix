# Block: End-to-End Tests Exports
# Cell: tests
#
# This block exports end-to-end tests for full system scenarios.

{
  inputs,
  cell,
}: let
  lib = inputs.self.lib.${inputs.nixpkgs.system} or {};
in {
  # E2E tests (8+ tests)
  # home-manager = import ./e2e/home-manager.test.nix {inherit lib;};
  # real-world-scenarios = import ./e2e/real-world-scenarios.test.nix {inherit lib;};
}
