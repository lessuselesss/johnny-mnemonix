# Test Johnny Decimal formatted module
# This should create: ~/Declaritive Office/10-19 Projects/10 Code/19 Test-Project/
{
  config,
  lib,
  pkgs,
  ...
}: {
  # This module's filename automatically generates johnny-mnemonix configuration
  # The directory structure is created from the parsed filename

  # Add a custom package for this project
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.test-project-tool = pkgs.writeShellScriptBin "test-project" ''
      echo "Test project tool from JD-formatted module"
      echo "This demonstrates flake-parts module integration"
    '';
  };
}
