# Johnny Declarative Decimal - Root Specification

**Version**: 1.0.0-alpha
**Status**: In Development
**Last Updated**: 2025-10-17

> This file follows the kiro.dev specification format with comprehensive TDD methodology.
> See subdirectory CLAUDE.md files for detailed implementation specs of each component.

---

## Phase 1: Requirements

### System Overview

Johnny Declarative Decimal is a configurable Nix system for managing directory hierarchies using generalized decimal organizational methods. It provides a layered library architecture that supports everything from classic Johnny Decimal (2 octets, base 10, span of 10) to arbitrary numbering systems (mixed radix, custom alphabets, variable depth).

**Evolution from Johnny-Mnemonix**: This project extends the original home-manager module with a full library layer, making the organizational system reusable beyond just directory management.

### Core User Stories

#### US-1: Configurable Syntax
**As a** user
**I want to** customize all visual syntax elements (encapsulators, separators)
**So that** my file/directory names match my preferences

**Acceptance Criteria**:
- Can customize ID encapsulators (e.g., `[]` → `<>`)
- Can customize area encapsulators (e.g., `{}` → `[]`)
- Can customize category encapsulators (e.g., `()` → `{}`)
- Can customize all separators (numeral-name, hierarchy levels, octets, ranges)
- Changes apply to all parsing and formatting consistently

#### US-2: Flexible Number Systems
**As a** power user
**I want to** use different number bases and widths
**So that** I can optimize my ID space for my use case

**Acceptance Criteria**:
- Support base 2, 8, 10, 16 out of the box
- Support custom bases with custom alphabets
- Support mixed radix (different bases per octet)
- Support variable width fields
- Support fixed and variable digit counts

#### US-3: Self-Validating Configuration
**As a** system designer
**I want** configuration modules to validate themselves
**So that** the system demonstrates dogfooding and correctness

**Acceptance Criteria**:
- Config modules use Johnny Decimal naming
- Config modules define the syntax they're named with
- Two-pass loading: bootstrap → validate → export
- Clear errors when config doesn't self-validate

#### US-4: Layered Architecture
**As a** developer
**I want to** choose my level of abstraction
**So that** simple cases are simple and complex cases are possible

**Acceptance Criteria**:
- Layer 1 (Primitives): Low-level building blocks
- Layer 2 (Composition): Combine primitives
- Layer 3 (Builders): High-level constructors
- Layer 4 (Frameworks): Complete solutions
- Escape hatches between all layers

#### US-5: Home Manager Integration
**As a** NixOS/home-manager user
**I want to** declaratively manage my directory structure
**So that** my workspace is reproducible

**Acceptance Criteria**:
- Home-manager module exports
- Generates directory structures in ~/
- Creates index files (tree, markdown, Typst, JSON)
- Supports git-backed items and symlinks
- XDG Base Directory compliance

### System Dependencies

**Required**:
- Nix (flakes enabled, v2.18+)
- nixpkgs (for lib utilities)
- flake-parts (for modular flake composition)
- divnix/std (for cell organization)

**Optional**:
- home-manager 23.11+ (for home integration)
- typix (for Typst rendering)

### Constraints

1. **Performance**: Two-pass loading must complete in <5 seconds for 100 modules
2. **Compatibility**: Nix 2.18+, home-manager 23.11+
3. **Breaking Changes**: Pre-1.0, breaking changes allowed for better design
4. **Target**: Extract library to separate package by v1.0

---

## Phase 2: Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Configuration                        │
│  nix/config/01.01-01.07 Config Modules                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Two-Pass Loading (flake.nix)                   │
│                                                              │
│  Pass 1: Bootstrap with defaults → Load config              │
│  Pass 2: Re-parse with actualSyntax → Validate              │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   Layered Library                            │
│                                                              │
│  Layer 4: Frameworks (johnny-decimal-classic, semver, ...)  │
│           ▲                                                  │
│  Layer 3: Builders (mkJohnnyDecimal, mkVersioning, ...)     │
│           ▲                                                  │
│  Layer 2: Composition (identifiers, ranges, hierarchies)    │
│           ▲                                                  │
│  Layer 1: Primitives (number-systems, fields, constraints)  │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│            Home Manager Integration                          │
│  modules/johnny-mnemonix.nix                                │
│  → Directory creation                                        │
│  → Index generation                                          │
│  → File management                                           │
└─────────────────────────────────────────────────────────────┘
```

### Two-Pass Loading Sequence

```
┌──────────────────┐
│  Start           │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Pass 1: Bootstrap                                │
│                                                  │
│ 1. Load defaultSyntax from flake.nix            │
│ 2. Parse all modules with defaultSyntax         │
│ 3. Filter config modules (01.01-01.07)          │
│ 4. Evaluate config modules                      │
│ 5. Extract actualSyntax from 01.04              │
│ 6. Extract other configs (base, octets, etc.)   │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Pass 2: Validate                                 │
│                                                  │
│ 1. Re-parse all modules with actualSyntax       │
│ 2. Validate config modules against own syntax   │
│ 3. Assert consistency or fail with error        │
│ 4. Build jdModuleSources index                  │
│ 5. Build jdDefinitionsFromModules hierarchy     │
│ 6. Export validated data                        │
└────────┬─────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│ Export to HM     │
└──────────────────┘
```

### Data Flow

```
Config File (01.04 Syntax.nix)
    │
    │ defines
    ▼
{ idNumEncapsulator = {open = "["; close = "]"}; ... }
    │
    │ used by
    ▼
Parser (Pass 2)
    │
    │ parses
    ▼
"[01.04]{01-09 Meta}__(01 Configuration)__[04 Syntax].nix"
    │
    │ validates
    ▼
✓ Self-consistent!
```

### Module Organization (divnix/std)

```
nix/
├── lib/              # Cell: Library code
│   ├── primitives.nix        # Block: Layer 1 exports
│   ├── composition.nix       # Block: Layer 2 exports
│   └── builders.nix          # Block: Layer 3 exports
├── frameworks/       # Cell: Pre-built solutions
│   └── configs.nix           # Block: Framework definitions
├── config/           # Cell: System configuration
│   └── modules.nix           # Block: 01.01-01.07 exports
├── tests/            # Cell: Test suites
│   ├── unit.nix              # Block: Unit tests
│   └── integration.nix       # Block: Integration tests
└── examples/         # Cell: Example systems
    └── configs.nix           # Block: Example configurations
```

### API Surface (Public Exports)

```nix
# From flake
johnny-declarative-decimal = {
  # Library layers
  lib = {
    primitives = {
      numberSystems = { mk, parse, format, validate, ... };
      fields = { mk, parse, format, validate, range, ... };
      constraints = { range, enum, pattern, custom, ... };
      templates = { parse, render, validate, ... };
    };

    composition = {
      identifiers = { mk, parse, format, validate, ... };
      ranges = { mk, containing, contains, ... };
      hierarchies = { mk, path, validate, leaves, ... };
      validators = { mk, combine, required, unique, ... };
    };

    builders = {
      mkJohnnyDecimal = { levels, base, digits, area_span } -> System;
      mkVersioning = { octets, separator, prerelease } -> System;
      mkClassification = { depth, digits_per_level, base } -> System;
    };
  };

  # Frameworks
  frameworks = {
    johnny-decimal-classic = { homeManagerModule, flakeModule };
    johnny-decimal-hex = { homeManagerModule, flakeModule };
    semver = { homeManagerModule, flakeModule };
  };

  # Home Manager
  homeManagerModules = {
    default = /* johnny-mnemonix module */;
    johnny-mnemonix = /* johnny-mnemonix module */;
  };

  # Flake Parts
  flakeModules = {
    default = /* config integration */;
  };
};
```

---

## Phase 3: Implementation

### TDD Strategy

All implementation follows strict RED → GREEN → REFACTOR cycles:

1. **🔴 RED**: Write failing test first, verify it fails correctly
2. **🟢 GREEN**: Minimal implementation to pass the test
3. **🔵 REFACTOR**: Improve without breaking tests

### Test Hierarchy

```
nix/tests/
├── primitives/
│   ├── number-systems.test.nix     # 20+ test cases
│   ├── fields.test.nix             # 15+ test cases
│   ├── constraints.test.nix        # 10+ test cases
│   └── templates.test.nix          # 10+ test cases
├── composition/
│   ├── identifiers.test.nix        # 15+ test cases
│   ├── ranges.test.nix             # 10+ test cases
│   ├── hierarchies.test.nix        # 12+ test cases
│   └── validators.test.nix         # 8+ test cases
├── builders/
│   ├── johnny-decimal.test.nix     # 10+ test cases
│   └── versioning.test.nix         # 8+ test cases
├── integration/
│   ├── two-pass-loading.test.nix   # 5+ test cases
│   └── self-validation.test.nix    # 5+ test cases
└── e2e/
    └── home-manager.test.nix       # 3+ test cases
```

### Implementation Phases

#### Week 1: Foundation
**Goal**: divnix/std setup + two-pass loading

**TDD Examples (RED first)**:
```nix
# 🔴 Test: Default syntax loads correctly
testDefaultSyntax = {
  expr = defaultSyntax.idNumEncapsulator.open;
  expected = "[";
};

# 🔴 Test: Pass 1 parses with defaults
testPass1Parse = {
  expr = (pass1Parse "[01.04]{...}__...").parsed;
  expected = true;
};

# 🔴 Test: Pass 2 validates self-consistency
testPass2Validation = {
  expr = (pass2Validate configModules).valid;
  expected = true;
};
```

#### Week 2-5: See detailed CLAUDE.md files
- `nix/lib/primitives/CLAUDE.md` - 55+ tests
- `nix/lib/composition/CLAUDE.md` - 45+ tests
- `nix/lib/builders/CLAUDE.md` - 20+ tests
- `nix/frameworks/CLAUDE.md` - Framework integration
- `modules/CLAUDE.md` - Home-manager integration

---

## Legacy System Documentation

> The following sections document the existing johnny-mnemonix implementation.
> These will be refactored to use the new library layers.

1. **Type System**: Nested submodules define the structure
   - `itemOptionsType`: Individual directories (supports Git URLs, symlinks, sparse checkout)
   - `categoryOptionsType`: Category groupings containing items
   - `areaOptionsType`: Top-level area groupings containing categories

2. **Path Generation**:
   - `sanitizeName`: Removes special characters and truncates names to 50 chars
   - `mkSafePath`: Builds directory paths with configurable spacer between ID and name
   - Paths follow pattern: `{baseDir}/{areaId}{spacer}{areaName}/{categoryId}{spacer}{categoryName}/{itemId}{spacer}{itemName}`

3. **Directory Creation (`mkAreaDirs`)**:
   - Generates bash script executed during Home Manager activation
   - Uses `home.activation.createJohnnyMnemonixDirs` DAG entry (runs after "writeBoundary")
   - Handles four item types:
     - **Git + Symlink**: Clone repo to `target` location, symlink from Johnny Decimal path to `target`
     - **Git repositories**: Clone with `git clone`, update with `git fetch/pull`, supports sparse checkout
     - **Symlinks**: Create with `ln -sfn`, backs up existing non-symlink conflicts
     - **Regular directories**: Simple `mkdir -p`
   - Backs up conflicting directories with timestamp suffix before git clone/symlink

4. **XDG Compliance**:
   - State: `${XDG_STATE_HOME}/johnny-mnemonix/` (structure tracking, changes log)
   - Cache: `${XDG_CACHE_HOME}/johnny-mnemonix/`
   - Config: `${XDG_CONFIG_HOME}/johnny-mnemonix/`
   - All paths configurable via `xdg.*` options

### Test Structure (`tests/`)

- `tests/default.nix`: Helper function `mkHomeConfig` creates minimal Home Manager configurations for testing
- `tests/home-manager/`: Integration tests for different scenarios:
  - `structure-changes.nix`: Tests structure modification handling
  - `state-tracking.nix`: Tests XDG state management
  - `spacer-config.nix`: Tests configurable spacer
  - `example-config.nix`: Reference configuration
  - `git-symlink.nix`: Tests git+symlink combination feature
  - `typix-config.nix`: Tests Typix integration (basic and watch modes)
- `tests/cache.nix`: Cache-specific tests

Tests use Home Manager's `homeManagerConfiguration` to validate module evaluation and activation.

### Flake Architecture (`flake.nix`)

**Structure**: Uses `flake-parts` for modular flake composition

**Inputs**:
- `flake-parts`: Modular flake composition framework
- `nixpkgs`: NixOS packages
- `home-manager`: Home Manager for declarative user environment
- `typix`: Typst document compilation with Nix (passed to module via `_module.args`)

**Exports** (via flake-parts):
- `flake.homeManagerModules.default` and `flake.homeManagerModules.johnny-mnemonix`: The main module
- `flake.homeManagerModule`: Backwards compatibility alias
- `perSystem.checks.moduleEval`: Evaluates module with minimal config to ensure it loads
- `perSystem.devShells.default`: Development environment with formatting/linting tools

**Key flake-parts Benefits**:
- Separation of flake-wide outputs (`flake` attribute) from per-system outputs (`perSystem`)
- No manual `forAllSystems` boilerplate needed
- Standard patterns for adding new outputs/modules
- Better code organization and modularity

**System Support**: x86_64-linux, aarch64-linux, aarch64-darwin, x86_64-darwin

**Structure**:
```nix
flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [...];

  # Flake-wide outputs (not system-specific)
  flake = {
    homeManagerModules = { ... };
    homeManagerModule = ...;
  };

  # Per-system outputs
  perSystem = { pkgs, system, ... }: {
    checks = { ... };
    devShells = { ... };
  };
}
```

## Key Implementation Details

### Git Repository Handling
- Uses `GIT_SSH_COMMAND="ssh -o 'AddKeysToAgent yes'"` for SSH key handling
- Supports branch/ref specification via `ref` option (defaults to "main")
- Sparse checkout configured via `.git/info/sparse-checkout` when `sparse` patterns provided
- Existing repos are updated (fetch/pull) rather than re-cloned

### Symlink Handling
- Conflicts with existing non-symlink directories are backed up with timestamp
- Uses `ln -sfn` to ensure atomic symlink creation/updates
- Parent directories created as needed with `mkdir -p`

### Home Manager Backup Integration
Johnny-mnemonix integrates with Home Manager's backup system to handle file conflicts:

**Configuration Options**:
- `backup.enable`:
  - `null` (default): Follow `home-manager.backupFileExtension` setting
  - `true`: Enable backups with johnny-mnemonix-specific extension
  - `false`: Fail on conflicts (no backups)
- `backup.extension`: Backup file extension (default: "jm-backup")

**Behavior**:
- When `backup.enable == null` and `home-manager.backupFileExtension` is set, johnny-mnemonix uses that extension
- Backup files are named: `<original>.<extension>-YYYYMMDD-HHMMSS`
- Only applies to johnny-mnemonix operations (git clones, symlinks) within `baseDir`

Example:
```nix
# Follow HM settings (default)
johnny-mnemonix.backup.enable = null;

# Override with johnny-mnemonix-specific settings
johnny-mnemonix.backup = {
  enable = true;
  extension = "jm-backup";
};
```

### Git + Symlink Combination
When both `url` and `target` are set on an item:
1. Git repo is cloned to the `target` location (not the Johnny Decimal path)
2. A symlink is created from the Johnny Decimal path pointing to `target`
3. Git operations (fetch/pull) happen at the `target` location
4. This allows storing repos in a centralized location while maintaining Johnny Decimal organization

Example configuration:
```nix
"11.01" = {
  name = "My Project";
  url = "git@github.com:user/project.git";
  target = "/mnt/storage/repos/project";  # Actual git repo location
  ref = "main";
};
# Results in: Documents/10-19 Area/11 Category/11.01 My Project -> /mnt/storage/repos/project
```

### Typix Integration
The module integrates with Typix for deterministic Typst document compilation:

**Configuration Options**:
- `typix.enable`: Enable Typix integration (default: false)
- `typix.autoCompileOnActivation`: Auto-compile .typ files on `home-manager switch` (default: true when enabled)
- `typix.watch.enable`: Enable systemd service for file watching (default: false)
- `typix.watch.interval`: Watch debounce interval in seconds (default: 5)

**Implementation Details**:
- **Auto-detection**: Finds all `.typ` files recursively in `baseDir`
- **Compilation**: Uses `typst compile` from nixpkgs, outputs PDFs alongside source files
- **Logging**: All compilation activity logged to `${XDG_STATE_HOME}/johnny-mnemonix/typix.log`
- **Manual compilation**: `jm-compile-typst` command available when Typix enabled
- **Watch service**: `johnny-mnemonix-typst-watch.service` monitors for .typ file changes using inotify
- **Activation**: `compileTypstDocuments` DAG entry runs after `createJohnnyMnemonixDirs`

**Watch Service Behavior**:
- Uses `inotifywait` to monitor for modify/create/move events on .typ files
- Debounces compilation by waiting `interval` seconds after detecting changes
- Runs as systemd user service, auto-restarts on failure
- Service logs to same typix.log file as manual/auto compilation

### Workspace Index Generation
The module automatically generates a `__INDEX__` file providing a tree-like view of the workspace structure:

**Configuration Options**:
- `index.enable`: Enable index generation (default: true)
- `index.format`: Output format - "md", "typ", "pdf", or "txt" (default: "md")
- `index.enhanced`: Include metadata (git URLs, symlink targets) (default: true)
- `index.watch.enable`: Enable systemd watch service (default: false)
- `index.watch.interval`: Debounce interval in seconds (default: 2)

**Implementation Details** (johnny-mnemonix.nix:290-498):
1. **Content Generation**:
   - `generateIndexContent`: Traverses `mergedAreas` structure recursively
   - Generates format-specific headers and tree symbols
   - `mkItemMetadata`: Adds git URL and symlink target info when `enhanced = true`
   - Format-specific formatting:
     - Markdown: Uses `**bold**` for categories, `_italic_` for metadata
     - Typst: Uses `#text()` macros with monospace font, gray metadata
     - TXT: Plain text with parenthetical metadata
     - PDF: Compiles from Typst source

2. **File Generation**:
   - Source file: `${XDG_STATE_HOME}/johnny-mnemonix/__INDEX__.<format>`
   - Symlink: `${baseDir}/__INDEX__.<format>` → source file
   - For PDF: generates `.typ` source, compiles to `.pdf`, symlinks PDF
   - Logging: `${XDG_STATE_HOME}/johnny-mnemonix/index.log`

3. **Activation Integration**:
   - `generateWorkspaceIndex` DAG entry runs after `createJohnnyMnemonixDirs`
   - Ensures index reflects newly created directory structure
   - Manual regeneration: `jm-regenerate-index` command

4. **Watch Service** (`johnny-mnemonix-index-watch.service`):
   - Monitors `baseDir` for directory structure changes (create, delete, move)
   - Excludes `__INDEX__` files and `.git` directories from watch
   - Debounces regeneration by waiting `interval` seconds after changes
   - Runs as systemd user service, auto-restarts on failure
   - Logs all regeneration activity to index.log

**Tree Format Example** (enhanced markdown):
```
### 10-19 Projects

│  ├── 10 Code
│  │  ├── 10.01 Web-App _git: git@github.com:user/webapp.git_
│  │  └── 10.02 CLI-Tool
│  └── 11 Scripts
│     ├── 11.01 Deploy _symlink to: /mnt/storage/deploy_
│     └── 11.02 Backup _git: https://github.com/user/backup.git, symlink to: /mnt/storage/backup_
```

### Flake-parts Module System

The project supports two types of flake-parts modules in `modules/`:

#### 1. Johnny Decimal Filename Format (Declarative Structure)

**Filename Pattern**:
```
[cat.item]{area-range area-name}__(cat cat-name)__[item item-name].nix
```

**Examples**:
```
[10.19]{10-19 Projects}__(10 Code)__[19 Web-App].nix
[21.05]{20-29 Personal}__(21 Finance)__[05 Budget].nix
```

**Components**:
- `[10.19]` - Full Johnny Decimal ID (category.item)
- `{10-19 Projects}` - Area range and name
- `__(10 Code)__` - Category number and name
- `[19 Web-App]` - Item number and name

**Validation** (flake.nix:23-80):
1. Category from `[10.19]` must match `(10 ...)`
2. Item from `[10.19]` must match `[19 ...]`
3. Category 10 must fall within area range 10-19

**Behavior**:
- Filename parsed via regex to extract components
- Automatically generates `johnny-mnemonix.areas` configuration
- Creates: `~/Deterministic Workspace/10-19 Projects/10 Code/19 Web-App/`
- Merges with user's manual configuration (user config takes precedence)

**Implementation**:
1. `parseJDFilename`: Regex `\[(\d+)\.(\d+)\]\{([^}]+)\}__\((\d+) ([^)]+)\)__\[(\d+) ([^\]]+)\]`
2. Extracts and validates all components
3. Groups parsed modules by area-range → category → item
4. Passes `jdDefinitionsFromModules` to johnny-mnemonix via `_module.args`
5. `mergedAreas = lib.recursiveUpdate jdDefinitionsFromModules cfg.areas`

**Example**:
```nix
# modules/[10.19]{10-19 Projects}__(10 Code)__[19 My-Project].nix
{ ... }: {
  # Creates: ~/Deterministic Workspace/10-19 Projects/10 Code/19 My-Project/

  perSystem = { pkgs, ... }: {
    packages.project-tool = pkgs.writeShellScriptBin "build" ''
      echo "Building..."
    '';
  };
}
```

#### 2. Simple Path Format (Override System)

**Filename Pattern**:
```
simple-name.nix → ~/simple-name
```

**Conflict Resolution**:
When a johnny-mnemonix configuration item would create a directory at a path managed by a simple module:
1. **Build-time**: Warning emitted via `config.warnings`
2. **Activation-time**: Johnny-mnemonix skips all operations for that path
3. **Result**: The module has full control of the path

**Implementation**:
- `flake.nix` extracts managed path names from filenames
- Passes `managedPathNames` to johnny-mnemonix via `_module.args`
- Johnny-mnemonix checks conflicts with `pathConflicts` helper
- Conflicting paths skipped in activation script

**Example** (`modules/special-project.nix`):
```nix
{ ... }: {
  # Declares ownership of ~/special-project
  perSystem = { pkgs, ... }: {
    packages.special-tool = pkgs.writeShellScriptBin "tool" ''
      echo "Custom tool"
    '';
  };
}
```

**Auto-Discovery**:
- All `.nix` files in `modules/` (except `johnny-mnemonix.nix`, `example-project.nix`, `README.md`)
- Automatically imported as flake-parts modules
- JD-formatted files parsed for structure generation
- Simple files create path ownership declarations

### Activation Script PATH
The activation script explicitly sets PATH to include:
```nix
PATH="${lib.makeBinPath [pkgs.git pkgs.openssh pkgs.coreutils pkgs.gnused pkgs.findutils]}:$PATH"
```
This ensures git/ssh/coreutils are available during Home Manager activation.

## Commit Message Format

Follow conventional commits format:
```
type(scope): description

[optional body]
```

Types: feat, fix, docs, style, refactor, test, chore

## Important Notes

- This is a **flakes-only** project - no support for legacy Nix
- Module creates directories non-destructively (won't overwrite existing structures)
- All directory names must follow Johnny Decimal format validation
- The project uses Alejandra as the single Nix formatter (not nixpkgs-fmt)
