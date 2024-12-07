{pkgs}: let
  mkTest = import;
in {
  structure-changes = mkTest ./home-manager/structure-changes.nix {inherit pkgs;};
  spacer-config = mkTest ./home-manager/spacer-config.nix {inherit pkgs;};
}
