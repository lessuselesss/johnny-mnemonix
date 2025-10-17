# Frameworks Cell (`frameworks`)

**Cell Type**: Pre-built solutions
**Purpose**: Complete, ready-to-use organizational systems
**Blocks**: `configs.nix`
**Status**: ⏳ Planned (specifications complete, implementation pending)

---

## Overview

The `frameworks` cell provides complete, batteries-included organizational systems built on top of the `lib` cell. Each framework combines:

- Library builders (from `nix/lib/builders/`)
- Home-manager integration
- Default configurations
- Documentation and examples

Frameworks are **opinionated** but **customizable** - they provide sensible defaults for common use cases while allowing full customization through the underlying library.

---

## Architecture

```
Frameworks (pre-built systems)
     ↓ uses
Builders (high-level constructors)
     ↓ uses
Composition (structured systems)
     ↓ uses
Primitives (atomic operations)
```

Each framework is a **complete solution** that:
1. Uses `lib.builders` to create ID system
2. Provides home-manager module integration
3. Includes default directory structures
4. Offers customization options
5. Ships with documentation

---

## Directory Structure

```
nix/frameworks/
├── README.md                        # This file
├── CLAUDE.md                        # Framework specifications
│
├── configs.nix                      # Block: Framework exports
│
├── johnny-decimal-classic/          # Classic JD (N₁.N₂)
│   ├── default.nix                  # Framework definition
│   ├── home-manager.nix             # HM module
│   └── README.md                    # Usage docs
│
├── johnny-decimal-hex/              # Hexadecimal JD
│   ├── default.nix
│   ├── home-manager.nix
│   └── README.md
│
├── johnny-decimal-extended/         # 3-level JD (N₁.N₂.N₃)
│   ├── default.nix
│   ├── home-manager.nix
│   └── README.md
│
└── semver/                          # Semantic versioning
    ├── default.nix
    ├── home-manager.nix
    └── README.md
```

---

## Planned Frameworks

### 1. Johnny Decimal Classic

**Purpose**: Standard 2-level Johnny Decimal (N₁.N₂ format)

**Features**:
- Category.Item structure (e.g., `10.05`)
- Decimal base (00-99 per level)
- Dot separator
- Area grouping (10-19, 20-29, etc.)
- Home-manager directory creation
- Index generation

**Usage**:
```nix
{
  inputs.johnny-dd.url = "github:youruser/johnny-mnemonix";

  outputs = { johnny-dd, ... }: {
    homeConfigurations.user = johnny-dd.frameworks.johnny-decimal-classic.homeManagerModule {
      areas = {
        "10-19 Projects" = {
          "10" = { name = "Code"; };
          "11" = { name = "Docs"; };
        };
      };
    };
  };
}
```

**Configuration**:
- Default base: 10 (decimal)
- Default levels: 2 (category.item)
- Default separator: "."
- Default area span: 10

---

### 2. Johnny Decimal Hex

**Purpose**: Hexadecimal variant for larger ID spaces

**Features**:
- Hexadecimal base (00-FF per level)
- 256 items per category (vs 100 in decimal)
- Same structure as classic
- Uppercase formatting

**Usage**:
```nix
johnny-dd.frameworks.johnny-decimal-hex.homeManagerModule {
  areas = {
    "10-1F Projects" = {
      "1A" = { name = "Code"; };  # 26 in decimal
    };
  };
}
```

**Configuration**:
- Default base: 16 (hexadecimal)
- Default levels: 2
- Default separator: "."
- Default area span: 16

---

### 3. Johnny Decimal Extended

**Purpose**: 3-level hierarchy (N₁.N₂.N₃)

**Features**:
- Area.Category.Item structure (e.g., `10.05.02`)
- Finer-grained organization
- More capacity (100 × 100 × 100 = 1M IDs)
- Breadcrumb path generation

**Usage**:
```nix
johnny-dd.frameworks.johnny-decimal-extended.homeManagerModule {
  areas = {
    "10" = {
      name = "Projects";
      categories = {
        "05" = {
          name = "Code";
          items = {
            "02" = { name = "WebApp"; };
          };
        };
      };
    };
  };
}
```

**Configuration**:
- Default base: 10 (decimal)
- Default levels: 3 (area.category.item)
- Default separator: "."

---

### 4. Semantic Versioning

**Purpose**: Software version management

**Features**:
- MAJOR.MINOR.PATCH format
- Prerelease tags (-alpha, -beta)
- Build metadata (+build.123)
- Version comparison
- Automated bumping

**Usage**:
```nix
johnny-dd.frameworks.semver.homeManagerModule {
  projects = {
    "my-app" = {
      currentVersion = "1.2.3";
      autoTag = true;  # Git tags
      changelogGen = true;
    };
  };
}
```

**Configuration**:
- Default octets: 3 (major.minor.patch)
- Default separator: "."
- Prerelease support: enabled
- Build metadata support: enabled

---

## Framework Structure

Each framework provides:

### 1. System Definition
```nix
# frameworks/johnny-decimal-classic/default.nix
{lib}: let
  builders = lib.builders;
in {
  # Use builder with framework defaults
  system = builders.mkJohnnyDecimal {
    levels = 2;
    base = 10;
    digits = 2;
    separators = ["."];
  };

  # Framework metadata
  meta = {
    name = "johnny-decimal-classic";
    description = "Standard 2-level Johnny Decimal";
    version = "1.0.0";
  };
}
```

### 2. Home Manager Module
```nix
# frameworks/johnny-decimal-classic/home-manager.nix
{config, lib, pkgs, ...}: let
  framework = import ./default.nix {inherit lib;};
in {
  options.johnny-decimal-classic = {
    enable = lib.mkEnableOption "Johnny Decimal Classic";

    baseDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents";
      description = "Base directory for JD structure";
    };

    areas = lib.mkOption {
      type = /* attrset of areas */;
      default = {};
      description = "Area definitions";
    };
  };

  config = lib.mkIf config.johnny-decimal-classic.enable {
    # Use framework.system for parsing/formatting
    # Generate directory structure
    # Create index files
  };
}
```

### 3. Documentation
```markdown
# frameworks/johnny-decimal-classic/README.md
# Johnny Decimal Classic Framework

Complete guide to using this framework...
```

---

## Using Frameworks

### As a Flake Input

```nix
{
  description = "My organized workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    johnny-dd.url = "github:youruser/johnny-mnemonix";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, johnny-dd, home-manager }: {
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        johnny-dd.frameworks.johnny-decimal-classic.homeManagerModule
        {
          johnny-decimal-classic = {
            enable = true;
            baseDir = "$HOME/Documents";
            areas = {
              "10-19 Projects" = {
                "10" = { name = "Code"; };
                "11" = { name = "Docs"; };
              };
            };
          };
        }
      ];
    };
  };
}
```

### Direct Integration

```nix
# In home.nix or configuration.nix
{inputs, ...}: {
  imports = [
    inputs.johnny-dd.frameworks.johnny-decimal-classic.homeManagerModule
  ];

  johnny-decimal-classic = {
    enable = true;
    areas = {
      # Your structure here
    };
  };
}
```

---

## Customization Levels

Frameworks offer three levels of customization:

### Level 1: Framework Defaults (Easiest)
Use framework as-is with minimal config.

```nix
johnny-decimal-classic = {
  enable = true;
  areas = { /* minimal structure */ };
};
```

### Level 2: Framework Options (Moderate)
Customize framework through provided options.

```nix
johnny-decimal-classic = {
  enable = true;
  baseDir = "$HOME/Workspace";
  indexFormat = "typ";
  gitIntegration = true;
  areas = { /* structure */ };
};
```

### Level 3: Direct Library Access (Advanced)
Bypass framework, use library directly.

```nix
let
  jd = inputs.johnny-dd.lib.x86_64-linux.builders.mkJohnnyDecimal {
    levels = 3;  # Custom: 3 levels instead of 2
    base = 16;   # Custom: hexadecimal
    # ... full control
  };
in {
  # Build your own integration
}
```

---

## Framework vs Library

**When to use frameworks**:
- ✅ Standard use cases (classic JD, semver)
- ✅ Want home-manager integration
- ✅ Need quick setup
- ✅ Prefer opinionated defaults
- ✅ Want included documentation

**When to use library directly**:
- ✅ Custom organizational system
- ✅ Non-standard number bases
- ✅ Novel hierarchy structures
- ✅ Integration with other tools
- ✅ Maximum flexibility

---

## Development Status

### Completed
- ✅ Framework specifications (see `CLAUDE.md`)
- ✅ Library foundation (all builders complete)
- ✅ Architecture design

### In Progress
- ⏳ Johnny Decimal Classic implementation
- ⏳ Home-manager module integration
- ⏳ Index generation
- ⏳ Git integration

### Planned
- ⏳ Johnny Decimal Hex variant
- ⏳ Johnny Decimal Extended (3-level)
- ⏳ Semantic Versioning framework
- ⏳ Calendar Versioning (CalVer)
- ⏳ Custom framework templates

---

## Related Documentation

- **Library Documentation**: See `nix/lib/README.md`
- **Framework Specifications**: See `CLAUDE.md` in this directory
- **Individual Frameworks**: See `*/README.md` in framework directories
- **Project Overview**: See root `CLAUDE.md`
- **Vision & Roadmap**: See root `TODO.md`

---

## Contributing

To add a new framework:

1. **Create framework directory**:
   ```bash
   mkdir nix/frameworks/my-framework
   ```

2. **Implement system definition**:
   ```nix
   # nix/frameworks/my-framework/default.nix
   {lib}: {
     system = lib.builders.mkMySystem { /* config */ };
     meta = { /* metadata */ };
   }
   ```

3. **Create home-manager module**:
   ```nix
   # nix/frameworks/my-framework/home-manager.nix
   {config, lib, ...}: {
     options.my-framework = { /* options */ };
     config = { /* implementation */ };
   }
   ```

4. **Add to configs.nix block**:
   ```nix
   # nix/frameworks/configs.nix
   {inputs, cell}: {
     my-framework = import ./my-framework {
       inherit (inputs.self.lib) lib;
     };
   }
   ```

5. **Document in README**:
   ```markdown
   # nix/frameworks/my-framework/README.md
   # My Framework
   ...
   ```

6. **Export from flake**:
   ```nix
   # flake.nix
   frameworks = {
     my-framework = cells.frameworks.${system}.configs.my-framework;
   };
   ```

---

## Next Steps

1. Complete johnny-decimal-classic framework
2. Refactor existing johnny-mnemonix to use framework
3. Implement remaining frameworks
4. Add integration tests
5. Create usage examples

---

## Status Summary

**Current**: ⏳ Planned (0/4 frameworks implemented)

**Timeline**: Phase 3 (after library complete and existing module refactored)

**Priority**: High (enables easy adoption of the library)
