{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Type for Johnny Decimal ID (e.g., "11.01")
  jdIdType = types.strMatching "[0-9]{2}[.][0-9]{2}";

  # Type for Category ID (e.g., "11")
  categoryIdType = types.strMatching "[0-9]{2}";

  # Type for Area ID (e.g., "10-19")
  areaIdType = types.strMatching "[0-9]{2}-[0-9]{2}";

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
  };

  config = mkIf cfg.enable {
    # Create the base directory
    home.file = let
      # Helper function to create directory paths
      mkDirPath = area: category: id: name: "${cfg.baseDir}/${area.name}/${category.name}/${id} ${name}";

      # Create all directory entries
      mkDirs = foldAttrs (n: a: n) {} (
        concatLists (mapAttrsToList (
            areaId: area:
              concatLists (mapAttrsToList (
                  catId: category:
                    mapAttrsToList (id: name: {
                      "${mkDirPath areaId area catId category id name}".source = null;
                    })
                    category.items
                )
                area.categories)
          )
          cfg.areas)
      );
    in
      mkDirs;

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
