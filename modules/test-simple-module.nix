# Test simple path module
# This declares ownership of ~/test-simple-module
# Johnny-mnemonix will skip operations for this path
{
  config,
  lib,
  pkgs,
  ...
}: {
  # This module controls ~/test-simple-module
  # If johnny-mnemonix config tries to create something at this path,
  # it will be skipped with a warning

  # Add a custom package demonstrating module ownership
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.simple-module-tool = pkgs.writeShellScriptBin "simple-tool" ''
      echo "Simple path module tool"
      echo "This module owns ~/test-simple-module"
    '';
  };
}
