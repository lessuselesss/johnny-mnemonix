# Tests Cell - Unitype Block
# Unit tests for the unitype transformation system
{
  inputs,
  cell,
}: let
  # Our library (for testing unitype)
  lib = inputs.self.lib.${inputs.nixpkgs.system} or {
    unitype = {};
  };

  nixpkgsLib = inputs.nixpkgs.lib;

  # Test runner utilities
  testLib = import ./lib.nix {lib = nixpkgsLib;};

  # Helper to safely import test file
  safeImport = path:
    if builtins.pathExists path
    then import path {lib = lib;}
    else builtins.trace "Warning: Test file ${path} not found yet" {};
in {
  # Export test runner for use in checks
  inherit testLib;

  # IR tests (28 tests)
  ir = safeImport ./unitype/ir.test.nix;

  # Encoder tests
  encoders = {
    nixos = safeImport ./unitype/encoders/nixos.test.nix;
  };

  # Decoder tests
  decoders = {
    dendrix = safeImport ./unitype/decoders/dendrix.test.nix;
  };
}
