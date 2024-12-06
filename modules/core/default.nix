{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;

  # Import utility functions
  utils = import ../../lib/utils.nix {nixpkgs = pkgs;};

  # Helper function to create directory commands
  mkDirCmd = path: ''
    $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${path}"
    $DRY_RUN_CMD chmod $VERBOSE_ARG 750 "${path}"
  '';

  # Helper functions for directory creation
  mkAreaDirs = mapAttrsToList (areaId: area:
    mkDirCmd (utils.path.makeAreaPath {
      baseDir = cfg.baseDir;
      areaId = areaId;
      areaName = area.name;
    }))
  cfg.areas;

  mkCategoryDirs = mapAttrsToList (areaId: area:
    mapAttrsToList (catId: cat:
      mkDirCmd (utils.path.makeCategoryPath {
        baseDir = cfg.baseDir;
        areaId = areaId;
        areaName = area.name;
        categoryId = catId;
        categoryName = cat.name;
      }))
    area.categories)
  cfg.areas;

  mkItemDirs = mapAttrsToList (areaId: area:
    mapAttrsToList (catId: cat:
      mapAttrsToList (itemId: name:
        mkDirCmd (utils.path.makeItemPath {
          baseDir = cfg.baseDir;
          areaId = areaId;
          areaName = area.name;
          categoryId = catId;
          categoryName = cat.name;
          itemId = itemId;
          itemName = name;
        }))
      cat.items)
    area.categories)
  cfg.areas;
in {
  config = mkIf cfg.enable {
    home.activation.createJohnnyMnemonixStructure = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create base directory
      ${mkDirCmd cfg.baseDir}

      # Create area directories
      ${concatStringsSep "\n" mkAreaDirs}

      # Create category directories
      ${concatStringsSep "\n" (concatLists mkCategoryDirs)}

      # Create item directories
      ${concatStringsSep "\n" (concatLists (concatLists mkItemDirs))}
    '';
  };
}
