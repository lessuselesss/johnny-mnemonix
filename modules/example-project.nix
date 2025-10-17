# Example flake-parts modules
#
# This file shows two module formats supported by johnny-mnemonix:
#
# 1. JOHNNY DECIMAL FORMAT (Declarative Structure):
#    Filename: [cat.item]{area-range area-name}__(cat cat-name)__[item item-name].nix
#    Example:  [10.19]{10-19 Projects}__(10 Code)__[19 My-Project].nix
#    Creates:  ~/Declaritive Office/10-19 Projects/10 Code/19 My-Project/
#
#    Validation:
#    - Category from [10.19] must match (10 ...)
#    - Item from [10.19] must match [19 ...]
#    - Category 10 must fall within range 10-19
#
# 2. SIMPLE PATH FORMAT (Override System):
#    Filename: simple-name.nix
#    Example:  example-project.nix
#    Declares:  ~/example-project (blocks johnny-mnemonix from managing it)
#
# This example file uses the Simple Path Format.
# When johnny-mnemonix tries to create ~/example-project:
# - Build warning emitted
# - Git/symlink operations skipped
# - Module has full control
{
  config,
  lib,
  ...
}: {
  # You can add flake-parts configuration here
  # For example, per-system packages, checks, etc.

  # perSystem = { pkgs, ... }: {
  #   packages.example-tool = pkgs.writeShellScriptBin "example" ''
  #     echo "Custom tool for ~/example-project"
  #   '';
  # };

  # Or add flake-wide outputs
  # flake = {
  #   # Add custom flake outputs here
  # };
}
