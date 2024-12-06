{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Helper to create directories
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig:
      mapAttrs' (itemId: itemName: {
        name = "${cfg.baseDir}/${areaId}-${areaConfig.name}/${categoryId}-${categoryConfig.name}/${itemId}-${itemName}";
        value.directory = {};
      })
      categoryConfig.items;

    mkAreaDir = areaId: areaConfig:
      mapAttrs' (
        categoryId: categoryConfig:
          mkCategoryDirs areaId areaConfig categoryId categoryConfig
      )
      areaConfig.categories;
  in
    mapAttrs mkAreaDir areas;

  # Helper to create shell functions
  mkShellFunctions = prefix: ''
    # Basic navigation
    ${prefix}() {
      local base="${cfg.baseDir}"
      if [ -z "$1" ]; then
        cd "$base"
      else
        local target=$(find "$base" -type d -name "*$1*" | head -n 1)
        if [ -n "$target" ]; then
          cd "$target"
        else
          echo "No matching directory found"
          return 1
        fi
      fi
    }

    # Up navigation
    ${prefix}-up() {
      cd ..
    }

    # Listing commands
    ${prefix}ls() {
      ls "${cfg.baseDir}"
    }

    ${prefix}l() {
      ls -l "${cfg.baseDir}"
    }

    ${prefix}ll() {
      ls -la "$@"
    }

    ${prefix}la() {
      ls -la "$@"
    }

    # Find command
    ${prefix}find() {
      if [ -z "$1" ]; then
        echo "Usage: ${prefix}find <pattern>"
        return 1
      fi
      find "${cfg.baseDir}" -type d -name "*$1*"
    }

    # Basic command completion
    if [[ -n "$ZSH_VERSION" ]]; then
      # ZSH completion
      compdef _jm_completion ${prefix}
      compdef _jm_completion ${prefix}ls
      compdef _jm_completion ${prefix}find

      function _jm_completion() {
        local curcontext="$curcontext" state line
        typeset -A opt_args

        case "$words[1]" in
          ${prefix})
            _arguments '1:directory:_jm_dirs'
            ;;
          ${prefix}ls)
            _arguments '1:directory:_jm_dirs'
            ;;
          ${prefix}find)
            _message 'pattern to search for'
            ;;
        esac
      }

      function _jm_dirs() {
        local base="${cfg.baseDir}"
        _files -W "$base" -/
      }

    elif [[ -n "$BASH_VERSION" ]]; then
      # Bash completion
      complete -F _jm_completion ${prefix}
      complete -F _jm_completion ${prefix}ls
      complete -F _jm_completion ${prefix}find

      function _jm_completion() {
        local cur prev
        COMPREPLY=()
        cur="$2"
        prev="$3"
        base="${cfg.baseDir}"

        case "$1" in
          ${prefix})
            COMPREPLY=($(compgen -d "$base/$cur" | sed "s|$base/||"))
            ;;
          ${prefix}ls)
            COMPREPLY=($(compgen -d "$base/$cur" | sed "s|$base/||"))
            ;;
          ${prefix}find)
            # No completion for find pattern
            ;;
        esac
      }
    fi
  '';
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "johnny-mnemonix";

    baseDir = mkOption {
      type = types.str;
      description = "Base directory for johnny-mnemonix";
    };

    shell = {
      enable = mkEnableOption "shell integration";
      prefix = mkOption {
        type = types.str;
        default = "jm";
        description = "Command prefix for shell integration";
      };
      aliases = mkEnableOption "shell aliases";
      functions = mkEnableOption "shell functions";
    };

    areas = mkOption {
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
                  description = "Items in the category";
                };
              };
            });
            description = "Categories within the area";
          };
        };
      });
      default = {};
      description = "Areas configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file.".local/share/johnny-mnemonix/.keep".text = "";

      home.file = mkMerge [
        (mkAreaDirs cfg.areas)
        {
          ".local/share/johnny-mnemonix/shell-functions.sh" = mkIf cfg.shell.enable {
            text = mkShellFunctions cfg.shell.prefix;
            executable = true;
          };
        }
      ];

      programs.zsh = mkIf cfg.shell.enable {
        enable = true;
        enableCompletion = true;
        initExtraFirst = ''
          # Source johnny-mnemonix functions
          if [ -f $HOME/.local/share/johnny-mnemonix/shell-functions.sh ]; then
            source $HOME/.local/share/johnny-mnemonix/shell-functions.sh
          fi
        '';
      };
    }
  ]);
}
