{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.johnny-mnemonix;
in {
  createDirectories = {
    data = let
      mkAreaDir = areaId: area: "${cfg.baseDir}/${areaId} ${area.name}";
      mkCategoryDir = areaId: area: catId: cat: "${mkAreaDir areaId area}/${catId} ${cat.name}";
      mkItemDir = areaId: area: catId: cat: itemId: name: "${mkCategoryDir areaId area catId cat}/${itemId} ${name}";
    in ''
      # Create base directory
      mkdir -p "${cfg.baseDir}"
      chmod 750 "${cfg.baseDir}"

      # Create area directories
      ${builtins.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs (areaId: area: ''
          mkdir -p "${mkAreaDir areaId area}"
          chmod 750 "${mkAreaDir areaId area}"
        '')
        cfg.areas))}

      # Create category directories
      ${builtins.concatStringsSep "\n" (lib.concatLists (lib.attrValues (lib.mapAttrs (
          areaId: area:
            lib.attrValues (lib.mapAttrs (catId: cat: ''
                mkdir -p "${mkCategoryDir areaId area catId cat}"
                chmod 750 "${mkCategoryDir areaId area catId cat}"
              '')
              area.categories)
        )
        cfg.areas)))}

      # Create item directories
      ${builtins.concatStringsSep "\n" (lib.concatLists (lib.attrValues (lib.mapAttrs (
          areaId: area:
            lib.concatLists (lib.attrValues (lib.mapAttrs (
                catId: cat:
                  lib.attrValues (lib.mapAttrs (itemId: name: ''
                      mkdir -p "${mkItemDir areaId area catId cat itemId name}"
                      chmod 750 "${mkItemDir areaId area catId cat itemId name}"
                    '')
                    cat.items)
              )
              area.categories))
        )
        cfg.areas)))}
    '';
    type = "data";
    after = ["writeBoundary"];
  };
}
