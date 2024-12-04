# Configuration Guide

This guide explains how to configure Johnny-Mnemonix for your document management needs.

## Basic Configuration

The minimal configuration requires:
1. Enabling the module
2. Defining at least one area

```nix
{
  johnny-mnemonix = {
    enable = true;
    areas = {
      "10-19" = {
        name = "Personal";
        categories = {
          "11" = {
            name = "Finance";
            items = {
              "11.01" = "Budget";
            };
          };
        };
      };
    };
  };
}
```

## Configuration Options

### Top-Level Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable Johnny Mnemonix |
| `baseDir` | string | `"$HOME/Documents"` | Base directory for document structure |

### Area Configuration

Areas must follow these rules:
- IDs must be in format `XX-YY` (e.g., "10-19")
- Names should be descriptive
- Areas should be logically grouped (e.g., 10-19 for Personal, 20-29 for Work)

Example:
```nix
areas = {
  "10-19" = {
    name = "Personal";
    categories = { ... };
  };
};
```

### Category Configuration

Categories must follow these rules:
- IDs must be two digits (e.g., "11")
- IDs should fall within their parent area's range
- Names should be clear and specific

Example:
```nix
categories = {
  "11" = {
    name = "Finance";
    items = { ... };
  };
};
```

### Item Configuration

Items must follow these rules:
- IDs must be in format `XX.YY` (e.g., "11.01")
- First two digits must match parent category
- Names should be specific and descriptive

Example:
```nix
items = {
  "11.01" = "Budget";
  "11.02" = "Investments";
};
```

## Shell Integration

Johnny-Mnemonix provides shell aliases for easy navigation:

| Alias | Description |
|-------|-------------|
| `jd` | Navigate to document root |

## Best Practices

1. **Consistent Naming**
   - Use clear, descriptive names
   - Maintain consistent naming conventions
   - Avoid special characters in names

2. **Logical Organization**
   - Group related items together
   - Use areas for broad categories
   - Use categories for specific groupings

3. **ID Management**
   - Keep IDs sequential when possible
   - Leave gaps for future additions
   - Follow the XX-YY format strictly

4. **Directory Structure**
   - Don't manually modify created directories
   - Use the configuration to make changes
   - Keep the structure flat (max 3 levels)

## Examples

See the [examples](../examples) directory for complete configuration examples:
- [Basic Configuration](../examples/basic/flake.nix)
- [Full Configuration](../examples/full/flake.nix) 