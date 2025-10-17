# Types Layer - Johnny Declarative Decimal

**Layer**: 4 (Types)
**Purpose**: Complete flake type system with module types and output validation
**Components**: `modules/`, `flakes/`, `types.nix`
**Status**: ✅ Complete

---

## Overview

The types layer provides a complete type system for Nix flakes, combining:

1. **Module Types**: NixOS-style module option types for configuration
2. **Flake Types**: Complete flake type definitions (input structure + output validation)

This enables:
- Type-safe module development across different flake ecosystems
- Automated validation of flake outputs via flake-schemas
- Reusable type definitions for common patterns

---

## Architecture

```
nix/lib/types/
├── CLAUDE.md                           # This file
├── types.nix                           # Block export (divnix/std)
├── modules/                            # NixOS module option types
│   ├── common.nix                      # Shared Johnny Decimal types
│   ├── nixos.nix                       # NixOS-specific types
│   ├── home-manager.nix                # home-manager-specific types
│   ├── nix-darwin.nix                  # nix-darwin-specific types
│   ├── dendrix.nix                     # Dendrix-specific types
│   ├── system-manager.nix              # system-manager-specific types
│   ├── typix.nix                       # Typix-specific types
│   ├── jm.nix                          # Johnny-Mnemonix types (dogfood)
│   ├── std.nix                         # divnix/std-specific types
│   └── hive.nix                        # divnix/hive-specific types
└── flakes/                             # Complete flake type definitions
    ├── nixos.nix                       # NixOS flake type
    ├── home-manager.nix                # home-manager flake type
    ├── darwin.nix                      # nix-darwin flake type
    ├── dendrix.nix                     # Dendrix flake type
    ├── system-manager.nix              # system-manager flake type
    ├── typix.nix                       # Typix flake type
    ├── jm.nix                          # Johnny-Mnemonix flake type
    ├── std.nix                         # divnix/std flake type
    └── hive.nix                        # divnix/hive flake type
```

---

## Part 1: Module Types

### Purpose

NixOS-style module option types (`lib.types.*`) for defining module options in each flake ecosystem.

### Structure

Each `modules/<class>.nix` file exports pure, class-specific types:

```nix
# modules/nixos.nix
{lib}: {
  nixosModulePath = lib.types.path;
  nixosConfigFile = lib.types.submodule { /* ... */ };
  systemPackages = lib.types.listOf lib.types.package;
  systemService = lib.types.submodule { /* ... */ };
}
```

### Common Types

`modules/common.nix` provides shared Johnny Decimal types used by `jm.nix`:

```nix
{
  jdIdentifier = lib.types.strMatching "[0-9]{2}\\.[0-9]{2}";
  jdAreaRange = lib.types.strMatching "[0-9]{2}-[0-9]{2}";
  jdCategory = lib.types.strMatching "[0-9]{2}";
  jdItemDef = lib.types.submodule { /* ... */ };
  jdCategoryDef = lib.types.submodule { /* ... */ };
  jdAreaDef = lib.types.submodule { /* ... */ };
  jdSyntax = lib.types.submodule { /* ... */ };
}
```

### Usage

```nix
# In a module
{ config, lib, ... }:
let
  types = inputs.johnny-dd.lib.${system}.types.moduleTypes;
in {
  options.myOption = lib.mkOption {
    type = types.nixos.systemService;
    description = "My NixOS service";
  };
}
```

---

## Part 2: Flake Types

### Purpose

Complete flake type definitions combining:
1. **Module Input Structure**: How to write modules (`flake.modules.<class>`)
2. **Output Validation**: Schema validation for flake outputs (via flake-schemas)

### Structure

Each `flakes/<class>.nix` file exports:

```nix
{lib}: {
  # Part 1: Module Input Structure
  moduleInput = {
    description = "...";
    moduleType = types.deferredModule;
    example = '' /* ... */ '';
    schema = { /* options */ };
  };

  # Part 2: Output Schemas (flake-schemas format)
  schemas = {
    <outputName> = {
      version = 1;
      doc = "...";
      inventory = output: { /* validation */ };
    };
  };
}
```

### Example: NixOS Flake Type

```nix
# flakes/nixos.nix
{
  moduleInput = {
    description = "NixOS system configuration modules";
    moduleType = types.deferredModule;
    example = ''
      flake.modules.nixos.myServer = { config, pkgs, ... }: {
        services.nginx.enable = true;
      };
    '';
  };

  schemas = {
    nixosModules = {
      version = 1;
      doc = "NixOS modules";
      inventory = output: {
        children = builtins.mapAttrs (name: module: {
          what = "NixOS module";
          evalChecks = {
            isImportable = builtins.isFunction module || builtins.isAttrs module;
          };
        }) output;
      };
    };

    nixosConfigurations = {
      version = 1;
      doc = "NixOS system configurations";
      inventory = output: { /* ... */ };
    };
  };
}
```

---

## Flake Types Defined

### Meta Framework

| Type | Module Input | Output Schemas | Description |
|------|--------------|----------------|-------------|
| `flakeParts` | flake.modules.generic | flakeModules, flakeModule, modules | Modular flake composition framework |

### Standard Flake Types

| Type | Module Input | Output Schemas |
|------|--------------|----------------|
| `nixos` | flake.modules.nixos | nixosModules, nixosConfigurations |
| `homeManager` | flake.modules.homeManager | homeModules, homeManagerModules, homeConfigurations |
| `darwin` | flake.modules.darwin | darwinModules, darwinConfigurations |

### Custom Flake Types

| Type | Module Input | Output Schemas | Description |
|------|--------------|----------------|-------------|
| `dendrix` | flake.modules.dendrix | dendrixModules | Dendritic aspect-oriented configuration |
| `systemManager` | flake.modules.systemManager | systemManagerModules, smModules | NixOS-style config for any Linux |
| `typix` | flake.modules.typix | typixModules, typixProjects | Typst document projects |
| `jm` | flake.modules.jm | jmModules, jmConfigurations | Johnny-Mnemonix (dogfood) |
| `std` | flake.modules.std | stdModules, stdCells | divnix/std cell/block structure |
| `hive` | flake.modules.hive | hiveModules, hive | divnix/hive NixOS deployment (std-based) |

---

## Usage Examples

### Using Module Types

```nix
# Define a module with typed options
{ config, lib, pkgs, inputs, ... }:
let
  types = inputs.johnny-dd.lib.${pkgs.system}.types.moduleTypes;
in {
  options = {
    myJDWorkspace = lib.mkOption {
      type = types.jm.jmConfiguration;
      description = "Johnny Decimal workspace configuration";
    };

    myTypixProject = lib.mkOption {
      type = types.typix.typixProject;
      description = "Typst document project";
    };
  };
}
```

### Using Flake Types (flake-parts)

```nix
# In flake.nix with flake-parts
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    johnny-dd.url = "github:user/johnny-declarative-decimal";
  };

  outputs = inputs @ { flake-parts, johnny-dd, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      # Use custom module classes
      flake.modules = {
        # Dendrix aspect-oriented modules
        dendrix.networking = ./dendrix/networking.nix;
        dendrix.graphics = ./dendrix/graphics.nix;

        # Typix document projects
        typix.thesis = {
          src = ./documents/thesis;
          entrypoint = "main.typ";
        };

        # Johnny-Mnemonix workspace
        jm.workspace = {
          baseDir = "\${config.home.homeDirectory}/Documents";
          areas = {
            "10-19" = {
              name = "Projects";
              categories = { /* ... */ };
            };
          };
        };
      };

      # Schemas validate outputs automatically
      flake = {
        # These are validated by johnny-dd schemas
        dendrixModules = { /* ... */ };
        typixModules = { /* ... */ };
        jmModules = { /* ... */ };
      };
    };
}
```

### Using Flake Schemas

```nix
# In flake.nix (with Nix PR #8892 or compatible tool)
{
  outputs = { self, nixpkgs, johnny-dd, ... }: {
    # Import schemas for validation
    schemas = johnny-dd.lib.x86_64-linux.types.schemas;

    # Your flake outputs (automatically validated)
    jmModules.workspace = { /* ... */ };
    dendrixModules.networking = { /* ... */ };
    typixModules.thesis = { /* ... */ };
  };
}
```

---

## Integration Points

### With flake-parts

Flake types integrate with flake-parts via `flake.modules.<class>`:

```nix
flake.modules.jm.workspace = { /* ... */ };
flake.modules.typix.thesis = { /* ... */ };
```

### With flake-schemas

Output schemas follow the flake-schemas format and can be used with:
- Nix PR #8892 (adds `nix flake check` schema support)
- Custom forks of flake-schemas
- Direct schema validation in CI

### With divnix/std

The types layer is itself a divnix/std block:

```nix
# Access via cells
cells.lib.${system}.types.moduleTypes.nixos
cells.lib.${system}.types.flakeTypes.nixos
cells.lib.${system}.types.schemas.nixosModules
```

---

## API Export

### From types.nix Block

```nix
{
  # All module types by class
  moduleTypes = {
    common = { jdIdentifier, jdAreaRange, ... };
    nixos = { nixosModulePath, systemService, ... };
    homeManager = { homeDirectory, xdgConfigFile, ... };
    darwin = { darwinConfiguration, brewPackage, ... };
    dendrix = { aspectName, aspectModule, ... };
    systemManager = { systemConfig, systemService, ... };
    typix = { typixProject, typixBuild, ... };
    jm = { jmConfiguration, jmModule, ... };
    std = { cellName, blockType, stdCell, ... };
    hive = { hiveNode, colmenaConfig, ... };
  };

  # All flake types (inputs + schemas)
  flakeTypes = {
    nixos = { moduleInput, schemas };
    homeManager = { moduleInput, schemas };
    # ... etc for all classes
  };

  # All schemas in one place
  schemas = {
    nixosModules, nixosConfigurations,
    homeModules, homeConfigurations,
    darwinModules, darwinConfigurations,
    dendrixModules,
    systemManagerModules, smModules,
    typixModules, typixProjects,
    jmModules, jmConfigurations,
    stdModules, stdCells,
    hiveModules, hive,
  };

  # All module inputs in one place
  moduleInputs = {
    nixos, homeManager, darwin,
    dendrix, systemManager, typix,
    jm, std, hive,
  };

  # Helpers
  schemasByCategory = { standard, custom };
  moduleInputsByCategory = { standard, custom };
}
```

---

## Design Principles

### 1. Purity

Module types are **pure** - they define only the types for their respective systems without mixing concerns:
- No Johnny Decimal types in non-JM module types
- Each module type file is self-contained
- Common JD types isolated in `common.nix`

### 2. Completeness

Each flake type provides both:
- **Input definition**: How to write modules
- **Output validation**: How to validate results

### 3. Composability

Types compose naturally:
- Module types used in option definitions
- Flake types used for validation
- Both work together in complete systems

### 4. Extensibility

Easy to add new flake types:
1. Create `modules/<class>.nix`
2. Create `flakes/<class>.nix`
3. Add to `types.nix` exports

---

## Related Documentation

- **Library Overview**: ../CLAUDE.md (library layers 1-3)
- **Primitives**: ../primitives/CLAUDE.md (layer 1)
- **Composition**: ../composition/CLAUDE.md (layer 2)
- **Builders**: ../builders/CLAUDE.md (layer 3)
- **Project Root**: ../../../CLAUDE.md (overall structure)

---

## Next Steps

1. **Use in frameworks**: Frameworks will leverage these types for validation
2. **Integrate with CI**: Use schemas for automated flake validation
3. **Extend as needed**: Add new flake types for emerging ecosystems

**Remember**: Types provide the type system foundation. Primitives/Composition/Builders provide the organizational logic. Together they enable complete, type-safe flake systems. 🎯
