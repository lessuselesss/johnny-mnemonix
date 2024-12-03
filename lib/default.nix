{nixpkgs}: {
  schema = import ./schema.nix {inherit nixpkgs;};
  utils = import ./utils.nix {inherit nixpkgs;};
}
