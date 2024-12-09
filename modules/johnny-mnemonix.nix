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

  # Create directories based on configuration
  mkAreaDirs = areas: let
    # Debug function
    debugValue = name: value:
      builtins.trace "Debug: ${name} = ${
        if value == null
        then "null"
        else if builtins.isString value
        then value
        else builtins.toJSON value
      }"
      value;

    mkCategoryDirs = areaId: areaConfig: categoryId: categoryConfig: let
      # Debug area and category config
      _ = debugValue "areaId" areaId;
      __ = debugValue "areaConfig" areaConfig;
      ___ = debugValue "categoryId" categoryId;
      ____ = debugValue "categoryConfig" categoryConfig;

      # Define the area path with validation
      areaPath =
        if !(areaConfig ? name)
        then throw "Area ${areaId} is missing name attribute"
        else if areaConfig.name == null
        then throw "Area ${areaId} has null name"
        else "${cfg.baseDir}/${areaId}${cfg.spacer}${areaConfig.name}";

      # Define the category path with validation
      categoryPath =
        if !(categoryConfig ? name)
        then throw "Category ${categoryId} in area ${areaId} is missing name attribute"
        else if categoryConfig.name == null
        then throw "Category ${categoryId} in area ${areaId} has null name"
        else "${areaPath}/${categoryId}${cfg.spacer}${categoryConfig.name}";

      # First, define the item handling function
      mkItemDir = itemId: itemDef: let
        # Debug item config
        _____ = debugValue "itemId" itemId;
        ______ = debugValue "itemDef" itemDef;

        # Convert simple string definitions to attribute set with validation
        itemConfig =
          if itemDef == null
          then throw "Item ${itemId} in category ${categoryId} (area ${areaId}) is null"
          else if isString itemDef
          then {name = itemDef;}
          else itemDef;

        # Validate item name
        name =
          if !(itemConfig ? name)
          then throw "Item ${itemId} in category ${categoryId} (area ${areaId}) is missing name attribute"
          else if itemConfig.name == null
          then throw "Item ${itemId} in category ${categoryId} (area ${areaId}) has null name"
          else itemConfig.name;

        # Construct path with name included
        newPath = "${categoryPath}/${itemId}${cfg.spacer}${name}";

        # Define symlink command if target is specified
        symlinkCmd =
          if itemConfig ? target && itemConfig.target != null
          then ''
            if test -e "${newPath}" && test ! -L "${newPath}"; then
              # Backup existing directory if it's not a symlink
              mv "${newPath}" "${newPath}.bak-$(date +%Y%m%d-%H%M%S)"
            fi
            # Create parent directory if needed
            mkdir -p "$(dirname "${newPath}")"
            # Create or update symlink
            ln -sfn "${itemConfig.target}" "${newPath}"
          ''
          else "";

        # Debug symlink info
        ________ = debugValue "target" (itemConfig.target or null);

        # Define git commands based on item configuration
        gitCloneCmd =
          if itemConfig ? url && itemConfig.url != null
          then ''
            if test ! -d "${newPath}/.git"; then
              # If directory exists but isn't a git repo, move it
              if test -d "${newPath}"; then
                mv "${newPath}" "${newPath}.bak-$(date +%Y%m%d-%H%M%S)"
              fi
              # Clone with SSH agent forwarding
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git clone ${
              if itemConfig ? ref && itemConfig.ref != null
              then "-b ${itemConfig.ref}"
              else ""
            } ${itemConfig.url} "${newPath}"
            else
              # If it's already a git repo, just update it
              cd "${newPath}"
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git fetch
              git checkout ${
              if itemConfig ? ref && itemConfig.ref != null
              then itemConfig.ref
              else "main"
            }
              GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'" git pull
            fi
          ''
          else "";

        sparseCheckoutCmd =
          if (itemConfig ? url && itemConfig.url != null && itemConfig ? sparse && itemConfig.sparse != [])
          then ''
            if test -d "${newPath}/.git"; then
              cd "${newPath}"
              git config core.sparseCheckout true
              mkdir -p .git/info
              printf "%s\n" ${builtins.concatStringsSep " " (map (pattern: "\"${pattern}\"") itemConfig.sparse)} > .git/info/sparse-checkout
              git read-tree -mu HEAD
            fi
          ''
          else "";

        # Debug final path
        _______ = debugValue "newPath" newPath;
      in ''
        # Handle symlinks first
        if test -n "${symlinkCmd}"; then
          ${symlinkCmd}
        fi

        # Only proceed with regular directory/git operations if not a symlink
        if test -z "${symlinkCmd}"; then
          # For non-git directories, create them if they don't exist
          if test ! -e "${newPath}" && test -z "${gitCloneCmd}"; then
            mkdir -p "${newPath}"
          fi

          # Execute git commands if specified
          if test -n "${gitCloneCmd}"; then
            ${gitCloneCmd}
            ${sparseCheckoutCmd}
          fi
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
    ${concatMapStrings (areaId: mkAreaDir areaId cfg.areas.${areaId}) (attrNames cfg.areas)}
  '';
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "johnny-mnemonix";

    baseDir = mkOption {
      type = types.str;
      description = "Base directory for the structure";
    };

    spacer = mkOption {
      type = types.str;
      default = " ";
      description = "Spacer between ID and name in directory names";
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
      # Ensure required utilities are in PATH
      export PATH="${lib.makeBinPath [
        pkgs.git
        pkgs.openssh
        pkgs.coreutils
        pkgs.gnused
        pkgs.findutils
      ]}:$PATH"

      # Start SSH agent if not running
      if test -z "$SSH_AUTH_SOCK"; then
        eval $(ssh-agent -s)
        trap "ssh-agent -k" EXIT
      fi

      # Create XDG directories if they don't exist
      mkdir -p "${stateDir}"
      mkdir -p "${cacheDir}"
      mkdir -p "${configDir}"

      # Ensure proper permissions
      chmod 700 "${stateDir}"
      chmod 700 "${cacheDir}"
      chmod 700 "${configDir}"

      # Initialize state file if it doesn't exist
      if test ! -f "${stateFile}"; then
        echo '{}' > "${stateFile}"
      fi

      # Run directory creation with SSH agent maintained
      ${mkAreaDirs cfg.areas}
    '';
  };
}
