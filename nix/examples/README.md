# Examples Cell (`examples`)

**Cell Type**: Example configurations
**Purpose**: Real-world usage examples and templates
**Blocks**: `configs.nix`
**Status**: ⏳ Planned (specifications complete, implementations pending)

---

## Overview

The `examples` cell provides **complete, working examples** of johnny-declarative-decimal in action. Each example demonstrates different use cases, patterns, and integrations, serving as both documentation and starter templates.

### Purpose

1. **Learning**: Show how to use the system
2. **Templates**: Provide starting points for new projects
3. **Testing**: Verify system works in realistic scenarios
4. **Documentation**: Living examples are better than static docs

---

## Directory Structure

```
nix/examples/
├── README.md                        # This file
├── CLAUDE.md                        # Example specifications
│
├── configs.nix                      # Block: Example exports
│
├── classic-jd/                      # Classic Johnny Decimal
│   ├── flake.nix                    # Complete working flake
│   ├── home.nix                     # Home-manager config
│   └── README.md                    # Usage guide
│
├── hex-variant/                     # Hexadecimal variant
│   ├── flake.nix
│   ├── home.nix
│   └── README.md
│
├── extended-3-level/                # 3-level hierarchy
│   ├── flake.nix
│   ├── home.nix
│   └── README.md
│
├── custom-builder/                  # Custom system using builders
│   ├── flake.nix
│   ├── builder.nix                  # Custom builder definition
│   └── README.md
│
├── from-scratch/                    # Built from primitives
│   ├── flake.nix
│   ├── system.nix                   # Using primitives directly
│   └── README.md
│
├── office-workspace/                # Office/workspace setup
│   ├── flake.nix
│   ├── home.nix
│   └── README.md
│
└── software-project/                # Software development
    ├── flake.nix
    ├── home.nix
    └── README.md
```

---

## Example Categories

### 1. Basic Examples

**Target Audience**: New users learning the system

#### Classic Johnny Decimal
**Path**: `classic-jd/`

**What it shows**:
- Using `johnny-decimal-classic` framework
- Standard 2-level hierarchy (N₁.N₂)
- Basic area/category/item structure
- Home-manager integration

**Structure**:
```
~/Documents/
├── 10-19 Projects/
│   ├── 10 Code/
│   │   ├── 10.01 Web-App/
│   │   └── 10.02 CLI-Tool/
│   └── 11 Documentation/
│       └── 11.01 User-Guide/
└── 20-29 Personal/
    └── 20 Finance/
        └── 20.01 Budget/
```

**Config snippet**:
```nix
{
  inputs.johnny-dd.url = "github:youruser/johnny-mnemonix";

  outputs = { johnny-dd, ... }: {
    homeConfigurations.user = {
      imports = [
        johnny-dd.frameworks.johnny-decimal-classic.homeManagerModule
      ];

      johnny-mnemonix = {
        enable = true;
        areas = {
          "10-19 Projects" = {
            "10" = { name = "Code"; };
            "11" = { name = "Documentation"; };
          };
          "20-29 Personal" = {
            "20" = { name = "Finance"; };
          };
        };
      };
    };
  };
}
```

#### Hex Variant
**Path**: `hex-variant/`

**What it shows**:
- Using hexadecimal base (00-FF)
- Larger ID space (256 vs 100 per level)
- Same structure, different syntax

**Structure**:
```
~/Projects/
├── 10-1F Development/
│   └── 1A Code/
│       └── 1A.3F My-Project/
```

**Config snippet**:
```nix
johnny-dd.frameworks.johnny-decimal-hex.homeManagerModule {
  areas = {
    "10-1F Development" = {
      "1A" = { name = "Code"; };  # 26 in decimal
    };
  };
}
```

---

### 2. Intermediate Examples

**Target Audience**: Users customizing the system

#### Extended 3-Level
**Path**: `extended-3-level/`

**What it shows**:
- 3-level hierarchy (N₁.N₂.N₃)
- Area.Category.Item structure
- Breadcrumb navigation
- Deeper organization

**Structure**:
```
~/Workspace/
├── 10 Projects/
│   ├── 10.05 Active/
│   │   ├── 10.05.01 WebApp/
│   │   └── 10.05.02 MobileApp/
│   └── 10.10 Archive/
│       └── 10.10.01 OldProject/
```

**Config snippet**:
```nix
johnny-dd.frameworks.johnny-decimal-extended.homeManagerModule {
  areas = {
    "10" = {
      name = "Projects";
      categories = {
        "05" = {
          name = "Active";
          items = {
            "01" = { name = "WebApp"; };
            "02" = { name = "MobileApp"; };
          };
        };
      };
    };
  };
}
```

#### Custom Builder
**Path**: `custom-builder/`

**What it shows**:
- Using `lib.builders` directly
- Custom number base
- Custom separators
- Custom constraints

**Example**:
```nix
let
  # Custom JD with underscore separators and 3-digit components
  myJD = johnny-dd.lib.x86_64-linux.builders.mkJohnnyDecimal {
    levels = 2;
    base = 10;
    digits = 3;
    separators = ["_"];
    constraints = {
      category = { min = 100; max = 999; };
    };
  };
in {
  # Use custom system
  # Format: 123_456 instead of 12.34
}
```

---

### 3. Advanced Examples

**Target Audience**: Power users building custom systems

#### From Scratch (Primitives)
**Path**: `from-scratch/`

**What it shows**:
- Building system from primitives layer
- Maximum flexibility
- Custom validation rules
- Novel organizational patterns

**Example**:
```nix
let
  primitives = johnny-dd.lib.x86_64-linux.primitives;

  # Custom field with validation
  customField = primitives.fields.mk {
    system = primitives.numberSystems.decimal;
    width = 2;
    padding = "zeros";
  };

  # Custom constraint
  evenOnly = primitives.constraints.custom (v: v % 2 == 0);

  # Build custom identifier
  myId = {
    parse = str: /* custom parsing */;
    format = val: /* custom formatting */;
    validate = str: /* custom validation */;
  };
in {
  # Use completely custom system
}
```

---

### 4. Real-World Examples

**Target Audience**: Users implementing practical solutions

#### Office Workspace
**Path**: `office-workspace/`

**What it shows**:
- Complete office setup
- Document management
- Project organization
- Meeting notes structure
- Reference materials

**Structure**:
```
~/Office/
├── 10-19 Projects/
│   ├── 10 Active/
│   │   ├── 10.01 Project-Alpha/
│   │   └── 10.02 Project-Beta/
│   └── 11 Archive/
├── 20-29 Documents/
│   ├── 20 Reports/
│   │   └── 20.01 Q4-2024/
│   └── 21 Templates/
├── 30-39 Meetings/
│   └── 30 Notes/
│       ├── 30.01 2024-10-17-Standup/
│       └── 30.02 2024-10-18-Planning/
└── 40-49 References/
    └── 40 Documentation/
```

**Features**:
- Typst integration for documents
- Index generation
- Git tracking for notes
- Template system

#### Software Project
**Path**: `software-project/`

**What it shows**:
- Software development workflow
- Code organization
- Documentation structure
- Test and build configs

**Structure**:
```
~/Dev/MyProject/
├── 10-19 Source/
│   ├── 10 Core/
│   │   ├── 10.01 API/
│   │   └── 10.02 Database/
│   └── 11 UI/
│       └── 11.01 Components/
├── 20-29 Documentation/
│   ├── 20 User/
│   └── 21 Developer/
├── 30-39 Testing/
│   ├── 30 Unit/
│   └── 31 Integration/
└── 40-49 Build/
    └── 40 Configs/
```

**Features**:
- Git submodules for 10.01, 10.02, etc.
- Automated doc generation
- CI/CD integration
- Version tracking

---

## Example Format

Each example follows this structure:

### 1. `flake.nix`
Complete, working flake with:
- Inputs (johnny-dd, home-manager, etc.)
- Outputs (homeConfigurations)
- Full configuration
- Comments explaining choices

### 2. `home.nix` (if applicable)
Home-manager module with:
- johnny-mnemonix configuration
- Directory structure definition
- Integration settings

### 3. `README.md`
Documentation including:
- What the example demonstrates
- Target audience
- Setup instructions
- Customization points
- Common patterns
- Troubleshooting

### 4. Additional Files
As needed:
- `builder.nix`: Custom builder definitions
- `system.nix`: Custom system implementations
- `modules/`: Custom modules

---

## Using Examples

### Quick Start

```bash
# Clone example to start new project
nix flake init -t github:youruser/johnny-mnemonix#classic-jd

# Or copy example directory
cp -r examples/classic-jd ~/my-project
cd ~/my-project

# Customize for your needs
vim flake.nix

# Apply with home-manager
home-manager switch --flake .
```

### Learning Path

1. **Start here**: `classic-jd/` - Learn basics
2. **Customize**: `hex-variant/` - See variations
3. **Extend**: `extended-3-level/` - More complexity
4. **Build**: `custom-builder/` - Use builders directly
5. **Master**: `from-scratch/` - Use primitives

---

## Example Testing

All examples are tested to ensure they work:

```nix
# Test: Example flake evaluates
testExampleEvaluates = {
  expr = (evalFlake ./examples/classic-jd).homeConfigurations ? user;
  expected = true;
};

# Test: Example activates successfully
testExampleActivates = let
  config = (evalFlake ./examples/classic-jd).homeConfigurations.user;
in {
  expr = config.home.activation ? createJohnnyMnemonixDirs;
  expected = true;
};

# Test: Example generates expected structure
testExampleStructure = let
  result = activateExample ./examples/classic-jd;
in {
  expr = builtins.pathExists "${result}/Documents/10-19 Projects";
  expected = true;
};
```

---

## Contributing Examples

To add a new example:

### 1. Create Directory
```bash
mkdir nix/examples/my-example
```

### 2. Add Files
```nix
# nix/examples/my-example/flake.nix
{
  description = "Example showing [what it demonstrates]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    johnny-dd.url = "github:youruser/johnny-mnemonix";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { johnny-dd, home-manager, ... }: {
    # Your example configuration
  };
}
```

### 3. Document
```markdown
# nix/examples/my-example/README.md
# My Example

## What This Demonstrates

...

## Setup

...
```

### 4. Export
```nix
# nix/examples/configs.nix
{inputs, cell}: {
  # ... existing examples

  my-example = ./my-example;
}
```

### 5. Test
```bash
nix flake check ./examples/my-example
```

---

## Template System

Examples can be used as flake templates:

```nix
# In root flake.nix
{
  templates = {
    classic-jd = {
      path = ./nix/examples/classic-jd;
      description = "Classic Johnny Decimal workspace";
    };

    office = {
      path = ./nix/examples/office-workspace;
      description = "Office/workspace organization";
    };

    # ... more templates
  };
}
```

**Usage**:
```bash
nix flake init -t github:youruser/johnny-mnemonix#classic-jd
```

---

## Development Status

### Planned Examples
- ⏳ classic-jd (basic 2-level)
- ⏳ hex-variant (hexadecimal)
- ⏳ extended-3-level (3-level hierarchy)
- ⏳ custom-builder (using builders)
- ⏳ from-scratch (using primitives)
- ⏳ office-workspace (real-world)
- ⏳ software-project (real-world)

### Future Examples
- Calendar-based organization (YYYY.MM.DD)
- Mixed-radix system (hex areas, decimal items)
- Multi-user shared workspace
- Git-backed knowledge base
- Zettelkasten integration

---

## Related Documentation

- **Framework Documentation**: See `nix/frameworks/README.md`
- **Library Documentation**: See `nix/lib/README.md`
- **Example Specifications**: See `CLAUDE.md` in this directory
- **Project Overview**: See root `CLAUDE.md`

---

## Tips for Using Examples

### 1. Start Simple
Begin with `classic-jd`, understand it fully before moving to more complex examples.

### 2. Copy, Don't Link
Copy examples to your project and customize - they're meant to be starting points, not dependencies.

### 3. Learn Incrementally
Each example builds on previous concepts - follow the suggested learning path.

### 4. Experiment Freely
Examples are safe to modify - break things, learn, iterate.

### 5. Share Your Examples
If you create something useful, contribute it back!

---

## Troubleshooting

### Example Won't Evaluate
```bash
# Check flake syntax
nix flake check ./examples/my-example --show-trace

# Verify inputs are accessible
nix flake metadata ./examples/my-example
```

### Home Manager Activation Fails
```bash
# Test home-manager config in isolation
home-manager build --flake ./examples/my-example

# Check logs
journalctl --user -u home-manager-switch
```

### Structure Not Created
```bash
# Verify activation script
home-manager packages | grep johnny-mnemonix

# Check permissions
ls -la ~/Documents/

# Review activation output
home-manager switch --flake . -v
```

---

## Status Summary

**Current**: ⏳ Planned (specifications complete, 0/7 examples implemented)

**Timeline**: Phase 4 (after frameworks complete)

**Priority**: Medium (helpful for adoption, not critical for core functionality)

**Dependencies**: Requires frameworks layer to be functional

---

## Next Steps

1. Complete framework layer (especially johnny-decimal-classic)
2. Implement `classic-jd` example (template for others)
3. Add example testing infrastructure
4. Implement remaining examples
5. Set up flake templates
6. Create video walkthroughs for key examples
