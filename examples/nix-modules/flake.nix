{
  description = "Example demonstrating johnny-declarative-decimal module parsing and validation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Reference the parent flake (johnny-declarative-decimal)
    johnny-declarative-decimal.url = "path:../..";
  };

  outputs = {
    self,
    nixpkgs,
    johnny-declarative-decimal,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    lib = pkgs.lib;

    # Import the johnny-declarative-decimal configuration modules
    jddConfig = johnny-declarative-decimal.johnny-declarative-decimal.config or {};

    # Get syntax configuration from the parent flake
    # This demonstrates loading configuration from 01.04 Syntax module
    syntaxConfig = jddConfig.syntax or {
      area_range_encapsulator = {
        open = "{";
        close = "}";
      };
      category_num_encapsulator = {
        open = "(";
        close = ")";
      };
      id_num_encapsulator = {
        open = "[";
        close = "]";
      };
      numeral_name_separator = " ";
      area_category_separator = "__";
      category_item_separator = "__";
      octet_separator = ".";
      range_separator = "-";
    };

    # Escape special regex characters for POSIX ERE
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

    escapeRegexString = str:
      lib.concatStrings (map escapeRegexChar (lib.stringToCharacters str));

    # Parse a johnny-decimal filename using the configured syntax
    parseJDFilename = filename: let
      base = lib.removeSuffix ".nix" filename;

      # Build regex pattern from syntax config
      idOpen = escapeRegexString syntaxConfig.id_num_encapsulator.open;
      idClose = escapeRegexString syntaxConfig.id_num_encapsulator.close;
      areaOpen = escapeRegexString syntaxConfig.area_range_encapsulator.open;
      areaClose = escapeRegexString syntaxConfig.area_range_encapsulator.close;
      catOpen = escapeRegexString syntaxConfig.category_num_encapsulator.open;
      catClose = escapeRegexString syntaxConfig.category_num_encapsulator.close;
      areaCatSep = escapeRegexString syntaxConfig.area_category_separator;
      catItemSep = escapeRegexString syntaxConfig.category_item_separator;
      numNameSep = escapeRegexString syntaxConfig.numeral_name_separator;
      octSep = escapeRegexString syntaxConfig.octet_separator;
      rangeSep = escapeRegexString syntaxConfig.range_separator;

      # Raw characters for character classes
      areaCloseRaw = syntaxConfig.area_range_encapsulator.close;
      catCloseRaw = syntaxConfig.category_num_encapsulator.close;
      idCloseRaw = syntaxConfig.id_num_encapsulator.close;

      # Pattern: [CAT.ITEM]{RANGE Name}__(CAT Name)__[ITEM Name]
      pattern = "${idOpen}([0-9]+)${octSep}([0-9]+)${idClose}${areaOpen}([^${areaCloseRaw}]+)${areaClose}${areaCatSep}${catOpen}([0-9]+)${numNameSep}([^${catCloseRaw}]+)${catClose}${catItemSep}${idOpen}([0-9]+)${numNameSep}(.+)${idClose}";

      match = builtins.match pattern base;

      # Extract components
      jdCategory = if match != null then builtins.elemAt match 0 else null;
      jdItem = if match != null then builtins.elemAt match 1 else null;
      areaString = if match != null then builtins.elemAt match 2 else null;
      categoryNum = if match != null then builtins.elemAt match 3 else null;
      categoryName = if match != null then builtins.elemAt match 4 else null;
      itemNum = if match != null then builtins.elemAt match 5 else null;
      itemName = if match != null then builtins.elemAt match 6 else null;

      # Parse area string
      areaPattern = "([0-9]+${rangeSep}[0-9]+)${numNameSep}(.+)";
      areaMatch = if areaString != null then builtins.match areaPattern areaString else null;
      areaRange = if areaMatch != null then builtins.elemAt areaMatch 0 else null;
      areaName = if areaMatch != null then builtins.elemAt areaMatch 1 else null;

      # Validation: category from [cat.item] must match (cat ...)
      validCategory = if match != null then jdCategory == categoryNum else false;

      # Validation: item from [cat.item] must match [item ...]
      validItem = if match != null then jdItem == itemNum else false;

      # Validation: category must fall within area range
      validRange = if areaMatch != null then
        let
          rangeParts = lib.splitString syntaxConfig.range_separator areaRange;
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
        inherit areaRange areaName categoryName itemName;
        categoryId = jdCategory;
        itemId = "${jdCategory}.${jdItem}";
        validations = {
          category_match = validCategory;
          item_match = validItem;
          range_valid = validRange;
        };
      }
      else if match != null && !allValid
      then {
        parsed = false;
        error =
          if !validCategory then "Category mismatch: [${jdCategory}.${jdItem}] vs (${categoryNum} ...)"
          else if !validItem then "Item mismatch: [${jdCategory}.${jdItem}] vs [${itemNum} ...]"
          else "Category ${jdCategory} not in range ${areaRange}";
      }
      else {
        parsed = false;
        error = "Filename does not match johnny-decimal pattern";
      };

    # Test modules from the parent flake
    testModules = [
      "[01.01]{01-09 Meta}__(01 Configuration)__[01 Base-Octets].nix"
      "[01.02]{01-09 Meta}__(01 Configuration)__[02 Numbers-Ranges-Rules].nix"
      "[01.03]{01-09 Meta}__(01 Configuration)__[03 Name-space].nix"
      "[01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix"
      "[01.05]{01-09 Meta}__(01 Configuration)__[05 Nix-module-validation].nix"
      "[01.06]{01-09 Meta}__(01 Configuration)__[06 Flake-parts-validation].nix"
      "[01.07]{01-09 Meta}__(01 Configuration)__[07 Indexor-rules].nix"
      "[10.19]{10-19 Projects}__(10 Code)__[19 Test-Project].nix"
      "test-simple-module.nix"
    ];

    # Parse all test modules
    parsedModules = map parseJDFilename testModules;

    # Detect ID collisions
    moduleIds = builtins.filter (m: m.parsed) parsedModules;
    idList = map (m: m.itemId) moduleIds;

    # Check for duplicate IDs
    checkDuplicates = ids: let
      countOccurrences = id: builtins.length (builtins.filter (x: x == id) ids);
      duplicates = builtins.filter (id: countOccurrences id > 1) ids;
      uniqueDuplicates = lib.unique duplicates;
    in
      if builtins.length uniqueDuplicates > 0
      then {
        hasDuplicates = true;
        duplicateIds = uniqueDuplicates;
      }
      else {
        hasDuplicates = false;
        duplicateIds = [];
      };

    collisionReport = checkDuplicates idList;

    # Generate validation report
    validationReport = {
      total_modules = builtins.length testModules;
      parsed_successfully = builtins.length (builtins.filter (m: m.parsed) parsedModules);
      parse_failures = builtins.length (builtins.filter (m: !m.parsed) parsedModules);

      parsed_modules = map (m: {
        inherit (m) areaRange areaName categoryId categoryName itemId itemName validations;
      }) moduleIds;

      failed_modules = map (m: {
        error = m.error;
      }) (builtins.filter (m: !m.parsed) parsedModules);

      inherit collisionReport;

      syntax_config_used = {
        area_encap = "${syntaxConfig.area_range_encapsulator.open}...${syntaxConfig.area_range_encapsulator.close}";
        category_encap = "${syntaxConfig.category_num_encapsulator.open}...${syntaxConfig.category_num_encapsulator.close}";
        id_encap = "${syntaxConfig.id_num_encapsulator.open}...${syntaxConfig.id_num_encapsulator.close}";
        separators = {
          numeral_name = syntaxConfig.numeral_name_separator;
          area_category = syntaxConfig.area_category_separator;
          category_item = syntaxConfig.category_item_separator;
          octet = syntaxConfig.octet_separator;
          range = syntaxConfig.range_separator;
        };
      };
    };
  in {
    # Expose the validation report as a package
    packages.${system}.default = pkgs.writeTextFile {
      name = "johnny-decimal-validation-report";
      text = builtins.toJSON validationReport;
      destination = "/validation-report.json";
    };

    # Also expose as a check
    checks.${system}.validation = pkgs.runCommand "validate-johnny-decimal" {} ''
      ${pkgs.jq}/bin/jq . ${self.packages.${system}.default}/validation-report.json

      # Check for failures
      parse_failures=$(${pkgs.jq}/bin/jq -r '.parse_failures' ${self.packages.${system}.default}/validation-report.json)
      has_duplicates=$(${pkgs.jq}/bin/jq -r '.collisionReport.hasDuplicates' ${self.packages.${system}.default}/validation-report.json)

      if [ "$parse_failures" != "0" ]; then
        echo "ERROR: $parse_failures modules failed to parse"
        exit 1
      fi

      if [ "$has_duplicates" = "true" ]; then
        echo "ERROR: Duplicate IDs detected"
        ${pkgs.jq}/bin/jq -r '.collisionReport.duplicateIds[]' ${self.packages.${system}.default}/validation-report.json
        exit 1
      fi

      echo "All validations passed!"
      touch $out
    '';

    # Expose parsed modules for inspection
    inherit parsedModules validationReport;
  };
}
