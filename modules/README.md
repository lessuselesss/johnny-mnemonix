# Flake-parts Modules

This directory contains flake-parts modules in two formats:

## 1. Johnny Decimal Format (Declarative Structure)

**Filename encodes the full Johnny Decimal hierarchy:**

### Pattern
```
[cat.item]{area-range area-name}__(cat cat-name)__[item item-name].nix
```

### Examples
```
[10.19]{10-19 Projects}__(10 Code)__[19 My-Project].nix
[21.05]{20-29 Personal}__(21 Finance)__[05 Budget-2024].nix
[31.12]{30-39 Resources}__(31 Documents)__[12 Templates].nix
```

### Components
- `[cat.item]` - **Full Johnny Decimal ID** (e.g., `[10.19]` = category 10, item 19)
- `{area-range area-name}` - **Area range and name** (e.g., `{10-19 Projects}`)
- `__(cat cat-name)__` - **Category number and name** (e.g., `__(10 Code)__`)
- `[item item-name]` - **Item number and name** (e.g., `[19 My-Project]`)

### Validation Rules
1. **Category match**: The `10` from `[10.19]` must equal the `10` in `__(10 Code)__`
2. **Item match**: The `19` from `[10.19]` must equal the `19` in `[19 My-Project]`
3. **Range check**: Category `10` must fall within area range `10-19`

### Directory Creation
Automatically creates: `~/Declaritive Office/area-range area-name/cat cat-name/item item-name/`

Example: `[10.19]{10-19 Projects}__(10 Code)__[19 Web-App].nix`
Creates: `~/Declaritive Office/10-19 Projects/10 Code/19 Web-App/`

### Behavior
The filename is parsed and automatically generates johnny-mnemonix configuration:

```nix
# [10.19]{10-19 Projects}__(10 Code)__[19 Web-App].nix
# Automatically creates:
johnny-mnemonix.areas."10-19" = {
  name = "Projects";
  categories."10" = {
    name = "Code";
    items."10.19" = "Web-App";
  };
};
```

**Merging**: Module-generated areas merge with your manual configuration (manual config takes precedence)

### Example Module
`modules/[10.19]{10-19 Projects}__(10 Code)__[19 My-Project].nix`:
```nix
{ ... }: {
  # Directory structure created automatically from filename
  # ~/Declaritive Office/10-19 Projects/10 Code/19 My-Project/

  # Optional: Add custom flake-parts configuration
  perSystem = { pkgs, ... }: {
    packages.my-project-tool = pkgs.writeShellScriptBin "build-project" ''
      echo "Building project..."
    '';
  };
}
```

## 2. Simple Path Format (Override System)

**Filename determines a single managed path under `$HOME`:**

### Pattern
```
simple-name.nix → ~/simple-name
```

### Examples
```
recovered-dendrix-config.nix → ~/recovered-dendrix-config
work-backup.nix → ~/work-backup
```

### Behavior
When a johnny-mnemonix configuration item would create a directory at this path:

1. **Build warning**: `"Path conflicts with module 'name.nix' - skipping operations"`
2. **Activation skip**: Johnny-mnemonix skips git/symlink operations
3. **Module control**: The module has full control of that path

### Example
`modules/special-project.nix`:
```nix
{ ... }: {
  # This module declares ownership of ~/special-project
  # Johnny-mnemonix will skip operations for any items at that path

  perSystem = { pkgs, ... }: {
    packages.special-tool = pkgs.writeShellScriptBin "special" ''
      echo "Special tool"
    '';
  };
}
```

## Templates

- **Johnny Decimal**: See inline examples above
- **Simple Path**: See `example-project.nix` for commented template

## Base Directory

The base directory for Johnny Decimal structures is configured via:
```nix
johnny-mnemonix.baseDir = "${config.home.homeDirectory}/Declaritive Office";
```

This follows XDG principles by keeping workspace-related files in a dedicated directory.

## Workspace Index

Johnny-mnemonix automatically generates a `__INDEX__` file that provides a tree-like view of your entire workspace structure.

### Features

- **Multiple Output Formats**: Markdown (`.md`), Typst (`.typ`), PDF (`.pdf`), or plain text (`.txt`)
- **Enhanced Metadata**: Optionally includes git repository URLs and symlink targets
- **Automatic Updates**: Regenerates during home-manager activation
- **Watch Mode**: Optional systemd service to regenerate on directory changes
- **Manual Regeneration**: Use `jm-regenerate-index` command

### Configuration

```nix
johnny-mnemonix.index = {
  enable = true;              # Enable index generation (default: true)
  format = "md";              # Output format: "md", "typ", "pdf", or "txt" (default: "md")
  enhanced = true;            # Include metadata like git URLs (default: true)

  watch = {
    enable = false;           # Enable automatic regeneration on changes (default: false)
    interval = 2;             # Debounce interval in seconds (default: 2)
  };
};
```

### File Locations

- **Source**: `~/.local/state/johnny-mnemonix/__INDEX__.<format>`
- **Symlink**: `~/Declaritive Office/__INDEX__.<format>`

### Format Notes

- **PDF format**: Requires `johnny-mnemonix.typix.enable = true` for compilation
- **Enhanced mode**: Displays item types and metadata in tree output
- **Watch mode**: Monitors directory structure changes (create, delete, move operations)
