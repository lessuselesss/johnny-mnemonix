# Block Types - std Block Definitions

**Location**: `nix/lib/types/blocks/`
**Purpose**: divnix/std block type definitions
**Layer**: 4 (Type Bridge)

---

## Purpose

This directory provides **std block type definitions** that specify:

1. **What blocks export** - The structure of block outputs
2. **What actions are available** - CLI commands users can run
3. **How blocks are validated** - Type checking for block contents

**Key Insight**: Block types are NOT the same as module types or flake types. They define the **interface between std cells/blocks and the std CLI/TUI**.

---

## Block Types vs Other Types

### Module Types (`types/modules/`)
- **Purpose**: Define option types for NixOS modules
- **Used in**: `lib.mkOption { type = moduleTypes.nixos.systemService; }`
- **Scope**: Inside module definitions

### Flake Types (`types/flakes/`)
- **Purpose**: Define flake input structure + output schemas
- **Used in**: `flake.modules.<class>` and flake-schemas validation
- **Scope**: Flake-level organization

### Block Types (`types/blocks/`) ← THIS DIRECTORY
- **Purpose**: Define what std blocks can export + their CLI actions
- **Used in**: std block definitions (`growOn`, cell/block structure)
- **Scope**: std framework integration

---

## Files

### `std.nix`
**Purpose**: Standard divnix/std block types

std provides 18 built-in block types organized by category:

**Container & Orchestration**:
- `arion` - Docker Compose management (up, ps, stop, rm, config)
- `containers` - OCI images via nix2container (print-image, publish, load)
- `microvms` - microvm.nix VMs (run, console)

**Kubernetes & Scheduling**:
- `kubectl` - Kubernetes manifests (render, diff, apply, explore)
- `nomad` - Nomad jobs (render, deploy, explore)

**Infrastructure as Code**:
- `terra` - Terraform/Terranix (init, plan, apply, state, refresh, destroy)

**Development**:
- `devshells` - Dev environments (build, enter)

**Executables & Packages**:
- `runnables` - Executables (build, run)
- `installables` - User profile packages (install, upgrade, remove, bundle)
- `pkgs` - Custom nixpkgs (no CLI actions)

**Configuration & Data**:
- `nixago` - Dotfile management (populate, explore)
- `data` - JSON data (write, explore)
- `files` - Text files (explore via bat)

**Testing**:
- `namaka` - Snapshot testing (eval, check, review, clean)
- `nixostests` - NixOS VM tests (run, audit-script, run-vm)

**Package Management**:
- `nvfetcher` - Source updates (fetch)

**Generic**:
- `functions` - Pure library code (no actions)
- `anything` - Fallback type (no actions)

### `hive.nix`
**Purpose**: Block types for divnix/hive deployments

Hive provides specialized block types for NixOS deployment:

**Block Types Defined**:
- `nixosConfigurations` - NixOS system configurations
  - Actions: `switch`, `boot`, `test`, `build`, `dry-build`, `dry-activate`, `edit`, `repl`, `build-vm`, `list-generations`

- `darwinConfigurations` - macOS/Darwin system configurations
  - Actions: Similar to nixosConfigurations but for Darwin

- `homeConfigurations` - home-manager user environments
  - Actions: `switch`, `build`, `activate`, etc.

- `colmenaConfigurations` - Colmena deployment configurations
  - Actions: Colmena-specific deployment commands

- `diskoConfigurations` - Disko disk partition configurations
  - Actions: Disk formatting and partitioning commands

**Structure**:
```nix
{
  nixosConfigurations = {
    name = "nixosConfigurations";
    type = "nixosConfiguration";

    # Export structure
    exports = lib.types.attrsOf (lib.types.submodule {
      # NixOS system definition
    });

    # Available actions (CLI commands)
    actions = {
      switch = { /* ... */ };
      boot = { /* ... */ };
      test = { /* ... */ };
      # ...
    };
  };

  # ... other block types
}
```

---

## Usage Pattern

Block types are used when **defining std cells**:

```nix
# In a hive-based flake
{
  inputs = {
    std.url = "github:divnix/std";
    hive.url = "github:divnix/hive";
    johnny-dd.url = "github:user/johnny-declarative-decimal";
  };

  outputs = { std, hive, johnny-dd, ... }:
    std.growOn {
      inherit inputs;
      cellsFrom = ./cells;
      cellBlocks = [
        # Use hive's block types
        (hive.blockTypes.nixosConfigurations "hosts")
        (hive.blockTypes.homeConfigurations "users")

        # Now you can organize with Johnny Decimal
        # cells/prod/hosts/10.01-web-server.nix
        # cells/staging/hosts/20.01-test-server.nix
      ];
    };
}
```

---

## How Block Types Work

### 1. Define Export Structure
Block type specifies what the block exports:
```nix
nixosConfigurations = {
  exports = lib.types.attrsOf nixosSystem;
};
```

### 2. Define Actions
Block type specifies CLI commands:
```nix
actions = {
  switch = { currentSystem, fragment, target, ... }: ''
    nixos-rebuild switch --flake .#${target}
  '';
};
```

### 3. std Generates CLI
std automatically creates CLI commands:
```bash
# std provides these based on block type actions
std //prod/hosts/10.01-web-server:switch
std //prod/hosts/10.01-web-server:boot
std //prod/hosts/10.01-web-server:build
```

---

## Integration with Johnny Decimal

Block types enable organizing std blocks using Johnny Decimal:

```nix
# cells/infrastructure/
#   hosts/
#     10.01-web-production.nix     → nixosConfiguration
#     10.02-web-staging.nix        → nixosConfiguration
#     11.01-db-primary.nix         → nixosConfiguration
#     11.02-db-replica.nix         → nixosConfiguration
#   users/
#     20.01-admin-config.nix       → homeConfiguration
#     20.02-developer-config.nix   → homeConfiguration
```

Each file exports according to its block type, and std provides the appropriate CLI actions.

---

## Design Principles

1. **Block types define interfaces** - They specify contracts between blocks and std
2. **Actions enable CLI/TUI** - Each action becomes a runnable command
3. **Validation ensures correctness** - Type checking prevents invalid exports
4. **Composability** - Block types can be combined in cell definitions

---

## Related Documentation

- **Parent Layer**: `../CLAUDE.md` (complete types system overview)
- **Module Types**: `../modules/CLAUDE.md` (NixOS module option types)
- **Flake Types**: `../flakes/CLAUDE.md` (flake input + output schemas)
- **std Documentation**: https://std.divnix.com/reference/blocktypes.html
- **hive Block Types**: https://github.com/divnix/hive/tree/main/src/blockTypes
