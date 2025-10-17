{
  description = "A Nix home-manager module for managing directory structures";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
    inherit (inputs.nixpkgs) lib;

    # Load Johnny Decimal syntax configuration
    syntaxConfig =
      if builtins.pathExists ./name-number-hierarchy-signifiers.nix
      then import ./name-number-hierarchy-signifiers.nix
      else {
        # Default configuration if file doesn't exist
        areaRangeEncapsulator = {open = "{"; close = "}";};
        categoryNumEncapsulator = {open = "("; close = ")";};
        idNumEncapsulator = {open = "["; close = "]";};
        numeralNameSeparator = " ";
        areaCategorySeparator = "__";
        categoryItemSeparator = "__";
      };

    # Escape special regex characters for POSIX ERE
    # In POSIX ERE, these need escaping or character class treatment:
    # [ ] { } ( ) . * + ? | \ ^ $
    escapeRegexChar = char:
      if char == "[" then "[[]"
      else if char == "]" then "[]]"
      else if char == "{" then "[{]"
      else if char == "}" then "[}]"
      else if char == "(" then "\\("
      else if char == ")" then "\\)"
      else if char == "." then "\\."
      else if char == "*" then "\\*"
      else if char == "+" then "\\+"
      else if char == "?" then "\\?"
      else if char == "|" then "\\|"
      else if char == "\\" then "\\\\"
      else if char == "^" then "\\^"
      else if char == "$" then "\\$"
      else char;

    # Escape a string for use in regex
    escapeRegexString = str:
      lib.concatStrings (map escapeRegexChar (lib.stringToCharacters str));

    # Parse johnny-decimal filename format using configurable syntax
    # Example with default syntax: [10.19]{10-19 Projects}__(10 Code)__[19 Test-Project].nix
    parseJDFilename = filename: let
      base = lib.removeSuffix ".nix" filename;

      # Build regex pattern dynamically from syntax config
      # Pattern structure: [ID]{Area}separator(Category)separator[Item]
      # Groups: 1=cat, 2=item, 3=area-string, 4=cat-num, 5=cat-name, 6=item-num, 7=item-name

      # Escape syntax elements for regex
      idOpen = escapeRegexString syntaxConfig.idNumEncapsulator.open;
      idClose = escapeRegexString syntaxConfig.idNumEncapsulator.close;
      areaOpen = escapeRegexString syntaxConfig.areaRangeEncapsulator.open;
      areaClose = escapeRegexString syntaxConfig.areaRangeEncapsulator.close;
      catOpen = escapeRegexString syntaxConfig.categoryNumEncapsulator.open;
      catClose = escapeRegexString syntaxConfig.categoryNumEncapsulator.close;
      areaCatSep = escapeRegexString syntaxConfig.areaCategorySeparator;
      catItemSep = escapeRegexString syntaxConfig.categoryItemSeparator;
      numNameSep = escapeRegexString syntaxConfig.numeralNameSeparator;

      # Build the full pattern
      # [ID.ID]{Range Name}__(Cat Name)__[Num Name]
      # Note: For character classes [^X], we need raw characters, not escaped forms
      areaCloseRaw = syntaxConfig.areaRangeEncapsulator.close;
      catCloseRaw = syntaxConfig.categoryNumEncapsulator.close;

      pattern = "${idOpen}([0-9]+)\\.([0-9]+)${idClose}${areaOpen}([^${areaCloseRaw}]+)${areaClose}${areaCatSep}${catOpen}([0-9]+)${numNameSep}([^${catCloseRaw}]+)${catClose}${catItemSep}${idOpen}([0-9]+)${numNameSep}(.+)${idClose}";

      match = builtins.match pattern base;

      # Extract matched components
      jdCategory = if match != null then builtins.elemAt match 0 else null;
      jdItem = if match != null then builtins.elemAt match 1 else null;
      areaString = if match != null then builtins.elemAt match 2 else null;
      categoryNum = if match != null then builtins.elemAt match 3 else null;
      categoryName = if match != null then builtins.elemAt match 4 else null;
      itemNum = if match != null then builtins.elemAt match 5 else null;
      itemName = if match != null then builtins.elemAt match 6 else null;

      # Parse area string "10-19 Projects" into range and name using configurable separator
      areaPattern = "([0-9]+-[0-9]+)${numNameSep}(.+)";
      areaMatch = if areaString != null then builtins.match areaPattern areaString else null;
      areaRange = if areaMatch != null then builtins.elemAt areaMatch 0 else null;
      areaName = if areaMatch != null then builtins.elemAt areaMatch 1 else null;

      # Validation: category from [cat.item] must match (cat ...)
      validCategory = if match != null then jdCategory == categoryNum else false;

      # Validation: item from [cat.item] must match [item ...]
      validItem = if match != null then jdItem == itemNum else false;

      # Validation: category must fall within area range
      # e.g., category 10 must be in range 10-19
      validRange = if areaMatch != null then
        let
          rangeParts = lib.splitString "-" areaRange;
          rangeStart = lib.toInt (builtins.elemAt rangeParts 0);
          rangeEnd = lib.toInt (builtins.elemAt rangeParts 1);
          catNum = lib.toInt jdCategory;
        in
          catNum >= rangeStart && catNum <= rangeEnd
      else false;

      allValid = validCategory && validItem && validRange;
    in
      if match != null && allValid
      then {
        parsed = true;
        areaId = areaRange;
        inherit areaName;
        categoryId = jdCategory;
        inherit categoryName;
        itemId = "${jdCategory}.${jdItem}";
        inherit itemName;
      }
      else if match != null && !allValid
      then builtins.trace "Warning: Invalid Johnny Decimal hierarchy in '${filename}': ${
        if !validCategory then "category mismatch [${jdCategory}.${jdItem}] vs (${categoryNum} ...)"
        else if !validItem then "item mismatch [${jdCategory}.${jdItem}] vs [${itemNum} ...]"
        else "category ${jdCategory} not in range ${areaRange}"
      }" {parsed = false;}
      else {parsed = false;};

    # Auto-discover modules from modules/ directory
    # Exclude: johnny-mnemonix.nix (the main HM module), example-project.nix (template), README.md
    allModuleFiles =
      if builtins.pathExists ./modules
      then
        builtins.filter
        (name:
          name != "johnny-mnemonix.nix"
          && name != "example-project.nix"
          && lib.hasSuffix ".nix" name)
        (builtins.attrNames (builtins.readDir ./modules))
      else [];

    # Separate parsed JD modules from simple path-based modules
    parsedModules = builtins.filter (f: (parseJDFilename f).parsed) allModuleFiles;
    simpleModules = builtins.filter (f: !(parseJDFilename f).parsed) allModuleFiles;

    # For simple modules: extract managed path names (without .nix extension)
    managedPathNames = map (file: lib.removeSuffix ".nix" file) simpleModules;

    # Build johnny-mnemonix areas configuration from parsed modules
    # Also track which module file created each item
    jdAreasFromModules = let
      # Pair each module filename with its parsed data
      parsedWithFiles = map (file: {
        inherit file;
        data = parseJDFilename file;
      }) parsedModules;

      # Filter to only successfully parsed modules
      parsedData = map (item: item.data) (builtins.filter (item: item.data.parsed) parsedWithFiles);

      # Group by area, then by category
      groupByArea = lib.foldl (acc: data:
        acc // {
          ${data.areaId} = (acc.${data.areaId} or {}) // {
            name = data.areaName;
            categories = (acc.${data.areaId}.categories or {}) // {
              ${data.categoryId} = {
                name = data.categoryName;
                items = ((acc.${data.areaId}.categories.${data.categoryId}.items or {}) // {
                  ${data.itemId} = data.itemName;
                });
              };
            };
          };
        }
      ) {} parsedData;
    in groupByArea;

    # Build mapping of item IDs to their source module files
    # Key format: "areaId.categoryId.itemId" -> "module-filename.nix"
    jdModuleSources = let
      parsedWithFiles = map (file: {
        inherit file;
        data = parseJDFilename file;
      }) parsedModules;
    in
      lib.foldl (acc: item:
        if item.data.parsed then
          acc // {
            "${item.data.areaId}.${item.data.categoryId}.${item.data.itemId}" = item.file;
          }
        else acc
      ) {} parsedWithFiles;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      # Import user-defined modules from modules/ directory (all types)
      imports =
        map (file: ./modules/${file}) allModuleFiles;

      # Flake-wide outputs (not system-specific)
      flake = {
        # Define the module
        homeManagerModules = let
          # Wrap the main module to inject managedPathNames, jdAreasFromModules, jdModuleSources, and syntaxConfig
          wrappedModule = {
            _module.args = {
              managedPathNames = managedPathNames;
              jdAreasFromModules = jdAreasFromModules;
              jdModuleSources = jdModuleSources;
              jdSyntaxConfig = syntaxConfig;
            };
            imports = [./modules/johnny-mnemonix.nix];
          };
        in {
          default = wrappedModule;
          johnny-mnemonix = wrappedModule;
        };

        # For backwards compatibility
        homeManagerModule = inputs.self.homeManagerModules.default;
      };

      # Per-system outputs
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Simple test that evaluates the module
        checks.moduleEval = pkgs.runCommand "test-johnny-mnemonix" {} ''
          echo "Testing module evaluation..."
          ${pkgs.nix}/bin/nix-instantiate --eval --expr '
            with import ${inputs.nixpkgs} { system = "${system}"; };
            let
              hmLib = import ${inputs.home-manager}/modules/lib/stdlib-extended.nix lib;
            in
            lib.evalModules {
              modules = [
                { _module.args = { inherit pkgs lib; }; }
                ${./modules/johnny-mnemonix.nix}
                {
                  config = {
                    home = {
                      username = "test";
                      homeDirectory = "/home/test";
                      stateVersion = "23.11";
                    };
                    johnny-mnemonix = {
                      enable = true;
                      baseDir = "/tmp/test";
                      spacer = " ";
                      areas = {};
                    };
                  };
                }
              ];
            }
          ' > $out
        '';

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            nixpkgs-fmt
            statix
            deadnix
            pre-commit
          ];
          shellHook = ''
            pre-commit install
          '';
        };
      };
    };
}
