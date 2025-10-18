# Johnny-Mnemonix TODO & Vision

**Last Updated**: 2025-10-17

---

## 🎯 Current Status: Library Implementation (TDD)

### ✅ Completed: 100/100 foundation tests (100%) 🎉

**Primitives Layer (100% - 55/55 tests)** ✅:
- ✅ `number-systems.nix` - Base conversion operations (20 tests)
- ✅ `fields.nix` - Constrained fields with width/padding (15 tests)
- ✅ `constraints.nix` - Validation predicates (10 tests)
- ✅ `templates.nix` - Template parsing and rendering (10 tests)

**Composition Layer (100% - 45/45 tests)** ✅:
- ✅ `identifiers.nix` - Multi-field identifier composition (15 tests)
- ✅ `ranges.nix` - Range operations and containment (10 tests)
- ✅ `hierarchies.nix` - Multi-level hierarchy navigation (12 tests)
- ✅ `validators.nix` - Constraint composition (8 tests)

**Builders Layer (0% - 0/26 tests)** - **NEXT**:
- ⏳ `johnny-decimal.nix` - Pre-built JD system (10 tests)
- ⏳ `versioning.nix` - SemVer builder (8 tests)
- ⏳ `classification.nix` - Custom hierarchy builder (8 tests)

### 🎯 Next Steps (Short Term)

1. **Implement Builders Layer** (3 components, 26 tests) - **IN PROGRESS**
   - High-level constructors for common patterns
   - Johnny Decimal, SemVer, Classification builders

2. **Integration Tests**
   - End-to-end system tests
   - Cross-layer integration verification

3. **Library Complete!**
   - Total: 126+ tests (100 unit + 26 builders + integration/e2e)
   - Ready for Phase 2: Refactor johnny-mnemonix

---

## 🚀 Future Vision: Unified Configuration System

### Overview

Extend johnny-mnemonix from a home-manager directory manager to a **unified configuration framework** that uses Johnny Decimal as the organizational principle across multiple domains.

### Architecture: `configuration-type.nix` Cell

Create a new divnix/std cell that defines different **configuration scopes**, each with:
- Custom base directory
- Type-specific module loading
- Johnny-decimal driven organization
- Integration with existing Nix ecosystems

---

## 📋 Configuration Types/Scopes

### 1. `nixos` - System Configuration

**Purpose**: Organize NixOS system configuration using Johnny Decimal

**Base Directory**: `/` or `/etc/nixos`

**Module Loading**:
- Standard `nixosModules` from system flake
- Maps JD structure to NixOS configuration hierarchy

**Example Structure**:
```
/etc/nixos/
├── 10-19 System/
│   ├── 10 Boot/
│   │   ├── 10.01 Bootloader/
│   │   └── 10.02 Kernel/
│   └── 11 Hardware/
├── 20-29 Services/
│   ├── 20 Network/
│   └── 21 Docker/
└── 30-39 Users/
```

**Integration**:
- Uses library to parse/validate JD structure
- Generates NixOS module imports
- Self-documenting configuration

---

### 2. `nixos-dendrix` - divnix/std System Organization

**Purpose**: Organize NixOS using divnix/std cells with JD naming

**Base Directory**: Project root with `nix/` cell directory

**Module Loading**:
- Uses flake-parts modules in `/modules` directory
- Filenames parsed to create JD structure
- Cell-based organization

**Example**:
```
modules/
├── [10.01]{10-19 System}__(10 Boot)__[01 Bootloader].nix
├── [10.02]{10-19 System}__(10 Boot)__[02 Kernel].nix
└── [20.01]{20-29 Services}__(20 Network)__[01 SSH].nix
```

**Features**:
- Filename parsing → directory creation
- Automatic cell discovery
- Two-pass validation

---

### 3. `nixos-darwin` - macOS System Configuration

**Purpose**: Organize nix-darwin system configuration

**Base Directory**: `/` or `~/.nixpkgs`

**Module Loading**:
- Standard `darwinModules` from system flake
- Similar to nixos but for macOS

**Example**:
```
~/.nixpkgs/
├── 10-19 System/
│   ├── 10 Homebrew/
│   └── 11 LaunchAgents/
└── 20-29 Services/
```

---

### 4. `home-manager` - User Environment Configuration

**Purpose**: Organize home-manager configuration (CURRENT IMPLEMENTATION)

**Base Directory**: `/home/<user>` or `$HOME`

**Module Loading**:
- `homeManagerModules`
- Integrated with existing `johnny-mnemonix.nix` module

**Current Features**:
- Directory creation with JD naming
- Git repository management
- Symlink support
- Index generation (Markdown, Typst, JSON)

**Future Enhancements**:
- Use johnny-declarative-decimal library
- Type-based templates
- Enhanced validation

---

### 5. `hm-dirs` - Declarative Directory Structures

**Purpose**: Define home-manager managed directories using JD organization

**Base Directory**: Configurable per area (e.g., `~/Documents`, `~/Projects`)

**Module Loading**:
- Home-manager modules defining directory hierarchies
- Can reference XDG directories
- Supports per-area base directory override

**Example**:
```nix
hm-dirs = {
  areas = {
    "10-19 Projects" = {
      baseDir = "~/Projects";
      categories = {
        "10 Personal" = { ... };
        "11 Work" = { ... };
      };
    };
    "20-29 Documents" = {
      baseDir = "~/Documents";  # Different base!
      categories = { ... };
    };
  };
};
```

---

### 6. `jd-office` - Office/Workspace Management

**Purpose**: Declarative office workspace with document management

**Base Directory**: `$OFFICE` (configurable, e.g., `/home/<user>/.local/johnny-decimal-office`)

**Features**:
- Declarative folder creation
- Document templates
- Can use standard flake or flake-parts modules
- Filename parsing for automatic structure

**Module Types**:
1. **Standard Flake**: Modules at explicit paths, parsed and created
2. **flake-parts**: Filenames parsed → directory hierarchy + content generation

**Example**:
```nix
jd-office = {
  baseDir = "/home/user/.local/jd-office";  # or $OFFICE
  type = "flake-parts";  # or "standard"

  # Automatically parses modules/[XX.YY]{...}__...nix
  # Creates directory structure
  # Places lowest-level content in created dirs
};
```

**Use Cases**:
- Meeting notes organization
- Project documentation
- Reference materials
- Templates

---

### 7. `typix` - Johnny Decimal Typst Documents

**Purpose**: Generate and organize Typst documents using JD structure

**Base Directory**: `$OFFICE` or configurable

**Features**:
- JD-defined document creation
- Auto-generate `__INDEX__.typ` with hierarchy
- Template system for different document types
- Watch mode for auto-compilation
- Integration with `jd-office`

**Example**:
```nix
typix = {
  baseDir = "$OFFICE/10-19 Documents";

  documents = {
    "10.01 Project-Plan" = {
      template = "project-plan";
      metadata = { ... };
    };
    "10.02 Requirements" = {
      template = "requirements-doc";
    };
  };

  index = {
    enable = true;
    format = "typ";  # Generates __INDEX__.typ
    enhanced = true;  # Include metadata
  };

  watch = {
    enable = true;
    interval = 5;
  };
};
```

**Integration with Existing**:
- Extends current Typix support in johnny-mnemonix
- Uses johnny-declarative-decimal library for structure
- Generates hierarchical index automatically

---

### 8. `permanence` - Configuration Reconciliation for Impermanence

**Purpose**: Reconciliation tool for impermanence configurations

**Base Directory**: All configured base-dirs across all types

**Problem Statement**:
When using impermanence (ephemeral root/home), directories need explicit persistence rules. Manual directory creation creates drift between configuration and reality. This tool bridges that gap.

**Features**:

1. **Diff Engine**:
   - Compare declared JD structure vs actual filesystem
   - Detect new directories/files not in configuration
   - Detect missing directories that should exist per config
   - Detect structural mismatches (wrong names, levels, etc.)
   - Report persistence status (ephemeral vs persisted)

2. **Configuration Reconciliation**:
   - Generate proposed config additions for new items
   - Suggest removals for items no longer present
   - Validate JD naming compliance of discovered items
   - Parse existing directory names to infer JD structure
   - Preserve user intent (non-destructive, proposal-based)

3. **Impermanence Integration**:
   - Understand persistence rules (what's ephemeral, what persists)
   - Help maintain `environment.persistence` declarations
   - Suggest which new items should be persisted
   - Warn about conflicts with impermanence strategy
   - Integrate with existing impermanence modules

4. **Smart Suggestions**:
   - Infer area/category/item from directory names
   - Suggest JD-compliant names for non-compliant dirs
   - Recommend where newly discovered items fit in hierarchy
   - Learn from existing patterns in configuration

**Example Configuration**:
```nix
permanence = {
  enable = true;

  # Which base directories to monitor
  baseDirs = [
    "$HOME/Documents"
    "$HOME/Projects"
    "$OFFICE"
  ];

  reconcile = {
    # Propose configuration updates automatically
    autoSuggest = true;

    # Check JD naming compliance
    validateJD = true;

    # Integrate with impermanence config
    checkPersistence = true;

    # Output format for suggestions
    outputFormat = "nix";  # or "json", "yaml", "interactive"
  };

  # Impermanence integration
  impermanence = {
    enable = true;

    # Path to impermanence config
    persistencePath = "/persist";

    # Auto-suggest persistence rules
    suggestPersistence = true;
  };

  # Actions to take on differences
  actions = {
    # Create missing directories
    createMissing = false;  # Manual by default

    # Remove orphaned config entries
    pruneOrphaned = false;  # Manual by default

    # Update config file
    updateConfig = false;  # Always manual
  };
};
```

**Use Cases**:

1. **Manual Creation Reconciliation**:
   ```bash
   # User creates: ~/Documents/30-39 Finance/30 Taxes/30.01 2024/
   # Command: jd-reconcile
   # Output:
   #   Found new item: ~/Documents/30-39 Finance/30 Taxes/30.01 2024/
   #   Suggested config addition:
   #     areas."30-39 Finance".categories."30 Taxes".items."30.01" = {
   #       name = "2024";
   #       # ... suggested attributes
   #     };
   #   Persistence: NOT PERSISTED (ephemeral)
   #   Suggest adding to: environment.persistence."/persist".directories
   ```

2. **Configuration Drift Detection**:
   ```bash
   # Config declares: 10.05 My-Project
   # Filesystem has: 10.05 Old-Project-Name
   # Command: jd-reconcile --check
   # Output:
   #   MISMATCH: 10.05
   #     Config:     "My-Project"
   #     Filesystem: "Old-Project-Name"
   #   Suggest: Update config to match reality? [y/N]
   ```

3. **JD Compliance Validation**:
   ```bash
   # User creates: ~/Documents/random-folder/
   # Command: jd-reconcile
   # Output:
   #   WARNING: Non-JD compliant directory: random-folder
   #   Suggested JD names based on context:
   #     - 90-99 Archive/90 Unsorted/90.01 Random-Folder
   #     - 80-89 References/80 Misc/80.01 Random-Folder
   #   Apply suggestion? [1/2/custom/skip]
   ```

4. **Impermanence Audit**:
   ```bash
   # Command: jd-reconcile --audit-persistence
   # Output:
   #   JD Structure Persistence Status:
   #
   #   10-19 Projects (✓ persisted)
   #     10.01 Website (✓ persisted)
   #     10.02 CLI-Tool (✗ EPHEMERAL) ← Recommend persisting?
   #
   #   20-29 Documents (✗ EPHEMERAL)
   #     20.01 Notes (✗ EPHEMERAL) ← Recommend persisting?
   ```

**Implementation Details**:

1. **Diff Algorithm**:
   - Walk filesystem recursively within base-dirs
   - Parse directory names using johnny-declarative-decimal library
   - Compare parsed structure against declared configuration
   - Generate diff report (additions, deletions, modifications)

2. **Suggestion Engine**:
   - Use identifiers/hierarchies from composition layer
   - Validate discovered names using validators
   - Infer level (area/category/item) from directory depth
   - Generate Nix code for config additions

3. **Impermanence Integration**:
   - Parse `environment.persistence` or home-manager equivalents
   - Cross-reference JD items with persistence rules
   - Suggest additions to persistence configuration
   - Detect conflicts (declared but not persisted, etc.)

4. **CLI Interface**:
   ```bash
   jd-reconcile                  # Show diff
   jd-reconcile --check          # Validate only (exit code)
   jd-reconcile --suggest        # Generate config suggestions
   jd-reconcile --apply          # Interactive application
   jd-reconcile --audit-persistence  # Persistence status report
   jd-reconcile --fix-names      # Suggest JD-compliant renames
   ```

**Integration with Configuration Types**:

Works across all configuration types:
- `home-manager`: Reconcile ~/Documents, ~/Projects
- `jd-office`: Reconcile $OFFICE workspace
- `hm-dirs`: Reconcile per-area base directories
- `typix`: Reconcile Typst document directories

**Risks & Considerations**:

1. **Safety**: Never modify filesystem/config without explicit confirmation
2. **Conflicts**: Handle cases where filesystem and config both exist but differ
3. **Performance**: Efficiently scan large directory trees
4. **Idempotency**: Running multiple times should produce same suggestions
5. **False Positives**: Some non-JD directories might be intentional (git repos, etc.)

**Timeline**: Phase 6 (After core types implemented)

---

### 9. `fuse` - FUSE Filesystem Integration

**Purpose**: Virtual filesystem layer providing dynamic, multi-faceted views of JD-organized content

**Base Directory**: Varies by use case - can mount at any path

**Status**: **Exploratory** - All options open for investigation

**Overview**:

FUSE (Filesystem in Userspace) integration could provide powerful virtual filesystem capabilities for Johnny Decimal structures. This is a broad exploration area with multiple possible directions, all worth investigating as the project matures.

**Potential Use Cases**:

#### 1. **Virtual Views** - Same Content, Multiple Organizations
Mount points that present the same content organized in different ways:
```
~/JD/                          # Physical JD structure
~/JD-by-date/                  # Virtual: same files organized by date
~/JD-by-type/                  # Virtual: same files organized by file type
~/JD-by-project/               # Virtual: same files organized by project tags
~/JD-by-tag/work/              # Virtual: all work-tagged files
```

Each mount point shows the same underlying files but through different organizational lenses.

#### 2. **Auto-categorization** - Smart File Organization
Filesystem that automatically suggests or applies JD category placement:
```
~/JD-smart/                    # FUSE mount
# User creates file: ~/JD-smart/my-document.pdf
# System analyzes content/metadata
# Suggests: "Move to 20-29 Documents/20 Reports/20.03 Quarterly?"
# Or auto-places based on learned patterns
```

Features:
- Content analysis (text extraction, metadata)
- Machine learning categorization
- Rule-based placement (file type, name patterns, metadata)
- Interactive prompts for ambiguous cases
- Learn from user corrections

#### 3. **Union/Overlay** - Unified View of Distributed Content
Merge multiple storage locations into single JD hierarchy:
```
~/JD-unified/                  # FUSE mount combining:
  ├── local:       ~/Documents/10-19 Projects/
  ├── git repos:   Various cloned repositories
  ├── remote SSH:  user@server:/data/projects/
  ├── cloud S3:    s3://my-bucket/work/
  └── archives:    /mnt/backup/old-projects/

# All appear as unified JD structure
# Transparent access regardless of actual location
# Write operations route to appropriate backend
```

Sources:
- Local filesystem paths
- Git repositories (multiple remotes)
- SSH/SFTP remote mounts
- Cloud storage (S3, GCS, Azure, WebDAV)
- Archive files (tar, zip, etc.)

#### 4. **Enhanced Navigation** - JD-Aware Filesystem Semantics
Filesystem that understands JD structure and provides smart navigation:

**Special Virtual Directories**:
```
~/JD/.search/keyword/          # Full-text search results
~/JD/.recent/                  # Recently modified files
~/JD/.uncommitted/             # Git files with uncommitted changes
~/JD/.tags/work/               # All items tagged "work"
~/JD/.type/pdf/                # All PDF files
~/JD/.breadcrumb/10/11/11.05/  # Breadcrumb navigation
```

**Smart Navigation Features**:
- Path completion understands JD hierarchy
- Breadcrumb-style navigation
- Symlinks to related items
- Automatic index generation at each level
- README.md auto-generated with hierarchy info

#### 5. **Caching & Performance Layer**
FUSE layer that caches remote/slow sources:
- Cache remote files locally
- Prefetch frequently accessed items
- Lazy loading of large hierarchies
- Background sync of changes
- Conflict resolution for multi-source edits

**Customizable Access Modes**:

The FUSE filesystem should support configurable access semantics:

1. **Read-only View** (Safest):
   - Virtual views are read-only
   - No modifications propagate to underlying storage
   - Good for exploration, search, alternate views

2. **Read-write with Propagation**:
   - Changes in FUSE mount propagate to underlying storage
   - Maintains JD structure constraints
   - Validates writes against hierarchy rules
   - Atomic operations with rollback

3. **Hybrid Mode**:
   - JD hierarchy structure is read-only
   - Files within valid categories can be created/modified
   - Prevents structure corruption while allowing content changes

**Example Configuration** (Aspirational):

```nix
fuse = {
  enable = true;

  mounts = {
    # Virtual date-based view (read-only)
    by-date = {
      mountPoint = "$HOME/JD-by-date";
      source = "$HOME/Documents";  # Physical JD structure
      view = "date";  # Reorganize by file modification date
      readOnly = true;
    };

    # Unified multi-source view (read-write)
    unified = {
      mountPoint = "$HOME/JD-all";
      sources = [
        { type = "local"; path = "$HOME/Documents"; }
        { type = "git"; repos = [ "~/Projects/repo1" "~/Projects/repo2" ]; }
        { type = "ssh"; host = "server"; path = "/data/work"; }
        { type = "s3"; bucket = "my-work-bucket"; prefix = "jd/"; }
      ];
      readOnly = false;
      conflictResolution = "prompt";  # or "local-wins", "remote-wins"
    };

    # Smart categorization assistant (hybrid)
    smart = {
      mountPoint = "$HOME/JD-smart";
      source = "$HOME/Documents";
      features = {
        autoCategorization = {
          enable = true;
          method = "ml";  # or "rules", "interactive"
          confidence = 0.8;  # Auto-place if confidence > 80%
        };
        contentAnalysis = true;
        metadataExtraction = true;
      };
      readOnly = false;
      structureReadOnly = true;  # Can't modify hierarchy
    };

    # Search and filter views
    search = {
      mountPoint = "$HOME/JD-search";
      source = "$HOME/Documents";
      features = {
        fullTextSearch = true;
        tagFiltering = true;
        typeFiltering = true;
        dateFiltering = true;
        gitStatusFiltering = true;
      };
      readOnly = true;
      indexing = {
        enable = true;
        interval = 300;  # Reindex every 5 minutes
        fullTextEngine = "ripgrep";  # or "tantivy", "meilisearch"
      };
    };
  };

  # Global FUSE options
  options = {
    # FUSE library (implementation choice)
    library = "fuser";  # Rust: fuser, or "bazil-fuse" (Go), "fusepy" (Python)

    # Performance
    caching = {
      enable = true;
      size = "1GB";
      ttl = 3600;  # Cache entries valid for 1 hour
    };

    # Logging
    logging = {
      level = "info";  # or "debug", "warn", "error"
      path = "$HOME/.local/state/johnny-mnemonix/fuse.log";
    };

    # Safety
    safeMode = true;  # Extra validation, no destructive ops
    backups = true;   # Backup before write operations
  };
};
```

**Implementation Considerations**:

**Technology Stack** (To be decided):
- **Rust** (fuser crate): Performance, safety, modern
- **Go** (bazil/fuse): Good concurrency, simpler than Rust
- **Python** (fusepy): Rapid prototyping, easier to modify
- **Nix-native**: Pure Nix implementation (challenging but interesting)

**Architecture Questions** (To be resolved):

1. **Integration Approach**:
   - New configuration type in `nix/configuration-types/fuse.nix`?
   - Separate divnix/std cell (`nix/fuse/`)?
   - Extension to existing home-manager module?
   - Standalone tool/service with Nix packaging?

2. **Systemd Integration**:
   - User service for automatic mounting?
   - Socket activation?
   - Dependency management (mount after base dirs created)?

3. **Performance Strategy**:
   - How to handle large hierarchies (1000s of items)?
   - Caching strategy (local, in-memory, persistent)?
   - Indexing approach (real-time, periodic, on-demand)?
   - Invalidation triggers?

4. **Conflict Resolution**:
   - Multiple sources with same JD id?
   - Concurrent modifications?
   - Offline/online sync?
   - User vs. auto-categorization conflicts?

5. **Security & Safety**:
   - Permission handling across sources?
   - Prevent accidental data loss?
   - Validation before propagating writes?
   - Rollback/undo mechanisms?

**Design Experiments to Run**:

1. **Proof of Concept**: Simple read-only FUSE mount of existing JD structure
2. **Date View Prototype**: Reorganize by modification date
3. **Search Integration**: Dynamic directories for search results
4. **Git Integration**: Virtual dirs showing git status (.uncommitted/, .branches/)
5. **Union FS Test**: Combine local + one git repo
6. **Auto-categorization**: Rule-based file placement based on extension/name

**Related Technologies to Investigate**:

- **OverlayFS/UnionFS**: Linux kernel union filesystem capabilities
- **mergerfs**: User-space union filesystem (could be wrapped/extended)
- **rclone mount**: Already handles remote sources, could be integrated
- **git-fuse**: Existing FUSE filesystems for git repositories
- **TagFS**: Tag-based filesystem organization (similar concept)
- **Full-text engines**: ripgrep, tantivy, meilisearch for search features

**Potential Risks & Challenges**:

1. **Complexity**: FUSE development is non-trivial, especially for write operations
2. **Performance**: Virtual filesystems can be slow without good caching
3. **Stability**: Bugs in FUSE can cause hangs, crashes, data loss
4. **Portability**: FUSE behavior varies across Linux, macOS, Windows
5. **Maintenance**: Requires ongoing support for kernel/FUSE API changes
6. **User Expectations**: Virtual filesystems can be confusing if not intuitive

**Success Criteria** (When to pursue this):

- Core library fully stable (Phase 1 complete)
- Multiple configuration types working well (Phase 4 complete)
- Real user demand for virtual views / multi-source integration
- Team member with FUSE expertise or willingness to learn
- Clear, focused use case to start with (not trying to do everything)

**Recommended Approach**:

1. **Start small**: Read-only, single-source, simple view (by-date or by-type)
2. **Validate usefulness**: Does it solve real problems for users?
3. **Iterate**: Add features based on actual usage patterns
4. **Consider alternatives**: Could some features be shell scripts / utilities instead?
5. **Community input**: Gather feedback before heavy investment

**Timeline**: Phase 7+ (Exploratory - after core ecosystem mature, if demand exists)

**Dependencies**:
- Phases 1-4 complete (library + core types working)
- Real-world usage data to validate use cases
- FUSE expertise acquired or available
- Clear primary use case identified

---

## 🏗️ Implementation Architecture

### Layer 4: Configuration Types (New)

```
nix/configuration-types/
├── CLAUDE.md                    # Specification
├── types.nix                    # Type definitions
├── nixos.nix                    # NixOS type handler
├── nixos-dendrix.nix           # divnix/std NixOS handler
├── nixos-darwin.nix            # nix-darwin handler
├── home-manager.nix            # HM handler (wraps existing)
├── hm-dirs.nix                 # Directory structures handler
├── jd-office.nix               # Office workspace handler
├── typix.nix                   # Typst documents handler
└── permanence.nix              # Config reconciliation & impermanence
```

### Type Definition Structure

```nix
{
  # Type identifier
  name = "jd-office";

  # Base directory (can use variables)
  baseDir = "$OFFICE" or "/home/<user>/Office" or null;

  # How modules are discovered
  moduleDiscovery = "flake-parts" or "standard" or "explicit";

  # Module location patterns
  modulePaths = ["./modules/[*]{*}__*__[*].nix"] or ["./config/*.nix"];

  # Module loading strategy
  moduleLoader = "flake-parts" or "nixosModules" or "homeManagerModules";

  # Directory creation strategy
  directoryCreation = "from-filenames" or "from-config" or "none";

  # Validation rules
  validation = {
    parseFilenames = true;
    validateSelfConsistency = true;
    requireTwoPassLoading = true;
  };

  # Integration hooks
  hooks = {
    preParse = ...;
    postParse = ...;
    preCreate = ...;
    postCreate = ...;
  };

  # Type-specific features
  features = {
    gitRepos = true;
    symlinks = true;
    indexGeneration = true;
    typixIntegration = true;
  };
}
```

### Unified Configuration Entry Point

```nix
# flake.nix or home-manager configuration
{
  johnny-declarative-decimal = {
    enable = true;

    # Multiple configuration types can coexist
    configurations = {
      office = {
        type = "jd-office";
        baseDir = "$OFFICE";
        # ... type-specific config
      };

      home = {
        type = "home-manager";
        baseDir = "$HOME";
        # ... type-specific config
      };

      typst-docs = {
        type = "typix";
        baseDir = "$OFFICE/10-19 Documents";
        # ... type-specific config
      };
    };
  };
}
```

---

## 🎯 Implementation Roadmap

### Phase 1: Complete Library (Current - 80% Done)
- ✅ Primitives layer (100%)
- 🚧 Composition layer (56% → target 100%)
- ⏳ Builders layer (0% → target 100%)
- ⏳ Integration tests

**Timeline**: Continue TDD rampage until library is complete

---

### Phase 2: Refactor Existing johnny-mnemonix
- Replace hand-coded parsing with library
- Use builders for JD system definition
- Maintain backward compatibility
- Improve validation using composition layer

**Timeline**: After library completion

---

### Phase 3: Configuration Type Abstraction
- Design type system architecture
- Implement base `configuration-type` abstraction
- Create type registry/discovery
- Define hooks and extension points

**Timeline**: After johnny-mnemonix refactor

---

### Phase 4: Implement Core Types
- `home-manager` (refactor existing)
- `jd-office` (new workspace management)
- `typix` (extend existing Typst integration)

**Timeline**: Iterative - one type at a time

---

### Phase 5: System-Level Types (Stretch)
- `nixos` (system configuration)
- `nixos-dendrix` (divnix/std integration)
- `nixos-darwin` (macOS support)
- `hm-dirs` (enhanced directory management)

**Timeline**: Community-driven / as needed

---

### Phase 6: Advanced Features
- `permanence` (configuration reconciliation & impermanence)
- Smart indexing and cross-references
- Multi-user / team support features

**Timeline**: After core ecosystem stable

---

### Phase 7: FUSE Integration (Exploratory)
- `fuse` (virtual filesystem layer)
- Prototype: Read-only virtual views
- Experiment: Multi-source union filesystem
- Explore: Auto-categorization and smart navigation
- Evaluate: User demand and feasibility

**Timeline**: Post-maturity - if real demand exists and use cases validated

**Prerequisites**:
- Core library stable (Phase 1 ✓)
- Multiple config types proven (Phase 4)
- FUSE expertise available
- Clear primary use case identified

---

## 📝 Design Questions to Resolve

### 1. Base Directory Variables

**Question**: How do we handle variable substitution in base directories?

**Options**:
- Shell-style: `$OFFICE`, `$HOME`, `${XDG_CONFIG_HOME}`
- Nix evaluation: `config.home.homeDirectory + "/Office"`
- Hybrid: Allow both with precedence rules

**Decision**: TBD

---

### 2. Configuration Discovery

**Question**: How do types discover their configuration?

**Options**:
- Explicit: User provides paths in flake
- Convention: Scan `./modules`, `./config`, etc.
- Hybrid: Convention + override

**Decision**: TBD

---

### 3. Filename Parsing Spec

**Question**: Should all types support filename parsing, or just specific ones?

**Current**: Only `nixos-dendrix` and `jd-office` (flake-parts mode)

**Options**:
- Universal: All types can parse filenames
- Opt-in: Types declare support
- Type-specific: Each type has own parsing rules

**Decision**: TBD

---

### 4. Validation Strategy

**Question**: How strict should validation be? When does it run?

**Options**:
- Strict: Fail on any inconsistency
- Permissive: Warn but continue
- Configurable: Per-type validation level

**Timing**:
- Build-time: Flake evaluation
- Activation-time: Home-manager activation
- Both: Two-pass validation

**Decision**: TBD

---

### 5. Integration with Existing Ecosystem

**Question**: How do we integrate with existing Nix tools?

**Considerations**:
- flake-parts: Already using, expand usage?
- home-manager: Core integration point
- divnix/std: Cell organization paradigm
- nixos modules: System configuration
- Community standards: Follow or innovate?

**Decision**: TBD - balance innovation with compatibility

---

## 💡 Open Ideas

### N Notation for Documentation

**Status**: Partially implemented (versioning.nix uses it)

**Goal**: Use mathematical N notation throughout documentation instead of fixed position names.

**Current** (position-specific):
- XX.YY (implies exactly 2 positions)
- XX.YY.ZZ (implies exactly 3 positions)

**Proposed** (extensible):
- N₁.N₂ (2 components)
- N₁.N₂.N₃ (3 components)
- N₁.N₂.N₃...Nₖ (k components, arbitrary depth)

**Benefits**:
- Emphasizes extensibility (not limited to 2 or 3 levels)
- More mathematical/formal notation
- Clearer that each position is "the nth component"
- Language-agnostic (not tied to English "X, Y, Z")

**Implementation**:
- ✅ versioning.nix already uses N notation
- ⏳ Update johnny-decimal.nix comments
- ⏳ Update classification.nix comments
- ⏳ Update all CLAUDE.md specification files
- ⏳ Update root CLAUDE.md
- ⏳ Update TODO.md examples

**Timeline**: After builders layer complete

---

### Directory Templating
- Define templates for different project types
- Auto-populate new areas with standard structure
- Language/framework specific templates

### Smart Indexing
- Cross-reference between areas
- Backlink support
- Tag system
- Full-text search integration

### Workflow Integration
- Git hooks for structure validation
- Pre-commit hooks for JD formatting
- CI/CD checks for consistency

### Metadata System
- Attach metadata to any JD item
- Queryable index
- Export to different formats (JSON, YAML, Typst)

### Multi-User / Team Support
- Shared base structure
- Per-user customization
- Conflict resolution
- Access control

### Vector Embedding Identifiers
**Status**: Exploratory idea

**Goal**: Support arrays and objects as identifier octets, enabling vector embeddings as navigational primitives.

**Motivation**:
Current system uses scalar values (numbers) for each position in an identifier (e.g., `10.05`). Extending this to support structured data would enable powerful new use cases:

1. **Vector Embeddings as Identifiers**:
   ```nix
   # Current: 10.05 (two scalar octets)
   # Proposed: [0.123, 0.456, 0.789].[0.321, 0.654, 0.987] (vector octets)
   ```

2. **Semantic Organization**:
   - Items organized by embedding similarity
   - Navigate by conceptual proximity, not just numeric hierarchy
   - AI-assisted categorization using semantic vectors

3. **Object-Valued Octets**:
   ```nix
   # Object as identifier component
   { topic = "nix"; sentiment = 0.8; importance = 0.9 }
   ```

**Potential Applications**:
- **Document similarity**: Files with similar embeddings cluster together
- **Project organization**: Group by semantic meaning, not manual categories
- **Knowledge graphs**: Identifiers become nodes with vector properties
- **Search/discovery**: "Find items similar to this one" via vector distance

**Technical Challenges**:
1. **Parsing/Formatting**: How to represent vectors in strings?
   - JSON serialization: `[0.1,0.2].[0.3,0.4]`
   - Base64 encoding: `b64:abc123.b64:def456`
   - Custom syntax: `vec(0.1,0.2,0.3)`

2. **Ordering**: Vectors don't have natural total order
   - Use magnitude/norm for ordering?
   - Lexicographic on components?
   - Clustering-based organization?

3. **Validation**: What makes a valid vector octet?
   - Fixed dimensionality per level?
   - Value ranges (normalized vectors)?
   - Type constraints (all floats, specific precision)?

4. **Storage**: How to persist vector identifiers?
   - Filesystem limitations (filename length, special chars)
   - Database integration for richer queries?
   - Index structures for fast similarity search?

**Library Extensions Needed**:
- `nix/lib/primitives/vector-systems.nix` - Vector operations and validation
- `nix/lib/primitives/object-systems.nix` - Structured octet support
- `nix/lib/composition/similarity.nix` - Distance metrics and clustering
- `nix/lib/builders/semantic-decimal.nix` - Semantic JD builder

**Use Case Example**:
```nix
semantic = mkSemanticDecimal {
  levels = 2;
  levelConfigs = [
    {
      type = "vector";
      dimensions = 768;  # OpenAI embedding size
      metric = "cosine";  # Similarity metric
    }
    {
      type = "scalar";
      base = 10;
      chars = 2;
    }
  ];
};

# Parse document embedding as identifier
doc1 = semantic.parse "[0.123,0.456,...,0.789].01";
doc2 = semantic.parse "[0.121,0.458,...,0.791].02";

# Find similar documents
similar = semantic.findSimilar doc1 threshold: 0.95;
# => [doc2, ...] (cosine similarity > 0.95)
```

**Timeline**: Post-Phase 4 (after core types mature, if use cases emerge)

**Dependencies**:
- Library foundation complete
- Real-world use case validation
- Performance considerations (vector operations can be expensive)
- Integration with embedding models (sentence-transformers, OpenAI, etc.)

---

### Name Abstraction Layer
**Status**: Architectural consideration

**Goal**: Abstract the "name" component from identifier structure, treating it as a separate semantic layer.

**Current Architecture**:
```nix
# Identifier components are tightly coupled with names
{
  id = "10.05";
  name = "My-Project";  # Name is separate but not abstracted
}
```

**Proposed Architecture**:
```nix
# Names as a separate resolution layer
identifier = {
  numeral = "10.05";           # Pure numeric identifier
  label = "My-Project";         # Human-readable label
  path = "10.05-My-Project";    # Rendered combination
};

# Name resolution is decoupled from identifier structure
nameResolver = {
  resolve = id: lookupName id;  # id -> label
  format = id: label: formatPath id label;  # Render combination
  parse = path: { id; label; };  # Extract both from path
};
```

**Benefits**:

1. **Flexibility**: Change name rendering without touching identifier logic
   ```nix
   # Different name formats for different contexts
   formats = {
     filesystem = id: name: "${id}-${name}";      # "10.05-My-Project"
     display = id: name: "${id} ${name}";         # "10.05 My Project"
     url = id: name: "${id}/${slugify name}";     # "10.05/my-project"
   };
   ```

2. **Internationalization**: Names in multiple languages, same identifier
   ```nix
   names = {
     "10.05" = {
       en = "My-Project";
       es = "Mi-Proyecto";
       ja = "私のプロジェクト";
     };
   };
   ```

3. **Name Evolution**: Rename without changing identifier
   ```nix
   # Identifier stable, name can change
   "10.05" = {
     name = "New-Project-Name";
     aliases = ["Old-Project-Name" "Legacy-Name"];
     history = [
       { name = "Original-Name"; from = "2024-01-01"; to = "2024-06-01"; }
       { name = "Revised-Name"; from = "2024-06-01"; to = "2025-01-01"; }
     ];
   };
   ```

4. **Rich Metadata**: Names become first-class entities
   ```nix
   nameMetadata = {
     "10.05" = {
       canonical = "My-Project";
       display = "My Amazing Project";
       short = "MyProj";
       description = "Long description...";
       tags = ["active" "important"];
       created = "2024-01-01";
     };
   };
   ```

**Implementation Layers**:

1. **Layer 1 (Primitives)**: Name systems
   ```nix
   # nix/lib/primitives/name-systems.nix
   {
     mk = { format, validation, transforms } -> NameSystem;
     validate = NameSystem -> String -> Bool;
     transform = NameSystem -> String -> String;  # Case, slug, etc.
   }
   ```

2. **Layer 2 (Composition)**: Name resolution
   ```nix
   # nix/lib/composition/name-resolution.nix
   {
     mkResolver = { mapping, fallback } -> Resolver;
     resolve = Resolver -> Identifier -> Name;
     format = Resolver -> Identifier -> Name -> Path;
   }
   ```

3. **Layer 3 (Builders)**: Integrated builders
   ```nix
   mkJohnnyDecimal {
     # Identifier config
     levels = 2;
     base = 10;

     # Name layer config (NEW)
     names = {
       format = "kebab-case";        # Name transformation
       separator = "-";              # Between id and name
       resolver = customResolver;    # Custom name lookup
       locales = ["en" "es"];       # i18n support
     };
   };
   ```

**Use Cases**:

1. **Multi-language Documentation**:
   ```
   docs/en/10.05-Getting-Started/
   docs/es/10.05-Comenzando/
   docs/ja/10.05-はじめに/
   ```

2. **Context-Specific Rendering**:
   ```nix
   # Filesystem: hyphenated
   ~/Documents/10.05-My-Project/

   # Display: spaced
   Index: "10.05 My Project"

   # URL: slugified
   https://example.com/docs/10.05/my-project
   ```

3. **Historical Tracking**:
   ```nix
   # Git history shows renames
   git log --follow 10.05-*/
   # Finds all names that identifier had over time
   ```

**Migration Path**:
1. Keep current name handling (backward compatible)
2. Add optional name resolution layer
3. Gradually adopt in new code
4. Provide migration utilities for existing setups

**Timeline**: Phase 3-4 (during configuration type abstraction)

**Dependencies**:
- Primitives layer stable
- Clear use cases for name abstraction identified
- i18n requirements defined (if needed)

---

### Cryptographic Transformers (sodiumoxide)
**Status**: Exploratory idea

**Goal**: Add bidirectional cryptographic transformation layer using sodiumoxide (Rust/libsodium) that operates between config definitions and physical outputs.

**Architecture Insight**: Transformers sit between two layers:
```
Config Definition (Nix) ←→ Transformer ←→ Physical Output (Filesystem)
```

**Bidirectional Transformations**:

1. **Forward Transform** (Config → Encrypted Output):
   ```nix
   # Config is plaintext (safe to version control)
   config = {
     areas."30-39 Finance" = {
       transform = "encrypt";
       publicKeys = [ "alice" "bob" ];  # Recipients
     };
   };

   # Filesystem output is encrypted
   ~/Documents/30-39 Finance/  # ← Encrypted at rest
   ```

2. **Reverse Transform** (Encrypted Config → Plaintext Output):
   ```nix
   # Config is encrypted (like sops-nix)
   config = sops.decrypt {
     file = ./secrets/finance.nix.enc;
     key = "my-key";
   };

   # Filesystem output is plaintext (usable)
   ~/Documents/30-39 Finance/  # ← Decrypted, accessible
   ```

3. **Hybrid** (Encrypted Both Ways):
   ```nix
   # Config encrypted in repo
   # Output encrypted on disk
   # Decryption happens only in memory during access
   ```

**Motivation**:
Cryptographic primitives enable powerful new organizational patterns:
- **Content-addressed identifiers** (hash → ID)
- **Verifiable hierarchies** (signed structures)
- **Privacy-preserving organization** (encrypted IDs)
- **Decentralized identity** (public key as root)
- **Bidirectional encryption** (config OR output encrypted)

**Library**: [sodiumoxide](https://github.com/sodiumoxide/sodiumoxide)
- Rust bindings to libsodium
- Modern cryptographic primitives
- Safe, audited implementations
- BLAKE2b, Ed25519, X25519, ChaCha20-Poly1305

**Proposed Architecture**:

```
nix/lib/transformers/
├── CLAUDE.md                    # Transformers layer spec
├── crypto.nix                   # Nix wrapper exports
├── rust/                        # Rust implementation
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs              # FFI interface
│   │   ├── hash.rs             # Hashing functions
│   │   ├── sign.rs             # Digital signatures
│   │   ├── encrypt.rs          # Encryption/decryption
│   │   └── derive.rs           # Key derivation
│   └── default.nix             # Build expression
└── tests/
    └── crypto.test.nix         # Cryptographic tests
```

**Cryptographic Primitives**:

1. **Hashing** (Content-Addressed Identifiers):
   ```nix
   # BLAKE2b hash of content → identifier
   transformers.hash.blake2b content
   # => "a1b2c3d4e5f6..."

   # Use hash as JD identifier (truncated/encoded)
   hashToJD = hash: parseBase58 (take 4 hash);
   # => {category = 42; item = 13;} (derived from hash)
   ```

2. **Digital Signatures** (Verifiable Hierarchies):
   ```nix
   # Sign a JD structure with Ed25519
   signed = transformers.sign.ed25519 {
     structure = myJDHierarchy;
     secretKey = mySecretKey;
   };

   # Verify signature
   transformers.verify.ed25519 {
     structure = receivedStructure;
     signature = receivedSignature;
     publicKey = trustedPublicKey;
   };
   # => true/false
   ```

3. **Encryption** (Privacy-Preserving IDs):
   ```nix
   # Encrypt identifier with ChaCha20-Poly1305
   encrypted = transformers.encrypt.chacha20 {
     plaintext = "10.05-Sensitive-Project";
     key = secretKey;
     nonce = nonce;
   };

   # Store encrypted, decrypt on access
   decrypted = transformers.decrypt.chacha20 {
     ciphertext = encrypted;
     key = secretKey;
     nonce = nonce;
   };
   ```

4. **Key Derivation** (Hierarchical Keys):
   ```nix
   # Derive per-area keys from master key
   areaKey = transformers.derive.hkdf {
     masterKey = rootKey;
     info = "area-10-19";
     length = 32;
   };

   # Derive per-item keys
   itemKey = transformers.derive.hkdf {
     masterKey = areaKey;
     info = "item-10.05";
     length = 32;
   };
   ```

**Use Cases**:

1. **Private Filesystem, Public Config** (Forward Transform):
   ```nix
   # Configuration in git (public)
   johnny-mnemonix.areas."30-39 Finance" = {
     name = "Finance";
     transform.encrypt = {
       enable = true;
       recipients = [
         "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"  # Alice
         "age1lggyhqrw2nlhcxprm67z43rphfr8pk0p30fpjjwv8lqdvfdq3uksk59fgy"  # Bob
       ];
       method = "age";  # or "gpg", "chacha20"
     };
     categories.30 = {
       name = "Taxes";
       items."30.01".name = "2024";
     };
   };

   # Output: Encrypted filesystem
   ~/Documents/
     └── 30-39 Finance.enc/           # ← Encrypted directory name
         ├── .jd-encryption-metadata  # Recipients, nonces, etc.
         ├── 30.enc/                   # ← Encrypted category
         │   └── 30.01.enc/           # ← Encrypted item
         │       └── tax-return.pdf.enc  # ← Encrypted files
         └── __INDEX__.typ.enc

   # Access: Decrypt on-the-fly with age key
   jd-decrypt ~/Documents/30-39\ Finance.enc/30/30.01/
   # → Temporarily decrypts to tmpfs for viewing
   ```

2. **Public Filesystem, Private Config** (Reverse Transform):
   ```nix
   # Configuration encrypted with sops-nix (in git)
   sops.secrets."finance-config" = {
     sopsFile = ./secrets/finance.yaml;
     format = "yaml";
   };

   johnny-mnemonix.areas = builtins.fromJSON (
     builtins.readFile config.sops.secrets."finance-config".path
   );

   # Output: Regular plaintext filesystem
   ~/Documents/
     └── 30-39 Finance/      # ← Plaintext, usable
         ├── 30 Taxes/
         │   └── 30.01 2024/
         │       └── tax-return.pdf  # ← Regular files
         └── __INDEX__.typ

   # Config stays encrypted in git
   # Files are decrypted during home-manager activation
   ```

3. **Hybrid: Both Encrypted** (Double Transform):
   ```nix
   # Config encrypted with sops
   sops.secrets."encrypted-finance" = { /* ... */ };

   # AND outputs encrypted with age
   johnny-mnemonix.areas = {
     transform.mode = "hybrid";
     transform.config = {
       source = "sops";
       key = "encrypted-finance";
     };
     transform.output = {
       method = "age";
       recipients = [ /* ... */ ];
     };
   };

   # Result: Config encrypted in git, outputs encrypted on disk
   # Only decrypted in memory during authorized access
   ```

4. **Content-Addressed with Encryption**:
   ```nix
   # Content-addressed IDs with encrypted storage
   areas."40-49 Archive" = {
     transform = {
       contentAddressed = true;
       hashFunction = "blake2b";
       encrypt = true;
       recipients = [ "myself" ];
     };
   };

   # Files get IDs from content hash
   # Stored encrypted on disk
   ~/Archive/
     └── 40-49 Archive.enc/
         ├── a1b2c3.enc  # ← Hash-based ID, encrypted content
         ├── d4e5f6.enc
         └── .hash-index.enc  # Encrypted mapping: hash → metadata
   ```

5. **Signed + Encrypted Collaborative Config**:
   ```nix
   # Each team member signs their section
   # Then encrypt for the team
   areas."10-19 Projects" = {
     "10 Website" = {
       author = "alice";
       signature = signWith aliceKey;
       transform.encrypt.recipients = [ "team-key" ];
     };
     "11 Backend" = {
       author = "bob";
       signature = signWith bobKey;
       transform.encrypt.recipients = [ "team-key" ];
     };
   };

   # Verification: Check signature, then decrypt
   # Output: Verified + encrypted directories
   ```

6. **Public Key Directory Sharing**:
   ```nix
   # Share specific directories with specific people
   areas."20-29 Shared" = {
     "20 Alice-Bob" = {
       transform.encrypt.recipients = [
         alicePublicKey
         bobPublicKey
       ];
     };
     "21 Public-Docs" = {
       transform.sign = true;  # Signed but not encrypted
       transform.signature.key = myPrivateKey;
     };
   };

   # Alice and Bob can decrypt "20"
   # Anyone can verify "21" signature
   ```

**Integration with Existing Layers**:

```nix
# Layer 1: Primitives + Transformers (crypto primitives)
transformers.hash.blake2b "content"  # => hash bytes
transformers.sign.ed25519 data key   # => signature
transformers.encrypt.age data recipients  # => ciphertext

# Layer 2: Composition with transforms
composition.transformedHierarchy = {
  hierarchy = mkHierarchy { /* ... */ };

  # Bidirectional transform specification
  transform = {
    direction = "forward";  # or "reverse" or "hybrid"

    forward = {
      # Config → Encrypted Output
      encrypt = true;
      recipients = [ "age-public-key" ];
    };

    reverse = {
      # Encrypted Config → Plaintext Output
      decrypt = true;
      source = "sops";
      key = "config-key";
    };
  };
};

# Layer 3: Builders with transforms
mkTransformedJohnnyDecimal = {
  # Base JD config
  levels = 2;
  base = 10;
  chars = 2;

  # Transform layer (NEW)
  transform = {
    # Which direction?
    mode = "forward" | "reverse" | "hybrid" | "none";

    # Forward: Config → Encrypted FS
    forward = {
      encrypt = {
        method = "age";  # or "gpg", "chacha20", "xchacha20"
        recipients = [
          "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
        ];
        # Per-level encryption (optional)
        perLevel = {
          area = false;      # Areas: plaintext names
          category = true;   # Categories: encrypted
          item = true;       # Items: encrypted
        };
      };

      sign = {
        enable = true;
        algorithm = "ed25519";
        publicKey = "...";
      };
    };

    # Reverse: Encrypted Config → Plaintext FS
    reverse = {
      decryptConfig = {
        method = "sops";
        file = ./secrets/areas.yaml;
      };
    };

    # Hybrid: Both encrypted
    hybrid = {
      configSource = "sops";
      outputEncryption = "age";
    };
  };
};

# Layer 4: Home-manager integration
johnny-mnemonix = {
  enable = true;
  baseDir = "$HOME/Documents";

  # Transform at module level
  transform = {
    mode = "forward";
    encrypt = {
      enable = true;
      recipients = [ /* ... */ ];
    };
  };

  areas = {
    "30-39 Finance" = {
      # Override: extra encryption for this area
      transform.encrypt.recipients = [ "trusted-accountant" ];
    };
  };
};
```

**Nix Integration**:

1. **Build Rust Library**:
   ```nix
   # nix/lib/transformers/rust/default.nix
   { rustPlatform, libsodium }:
   rustPlatform.buildRustPackage {
     pname = "jd-transformers";
     version = "0.1.0";
     src = ./.;
     cargoLock.lockFile = ./Cargo.lock;
     buildInputs = [ libsodium ];

     # Build FFI library
     cargoBuildFlags = [ "--lib" ];
   }
   ```

2. **Nix Wrapper**:
   ```nix
   # nix/lib/transformers/crypto.nix
   { pkgs, lib }:
   let
     rustLib = pkgs.callPackage ./rust {};

     # FFI bindings via Nix
     callRust = fn: args:
       builtins.readFile (pkgs.runCommand "crypto-${fn}" {} ''
         ${rustLib}/bin/jd-crypto ${fn} ${args} > $out
       '');
   in {
     hash = {
       blake2b = data: callRust "blake2b" data;
       sha256 = data: callRust "sha256" data;
     };

     sign = {
       ed25519 = data: key: callRust "sign-ed25519" "${data} ${key}";
     };

     # ... etc
   }
   ```

3. **Pure Nix Fallbacks** (Optional):
   ```nix
   # For hashing, could use pure Nix implementations
   hash.blake2b = data:
     if hasSodiumoxide
     then rustHash data
     else pureNixBlake2b data;  # Slower but pure
   ```

**Security Considerations**:

1. **Key Management**:
   - Never store private keys in Nix store (world-readable!)
   - Use pass, age, sops-nix for secrets
   - Derive keys from user passwords at runtime
   - Consider hardware security modules (HSM) integration

2. **Nonce Management**:
   - Encryption requires unique nonces
   - Never reuse nonces with same key
   - Store nonces alongside ciphertext
   - Use counter mode or random generation

3. **Side Channels**:
   - Timing attacks on comparisons
   - sodiumoxide provides constant-time operations
   - Be careful with pure Nix implementations

4. **Auditing**:
   - Log all cryptographic operations
   - Record signatures and verification results
   - Track key usage

**Performance Considerations**:

1. **Nix Store Overhead**:
   - FFI calls expensive (process spawning)
   - Cache results when possible
   - Batch operations

2. **Build Time**:
   - Rust compilation adds to build time
   - Consider binary caching
   - Optional dependency (users can disable)

3. **Runtime**:
   - Hashing large files slow in pure Nix
   - Delegate to Rust for performance
   - Use lazy evaluation wisely

**Testing Strategy**:

```nix
# nix/lib/transformers/tests/crypto.test.nix
{
  # Test hashing
  testHashBlake2bDeterministic = {
    expr = let
      hash1 = transformers.hash.blake2b "test";
      hash2 = transformers.hash.blake2b "test";
    in hash1 == hash2;
    expected = true;
  };

  # Test signing round-trip
  testSignVerifyRoundTrip = {
    expr = let
      keypair = transformers.genKeypair "ed25519";
      data = "important message";
      signature = transformers.sign.ed25519 data keypair.secret;
      valid = transformers.verify.ed25519 data signature keypair.public;
    in valid;
    expected = true;
  };

  # Test encryption round-trip
  testEncryptDecryptRoundTrip = {
    expr = let
      key = transformers.genKey "chacha20" 32;
      nonce = transformers.genNonce "chacha20";
      plaintext = "secret data";
      ciphertext = transformers.encrypt.chacha20 plaintext key nonce;
      decrypted = transformers.decrypt.chacha20 ciphertext key nonce;
    in decrypted == plaintext;
    expected = true;
  };

  # Test key derivation consistency
  testKeyDerivationConsistent = {
    expr = let
      master = transformers.genKey "master" 32;
      derived1 = transformers.derive.hkdf master "area-10" 32;
      derived2 = transformers.derive.hkdf master "area-10" 32;
    in derived1 == derived2;
    expected = true;
  };
}
```

**Documentation Needs**:

1. **Security Guide**:
   - Best practices for key management
   - Threat model and mitigation strategies
   - Common pitfalls and how to avoid them

2. **Examples**:
   - Content-addressed filing system setup
   - Signed configuration deployment
   - Encrypted personal data workflow

3. **API Reference**:
   - All cryptographic functions documented
   - Input/output formats specified
   - Security properties explained

**Timeline**: Phase 5+ (after core library stable, if use cases validated)

**Dependencies**:
- Primitives layer complete and stable
- Rust toolchain in Nix build
- libsodium available in nixpkgs
- Clear security use cases identified
- Security expertise for review

**Risks**:
- Complexity: Cryptography is hard to get right
- Security: Bugs can have serious consequences
- Maintenance: Need to track libsodium updates
- Adoption: May be overkill for most users

**Success Criteria**:
- Real user need for cryptographic features
- Security review by expert
- Comprehensive test coverage
- Clear documentation with warnings
- Optional (doesn't burden non-crypto users)

---

## 🤝 Contributing

This is a **vision document**. As we implement:
- Update status sections
- Resolve design questions
- Document decisions
- Add implementation notes

**Current Priority**: Complete the library TDD implementation (Phase 1)

---

## 📚 References

- [Johnny Decimal System](https://johnnydecimal.com/)
- [divnix/std](https://github.com/divnix/std)
- [flake-parts](https://flake.parts/)
- [kiro.dev TDD methodology](https://kiro.dev)
- Project CLAUDE.md files for detailed specs

---

**Remember**: We're building the math first (library), then the applications (types). This document captures where we're going while staying focused on where we are. 🎯
