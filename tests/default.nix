{pkgs}:
pkgs.nixosTest {
  name = "structure-changes";
  nodes.machine = _: {
    imports = [./home-manager/structure-changes.nix];
  };
}
