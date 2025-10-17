# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Johnny-Mnemonix is a Home Manager module that implements the Johnny Decimal organizational system for document management in a declarative Nix configuration. It creates structured directory hierarchies following the pattern:
- **Areas** (10-19, 20-29, etc.) - Top-level groupings
- **Categories** (11, 12, etc.) - Mid-level organization
- **Items** (11.01, 11.02, etc.) - Individual directories

The module supports Git repository cloning, symlinks, Git+symlink combinations, Typix integration for Typst document compilation, and follows XDG Base Directory specifications.

## Development Commands

### Setup
```bash
# Enter development shell (installs pre-commit hooks automatically)
nix develop
```

### Testing
```bash
# Run all flake checks (includes module evaluation test)
nix flake check

# Run pre-commit checks manually
pre-commit run --all-files
```

### Code Quality
The pre-commit hooks automatically run on commit:
- **alejandra**: Nix code formatting
- **statix**: Static analysis for Nix
- **deadnix**: Dead code detection
- **check-flake**: Validates flake structure

## Architecture

### Module Structure (`modules/johnny-mnemonix.nix`)

The main module is a single-file Home Manager module with these key components:

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
4. Passes `jdAreasFromModules` to johnny-mnemonix via `_module.args`
5. `mergedAreas = lib.recursiveUpdate jdAreasFromModules cfg.areas`

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
