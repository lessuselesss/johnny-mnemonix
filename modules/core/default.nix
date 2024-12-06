{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.johnny-mnemonix = {
    baseDir = mkOption {
      type = types.path;
      apply = toString;
      description = "Base directory for document structure";
      example = "/home/user/Documents";
      check = x: builtins.substring 0 1 (toString x) == "/";
    };
  };

  # Add meta information
  meta = {
    maintainers = ["lessuseless"];
    doc = ./johnny-mnemonix.md; # Add documentation
  };

  # Import submodules
  activation = import ./activation.nix {inherit config lib pkgs;};

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
