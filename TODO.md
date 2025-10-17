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
