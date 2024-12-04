{ config, lib, pkgs, ... }:

with lib;
let
  # Import core module components
  core = import ./core {
    inherit config lib pkgs;
  };
in {
  imports = [
    ./core/default.nix
  ];

  options.johnny-mnemonix = {
    enable = mkEnableOption "Johnny Mnemonix document management";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for document structure (HOMEOFFICE)";
    };

    # Re-export core options
    inherit (core.options) areas;
  };

  config = mkIf config.johnny-mnemonix.enable {
    # Re-export core configuration
    inherit (core.config) 
      home
      programs;
  };
}
