{lib}:
with lib; {
  # Validation functions for structure components
  validateArea = name: area: let
    areaPattern = "^[0-9]{2}-[0-9]{2}$";
    isValid = builtins.match areaPattern name != null;
    errorMsg = "Area ID '${name}' must be in format 'XX-YY' (e.g., '10-19')";
  in
    if isValid
    then true
    else throw errorMsg;

  validateCategory = name: category: let
    categoryPattern = "^[0-9]{2}$";
    isValid = builtins.match categoryPattern name != null;
    errorMsg = "Category ID '${name}' must be two digits (e.g., '11')";
  in
    if isValid
    then true
    else throw errorMsg;

  validateItem = id: name: let
    itemPattern = "^[0-9]{2}[.][0-9]{2}$";
    isValid = builtins.match itemPattern id != null;
    errorMsg = "Item ID '${id}' must be in format 'XX.YY' (e.g., '11.01')";
  in
    if isValid
    then true
    else throw errorMsg;

  # Composite validation functions
  validateStructure = structure: let
    validateAreas =
      mapAttrsToList (
        areaId: area:
          assert validateArea areaId area;
            validateCategories area.categories
      )
      structure;

    validateCategories = categories:
      mapAttrsToList (
        catId: category:
          assert validateCategory catId category;
            validateItems category.items
      )
      categories;

    validateItems = items:
      mapAttrsToList (
        itemId: itemName:
          validateItem itemId itemName
      )
      items;
  in
    all (x: x) (flatten validateAreas);
}
