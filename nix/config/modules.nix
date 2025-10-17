# Block: Configuration Modules Exports
# Cell: config
#
# This block exports the self-describing numerical-named-index hierarchy
# composed of flake-parts modules that define the default base configuration.

{
  inputs,
  cell,
}: {
  # All config modules exported for flake-parts integration
  # These modules will be moved from /modules/ to /nix/config/ in the future

  # NOTE: Currently using placeholder imports until modules are migrated
  # TODO: Move modules from /modules/[01.xx]*.nix to /nix/config/01-xx-*.nix

  # base-octets = import ./01-01-base-octets.nix;
  # numbers-ranges-rules = import ./01-02-numbers-ranges-rules.nix;
  # name-space = import ./01-03-name-space.nix;
  # syntax = import ./01-04-syntax.nix;
  # nix-module-validation = import ./01-05-nix-module-validation.nix;
  # flake-parts-validation = import ./01-06-flake-parts-validation.nix;
  # indexor-rules = import ./01-07-indexor-rules.nix;
}
