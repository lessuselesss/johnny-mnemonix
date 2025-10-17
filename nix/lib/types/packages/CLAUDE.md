# Package Types - Nix Package Definitions

**Location**: `nix/lib/types/packages/`
**Purpose**: Type definitions for Nix packages and derivations
**Layer**: 4 (Type Bridge)

---

## Purpose

This directory provides **type definitions for Nix packages** that users might organize using Johnny Decimal. These are NOT std block types (which define CLI actions), but rather **package structure types** for specific tools and frameworks.

**Key Insight**: Package types define the **structure and configuration** of packages built by our organizational system, complementing block types which define how to **build and interact** with them via CLI.

---

## Package Types vs Block Types

### Block Types (`types/blocks/`)
- **Purpose**: Define what blocks export + CLI actions
- **Used In**: std `growOn` with `cellBlocks`
- **Example**: `std //proj/typstProjects/10.01-thesis:build`

### Package Types (`types/packages/`) ← THIS DIRECTORY
- **Purpose**: Define package structure and configuration
- **Used In**: Package definitions, derivation builders
- **Example**: `{ src, typstSource, fontPaths, ... }`

---

## Files

### `typix.nix`
**Purpose**: Package types for typix Typst document compilation

Defines the structure of typix packages:

**mkTypstDerivation Configuration**:
```nix
{
  # Required
  buildPhaseTypstCommand = "typst compile ...";

  # Optional compilation config
  typstSource = "main.typ";
  typstCompileCommand = "typst compile";
  fontPaths = [ ./fonts ];
  virtualPaths = [ { src = ./data; dest = "data"; } ];
  typstPackages = [ "preview/charged-ieee" ];

  # Standard derivation attrs
  name = "my-document";
  version = "1.0.0";
  src = ./src;

  # Build/install phases
  installPhase = "...";
}
```

**buildTypstProject Configuration**:
```nix
{
  src = ./document;
  typstSource = "main.typ";
  name = "thesis";
  version = "1.0.0";

  # Typix-specific
  fontPaths = [ ./fonts ];
  virtualPaths = [ ... ];
  typstPackages = [ ... ];
}
```

**watchTypstProject Configuration**:
```nix
{
  src = ./document;
  typstSource = "main.typ";

  # Watch-specific
  open = true;          # Open PDF after build
  command = "zathura";  # PDF viewer command
}
```

---

## Usage Pattern

Package types are used when **defining package configurations**:

```nix
# In a Johnny Decimal organized project
let
  packageTypes = inputs.johnny-dd.lib.${system}.types.packageTypes;

  # Validate package configuration
  validateTypixProject = config:
    lib.types.check packageTypes.typix.typstProject config;

in {
  packages = {
    # 10.01 - My Thesis
    "thesis" = buildTypstProject {
      src = ./documents/10.01-thesis;
      typstSource = "main.typ";
      name = "thesis";
      fontPaths = [ ./fonts ];
    };

    # 20.01 - Research Paper
    "paper" = buildTypstProject {
      src = ./documents/20.01-paper;
      typstSource = "paper.typ";
      name = "research-paper";
    };
  };
}
```

---

## Design Principles

1. **Configuration Validation**: Package types validate package configurations
2. **Tool-Specific**: Each file defines types for a specific tool (typix, etc.)
3. **Derivation-Focused**: Types match what package builders accept
4. **Complementary**: Work alongside block types for complete coverage

---

## Related Documentation

- **Parent Layer**: `../CLAUDE.md` (complete types system overview)
- **Block Types**: `../blocks/CLAUDE.md` (std block type definitions)
- **Module Types**: `../modules/CLAUDE.md` (NixOS module option types)
- **Flake Types**: `../flakes/CLAUDE.md` (flake input + output schemas)
