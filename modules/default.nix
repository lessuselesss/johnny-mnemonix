{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;
in {
  imports = [
    ./core/default.nix
  ];

  options.johnny-mnemonix = {
    enable = mkEnableOption "Johnny Mnemonix document management";

    baseDir = mkOption {
      type = types.addCheck types.path (
        x:
          builtins.substring 0 1 (toString x) == "/"
      );
      apply = toString;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for document structure";
    };

    areas = mkOption {
      type = types.attrs;
      default = {};
      description = "Document areas configuration";
    };

    validation = {
      strict = mkOption {
        type = types.bool;
        default = false;
        description = "Enable strict validation of the document structure";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.bash.shellAliases = {
      "jd" = "cd ${cfg.baseDir}";
    };
    programs.zsh.shellAliases = {
      "jd" = "cd ${cfg.baseDir}";
    };
    programs.fish.shellAliases = {
      "jd" = "cd ${cfg.baseDir}";
    };
  };

  meta = {
    maintainers = ["lessuseless"];
    doc = ./johnny-mnemonix.md;
  };
}
