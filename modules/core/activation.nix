{
  config,
  lib,
  ...
}: let
  cfg = config.johnny-mnemonix;
in {
  createDirectories = {
    createJohnnyStructure = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Helper function to create directories if they don't exist
      createIfNotExists() {
        local dir="$1"
        if [ ! -d "$dir" ]; then
          $DRY_RUN_CMD mkdir -p "$dir"
          echo "Created directory: $dir"
        fi
      }

      # Create base directory
      createIfNotExists "${cfg.baseDir}"

      # Create area directories
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (areaId: area: ''
          createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}"

          # Create category directories
          ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (catId: category: ''
              createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}"

              # Create item directories
              ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (itemId: itemName: ''
                  createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}/${itemId} ${itemName}"
                '')
                category.items)}
            '')
            area.categories)}
        '')
        cfg.areas)}

      # Set appropriate permissions
      $DRY_RUN_CMD chmod 755 "${cfg.baseDir}"
    '';
  };
}
