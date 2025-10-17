# Unitype Helpers - call-flake Integration
#
# Provides utilities for dynamically evaluating flakes for transformation.
# This is crucial for extracting real configuration from external flakes.

{
  lib,
  call-flake,
}: {
  # Evaluate a flake from its URL
  # Returns the full evaluated flake with outputs, inputs, sourceInfo
  evalFlake = flakeUrl: let
    # Fetch the flake
    flakeSrc = builtins.getFlake flakeUrl;
  in
    flakeSrc;

  # Evaluate a flake from lock file with overrides
  # Useful for extracting configs without full evaluation
  evalFlakeFromLock = {
    lockFileStr,
    overrides ? {},
  }:
    call-flake {
      inherit lockFileStr overrides;
    };

  # Extract nixosConfigurations from a flake URL
  # Returns: { hostname = nixosConfiguration; ... }
  extractNixosConfigurations = flakeUrl: let
    flake = builtins.getFlake flakeUrl;
  in
    flake.nixosConfigurations or {};

  # Extract a specific nixosConfiguration for encoding
  # Returns the configuration ready for unitype encoding
  extractNixosConfig = flakeUrl: hostname: let
    configs = extractNixosConfigurations flakeUrl;
  in
    configs.${hostname}
    or (throw "nixosConfiguration '${hostname}' not found in ${flakeUrl}");

  # Extract homeConfigurations from a flake URL
  extractHomeConfigurations = flakeUrl: let
    flake = builtins.getFlake flakeUrl;
  in
    flake.homeConfigurations or flake.homeManagerConfigurations or {};

  # Extract a specific homeConfiguration for encoding
  extractHomeConfig = flakeUrl: username: let
    configs = extractHomeConfigurations flakeUrl;
  in
    configs.${username}
    or (throw "homeConfiguration '${username}' not found in ${flakeUrl}");

  # Extract darwinConfigurations from a flake URL
  extractDarwinConfigurations = flakeUrl: let
    flake = builtins.getFlake flakeUrl;
  in
    flake.darwinConfigurations or {};

  # Extract all configurations from a flake (auto-detect type)
  # Returns: { nixos = {...}; home = {...}; darwin = {...}; }
  extractAllConfigurations = flakeUrl: let
    flake = builtins.getFlake flakeUrl;
  in {
    nixos = flake.nixosConfigurations or {};
    home = flake.homeConfigurations or flake.homeManagerConfigurations or {};
    darwin = flake.darwinConfigurations or {};
  };

  # Helper: Get flake metadata (description, inputs, etc.)
  getFlakeMetadata = flakeUrl: let
    flake = builtins.getFlake flakeUrl;
  in {
    description = flake.description or "";
    inputs = builtins.attrNames (flake.inputs or {});
    outputs = builtins.attrNames flake;
    sourceInfo = flake.sourceInfo or null;
  };

  # Extract configuration modules from a nixosConfiguration
  # This gets the actual module list for transformation
  extractConfigModules = nixosConfig: let
    # Try to access the modules via options
    modules =
      nixosConfig._module.args.modules
      or nixosConfig.options._module.args.value.modules
      or [];
  in
    modules;

  # Access to raw call-flake for advanced use
  raw = call-flake;
}
