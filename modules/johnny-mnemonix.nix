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

  # State file locations
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

    log_change() {
      echo "$1" >> "${changesFile}"
    }
  '';

  # Enhanced directory handling
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig: let
      newPath = "${cfg.baseDir}/${areaId}${cfg.spacer}${areaConfig.name}/${categoryId}${cfg.spacer}${categoryConfig.name}";
    in ''
      ${mkStateOps}

      # Generate hash of current state
      current_hash=$(${mkContentHash newPath})

      # Find matching directory by content hash
      state=$(read_state)
      matching_path=$(echo "$state" | ${pkgs.jq}/bin/jq -r --arg hash "$current_hash" \
        'to_entries | map(select(.value == $hash)) | .[0].key // empty')

      if [ -n "$matching_path" ] && [ "$matching_path" != "${newPath}" ]; then
        # Found matching content at different path - handle rename
        echo "# Content match found: $matching_path -> ${newPath}" >> "${cfg.baseDir}/.structure-changes"

        if [ ! -d "${newPath}" ]; then
          # Move directory to new location
          mkdir -p "$(dirname "${newPath}")"
          mv "$matching_path" "${newPath}"
        else
          # Merge contents if target exists
          cp -r "$matching_path"/* "${newPath}/" 2>/dev/null || true
          rm -rf "$matching_path"
        fi
      fi

      # Create directory if it doesn't exist
      mkdir -p "${newPath}"

      # Update state with new hash
      new_hash=$(${mkContentHash newPath})
      new_state=$(update_state "${newPath}" "$new_hash")
      write_state "$new_state"

      # Handle Git repositories or symlinks if specified
      ${
        if categoryConfig.items.${itemId}.url != null
        then ''
          if [ ! -d "${newPath}" ]; then
            ${gitWithSsh}/bin/git-with-ssh clone ${
            if categoryConfig.items.${itemId}.sparse != []
            then "--sparse"
            else ""
          } \
              --branch ${categoryConfig.items.${itemId}.ref} \
              ${categoryConfig.items.${itemId}.url} "${newPath}"

            ${optionalString (categoryConfig.items.${itemId}.sparse != []) ''
            cd "${newPath}"
            ${gitWithSsh}/bin/git-with-ssh sparse-checkout set ${concatStringsSep " " categoryConfig.items.${itemId}.sparse}
          ''}
          fi
        ''
        else if categoryConfig.items.${itemId}.target != null
        then ''
          if [ ! -e "${newPath}" ]; then
            ln -s "${categoryConfig.items.${itemId}.target}" "${newPath}"
          fi
        ''
        else ""
      }
    '';

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
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        git
        openssh
        gitWithSsh
        jq
      ];

      activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${mkAreaDirs cfg.areas}
      '';
    };

    programs.zsh = mkIf cfg.shell.enable {
      enable = true;
      enableCompletion = true;
      initExtraFirst = ''
        ${mkShellFunctions cfg.shell.prefix}
      '';
    };

    programs.bash = mkIf cfg.shell.enable {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        ${mkShellFunctions cfg.shell.prefix}
      '';
    };
  };
}
