{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.johnny-mnemonix;
in {
  imports = [./core.nix];

  options.johnny-mnemonix = {
    enable = mkEnableOption "Johnny Mnemonix document management";

    baseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for document structure (HOMEOFFICE)";
    };

    areas = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the area";
          };
          _module.check = name: area: let
            areaPattern = "^[0-9]{2}-[0-9]{2}$";
          in
            builtins.match areaPattern name
            != null
            || throw "Area ID '${name}' must be in format 'XX-YY' (e.g., '10-19')";

          categories = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = "Name of the category";
                };
                _module.check = name: category: let
                  categoryPattern = "^[0-9]{2}$";
                in
                  builtins.match categoryPattern name
                  != null
                  || throw "Category ID '${name}' must be two digits (e.g., '11')";

                items = mkOption {
                  type = types.attrsOf types.str;
                  description = "Map of ID codes to item names";
                  apply = attrs: let
                    itemPattern = "^[0-9]{2}[.][0-9]{2}$";
                    validateItem = id: name:
                      if builtins.match itemPattern id != null
                      then attrs.${id}
                      else throw "Item ID '${id}' must be in format 'XX.YY' (e.g., '11.01')";
                  in
                    mapAttrs validateItem attrs;
                };
              };
            });
            default = {};
            description = "Categories within this area";
          };
        };
      });
      default = {};
      description = "Defined areas in Johnny Decimal structure";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Add any required packages here
    ];

    # Create the base directory structure
    home.activation.createJohnnyStructure = lib.hm.dag.entryAfter ["writeBoundary"] ''
      createIfNotExists() {
        local dir="$1"
        if [ ! -d "$dir" ]; then
          $DRY_RUN_CMD mkdir -p "$dir"
          echo "Created directory: $dir"
        fi
      }

      createIfNotExists "${cfg.baseDir}"

      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (areaId: area: ''
          createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}"
          ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (catId: category: ''
              createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}"
              ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (itemId: itemName: ''
                  createIfNotExists "${cfg.baseDir}/${areaId} ${area.name}/${catId} ${category.name}/${itemId} ${itemName}"
                '')
                category.items)}
            '')
            area.categories)}
        '')
        cfg.areas)}
    '';

    # Add shell aliases for navigation
    programs.bash.shellAliases = {
      "jd" = "cd ${cfg.baseDir}";
    };

    programs.zsh.shellAliases = {
      "jd" = "cd ${cfg.baseDir}";
    };
  };
}
