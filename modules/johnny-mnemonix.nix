{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Type for a single item (ID + name)
  itemType = types.attrsOf types.str;

  # Type for a category
  categoryType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the category";
        example = "Finance";
      };
      items = mkOption {
        type = itemType;
        description = "Map of Johnny Decimal IDs to item names";
        example = {
          "11.01" = "Budget";
          "11.02" = "Investments";
        };
      };
    };
  };

  # Type for an area
  areaType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the area";
        example = "Personal";
      };
      categories = mkOption {
        type = types.attrsOf categoryType;
        description = "Map of category IDs to category configurations";
      };
    };
  };

  # New options for directory permissions
  permissionsType = types.submodule {
    options = {
      dirMode = mkOption {
        type = types.str;
        default = "0755";
        description = "Permissions for created directories (octal string)";
        example = "0700";
      };
      user = mkOption {
        type = types.str;
        default = config.home.username;
        description = "Owner of the directories";
      };
      group = mkOption {
        type = types.str;
        default = "users";
        description = "Group owner of the directories";
      };
    };
  };

  # Helper function to create directory paths
  mkDirPath = _: area: _: category: id: name: "${cfg.baseDir}/${area.name}/${category.name}/${id} ${name}";

  # Helper function to create directory entries for a single item
  mkItemDir = areaId: area: catId: category: id: name: {
    "${mkDirPath areaId area catId category id name}" = {
      source = null;
      inherit (cfg.permissions) dirMode user group;
    };
  };

  # Helper function to process all items in a category
  mkCategoryDirs = areaId: area: catId: category:
    mapAttrsToList
    (id: name: mkItemDir areaId area catId category id name)
    category.items;

  # Helper function to process all categories in an area
  mkAreaDirs = areaId: area:
    concatLists
    (mapAttrsToList
      (catId: category: mkCategoryDirs areaId area catId category)
      area.categories);

  # Create all directory entries
  mkDirs =
    foldAttrs
    (x: _: x)
    {}
    (concatLists (mapAttrsToList mkAreaDirs cfg.areas));
in {
  options.johnny-mnemonix = {
    enable = mkEnableOption "Johnny Decimal document management";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for Johnny Decimal structure";
    };

    areas = mkOption {
      type = types.attrsOf areaType;
      default = {};
      description = "Map of area IDs to area configurations";
    };

    # New permissions option
    permissions = mkOption {
      type = permissionsType;
      default = {};
      description = "Permissions for created directories";
    };

    # New cleanup option
    cleanup = {
      enable = mkEnableOption "Clean up directories when disabled";
      backup = mkOption {
        type = types.bool;
        default = true;
        description = "Create a backup before cleaning up directories";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create the base directory structure with permissions
    home.file =
      mkDirs
      // {
        ${cfg.baseDir} = {
          source = null;
          inherit (cfg.permissions) dirMode user group;
        };
      };

    # Add shell aliases
    programs.bash.shellAliases = {
      jd = "cd ${cfg.baseDir}";
    };

    programs.zsh.shellAliases = {
      jd = "cd ${cfg.baseDir}";
    };

    # Ensure XDG compliance
    xdg.userDirs = {
      documents = cfg.baseDir;
      enable = true;
    };
  };
}
