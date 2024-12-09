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

        # Define git commands based on item configuration
        gitCloneCmd =
          if itemConfig ? url && itemConfig.url != null
          then ''
            if [ ! -d "${newPath}/.git" ]; then
              # If directory exists but isn't a git repo, move it
              if [ -d "${newPath}" ]; then
                mv "${newPath}" "${newPath}.bak-$(date +%Y%m%d-%H%M%S)"
              fi
              git clone ${
              if itemConfig ? ref && itemConfig.ref != null
              then "-b ${itemConfig.ref}"
              else ""
            } ${itemConfig.url} "${newPath}"
            else
              # If it's already a git repo, just update it
              cd "${newPath}"
              git fetch
              git checkout ${
              if itemConfig ? ref && itemConfig.ref != null
              then itemConfig.ref
              else "main"
            }
              git pull
            fi
          ''
          else "";

        sparseCheckoutCmd =
          if (itemConfig ? url && itemConfig.url != null && itemConfig ? sparse && itemConfig.sparse != [])
          then ''
            if [ -d "${newPath}/.git" ]; then
              cd "${newPath}"
              git sparse-checkout init
              git sparse-checkout set ${concatStringsSep " " itemConfig.sparse}
            fi
          ''
          else "";

        # Debug final path
        _______ = debugValue "newPath" newPath;
      in ''
        # For non-git directories, create them if they don't exist
        if [ ! -e "${newPath}" ] && [ -z "${gitCloneCmd}" ]; then
          mkdir -p "${newPath}"
        fi

        # Execute git commands if specified
        ${gitCloneCmd}
        ${sparseCheckoutCmd}
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
      export PATH="${pkgs.git}/bin:$PATH"
      ${mkAreaDirs cfg.areas}
    '';
  };
}
