# Unitype Helpers - flake-utils-plus Integration
#
# Provides composable helpers for creating well-structured flakes using flake-utils-plus.
# These helpers handle channel management, host configuration, and module exports.

{
  lib,
  flake-utils-plus,
}: {
  # Transform IR to complete flake using mkFlake
  # Handles channels, hosts, overlays automatically
  mkFlakeFromIR = ir: {
    channels ? {},
    hostDefaults ? {},
    overlays ? [],
    ...
  } @ args:
    flake-utils-plus.lib.mkFlake ({
        # Inherit inputs from IR metadata
        inherit (ir.meta) inputs;

        # Default channel configuration
        channels.nixpkgs.input = ir.meta.inputs.nixpkgs or inputs.nixpkgs;

        # Configure host from IR
        hosts = {
          ${ir.id} = {
            system = ir.meta.system;
            modules = ir.payload.modules or [];
            channelName = "nixpkgs";
          };
        };

        # Apply provided overlays
        sharedOverlays = overlays;
      }
      // (builtins.removeAttrs args ["channels" "hostDefaults" "overlays"]));

  # Export modules from IR to organized attribute set
  # Converts file list to properly namespaced modules
  exportModulesFromIR = ir: moduleFiles:
    flake-utils-plus.lib.exportModules moduleFiles;

  # Export overlays from IR
  # Organizes overlays by aspect or category
  exportOverlaysFromIR = ir: overlayFiles:
    flake-utils-plus.lib.exportOverlays overlayFiles;

  # Export packages from IR using overlays
  # Generates per-system packages from overlay definitions
  exportPackagesFromIR = ir: channels:
    flake-utils-plus.lib.exportPackages ir.payload.overlays or [] channels;

  # Create multi-channel transformation
  # Useful for transformations that need both stable and unstable packages
  mkMultiChannelFlake = ir: {
    channels ? {
      # Default: stable + unstable
      nixpkgs-stable.input = ir.meta.inputs.nixpkgs-stable or inputs.nixpkgs;
      nixpkgs-unstable.input = ir.meta.inputs.nixpkgs-unstable or inputs.nixpkgs;
    },
    ...
  } @ args:
    flake-utils-plus.lib.mkFlake (args // {inherit channels;});

  # Host configuration builder from IR
  # Creates host definitions with sensible defaults
  mkHostFromIR = ir: extraConfig:
    {
      system = ir.meta.system;
      modules = ir.payload.modules or [];
      specialArgs = ir.payload.specialArgs or {};
    }
    // extraConfig;

  # Channel configuration from IR metadata
  mkChannelConfigFromIR = ir: channelName: {
    input = ir.meta.inputs.${channelName} or inputs.nixpkgs;
    patches = ir.payload.patches or [];
    config = ir.meta.channelsConfig or {};
  };

  # Access to full flake-utils-plus API
  # For advanced use cases not covered by helpers
  lib = flake-utils-plus.lib;
}
