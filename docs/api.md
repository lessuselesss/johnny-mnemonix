# API Documentation

This document describes the programmatic interfaces available in Johnny-Mnemonix.

## Nix API

### Core Functions

```nix
# Library functions for structure manipulation
{
  # Create a new area
  mkArea = { id, name, categories ? {} }:
    assert validateAreaId id;
    {
      inherit id name categories;
    };

  # Create a new category
  mkCategory = { id, name, items ? {} }:
    assert validateCategoryId id;
    {
      inherit id name items;
    };

  # Create a new item
  mkItem = { id, name }:
    assert validateItemId id;
    {
      inherit id name;
    };
}
```

### Validation Functions

```nix
{
  # Validate area ID format (XX-YY)
  validateAreaId = id: builtins.match "^[0-9]{2}-[0-9]{2}$" id != null;

  # Validate category ID format (XX)
  validateCategoryId = id: builtins.match "^[0-9]{2}$" id != null;

  # Validate item ID format (XX.YY)
  validateItemId = id: builtins.match "^[0-9]{2}[.][0-9]{2}$" id != null;
}
```

### Path Manipulation

```nix
{
  # Create full path for an item
  makePath = { baseDir, areaId, areaName, categoryId, categoryName, itemId, itemName }:
    "${baseDir}/${areaId} ${areaName}/${categoryId} ${categoryName}/${itemId} ${itemName}";

  # Sanitize path components
  sanitizePath = path: builtins.replaceStrings [" "] ["\\\ "] path;
}
```

## Plugin API

### Plugin Interface

```nix
# Plugin module interface
{
  # Plugin configuration options
  options.johnny-mnemonix.plugins.<name> = {
    enable = mkEnableOption "Enable the plugin";
    
    # Plugin-specific options
    config = mkOption {
      type = types.attrs;
      default = {};
      description = "Plugin configuration";
    };
  };

  # Plugin implementation
  config = mkIf cfg.enable {
    # Plugin functionality
  };
}
```

### Event Hooks

```nix
{
  # Directory creation hooks
  hooks.beforeCreate = path: {
    # Pre-creation actions
  };

  hooks.afterCreate = path: {
    # Post-creation actions
  };

  # Structure validation hooks
  hooks.beforeValidate = structure: {
    # Pre-validation actions
  };

  hooks.afterValidate = structure: {
    # Post-validation actions
  };
}
```

## Shell Integration API

### Shell Functions

```bash
# Available shell functions
{
  # Navigate to document root
  jd() {
    cd "${JOHNNY_MNEMONIX_BASE:-$HOME/Documents}"
  }

  # Navigate to specific area/category/item
  jj() {
    local code="$1"
    case "$code" in
      [0-9][0-9]-[0-9][0-9]) _jj_area "$code" ;;
      [0-9][0-9]) _jj_category "$code" ;;
      [0-9][0-9].[0-9][0-9]) _jj_item "$code" ;;
      *) echo "Invalid code format" ;;
    esac
  }
}
```

## Configuration API

### Module Options

```nix
{
  options.johnny-mnemonix = {
    # Basic options
    enable = mkEnableOption "Enable Johnny-Mnemonix";
    
    baseDir = mkOption {
      type = types.str;
      description = "Base directory for document structure";
    };

    # Structure definition
    areas = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Area name";
          };
          categories = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = "Category name";
                };
                items = mkOption {
                  type = types.attrsOf (types.submodule {
                    options = {
                      name = mkOption {
                        type = types.str;
                        description = "Item name";
                      };
                    };
                  });
                  default = {};
                  description = "Category items";
                };
              };
            });
            default = {};
            description = "Area categories";
          };
        };
      });
      default = {};
      description = "Document structure areas";
    };
  };
}
``` 