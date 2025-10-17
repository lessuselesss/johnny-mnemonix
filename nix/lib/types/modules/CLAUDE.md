# Module Types - Type System Bridge

**Location**: `nix/lib/types/modules/`
**Purpose**: NixOS-style module option types for organizing configurations
**Layer**: 4 (Type Bridge)

---

## Purpose

This directory provides **NixOS module option types** (`lib.types.*`) for defining configuration options in various flake ecosystems. These types bridge the gap between our pure organizational primitives and the actual things users want to organize.

**Key Insight**: These are NOT the organizational primitives themselves. They are **type definitions** that let users organize their NixOS/home-manager/typix/etc configs using Johnny Decimal or other hierarchical systems.

---

## Files

### `common.nix`
**Purpose**: Shared Johnny Decimal types used across all ecosystems

**Exports**:
```nix
{
  jdIdentifier = lib.types.strMatching "[0-9]{2}\\.[0-9]{2}";
  jdAreaRange = lib.types.strMatching "[0-9]{2}-[0-9]{2}";
  jdCategory = lib.types.strMatching "[0-9]{2}";
  jdItemDef = lib.types.submodule { /* item config */ };
  jdCategoryDef = lib.types.submodule { /* category config */ };
  jdAreaDef = lib.types.submodule { /* area config */ };
  jdSyntax = lib.types.submodule { /* syntax customization */ };
}
```

### Domain-Specific Module Types

Each file provides **pure type definitions** for that ecosystem:

#### `nixos.nix`
Types for NixOS system configuration modules
- `nixosModulePath`, `nixosConfigFile`, `systemPackages`, `systemService`

#### `home-manager.nix`
Types for home-manager user environment modules
- `homeDirectory`, `xdgConfigFile`, `homeService`, `homePackage`

#### `nix-darwin.nix`
Types for nix-darwin macOS system configuration
- `darwinConfiguration`, `brewPackage`, `launchdService`

#### `dendrix.nix`
Types for dendrix aspect-oriented configuration
- `aspectName`, `aspectModule`, `aspectPriority`

#### `system-manager.nix`
Types for system-manager NixOS-style config on any Linux
- `systemConfig`, `systemService`, `systemPackage`

#### `typix.nix`
Types for typix Typst document projects
- `typixProject`, `typixBuild`, `typixSource`, `typixTemplate`

#### `jm.nix`
Types for Johnny-Mnemonix (dogfooding)
- `jmConfiguration`, `jmModule`, `jmWorkspace`
- Uses `common.nix` types internally

#### `std.nix`
Types for divnix/std cell/block structures
- `cellName`, `blockType`, `stdCell`, `cellBlocks`

#### `hive.nix`
Types for divnix/hive NixOS deployment (std-based)
- `hiveNode`, `hiveCell`, `hiveBlock`, `cellBlocks`

#### `flake-parts.nix`
Types for flake-parts modular flake composition
- `flakeModule`, `perSystemModule`, `perInputModule`

---

## Usage Pattern

Users consume these types when defining module options:

```nix
{ config, lib, inputs, ... }:
let
  types = inputs.johnny-dd.lib.${system}.types.moduleTypes;
in {
  options.myJDWorkspace = lib.mkOption {
    type = types.jm.jmConfiguration;
    description = "Johnny Decimal workspace";
  };

  options.myTypixDocs = lib.mkOption {
    type = types.typix.typixProject;
    description = "Organized Typst documents";
  };
}
```

---

## Design Principles

1. **Purity**: Each file defines ONLY types for its ecosystem (no mixing concerns)
2. **Domain-Specific**: Types match the idioms of each ecosystem
3. **Common Base**: JD-specific types isolated in `common.nix`
4. **No Logic**: These define types, not organizational logic (that's in layers 1-3)

---

## Related Documentation

- **Parent Layer**: `../CLAUDE.md` (complete types system overview)
- **Flake Types**: `../flakes/CLAUDE.md` (complete flake type definitions)
- **Library Layers**: `../../CLAUDE.md` (primitives/composition/builders)
