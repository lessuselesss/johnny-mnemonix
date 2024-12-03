{nixpkgs}: let
  inherit (nixpkgs.lib) types;

  validate = {
    areaId = id: name: let
      pattern = "^[0-9]{2}-[0-9]{2}$";
      isValid = builtins.match pattern id != null;
      errorMsg = "Area ID '${id}' must be in format 'XX-YY' (e.g., '10-19')";
    in
      if isValid
      then true
      else throw errorMsg;

    categoryId = id: name: let
      pattern = "^[0-9]{2}$";
      isValid = builtins.match pattern id != null;
      errorMsg = "Category ID '${id}' must be two digits (e.g., '11')";
    in
      if isValid
      then true
      else throw errorMsg;

    itemId = id: name: let
      pattern = "^[0-9]{2}[.][0-9]{2}$";
      isValid = builtins.match pattern id != null;
      errorMsg = "Item ID '${id}' must be in format 'XX.YY' (e.g., '11.01')";
    in
      if isValid
      then true
      else throw errorMsg;
  };
in {
  inherit validate;

  # Core type definitions
  types = {
    # Area ID must be in format XX-YY (e.g., 10-19)
    areaId = types.strMatching "^[0-9]{2}-[0-9]{2}$";

    # Category ID must be two digits (e.g., 11)
    categoryId = types.strMatching "^[0-9]{2}$";

    # Item ID must be in format XX.YY (e.g., 11.01)
    itemId = types.strMatching "^[0-9]{2}[.][0-9]{2}$";

    # Area must be a submodule with name and categories
    area = types.submodule {
      options = {
        name = types.str;
        categories = types.attrsOf types.category;
      };
    };

    # Category must be a submodule with name and items
    category = types.submodule {
      options = {
        name = types.str;
        items = types.attrsOf types.str;
      };
    };
  };

  # Constructor functions
  mkArea = {
    id,
    name,
    categories ? {},
  }:
    assert validate.areaId id name; {
      inherit name categories;
    };

  mkCategory = {
    id,
    name,
    items ? {},
  }:
    assert validate.categoryId id name; {
      inherit name items;
    };

  mkItem = {
    id,
    name,
  }:
    assert validate.itemId id name; {
      inherit name;
    };
}
