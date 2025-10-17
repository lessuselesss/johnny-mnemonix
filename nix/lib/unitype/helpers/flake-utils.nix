# Unitype Helpers - flake-utils Integration
#
# Provides composable helpers for multi-system transformations using flake-utils.
# These helpers ensure transformed flakes work correctly across all target systems.

{
  lib,
  flake-utils,
}: {
  # Transform IR to multi-system outputs using eachDefaultSystem
  # Usage: mkMultiSystemOutputs ir decoder
  mkMultiSystemOutputs = ir: decoder:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Inject system into IR metadata
        systemIR = ir // {
          meta = ir.meta // {inherit system;};
        };
      in
        decoder.decode systemIR);

  # Transform IR to custom system set outputs
  # Usage: mkSystemOutputs ["x86_64-linux" "aarch64-darwin"] ir decoder
  mkSystemOutputs = systems: ir: decoder:
    flake-utils.lib.eachSystem systems (system:
      let
        systemIR = ir // {
          meta = ir.meta // {inherit system;};
        };
      in
        decoder.decode systemIR);

  # Standardize app creation from IR
  # Ensures apps have correct structure for `nix run`
  mkAppFromIR = ir: {
    drv,
    exePath ? "/bin/${ir.id}",
    ...
  }:
    flake-utils.lib.mkApp {
      inherit drv;
      inherit (ir.meta) name;
      inherit exePath;
    };

  # Flatten nested package hierarchies in transformed output
  # Useful when IR contains deeply nested package structures
  flattenPackages = packages:
    flake-utils.lib.flattenTree packages;

  # Available system references for type-safe system selection
  # Usage: helpers.systems.x86_64-linux
  systems = flake-utils.lib.system;

  # Get default systems list
  # Returns: ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]
  defaultSystems = flake-utils.lib.defaultSystems;

  # Merge multiple transformed sub-flakes sharing common inputs
  # Useful for splitting large transformations into composable pieces
  meld = flake-utils.lib.meld;
}
