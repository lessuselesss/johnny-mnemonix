# divnix/std: Framework Overview
**Project**: divnix/std  
**Source**: https://std.divnix.com/  
**Purpose**: DevOps framework for SDLC with Nix Flakes

---

## What is Standard?

"Standard is a nifty DevOps framework that enables an efficient Software Development Life Cycle (SDLC) with the power of Nix via Flakes."

It organizes Nix code systematically while integrating high-quality DevOps tooling from the broader Nix ecosystem.

## The Problem It Solves

Standard addresses a common challenge in Nix projects: as codebases grow complex, they become difficult to navigate and maintain. The framework introduces structure through a disciplined approach, making repositories more intuitive for teams.

**Key Question Answered**: *What can I do with this repository?*

Rather than asking colleagues to decipher undocumented Nix configurations, Standard provides a canonical answer through consistent structure.

## Core Concepts

### Cells

**Definition**: Folders within a designated directory (e.g., `nix/`) that group related functionality.

**Purpose**: Organize code by domain or functional area.

**Example**:
```
nix/
├── lib/          # Cell: Library code
├── apps/         # Cell: Applications
├── services/     # Cell: Services
└── config/       # Cell: Configuration
```

### Cell Blocks

**Definition**: Individual files or subdirectories within cells representing specific output types.

**Purpose**: Define what each cell exports (packages, shells, configurations, etc.).

**Example**:
```
nix/lib/
├── primitives.nix     # Block: Primitives exports
├── composition.nix    # Block: Composition exports
└── builders.nix       # Block: Builders exports
```

### Block Types

Standard provides curated block types for DevOps workflows:

- **functions**: Reusable Nix functions (library code)
- **installables**: Packages for user installation
- **runnables**: Targets with 'run' action
- **devshells**: Development environments
- **containers**: OCI images
- **arion**: Docker Compose management
- **nixago**: Repository dotfiles
- And 10+ more specialized types

## Philosophy

### More Intuition, Less Documentation

Standard emphasizes consistent patterns over extensive documentation. By establishing canonical structures, developers understand project capabilities through exploration.

### Dogfooding

The framework demonstrates its principles through its own implementation, serving as a living example of best practices.

### Disciplined Interfaces

Creates a "well-defined folder structure" that disciplines generic interfaces across projects, making codebases predictable and maintainable.

## Quick Start Example

### Hello World Structure

```nix
# flake.nix
{
  inputs = {
    std.url = "github:divnix/std";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = {std, ...} @ inputs:
    std.grow {
      inherit inputs;
      cellsFrom = ./nix;  # Where cells live
    };
}
```

```nix
# nix/hello/apps.nix (Cell Block)
{
  inputs,
  cell,
}: {
  default = inputs.nixpkgs.hello;
}
```

**Usage**:
```bash
$ std //hello/apps/default:run
Hello, world!
```

## Key Benefits

1. **Structure**: Consistent organization across projects
2. **Discovery**: Easy to find what's available
3. **Composability**: Cells and blocks combine naturally
4. **Tooling**: CLI/TUI for exploring capabilities
5. **Interoperability**: Works with flake-utils, flake-parts

## Integration with Our Project

### Our Cell Structure

```
nix/
├── lib/              # Cell: Library code
│   ├── primitives.nix        # Block: Layer 1
│   ├── composition.nix       # Block: Layer 2
│   └── builders.nix          # Block: Layer 3
├── frameworks/       # Cell: Pre-built solutions
│   └── configs.nix           # Block: Framework configs
├── config/           # Cell: System configuration
│   └── modules.nix           # Block: Config modules
├── tests/            # Cell: Test suites
│   ├── unit.nix              # Block: Unit tests
│   ├── integration.nix       # Block: Integration tests
│   └── e2e.nix               # Block: E2E tests
└── examples/         # Cell: Example systems
    └── configs.nix           # Block: Examples
```

### Block Types We Use

All our blocks use the **functions** blockType:
- **Purpose**: Reusable nix functions and modules
- **Actions**: None (pure library code, no CLI actions)
- **Output**: Attribute sets of functions

### Why std.growOn?

We use `std.growOn` to automatically discover and load our cells:

```nix
cells = inputs.std.growOn {
  inherit inputs;
  cellsFrom = ./nix;
  cellBlocks = [
    (inputs.std.blockTypes.functions "primitives")
    (inputs.std.blockTypes.functions "composition")
    (inputs.std.blockTypes.functions "builders")
    # ... etc
  ];
};
```

This gives us:
- **Auto-discovery**: All cells loaded automatically
- **Type safety**: Block types enforce structure
- **Access patterns**: `cells.lib.<system>.primitives.numberSystems`

## Comparison to Alternatives

### vs. flake-utils
- **std**: Opinionated structure, cells/blocks organization
- **flake-utils**: Simple system iteration, no structure

### vs. flake-parts
- **std**: Cell-based organization with block types
- **flake-parts**: Module system for flake composition

### Our Choice
We use **both**: std for cell organization + flake-parts for module composition.

## Resources

- **Docs**: https://std.divnix.com/
- **GitHub**: https://github.com/divnix/std
- **Block Types Reference**: https://std.divnix.com/reference/blocktypes.html
- **Tutorials**: https://std.divnix.com/tutorials/
