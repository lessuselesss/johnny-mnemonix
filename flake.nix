{
  description = "Johnny Declarative Decimal - A configurable Nix system for managing directory hierarchies using the Johnny Decimal organizational method";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    std = {
      url = "github:divnix/std";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
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

    # Parse johnny-decimal directory hierarchy format
    # Example: modules/[01-09] Meta/(01) Naming Convention/<01>Encapsulators.nix
    parseJDDirectory = fullPath: let
      # Remove modules/ prefix to get relative path
      relPath = lib.removePrefix "modules/" fullPath;
      parts = lib.splitString "/" relPath;

      # Only valid if we have exactly 3 parts: area/category/item.nix
      hasCorrectDepth = builtins.length parts == 3;

      # Escape syntax elements for regex
      idOpen = escapeRegexString syntaxConfig.idNumEncapsulator.open;
      idClose = escapeRegexString syntaxConfig.idNumEncapsulator.close;
      areaOpen = escapeRegexString syntaxConfig.areaRangeEncapsulator.open;
      areaClose = escapeRegexString syntaxConfig.areaRangeEncapsulator.close;
      catOpen = escapeRegexString syntaxConfig.categoryNumEncapsulator.open;
      catClose = escapeRegexString syntaxConfig.categoryNumEncapsulator.close;
      numNameSep = escapeRegexString syntaxConfig.numeralNameSeparator;

      # Raw characters for character classes
      areaCloseRaw = syntaxConfig.areaRangeEncapsulator.close;
      catCloseRaw = syntaxConfig.categoryNumEncapsulator.close;
      idCloseRaw = syntaxConfig.idNumEncapsulator.close;

      # Parse area directory: [01-09] Meta
      areaDir = if hasCorrectDepth then builtins.elemAt parts 0 else "";
      areaPattern = "${areaOpen}([0-9]+-[0-9]+)${areaClose}${numNameSep}(.+)";
      areaMatch = builtins.match areaPattern areaDir;

      # Parse category directory: (01) Naming Convention Definitions
      catDir = if hasCorrectDepth then builtins.elemAt parts 1 else "";
      catPattern = "${catOpen}([0-9]+)${catClose}${numNameSep}(.+)";
      catMatch = builtins.match catPattern catDir;

      # Parse item file: <01>Encapsulators.nix
      itemFile = if hasCorrectDepth then lib.removeSuffix ".nix" (builtins.elemAt parts 2) else "";
      itemPattern = "${idOpen}([0-9]+)${idClose}${numNameSep}(.+)";
      itemMatch = builtins.match itemPattern itemFile;

      # Extract matched components
      areaRange = if areaMatch != null then builtins.elemAt areaMatch 0 else null;
      areaName = if areaMatch != null then builtins.elemAt areaMatch 1 else null;
      catNum = if catMatch != null then builtins.elemAt catMatch 0 else null;
      catName = if catMatch != null then builtins.elemAt catMatch 1 else null;
      itemNum = if itemMatch != null then builtins.elemAt itemMatch 0 else null;
      itemName = if itemMatch != null then builtins.elemAt itemMatch 1 else null;

      # Validation: all parts must match
      allMatched = areaMatch != null && catMatch != null && itemMatch != null;

      # Validation: category must fall within area range
      validRange = if allMatched then
        let
          rangeParts = lib.splitString "-" areaRange;
          rangeStart = lib.toInt (builtins.elemAt rangeParts 0);
          rangeEnd = lib.toInt (builtins.elemAt rangeParts 1);
          catNumInt = lib.toInt catNum;
        in
          catNumInt >= rangeStart && catNumInt <= rangeEnd
      else false;

      allValid = allMatched && validRange;
    in
      if allMatched && allValid
      then {
        parsed = true;
        areaId = areaRange;
        inherit areaName;
        categoryId = catNum;
        categoryName = catName;
        itemId = "${catNum}.${itemNum}";
        inherit itemName;
        format = "directory";
      }
      else if allMatched && !allValid
      then builtins.trace "Warning: Invalid Johnny Decimal hierarchy in directory '${fullPath}': category ${catNum} not in range ${areaRange}" {parsed = false;}
      else {parsed = false;};

    # Recursively find all .nix files in a directory
    # Returns paths relative to modules/ for use in parsing and imports
    findNixFiles = baseDir: relPrefix: dir: let
      entries = if builtins.pathExists dir then builtins.readDir dir else {};

      processEntry = name: type: let
        fullPath = dir + "/${name}";
        # Build relative path by concatenating relPrefix with name
        newRelPath = if relPrefix == "" then name else "${relPrefix}/${name}";
      in
        if type == "directory"
        then findNixFiles baseDir newRelPath fullPath
        else if type == "regular" && lib.hasSuffix ".nix" name
        then [{path = fullPath; relPath = newRelPath;}]
        else [];
    in
      lib.flatten (lib.mapAttrsToList processEntry entries);

    # Auto-discover all .nix modules recursively from modules/ directory
    # Returns list of {path, relPath} records
    allModuleFiles =
      if builtins.pathExists ./modules
      then
        builtins.filter
        (m:
          let
            filename = baseNameOf m.relPath;
            # Exclude config modules (01.xx) until they're refactored for std
            isConfigModule = lib.hasPrefix "[01." filename;
          in filename != "johnny-mnemonix.nix"
          && filename != "example-project.nix"
          && filename != "README.md"
          && !isConfigModule)
        (findNixFiles ./modules "" ./modules)
      else [];

    # Unified module parsing: try both flat and directory formats
    parseModule = moduleFile: let
      # Extract just the filename for flat format
      filename = baseNameOf moduleFile.relPath;

      # Try flat self-describing format first
      flatParse = parseJDFilename filename;

      # If flat fails, try directory hierarchy format (use relPath for parsing)
      dirParse = if !flatParse.parsed then parseJDDirectory moduleFile.relPath else {parsed = false;};
    in
      if flatParse.parsed
      then flatParse // {path = moduleFile.relPath; fullPath = moduleFile.path; format = "flat";}
      else if dirParse.parsed
      then dirParse // {path = moduleFile.relPath; fullPath = moduleFile.path; format = "directory";}
      else {parsed = false; path = moduleFile.relPath; fullPath = moduleFile.path; format = "unknown";};

    # Parse all discovered modules
    allParsedModules = map parseModule allModuleFiles;

    # Separate parsed JD modules from simple path-based modules
    parsedModules = builtins.filter (m: m.parsed && m.format != "unknown") allParsedModules;
    simpleModules = builtins.filter (m: !m.parsed) allParsedModules;

    # For simple modules: extract managed path names (without .nix extension)
    managedPathNames = map (m: lib.removeSuffix ".nix" (baseNameOf m.path)) simpleModules;

    # Build complete hierarchy definitions from parsed modules
    # Contains areas, categories, AND items - not just areas!
    # Modules now include both flat and directory formats
    jdDefinitionsFromModules = let
      # Group by area, then by category
      groupByArea = lib.foldl (acc: module:
        acc // {
          ${module.areaId} = (acc.${module.areaId} or {}) // {
            name = module.areaName;
            categories = (acc.${module.areaId}.categories or {}) // {
              ${module.categoryId} = {
                name = module.categoryName;
                items = ((acc.${module.areaId}.categories.${module.categoryId}.items or {}) // {
                  ${module.itemId} = module.itemName;
                });
              };
            };
          };
        }
      ) {} parsedModules;
    in groupByArea;

    # Build mapping of item IDs to their source module files
    # Tracks both flat and directory format modules
    # Key format: "areaId.categoryId.itemId" -> { path = "...";  format = "flat"|"directory"; }
    jdModuleSources =
      lib.foldl (acc: module:
        acc // {
          "${module.areaId}.${module.categoryId}.${module.itemId}" = {
            path = module.path;  # Relative path like "[file].nix" or "area/cat/item.nix"
            format = module.format;
          };
        }
      ) {} parsedModules;

    # Load cells using divnix/std
    cells = inputs.std.growOn {
      inherit inputs;
      cellsFrom = ./nix;
      cellBlocks = [
        # Library cells
        (inputs.std.blockTypes.functions "primitives")
        (inputs.std.blockTypes.functions "composition")
        (inputs.std.blockTypes.functions "builders")
        (inputs.std.blockTypes.functions "unitype")

        # Framework cells
        (inputs.std.blockTypes.functions "configs")

        # Config cells
        (inputs.std.blockTypes.functions "modules")

        # Apps cells
        (inputs.std.blockTypes.runnables "runnables")

        # Test cells
        (inputs.std.blockTypes.functions "unit")
        (inputs.std.blockTypes.functions "integration")
        (inputs.std.blockTypes.functions "e2e")
        (inputs.std.blockTypes.functions "types")
        (inputs.std.blockTypes.functions "unitype")
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      # Import user-defined modules from modules/ directory (all types)
      # Use fullPath which is already a proper Nix path
      imports =
        map (m: m.path) allModuleFiles;

      # Flake-wide outputs (not system-specific)
      flake = {
        # Export cells (divnix/std)
        inherit cells;

        # Convenience exports for library layers (per-system)
        # lib.<system>.primitives, lib.<system>.composition, lib.<system>.builders, lib.<system>.types, lib.<system>.unitype
        lib = lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"] (system: {
          primitives = cells.lib.${system}.primitives or {};
          composition = cells.lib.${system}.composition or {};
          builders = cells.lib.${system}.builders or {};
          types = cells.lib.${system}.types or {};
          unitype = cells.lib.${system}.unitype or {};
        });

        # Convenience exports for frameworks (per-system)
        frameworks = lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"] (system:
          cells.frameworks.${system}.configs or {}
        );

        # Convenience exports for tests (per-system)
        tests = lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"] (system: {
          unit = cells.tests.${system}.unit or {};
          integration = cells.tests.${system}.integration or {};
          e2e = cells.tests.${system}.e2e or {};
          types = cells.tests.${system}.types or {};
        });

        # Convenience exports for examples (per-system)
        examples = lib.genAttrs ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"] (system:
          cells.examples.${system}.configs or {}
        );

        # Define the module
        homeManagerModules = let
          # Wrap the main module to inject managedPathNames, jdDefinitionsFromModules, jdModuleSources, and syntaxConfig
          wrappedModule = {
            _module.args = {
              managedPathNames = managedPathNames;
              jdDefinitionsFromModules = jdDefinitionsFromModules;
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
        # Apps from cells
        apps = cells.apps.${system}.runnables or {};

        # All checks including tests
        checks = let
          unitTests = cells.tests.${system}.unit or {};
          typesTests = cells.tests.${system}.types or {};
          unitypeTests = cells.tests.${system}.unitype or {};
          testLib = unitTests.testLib or typesTests.testLib or unitypeTests.testLib or null;

          # Create a check for each test suite
          mkTestCheck = name: testSuite:
            if testLib != null && testSuite != {}
            then testLib.runTests name testSuite
            else pkgs.runCommand "test-${name}-skipped" {} ''
              echo "Test suite ${name} skipped (not implemented yet)" > $out
            '';
        in {
          # Module evaluation test
          moduleEval = pkgs.runCommand "test-johnny-mnemonix" {} ''
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

          # Primitives tests
          tests-primitives-number-systems = mkTestCheck "primitives-number-systems" (unitTests.primitives.number-systems or {});
          tests-primitives-fields = mkTestCheck "primitives-fields" (unitTests.primitives.fields or {});
          tests-primitives-constraints = mkTestCheck "primitives-constraints" (unitTests.primitives.constraints or {});
          tests-primitives-templates = mkTestCheck "primitives-templates" (unitTests.primitives.templates or {});

          # Composition tests
          tests-composition-identifiers = mkTestCheck "composition-identifiers" (unitTests.composition.identifiers or {});
          tests-composition-ranges = mkTestCheck "composition-ranges" (unitTests.composition.ranges or {});
          tests-composition-hierarchies = mkTestCheck "composition-hierarchies" (unitTests.composition.hierarchies or {});
          tests-composition-validators = mkTestCheck "composition-validators" (unitTests.composition.validators or {});

          # Builder tests
          tests-builders-johnny-decimal = mkTestCheck "builders-johnny-decimal" (unitTests.builders.johnny-decimal or {});
          tests-builders-versioning = mkTestCheck "builders-versioning" (unitTests.builders.versioning or {});
          tests-builders-classification = mkTestCheck "builders-classification" (unitTests.builders.classification or {});

          # Types unit tests
          tests-types-common-types = mkTestCheck "types-common-types" (typesTests.unit.common-types or {});
          tests-types-module-types-nixos = mkTestCheck "types-module-types-nixos" (typesTests.unit.module-types-nixos or {});
          tests-types-module-types-home-manager = mkTestCheck "types-module-types-home-manager" (typesTests.unit.module-types-home-manager or {});
          tests-types-module-types-jm = mkTestCheck "types-module-types-jm" (typesTests.unit.module-types-jm or {});
          tests-types-flake-types-standard = mkTestCheck "types-flake-types-standard" (typesTests.unit.flake-types-standard or {});
          tests-types-flake-types-flake-parts = mkTestCheck "types-flake-types-flake-parts" (typesTests.unit.flake-types-flake-parts or {});

          # Types integration tests
          tests-types-schemas-validate = mkTestCheck "types-schemas-validate" (typesTests.integration.schemas-validate-outputs or {});
          tests-types-schemas-validate-standard = mkTestCheck "types-schemas-validate-standard" (typesTests.integration.schemas-validate-standard-outputs or {});
          tests-types-schemas-reject = mkTestCheck "types-schemas-reject" (typesTests.integration.schemas-reject-invalid or {});

          # Types real-world tests
          tests-types-standard-outputs-community = mkTestCheck "types-standard-outputs-community" (typesTests.real-world.standard-outputs-community or {});
          tests-types-nixos-community = mkTestCheck "types-nixos-community" (typesTests.real-world.nixos-community or {});
          tests-types-home-manager-community = mkTestCheck "types-home-manager-community" (typesTests.real-world.home-manager-community or {});
          tests-types-nix-darwin-community = mkTestCheck "types-nix-darwin-community" (typesTests.real-world.nix-darwin-community or {});
          tests-types-dendrix-community = mkTestCheck "types-dendrix-community" (typesTests.real-world.dendrix-community or {});
          tests-types-typix-community = mkTestCheck "types-typix-community" (typesTests.real-world.typix-community or {});
          tests-types-jm-dogfood = mkTestCheck "types-jm-dogfood" (typesTests.real-world.jm-dogfood or {});
          tests-types-std-dogfood = mkTestCheck "types-std-dogfood" (typesTests.real-world.std-dogfood or {});

          # Unitype tests
          tests-unitype-ir = mkTestCheck "unitype-ir" ((cells.tests.${system}.unitype or {}).ir or {});
        };

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
