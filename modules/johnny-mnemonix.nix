{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # XDG paths
  xdgStateHome = cfg.xdg.stateHome or "${config.home.homeDirectory}/.local/state";
  xdgCacheHome = cfg.xdg.cacheHome or "${config.home.homeDirectory}/.cache";
  xdgConfigHome = cfg.xdg.configHome or "${config.home.homeDirectory}/.config";
  xdgDataHome = "${config.home.homeDirectory}/.local/share";

  # Directory locations
  stateDir = "${xdgStateHome}/johnny-mnemonix";
  cacheDir = "${xdgCacheHome}/johnny-mnemonix";
  configDir = "${xdgConfigHome}/johnny-mnemonix";

  stateFile = "${stateDir}/state.json";
  changesFile = "${stateDir}/structure-changes.log";
  cacheFile = "${cacheDir}/cache.json";

  # Cache operations
  mkCacheOps = ''
    read_cache() {
      if [ -f "${cacheFile}" ]; then
        cat "${cacheFile}"
      else
        echo "{}"
      fi
    }

    write_cache() {
      echo "$1" > "${cacheFile}"
    }

    cache_directory_hash() {
      local path="$1"
      local hash="$2"
      local cache=$(read_cache)
      echo "$cache" | ${pkgs.jq}/bin/jq --arg path "$path" --arg hash "$hash" '. + {($path): $hash}' > "${cacheFile}"
    }

    get_cached_hash() {
      local path="$1"
      local cache=$(read_cache)
      echo "$cache" | ${pkgs.jq}/bin/jq -r --arg path "$path" '.[$path] // empty'
    }
  '';

  # Type definitions
  itemOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Directory name for the item";
      };
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional Git repository URL";
      };
      ref = mkOption {
        type = types.str;
        default = "main";
        description = "Git reference (branch, tag, or commit)";
      };
      sparse = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Sparse checkout patterns (empty for full checkout)";
      };
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional path to create symlink to";
      };
    };
  };

  itemType = types.either types.str itemOptionsType;

  # Git wrapper
  gitWithSsh = pkgs.writeShellScriptBin "git-with-ssh" ''
    # Ensure SSH knows about GitHub's host key
    if [ ! -f ~/.ssh/known_hosts ] || ! grep -q "^github.com" ~/.ssh/known_hosts; then
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh
      ${pkgs.openssh}/bin/ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
    fi

    # Set Git to use SSH
    export GIT_SSH="${pkgs.openssh}/bin/ssh"
    export PATH="${lib.makeBinPath [pkgs.git pkgs.openssh]}:$PATH"

    # Run Git command
    exec git "$@"
  '';

  # Generate a stable hash for directory contents
  mkContentHash = path: ''
    if [ -d "${path}" ]; then
      find "${path}" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1
    else
      echo "0000000000000000000000000000000000000000000000000000000000000000"
    fi
  '';

  # Helper to read/write state (updated to use XDG paths)
  mkStateOps = ''
    mkdir -p "${stateDir}" "${cacheDir}" "${configDir}"

    read_state() {
      if [ -f "${stateFile}" ]; then
        cat "${stateFile}"
      else
        echo "{}"
      fi
    }

    write_state() {
      echo "$1" > "${stateFile}"
    }

    update_state() {
      local path="$1"
      local hash="$2"
      local state=$(read_state)
      echo "$state" | ${pkgs.jq}/bin/jq --arg path "$path" --arg hash "$hash" '. + {($path): $hash}'
    }

    log_change() {
      echo "$1" >> "${changesFile}"
    }
  '';

  # Enhanced directory handling
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig: let
      # First, define the item handling function
      mkItemDir = itemId: itemDef: let
        # Convert simple string definitions to attribute set
        itemConfig =
          if isString itemDef
          then {title = itemDef;}
          else itemDef;

        # Construct path with name included
        newPath = "${categoryPath}/${itemId}${cfg.spacer}${itemConfig.title or itemId}";

        # Separate git commands for clarity
        gitCloneCmd =
          if itemConfig ? url
          then ''
            ${gitWithSsh}/bin/git-with-ssh clone ${
              optionalString (itemConfig ? ref) "-b ${itemConfig.ref}"
            } ${itemConfig.url} "${newPath}"
          ''
          else "";

        sparseCheckoutCmd =
          if (itemConfig ? url && itemConfig ? sparse && itemConfig.sparse != [])
          then ''
            cd "${newPath}"
            ${gitWithSsh}/bin/git-with-ssh sparse-checkout set ${concatStringsSep " " itemConfig.sparse}
          ''
          else "";
      in ''
        if [ ! -e "${newPath}" ]; then
          mkdir -p "${newPath}"
          ${gitCloneCmd}
          ${sparseCheckoutCmd}
        fi
      '';
    in
      concatMapStrings (itemId: mkItemDir itemId categoryConfig.items.${itemId})
      (attrNames categoryConfig.items);

    mkAreaDir = areaId: areaConfig:
      concatMapStrings (
        categoryId:
          mkCategoryDirs areaId areaConfig categoryId areaConfig.categories.${categoryId}
      ) (attrNames areaConfig.categories);
  in ''
    # Ensure base directory exists
    mkdir -p "${cfg.baseDir}"

    # Create area directories
    ${concatMapStrings (areaId: mkAreaDir areaId areas.${areaId}) (attrNames areas)}
  '';

  # Shell functions
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

    # Shell completion
    if [[ -n "$ZSH_VERSION" ]]; then
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

    spacer = mkOption {
      type = types.str;
      default = " ";
      example = "-";
      description = "Character(s) to use between ID and name";
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
                  type = types.attrsOf itemType;
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

    xdg = {
      stateHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override default XDG_STATE_HOME location";
      };

      cacheHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override default XDG_CACHE_HOME location";
      };

      configHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override default XDG_CONFIG_HOME location";
      };
    };

    git = {
      autoFetch = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically fetch git repositories";
      };
      fetchInterval = mkOption {
        type = types.int;
        default = 3600;
        description = "Interval between git fetches (in seconds)";
      };
      sparseByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Enable sparse checkout by default for new repositories";
      };
    };

    backup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic backups";
      };
      interval = mkOption {
        type = types.enum ["hourly" "daily" "weekly"];
        default = "daily";
        description = "Backup frequency";
      };
      location = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Backup destination path";
      };
      time = mkOption {
        type = types.str;
        default = "00:00:00";
        description = "Time of day to run backup (HH:MM:SS)";
      };
    };

    programs = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Program configurations";
    };

    home = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Home-manager configurations";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.backup.enable || cfg.backup.location != null;
        message = "backup.location must be set when backup is enabled";
      }
    ];

    home = {
      packages = with pkgs; [
        git
        openssh
        gitWithSsh
        jq
      ];

      activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${mkCacheOps}
        ${mkAreaDirs cfg.areas}
      '';
    };

    # Combine all programs configuration into a single attribute set
    programs = {
      zsh = mkIf cfg.shell.enable {
        enable = true;
        enableCompletion = true;
        initExtra = mkShellFunctions cfg.shell.prefix;
      };

      bash = mkIf cfg.shell.enable {
        enable = true;
        enableCompletion = true;
        initExtra =
          mkShellFunctions cfg.shell.prefix
          + ''
            export JOHNNY_MNEMONIX_CONFIG="${configDir}"
            export JOHNNY_MNEMONIX_CACHE="${cacheDir}"
            export JOHNNY_MNEMONIX_DATA="${xdgDataHome}/johnny-mnemonix"
            export JOHNNY_MNEMONIX_STATE="${stateDir}"
          '';
      };
    };

    systemd.user.timers.johnny-mnemonix-backup = mkIf cfg.backup.enable {
      Timer = {
        Unit = "johnny-mnemonix-backup.service";
        OnCalendar = let
          calendar = {
            hourly = "*-*-* *:00:00";
            daily = "*-*-* ${cfg.backup.time}";
            weekly = "Mon *-*-* ${cfg.backup.time}";
          };
        in
          calendar.${cfg.backup.interval};
        Persistent = true;
      };
    };
  };
}
