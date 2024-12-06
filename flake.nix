{
  description = "Flattened Johnny Mnemonix configuration example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: let
    # Core validation functions
    validateStructure = structure: let
      rules = {
        area = {
          id = {
            pattern = "^[0-9]{2}-[0-9]{2}$";
            message = "Area ID must be in format XX-YY (e.g., 10-19)";
            validate = value: builtins.match rules.area.id.pattern value != null;
          };
          name = {
            pattern = "^[A-Za-z0-9][A-Za-z0-9 _-]*$";
            message = "Area name must start with alphanumeric and contain only letters, numbers, spaces, underscores, or hyphens";
            validate = value: builtins.match rules.area.name.pattern value != null;
          };
        };
        category = {
          id = {
            pattern = "^[0-9]{2}$";
            message = "Category ID must be two digits (e.g., 11)";
            validate = value: builtins.match rules.category.id.pattern value != null;
          };
          name = {
            pattern = "^[A-Za-z0-9][A-Za-z0-9 _-]*$";
            message = "Category name must start with alphanumeric";
            validate = value: builtins.match rules.category.name.pattern value != null;
          };
        };
        item = {
          id = {
            pattern = "^[0-9]{2}[.][0-9]{2}$";
            message = "Item ID must be in format XX.YY (e.g., 11.01)";
            validate = value: builtins.match rules.item.id.pattern value != null;
          };
          name = {
            pattern = "^[A-Za-z0-9][A-Za-z0-9 _-]*$";
            message = "Item name must start with alphanumeric";
            validate = value: builtins.match rules.item.name.pattern value != null;
          };
        };
      };

      validateArea = areaId: area:
        if !rules.area.id.validate areaId
        then false
        else if !rules.area.name.validate area.name
        then false
        else true;

      validateCategory = categoryId: category:
        if !rules.category.id.validate categoryId
        then false
        else if !rules.category.name.validate category.name
        then false
        else true;

      validateItem = itemId: itemName:
        if !rules.item.id.validate itemId
        then false
        else if !rules.item.name.validate itemName
        then false
        else true;

      # Validate entire structure
      isValid = builtins.all (
        areaId: let
          area = structure.${areaId};
        in
          validateArea areaId area
          && builtins.all (
            catId: let
              category = area.categories.${catId};
            in
              validateCategory catId category
              && builtins.all (
                itemId:
                  validateItem itemId category.items.${itemId}
              ) (builtins.attrNames category.items)
          ) (builtins.attrNames area.categories)
      ) (builtins.attrNames structure);
    in {
      valid = isValid;
      rules = rules;
    };

    # Directory creation function
    mkDirs = baseDir: areas: let
      mkAreaDir = areaId: area: "${baseDir}/${areaId} ${area.name}";
      mkCategoryDir = areaId: area: catId: cat: "${mkAreaDir areaId area}/${catId} ${cat.name}";
      mkItemDir = areaId: area: catId: cat: itemId: name: "${mkCategoryDir areaId area catId cat}/${itemId} ${name}";
    in ''
      # Create base directory
      mkdir -p "${baseDir}"
      chmod 750 "${baseDir}"

      # Create area directories
      ${builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (areaId: area: ''
          mkdir -p "${mkAreaDir areaId area}"
          chmod 750 "${mkAreaDir areaId area}"
        '')
        areas))}

      # Create category directories
      ${builtins.concatStringsSep "\n" (builtins.concatLists (builtins.attrValues (builtins.mapAttrs (
          areaId: area:
            builtins.attrValues (builtins.mapAttrs (catId: cat: ''
                mkdir -p "${mkCategoryDir areaId area catId cat}"
                chmod 750 "${mkCategoryDir areaId area catId cat}"
              '')
              area.categories)
        )
        areas)))}

      # Create item directories
      ${builtins.concatStringsSep "\n" (builtins.concatLists (builtins.attrValues (builtins.mapAttrs (
          areaId: area:
            builtins.concatLists (builtins.attrValues (builtins.mapAttrs (
                catId: cat:
                  builtins.attrValues (builtins.mapAttrs (itemId: name: ''
                      mkdir -p "${mkItemDir areaId area catId cat itemId name}"
                      chmod 750 "${mkItemDir areaId area catId cat itemId name}"
                    '')
                    cat.items)
              )
              area.categories))
        )
        areas)))}
    '';
  in {
    homeConfigurations."example" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        ./modules/default.nix
        {
          home.username = "lessuseless";
          home.homeDirectory = "/Users/lessuseless";
          home.stateVersion = "24.11";

          johnny-mnemonix = {
            enable = true;
            baseDir = "/Users/lessuseless/Documents";
            validation.strict = true;

            # Your existing areas configuration
            areas = {
              "10-19" = {
                name = "Personal";
                categories = {
                  "11" = {
                    name = "Finance";
                    items = {
                      "11.01" = "Budget";
                      "11.02" = "Investments";
                      "11.03" = "Tax Records";
                    };
                  };
                  # ... rest of your existing configuration ...
                };
              };
            };
          };

          # Create directories on activation
          home.activation.createJohnnyMnemonixStructure = {
            config,
            lib,
          }: let
            validation = validateStructure config.johnny-mnemonix.areas;
          in
            lib.hm.dag.entryAfter ["writeBoundary"] (
              if !validation.valid && config.johnny-mnemonix.validation.strict
              then throw "Invalid Johnny Mnemonix structure"
              else mkDirs config.johnny-mnemonix.baseDir config.johnny-mnemonix.areas
            );

          # Shell integration
          programs = {
            bash.shellAliases.jd = "cd /Users/lessuseless/Documents";
            zsh.shellAliases.jd = "cd /Users/lessuseless/Documents";
            fish.shellAliases.jd = "cd /Users/lessuseless/Documents";
          };
        }
      ];
    };
  };
}
