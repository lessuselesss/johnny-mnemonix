{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Create a wrapper script that ensures proper SSH and Git configuration
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

  # Rename to itemOptionsType since it now handles more than just git
  itemOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Directory name for the item";
      };
      # Git options
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
      # Symlink option
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional path to create symlink to";
      };
    };
  };

  # Update the item type to support both strings and the new options
  itemType = types.either types.str itemOptionsType;

  # Helper to create directories and clone repositories
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig:
      concatMapStrings (itemId: let
        itemConfig = categoryConfig.items.${itemId};
        baseItemPath = "${cfg.baseDir}/${areaId}-${areaConfig.name}/${categoryId}-${categoryConfig.name}/${itemId}";
      in
        if isString itemConfig
        then ''
          mkdir -p "${baseItemPath}-${itemConfig}"
        ''
        else ''
          # Create parent directory if it doesn't exist
          mkdir -p "$(dirname "${baseItemPath}")"

          ${
            if itemConfig.url != null
            then ''
              # Git repository handling
              if [ ! -d "${baseItemPath}-${itemConfig.name}" ]; then
                ${gitWithSsh}/bin/git-with-ssh clone ${
                if itemConfig.sparse != []
                then "--sparse"
                else ""
              } \
                  --branch ${itemConfig.ref} \
                  ${itemConfig.url} "${baseItemPath}-${itemConfig.name}"

                ${optionalString (itemConfig.sparse != []) ''
                cd "${baseItemPath}-${itemConfig.name}"
                ${gitWithSsh}/bin/git-with-ssh sparse-checkout set ${concatStringsSep " " itemConfig.sparse}
              ''}
              fi
            ''
            else if itemConfig.target != null
            then ''
              # Symlink handling
              if [ ! -e "${baseItemPath}-${itemConfig.name}" ]; then
                ln -s "${itemConfig.target}" "${baseItemPath}-${itemConfig.name}"
              fi
            ''
            else ''
              # Regular directory
              mkdir -p "${baseItemPath}-${itemConfig.name}"
            ''
          }
        '') (attrNames categoryConfig.items);

    mkAreaDir = areaId: areaConfig:
      concatMapStrings (
        categoryId:
          mkCategoryDirs areaId areaConfig categoryId areaConfig.categories.${categoryId}
      ) (attrNames areaConfig.categories);
  in ''
    # Ensure base directory exists first
    mkdir -p "${cfg.baseDir}"

    # Handle any renamed directories from previous configurations
    ${concatMapStrings (
      oldPath:
        mkSafeRename oldPath "${cfg.baseDir}/new-${oldPath}"
    ) (attrNames areas)}

    # Create area directories
    ${concatMapStrings (areaId: mkAreaDir areaId areas.${areaId}) (attrNames areas)}
  '';

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

  # Helper function to safely rename directories
  mkSafeRename = oldPath: newPath: ''
    if [ -d "${oldPath}" ] && [ ! -d "${newPath}" ]; then
      # Comment out old path instead of removing
      # mv "${oldPath}" "${newPath}"
      echo "# Renamed: ${oldPath} -> ${newPath}" >> "${cfg.baseDir}/.structure-changes"
    fi
  '';

  # Helper function to handle moved items
  mkHandleMoved = oldPath: newPath: ''
    if [ -d "${oldPath}" ] && [ ! -d "${newPath}" ]; then
      # Comment out old path instead of moving
      # mv "${oldPath}/*" "${newPath}/"
      echo "# Moved: ${oldPath} -> ${newPath}" >> "${cfg.baseDir}/.structure-changes"
    fi
  '';

  # Helper function to mark deprecated paths
  mkMarkDeprecated = path: reason: ''
    if [ -d "${path}" ]; then
      # Comment out instead of removing
      # touch "${path}/.deprecated"
      echo "# Deprecated: ${path} - ${reason}" >> "${cfg.baseDir}/.structure-changes"
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
                  type = types.attrsOf itemType;
                  description = "Items in the category (string or git repository)";
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
      home = {
        packages = with pkgs; [
          git
          openssh
          gitWithSsh
        ];

        file = {
          # SSH configuration
          ".ssh/config".text = ''
            Host github.com
              User git
              IdentityFile ~/.ssh/id_rsa
              StrictHostKeyChecking accept-new
          '';

          # Shell functions
          ".local/share/johnny-mnemonix/shell-functions.sh".text =
            mkShellFunctions cfg.shell.prefix;
        };

        activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
          # Store previous structure hash for comparison
          structureHashFile="${cfg.baseDir}/.structure-hash"
          currentHash=$(echo '${builtins.toJSON cfg.areas}' | sha256sum | cut -d' ' -f1)

          # Check if structure has changed
          if [ -f "$structureHashFile" ]; then
            prevHash=$(cat "$structureHashFile")
            if [ "$currentHash" != "$prevHash" ]; then
              # Structure has changed - handle migrations
              echo "Directory structure changes detected..."

              # Create new directories
              ${mkAreaDirs cfg.areas}

              # Handle renamed/moved directories
              # ... existing directory creation code ...

              # Create backup of old structure (optional)
              timestamp=$(date +%Y%m%d_%H%M%S)
              # Comment out old structure instead of removing
              # mv "$structureHashFile" "${structureHashFile}.backup.$timestamp"

              # Log structural changes
              echo "# Structure changes on $(date)" >> "${cfg.baseDir}/.structure-changes"
              echo "Previous hash: $prevHash" >> "${cfg.baseDir}/.structure-changes"
              echo "Current hash: $currentHash" >> "${cfg.baseDir}/.structure-changes"
              echo "---" >> "${cfg.baseDir}/.structure-changes"
            fi
          else
            # First time setup
            ${mkAreaDirs cfg.areas}
          fi

          # Update structure hash
          echo "$currentHash" > "$structureHashFile"

          # Handle moved directories
          ${concatMapStrings (
            oldPath:
              mkHandleMoved oldPath "${cfg.baseDir}/moved-${oldPath}"
          ) (attrNames cfg.areas)}

          # Mark deprecated paths
          ${concatMapStrings (
            path:
              mkMarkDeprecated path "Deprecated in latest configuration"
          ) (attrNames cfg.areas)}
        '';
      };

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
