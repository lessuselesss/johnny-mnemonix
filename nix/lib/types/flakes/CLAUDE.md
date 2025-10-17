# Flake Types - Complete Flake Definitions

**Location**: `nix/lib/types/flakes/`
**Purpose**: Complete flake type definitions (input structure + output validation)
**Layer**: 4 (Type Bridge)

---

## Purpose

This directory provides **complete flake type definitions** that combine:

1. **Module Input Structure**: How users write modules in `flake.modules.<class>`
2. **Output Schemas**: How to validate flake outputs (via flake-schemas)

**Key Insight**: These definitions let users organize their **flake modules** using Johnny Decimal or other hierarchical systems, and automatically validate the outputs.

---

## Complete Standard Output Coverage

All standard Nix flake outputs now have full input/output type definitions:

| Output | Schema | Module Input | Provided By | Description |
|--------|--------|--------------|-------------|-------------|
| **Per-System Outputs** |
| `apps` | ✅ | ✅ | standard.nix, flake-parts.nix | Runnable programs (`nix run`) |
| `devShells` | ✅ | ✅ | standard.nix, flake-parts.nix | Development shells (`nix develop`) |
| `packages` | ✅ | ✅ | standard.nix | Installable packages (`nix build`) |
| `checks` | ✅ | ✅ | standard.nix | Tests and checks (`nix flake check`) |
| `formatter` | ✅ | ✅ | standard.nix | Code formatter (`nix fmt`) |
| `legacyPackages` | ✅ | ✅ | standard.nix | Legacy package sets (not in search) |
| **Flake-Wide Outputs** |
| `overlays` | ✅ | ✅ | standard.nix | Nixpkgs overlays |
| `templates` | ✅ | ✅ | standard.nix | Project templates (`nix flake init`) |
| `schemas` | ✅ | ✅ | standard.nix | Flake output schemas (meta!) |
| `hydraJobs` | ✅ | ✅ | standard.nix | Hydra CI jobs |
| `dockerImages` | ✅ | ✅ | standard.nix | Docker images |
| **Configuration Outputs** |
| `nixosModules` | ✅ | ✅ | nixos.nix | NixOS modules |
| `nixosConfigurations` | ✅ | ✅ | nixos.nix | NixOS system configurations |
| `homeModules` | ✅ | ✅ | home-manager.nix | home-manager modules |
| `homeConfigurations` | ✅ | ✅ | home-manager.nix | home-manager configurations |
| `darwinModules` | ✅ | ✅ | darwin.nix | nix-darwin modules |
| `darwinConfigurations` | ✅ | ✅ | darwin.nix | nix-darwin configurations |

---

## File Structure

Each file exports:

```nix
{
  # Part 1: How to write modules
  moduleInput = {
    description = "...";
    moduleType = types.deferredModule;
    example = '' /* usage example */ '';
    schema = { /* option types */ };
  };

  # Part 2: How to validate outputs
  schemas = {
    <outputName> = {
      version = 1;
      doc = "...";
      inventory = output: { /* validation logic */ };
    };
  };
}
```

---

## Files

### Standard Nix Outputs

#### `standard.nix`
**Purpose**: Complete coverage of standard Nix flake outputs

**Module Input**: `flake.modules.apps`, `flake.modules.devShells`, `flake.modules.packages`, etc.
**Output Schemas**: `apps`, `devShells`, `packages`, `checks`, `formatter`, `overlays`, `legacyPackages`, `templates`, `schemas`, `hydraJobs`, `dockerImages`

**Key Feature**: Supports both perSystem and dedicated module classes

Example:
```nix
# Approach 1: perSystem (standard)
perSystem.apps."10.01-build" = {
  type = "app";
  program = "${config.packages.builder}/bin/build";
};

# Approach 2: module classes (auto-merged to perSystem)
flake.modules.apps."10.01-build" = {
  type = "app";
  program = "${config.packages.builder}/bin/build";
};
```

### Meta Framework

#### `flake-parts.nix`
**Purpose**: Modular flake composition framework

**Module Input**: `flake.modules.generic`
**Output Schemas**: `flakeModules`, `flakeModule`, `modules`, `apps`, `devShells`

Example:
```nix
flake.modules.generic.myModule = { ... }: {
  perSystem = { pkgs, ... }: { /* ... */ };
};
```

---

### Standard Flake Types

#### `nixos.nix`
**Purpose**: NixOS system configuration

**Module Input**: `flake.modules.nixos.<id>`
**Output Schemas**: `nixosModules`, `nixosConfigurations`

Example:
```nix
flake.modules.nixos."10.01" = { config, pkgs, ... }: {
  services.nginx.enable = true;
};
```

#### `home-manager.nix`
**Purpose**: User environment configuration

**Module Input**: `flake.modules.homeManager.<id>`
**Output Schemas**: `homeModules`, `homeManagerModules`, `homeConfigurations`

#### `darwin.nix`
**Purpose**: macOS system configuration

**Module Input**: `flake.modules.darwin.<id>`
**Output Schemas**: `darwinModules`, `darwinConfigurations`

---

### Custom Flake Types

#### `dendrix.nix`
**Purpose**: Dendritic aspect-oriented configuration

**Module Input**: `flake.modules.dendrix.<aspect>`
**Output Schemas**: `dendrixModules`

Example:
```nix
flake.modules.dendrix.networking = { ... }: {
  # Aspect that can be composed across configs
};
```

#### `system-manager.nix`
**Purpose**: NixOS-style config for any Linux

**Module Input**: `flake.modules.systemManager.<id>`
**Output Schemas**: `systemManagerModules`, `smModules`

#### `typix.nix`
**Purpose**: Typst document projects

**Module Input**: `flake.modules.typix.<docId>`
**Output Schemas**: `typixModules`, `typixProjects`

Example:
```nix
flake.modules.typix."20.01" = {
  src = ./docs/thesis;
  entrypoint = "main.typ";
};
```

#### `jm.nix`
**Purpose**: Johnny-Mnemonix (dogfooding)

**Module Input**: `flake.modules.jm.<id>`
**Output Schemas**: `jmModules`, `jmConfigurations`

#### `std.nix`
**Purpose**: divnix/std cell/block structure

**Module Input**: `flake.modules.std.<cellName>`
**Output Schemas**: `stdModules`, `stdCells`

#### `hive.nix`
**Purpose**: divnix/hive NixOS deployment (std-based)

**Module Input**: `flake.modules.hive.<cellName>`
**Output Schemas**: `hiveModules`, `hive`

Example:
```nix
flake.modules.hive.prod = {
  cellBlocks = [ "web-servers" "databases" ];
  web-servers = {
    web01 = { services.nginx.enable = true; };
  };
};
```

---

## Integration with flake-parts

These types integrate with flake-parts via `flake.modules.<class>`:

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    johnny-dd.url = "github:user/johnny-declarative-decimal";
  };

  outputs = inputs @ { flake-parts, johnny-dd, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      # Organize modules using Johnny Decimal
      flake.modules = {
        nixos."10.01" = ./configs/networking.nix;
        homeManager."20.01" = ./configs/shell.nix;
        typix."30.01" = { src = ./docs/thesis; };
      };

      # Schemas validate outputs automatically
      flake.schemas = johnny-dd.lib.x86_64-linux.types.schemas;
    };
}
```

---

## Schema Validation

Schemas follow the flake-schemas format (DeterminateSystems):

```nix
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
```

Can be used with:
- Nix PR #8892 (adds `nix flake check` schema support)
- Custom CI validation scripts
- Compatible tooling

---

## Design Principles

1. **Completeness**: Each type defines both input structure AND output validation
2. **Composability**: Types work together in complete flake systems
3. **Standards-Based**: Follows flake-schemas format
4. **Ecosystem-Specific**: Matches idioms of each flake ecosystem

---

## Related Documentation

- **Parent Layer**: `../CLAUDE.md` (complete types system overview)
- **Module Types**: `../modules/CLAUDE.md` (NixOS module option types)
- **Library Layers**: `../../CLAUDE.md` (primitives/composition/builders)
- **flake-schemas**: https://github.com/DeterminateSystems/flake-schemas
