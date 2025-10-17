# Test directory-based module
# Demonstrates directory hierarchy format: modules/{Area}/(Category)/[Item].nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.test-dir-module-tool = pkgs.writeShellScriptBin "test-dir-tool" ''
      echo "Test tool from directory-based module"
      echo "Located at: modules/{20-29} Personal/(20) Projects/[01] Test-Dir-Module.nix"
    '';
  };
}
