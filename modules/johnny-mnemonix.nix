{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Sanitize function to remove special characters and limit length
  sanitizeName = name: let
    # Remove special characters, replace spaces with underscores
    cleaned =
      builtins.replaceStrings
      [" " "/" "\\" ":" "*" "?" "\"" "<" ">" "|"]
      ["_" "_" "_" "_" "_" "_" "_" "_" "_" "_"]
      name;
    # Truncate to a reasonable length if needed
    truncated =
      if builtins.stringLength cleaned > 50
      then builtins.substring 0 50 cleaned
      else cleaned;
  in
    truncated;

  # Modify path generation to be more robust
  mkSafePath = base: id: spacer: name: let
    sanitizedId = builtins.replaceStrings [" "] ["_"] id;
    sanitizedName = sanitizeName name;
  in "${base}/${sanitizedId}${spacer}${sanitizedName}";

  # Directory creation function
  mkAreaDirs = areas: let
    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig: let
      areaPath = mkSafePath cfg.baseDir areaId cfg.spacer areaConfig.name;
      categoryPath = mkSafePath areaPath categoryId cfg.spacer categoryConfig.name;

      mkItemDir = itemId: itemDef: let
        itemConfig =
          if isString itemDef
          then {name = itemDef;}
          else itemDef;

        name = sanitizeName itemConfig.name;
        newPath = mkSafePath categoryPath itemId cfg.spacer name;

        # Define commands for git operations
        gitCloneCmd =
          if itemConfig ? url && itemConfig.url != null
          then ''
            if [ ! -d "'${newPath}'" ]; then
              if [ -e "'${newPath}'" ]; then
                mv "'${newPath}'" "'${newPath}.bak-$(date +%Y%m%d-%H%M%S)'"
              fi
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git clone ${
              if itemConfig ? ref && itemConfig.ref != null
              then "-b '${itemConfig.ref}'"
              else ""
            } '${itemConfig.url}' '${newPath}'
            else
              cd '${newPath}'
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git fetch
              git checkout ${
              if itemConfig ? ref && itemConfig.ref != null
              then "'${itemConfig.ref}'"
              else "main"
            }
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git pull
            fi
          ''
          else "";

        sparseCheckoutCmd =
          if (itemConfig ? url && itemConfig.url != null && itemConfig ? sparse && itemConfig.sparse != [])
          then ''
            if [ -d "'${newPath}/.git'" ]; then
              cd '${newPath}'
              git config core.sparseCheckout true
              mkdir -p .git/info
              printf "%s\n" ${builtins.concatStringsSep " " (map (pattern: "'${pattern}'") itemConfig.sparse)} > .git/info/sparse-checkout
              git read-tree -mu HEAD
            fi
          ''
          else "";

        # Define symlink command if target is specified
        symlinkCmd =
          if itemConfig ? target && itemConfig.target != null
          then ''
            echo "Handling symlink for '${newPath}'"
            if [ -e "'${newPath}'" ] && [ ! -L "'${newPath}'" ]; then
              echo "Backing up existing directory"
              mv "'${newPath}'" "'${newPath}.bak-$(date +%Y%m%d-%H%M%S)'"
            fi
            echo "Creating parent directory"
            mkdir -p "$(dirname "'${newPath}'")"
            echo "Creating symlink"
            ln -sfn "'${itemConfig.target}'" "'${newPath}'"
          ''
          else "";
      in ''
        handle_path() {
          echo "Processing path: '${newPath}'"

          # Check for symlink command
          SYMLINK_CMD="${symlinkCmd}"
          if [ -n "$SYMLINK_CMD" ]; then
            echo "Executing symlink command"
            $SYMLINK_CMD
            return
          fi

          # Create directory if needed
          if [ ! -e "'${newPath}'" ]; then
            GIT_CMD="${gitCloneCmd}"
            if [ -z "$GIT_CMD" ]; then
              echo "Creating directory"
              mkdir -p "'${newPath}'"
              return
            fi
          fi

          # Handle git repository
          GIT_CMD="${gitCloneCmd}"
          if [ -n "$GIT_CMD" ]; then
            echo "Executing git commands"
            $GIT_CMD
            SPARSE_CMD="${sparseCheckoutCmd}"
            if [ -n "$SPARSE_CMD" ]; then
              echo "Executing sparse checkout"
              $SPARSE_CMD
            fi
          fi
        }

        handle_path
      '';

      categoryItems = categoryConfig.items or {};
    in
      concatMapStrings
      (itemId: mkItemDir itemId categoryItems.${itemId})
      (attrNames categoryItems);

    mkArea = areaId: let
      areaConfig = areas.${areaId};
      areaCategories = areaConfig.categories or {};
    in
      concatMapStrings
      (categoryId: mkCategoryDirs areaId areaConfig categoryId areaCategories.${categoryId})
      (attrNames areaCategories);
  in
    concatMapStrings mkArea (attrNames areas);

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

  # Type definitions
  itemOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Directory name for the item";
        example = "My Directory";
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

  categoryOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the category";
      };
      items = mkOption {
        type = types.attrsOf (types.either types.str itemOptionsType);
        default = {};
        description = "Items in this category";
      };
    };
  };

  areaOptionsType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the area";
      };
      categories = mkOption {
        type = types.attrsOf categoryOptionsType;
        default = {};
        description = "Categories in this area";
      };
    };
  };
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "johnny-mnemonix";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for document structure";
    };

    spacer = mkOption {
      type = types.str;
      default = " ";
      description = "Spacer between ID and name";
    };

    areas = mkOption {
      type = types.attrsOf areaOptionsType;
      default = {};
      description = "Areas in the structure";
    };

    xdg = {
      stateHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG state home directory";
      };

      cacheHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG cache home directory";
      };

      configHome = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "XDG config home directory";
      };
    };
  };

  config = mkIf cfg.enable {
    home.activation.createJohnnyMnemonixDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH="${lib.makeBinPath [
        pkgs.git
        pkgs.openssh
        pkgs.coreutils
        pkgs.gnused
        pkgs.findutils
      ]}:$PATH"

      ${mkAreaDirs cfg.areas}
    '';
  };
}
