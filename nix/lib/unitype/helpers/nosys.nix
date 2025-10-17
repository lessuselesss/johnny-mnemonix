# Unitype Helpers - nosys Integration
#
# Provides system-agnostic flake output generation.
# Simplifies decoders by eliminating per-system boilerplate.

{
  lib,
  nosys,
}: {
  # Wrap flake outputs to make them system-agnostic
  # Automatically generates system-specific variants
  mkSystemAgnosticFlake = {
    systems ? ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"],
    outputs,
    pkgsConfig ? {},
  }:
    nosys ({
        inherit systems;
        pkgs.config = pkgsConfig;
      }
      // outputs);

  # Create system-independent library outputs (prefixed with _)
  # These will be available without system discrimination
  mkLibOutput = libAttrs: {
    _lib = libAttrs;
  };

  # Create regular outputs that will be system-specific
  # nosys will automatically distribute these across systems
  mkOutputs = outputs: outputs;

  # Helper: Convert IR to nosys-compatible outputs
  # Decoders can use this to simplify their output generation
  irToNosysOutputs = ir: {
    # System-independent metadata
    _meta = {
      description = ir.meta.description or "";
      jdId = ir.id;
      aspects = ir.hints.aspects or {};
    };

    # System-specific outputs
    # nosys will handle the system variants
    packages = {
      # Generated from IR payload
    };

    apps = {
      # Generated from IR payload
    };

    nixosModules = {
      # Generated from IR payload
    };
  };

  # Combine with other flake generation helpers
  # Usage: mkFlakeWithNosys ir decoder
  mkFlakeWithNosys = ir: decoderFn: let
    baseOutputs = decoderFn ir;
  in
    mkSystemAgnosticFlake {
      systems = [ir.meta.system];
      outputs = baseOutputs;
    };

  # Access to raw nosys for advanced use
  raw = nosys;
}
