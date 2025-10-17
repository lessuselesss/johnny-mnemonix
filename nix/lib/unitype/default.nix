# Unitype - Universal Type Transformation System
#
# Layer 5: Transformation layer that converts between any Nix types through
# a canonical intermediate representation (IR).
#
# Instead of N² transformations, we implement 2N (N encoders + N decoders).

{lib}: let
  # Need to make lib.unitype available for encoders/decoders to use
  # This creates a circular dependency, but it's okay because Nix is lazy
  unitype = {
    ir = import ./ir/definition.nix {inherit lib;};
  };

  # Extend lib with unitype for encoder/decoder access
  libWithUnitype = lib // {
    unitype = unitype;
  };

  # Helpers - Composable utilities from external libraries
  # These are available to encoders/decoders via lib.unitype.helpers
  helpers = {
    # flake-utils integration (multi-system, mkApp, flattenTree)
    # Note: These require flake-utils input to be available
    # flake-utils = import ./helpers/flake-utils.nix {
    #   inherit lib;
    #   flake-utils = inputs.flake-utils;
    # };

    # flake-utils-plus integration (mkFlake, exportModules, channels)
    # Note: These require flake-utils-plus input to be available
    # flake-utils-plus = import ./helpers/flake-utils-plus.nix {
    #   inherit lib;
    #   flake-utils-plus = inputs.flake-utils-plus;
    # };

    # Helpers will be activated when encoders/decoders receive inputs
    # For now, they're defined but not loaded to avoid requiring inputs
  };
in {
  # IR (Intermediate Representation) - The "Rosetta Stone"
  ir = unitype.ir;

  # Encoders - Convert from specific types to IR
  encoders = {
    nixos = import ./encoders/nixos.nix {lib = libWithUnitype;};
    # dendrix = import ./encoders/dendrix.nix { lib = libWithUnitype; };
    # ...
  };

  # Decoders - Convert from IR to specific types
  decoders = {
    dendrix = import ./decoders/dendrix.nix {lib = libWithUnitype;};
    # nixos = import ./decoders/nixos.nix { lib = libWithUnitype; };
    # iso = import ./decoders/iso.nix { lib = libWithUnitype; };
    # ...
  };

  # Helpers - Exported for encoder/decoder use
  # Encoders/decoders can access via: lib.unitype.helpers.flakeUtils.*
  inherit helpers;

  # Transform engine (to be implemented)
  # transform = sourceType: targetType: value: result;

  # Registry (to be implemented)
  # registry = import ./registry/default.nix { inherit lib; };
}
