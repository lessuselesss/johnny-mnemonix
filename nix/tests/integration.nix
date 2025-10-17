# Block: Integration Tests Exports
# Cell: tests
#
# This block exports integration tests that verify cross-layer interactions.

{
  inputs,
  cell,
}: let
  lib = inputs.self.lib.${inputs.nixpkgs.system} or {};
in {
  # Integration tests (15+ tests)
  # two-pass-loading = import ./integration/two-pass-loading.test.nix {inherit lib;};
  # self-validation = import ./integration/self-validation.test.nix {inherit lib;};
  # framework-integration = import ./integration/framework-integration.test.nix {inherit lib;};
}
