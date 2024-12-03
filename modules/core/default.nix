{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Import submodules
  activation = import ./activation.nix {inherit config lib pkgs;};
in {
  options.johnny-mnemonix.areas = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        name = mkOption {
          type = types.str;
          description = "Name of the area";
        };

        categories = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the category";
              };

              items = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "Map of ID codes to item names";
              };
            };
          });
          default = {};
          description = "Categories within this area";
        };
      };
    });
    default = {};
    description = "Defined areas in Johnny Decimal structure";
  };

  config = mkIf cfg.enable {
    # Create directory structure
    home.activation = activation.createDirectories;

    # Shell integration
    programs = {
      bash.shellAliases = {
        "jd" = "cd ${cfg.baseDir}";
      };

      zsh.shellAliases = {
        "jd" = "cd ${cfg.baseDir}";
      };

      fish.shellAliases = {
        "jd" = "cd ${cfg.baseDir}";
      };
    };
  };
}
