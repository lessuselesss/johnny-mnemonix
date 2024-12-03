{
  config,
  lib,
  # pkgs,
  ...
}:
with lib; let
  cfg = config.mnemonic;
in {
  imports = [
    ./plugins
  ];

  options.mnemonic = {
    # Core options will go here
  };

  config = mkIf cfg.enable {
    # Core configuration will go here
  };
}
