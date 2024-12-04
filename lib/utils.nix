{nixpkgs}: let
  inherit (nixpkgs.lib) strings;

  error.handleError = message: code: ''
    echo "Error: ${message}" >&2
    return ${toString code}
  '';
in {
  error = {
    inherit (error) handleError;

    validatePath = path: ''
      if [[ ! -d "${path}" ]]; then
        ${error.handleError "Directory does not exist: ${path}" 1}
      fi
    '';
  };

  # Update path utilities with better error handling
  path = {
    # Make a path safe for shell usage with validation
    makeShellSafe = path: let
      sanitized = strings.escapeShellArg path;
    in ''
      if [[ "${sanitized}" =~ [[:space:]] ]]; then
        ${error.handleError "Path contains spaces: ${path}" 1}
      fi
      echo "${sanitized}"
    '';

    # Create full path for an item
    makeItemPath = {
      baseDir,
      areaId,
      areaName,
      categoryId,
      categoryName,
      itemId,
      itemName,
    }: "${baseDir}/${areaId} ${areaName}/${categoryId} ${categoryName}/${itemId} ${itemName}";

    # Create path for an area
    makeAreaPath = {
      baseDir,
      areaId,
      areaName,
    }: "${baseDir}/${areaId} ${areaName}";

    # Create path for a category
    makeCategoryPath = {
      baseDir,
      areaId,
      areaName,
      categoryId,
      categoryName,
    }: "${baseDir}/${areaId} ${areaName}/${categoryId} ${categoryName}";

    # Create cd command with proper escaping
    cdCommand = path: ''
      cd ${strings.escapeShellArg path}
    '';
  };

  # String manipulation utilities
  string = {
    # Sanitize a name for filesystem use
    sanitizeName = name:
      strings.sanitizeDerivationName name;

    # Format an area ID (ensure XX-YY format)
    formatAreaId = id: let
      parts = strings.splitString "-" id;
      pad = s:
        if (strings.stringLength s) == 1
        then "0${s}"
        else s;
    in "${pad (builtins.elemAt parts 0)}-${pad (builtins.elemAt parts 1)}";

    # Format a category ID (ensure XX format)
    formatCategoryId = id:
      if (strings.stringLength id) == 1
      then "0${id}"
      else id;

    # Format an item ID (ensure XX.YY format)
    formatItemId = id: let
      parts = strings.splitString "." id;
      padFirst = s:
        if (strings.stringLength s) == 1
        then "0${s}"
        else s;
      padSecond = s:
        if (strings.stringLength s) == 1
        then "0${s}"
        else s;
    in "${padFirst (builtins.elemAt parts 0)}.${padSecond (builtins.elemAt parts 1)}";
  };
}
