{
  config,
  lib,
  ...
}:
with lib; let
  # Enhanced error formatting
  formatError = context: message: details: ''
    Error in ${context}:
    ${message}
    Details: ${details}
  '';

  # Robust integer parsing
  toSafeInt = str: let
    result = builtins.tryEval (builtins.fromJSON str);
  in
    if result.success && builtins.match "^[0-9]+$" str != null
    then result.value
    else null;

  # Validation rules with more robust checks
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
      range = {
        message = "Area range must be valid (e.g., 10-19 contains categories 10-19)";
        validate = value: let
          parts = builtins.split "-" value;
          start = toSafeInt (elemAt parts 0);
          end = toSafeInt (elemAt parts 1);
        in
          if start == null || end == null
          then false
          else start <= end && (end - start) <= 9;
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
        message = "Category name must start with alphanumeric and contain only letters, numbers, spaces, underscores, or hyphens";
        validate = value: builtins.match rules.category.name.pattern value != null;
      };
      inRange = {
        areaId,
        categoryId,
      }: {
        message = "Category ID must be within area range";
        validate = value: let
          parts = builtins.split "-" areaId;
          areaStart = toSafeInt (elemAt parts 0);
          areaEnd = toSafeInt (elemAt parts 1);
          catNum = toSafeInt value;
        in
          areaStart
          != null
          && areaEnd != null
          && catNum != null
          && catNum >= areaStart
          && catNum <= areaEnd;
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
        message = "Item name must start with alphanumeric and contain only letters, numbers, spaces, underscores, or hyphens";
        validate = value: builtins.match rules.item.name.pattern value != null;
      };
      matchesCategory = {
        itemId,
        categoryId,
      }: {
        message = "Item ID must match its category ID (e.g., 11.01 belongs to category 11)";
        validate = value: let
          itemPrefix = substring 0 2 value;
        in
          itemPrefix == categoryId;
      };
    };
  };

  # Validation functions with improved error collection
  validateStructure = structure: let
    validateArea = areaId: area: let
      areaErrors =
        (
          if !rules.area.id.validate areaId
          then [(formatError "Area ${areaId}" rules.area.id.message "Got '${areaId}', expected format: XX-YY")]
          else []
        )
        ++ (
          if !rules.area.name.validate area.name
          then [(formatError "Area ${areaId}" rules.area.name.message "Got '${area.name}', expected format: [A-Za-z0-9][A-Za-z0-9 _-]*")]
          else []
        )
        ++ (
          if !rules.area.range.validate areaId
          then [(formatError "Area ${areaId}" rules.area.range.message "Got '${areaId}', expected format: XX-YY")]
          else []
        );
    in
      areaErrors ++ (validateCategories areaId area.categories);

    validateCategories = areaId: categories:
      if categories == null
      then []
      else
        concatLists (mapAttrsToList (
            categoryId: category:
              (
                if !rules.category.id.validate categoryId
                then [(formatError "Category ${categoryId}" rules.category.id.message "Got '${categoryId}', expected format: XX")]
                else []
              )
              ++ (
                if !rules.category.name.validate category.name
                then [(formatError "Category ${categoryId}" rules.category.name.message "Got '${category.name}', expected format: [A-Za-z0-9][A-Za-z0-9 _-]*")]
                else []
              )
              ++ (
                if !rules.category.inRange {inherit areaId categoryId;}.validate categoryId
                then [(formatError "Category ${categoryId}" rules.category.inRange.message "Got '${categoryId}', expected to be within area range")]
                else []
              )
              ++ (validateItems categoryId category.items)
          )
          categories);

    validateItems = categoryId: items:
      if items == null
      then []
      else
        concatLists (mapAttrsToList (
            itemId: itemName:
              (
                if !rules.item.id.validate itemId
                then [(formatError "Item ${itemId}" rules.item.id.message "Got '${itemId}', expected format: XX.YY")]
                else []
              )
              ++ (
                if !rules.item.name.validate itemName
                then [(formatError "Item ${itemId}" rules.item.name.message "Got '${itemName}', expected format: [A-Za-z0-9][A-Za-z0-9 _-]*")]
                else []
              )
              ++ (
                if !rules.item.matchesCategory {inherit itemId categoryId;}.validate itemId
                then [(formatError "Item ${itemId}" rules.item.matchesCategory.message "Got '${itemId}', expected to match category ID")]
                else []
              )
          )
          items);

    allErrors = concatLists (mapAttrsToList validateArea structure);
  in {
    valid = allErrors == [];
    errors = allErrors;
  };
in {
  # Export validation functions
  inherit validateStructure rules;

  # Add validation options to the module
  options.johnny-mnemonix = {
    validation = {
      strict = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to fail on validation errors";
      };

      customRules = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            pattern = mkOption {
              type = types.str;
              description = "Regex pattern for validation";
            };
            message = mkOption {
              type = types.str;
              description = "Error message";
            };
            validate = mkOption {
              type = types.functionTo types.bool;
              description = "Validation function";
            };
          };
        });
        default = {};
        description = "Custom validation rules";
      };
    };
  };

  # Add validation to the configuration
  config = mkIf config.johnny-mnemonix.enable {
    assertions = let
      validationResult = validateStructure config.johnny-mnemonix.areas;
    in [
      {
        assertion = !config.johnny-mnemonix.validation.strict || validationResult.valid;
        message = ''
          Johnny-Mnemonix configuration validation failed:
          ${concatStringsSep "\n" validationResult.errors}
        '';
      }
    ];
  };
}
