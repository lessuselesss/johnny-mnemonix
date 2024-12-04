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

      fish.functions = {
        jj = ''
          function jj
            set -l code $argv[1]
            set -l base_dir $JOHNNY_MNEMONIX_BASE
            test -z "$base_dir"; and set base_dir $HOME/Documents

            # Validate input
            if not string match -qr '^[0-9.-]+$' -- $code
              echo "Invalid format. Use: XX-YY (area) or XX (category) or XX.YY (item)" >&2
              return 1
            end

            switch $code
              # Area navigation (e.g., 10-19)
              case '[0-9][0-9]-[0-9][0-9]'
                set -l target_dir $base_dir/*$code*/
                if test -d $target_dir
                  cd $target_dir
                else
                  echo "Area not found: $code" >&2
                  return 1
                end

              # Category navigation (e.g., 11)
              case '[0-9][0-9]'
                set -l target_dir $base_dir/*/*$code\ */
                if test -d $target_dir
                  cd $target_dir
                else
                  echo "Category not found: $code" >&2
                  return 1
                end

              # Item navigation (e.g., 11.01)
              case '[0-9][0-9].[0-9][0-9]'
                set -l target_dir $base_dir/*/*/*$code\ */
                if test -d $target_dir
                  cd $target_dir
                else
                  echo "Item not found: $code" >&2
                  return 1
                end

              case '*'
                echo "Invalid Johnny Decimal code format" >&2
                echo "Usage: jj XX-YY (area) or XX (category) or XX.YY (item)" >&2
                return 1
            end
          end
        '';
      };
    };
  };
}
