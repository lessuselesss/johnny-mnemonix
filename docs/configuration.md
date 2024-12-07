# Configuration Guide

## Flake Integration

First, add Johnny-Mnemonix to your flake inputs:

```nix
{
  inputs = {
    johnny-mnemonix = {
      url = "github:lessuselesss/johnny-mnemonix";
      inputs.nixpkgs.follows = "nixpkgs";  # Optional but recommended
    };
  };
}
```

## Home Manager Integration

For Darwin/MacOS systems, add it to your darwin configuration:

```nix
{
  home-manager.users.${user} = { config, ... }: {
    imports = [johnny-mnemonix.homeManagerModules.default];
    
    johnny-mnemonix = {
      enable = true;
      baseDir = "${config.home.homeDirectory}/Documents";
      shell = {
        enable = true;
        prefix = "jm";
        aliases = true;
        functions = true;
      };
      areas = {
        "10-19" = {
          name = "Personal";
          categories = {
            "11" = {
              name = "Finance";
              items = {
                "11.01" = "Budget";
                "11.02" = "Investments";
              };
            };
          };
        };
      };
    };
  };
}
```

For NixOS systems, add it to your NixOS configuration:

```nix
{
  home-manager.users.${user} = { config, ... }: {
    imports = [johnny-mnemonix.homeManagerModules.default];
    # Same configuration as above
  };
}
```

## Configuration Options

### Required Options

| Option | Type | Description |
|--------|------|-------------|
| `enable` | boolean | Must be set to `true` to activate the module |
| `baseDir` | string | Base directory for document structure (e.g., `${config.home.homeDirectory}/Documents`) |

### Shell Integration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `shell.enable` | boolean | `false` | Enable shell integration |
| `shell.prefix` | string | `"jm"` | Command prefix for shell functions |
| `shell.aliases` | boolean | `false` | Enable shell aliases |
| `shell.functions` | boolean | `false` | Enable shell functions |

### Area Configuration

Areas must follow the Johnny Decimal format:

```nix
areas = {
  "10-19" = {
    name = "Personal";
    categories = {
      "11" = {
        name = "Finance";
        items = {
          "11.01" = "Budget";
          "11.02" = "Investments";
        };
      };
    };
  };
};
```

### Git Repository Examples

```nix
items = {
  # Basic repository - clones everything
  "11.01" = {
    url = "https://github.com/user/repo";
  };

  # Repository with specific branch
  "11.02" = {
    url = "https://github.com/user/repo";
    ref = "develop";  # Checkout this branch after cloning
  };

  # Repository with sparse checkout (partial clone)
  "11.03" = {
    url = "https://github.com/user/large-repo";
    ref = "main";
    # Only these paths will be checked out, saving disk space
    # and reducing initial clone time
    sparse = [
      # Directory patterns
      "docs/*.md"              # Only markdown files directly in docs/
      "docs/**/*.md"           # Markdown files in docs/ and all subdirectories
      "src/components/"        # Everything in the components directory
      
      # File patterns
      "README.md"              # Single file in root
      "package.json"           # Another single file
      
      # Multiple file types
      "assets/*.{png,jpg}"     # PNG and JPG files in assets/
      
      # Complex patterns
      "src/*/index.js"         # index.js in any immediate subdirectory of src/
      "tests/**/*_test.js"     # All test files in tests/ and subdirectories
      
      # Negative patterns (exclude)
      "!node_modules/**"       # Exclude all node_modules content
      "!**/*.log"             # Exclude all log files everywhere
    ];
  };

  # Private repository using SSH
  "11.04" = {
    url = "git@github.com:user/private-repo.git";
    ref = "main";
  };
};
```

#### Understanding Sparse Checkout Patterns

The `sparse` option uses Git's sparse-checkout pattern syntax:

| Pattern | Example | Description |
|---------|---------|-------------|
| `*` | `docs/*` | Matches any string except `/` |
| `**` | `docs/**` | Matches any string including `/` |
| `{x,y}` | `*.{jpg,png}` | Matches any of the alternatives |
| `!pattern` | `!node_modules` | Excludes matching paths |

Common use cases:
```nix
sparse = [
  # Documentation only
  "docs/**"                # All documentation files
  "*.md"                   # All markdown files in root
  
  # Source code subset
  "src/specific-module/**" # Just one module
  "src/**/*.ts"           # All TypeScript files
  
  # Configuration files
  "config/*.json"         # JSON configs in config/
  ".*rc"                 # All RC files in root
  
  # Mixed content
  "assets/images/*.svg"   # SVG files only
  "scripts/deploy/*"      # Deployment scripts only
  
  # Exclude patterns
  "!**/*.test.js"        # No test files
  "!**/dist/**"          # No build artifacts
];
```

**Important Notes:**
- Patterns are evaluated in order
- Later patterns can override earlier ones
- More specific patterns should come after general ones
- Exclude patterns (`!`) should typically come last
- Empty list means full checkout (no sparse-checkout)
```

## State Management

Johnny-Mnemonix follows the XDG Base Directory Specification:

```nix
{
  johnny-mnemonix = {
    enable = true;
    baseDir = "${config.home.homeDirectory}/Documents";
    # State files are automatically managed in XDG directories:
    # - State: $XDG_STATE_HOME/johnny-mnemonix/state.json (default: ~/.local/state/johnny-mnemonix/)
    # - Cache: $XDG_CACHE_HOME/johnny-mnemonix/ (default: ~/.cache/johnny-mnemonix/)
    # - Config: $XDG_CONFIG_HOME/johnny-mnemonix/ (default: ~/.config/johnny-mnemonix/)
  };
}
```

### State Files Location

| File | XDG Path | Default Location | Purpose |
|------|----------|-----------------|----------|
| `state.json` | `$XDG_STATE_HOME/johnny-mnemonix/` | `~/.local/state/johnny-mnemonix/state.json` | Directory content hashes and metadata |
| `structure-changes.log` | `$XDG_STATE_HOME/johnny-mnemonix/` | `~/.local/state/johnny-mnemonix/structure-changes.log` | Directory structure change history |
| `cache.json` | `$XDG_CACHE_HOME/johnny-mnemonix/` | `~/.cache/johnny-mnemonix/cache.json` | Shell completion cache |
| `config.json` | `$XDG_CONFIG_HOME/johnny-mnemonix/` | `~/.config/johnny-mnemonix/config.json` | Runtime configuration |

### Custom Locations

You can override default locations:

```nix
{
  johnny-mnemonix = {
    enable = true;
    baseDir = "${config.home.homeDirectory}/Documents";
    xdg = {
      # Optional: override default XDG paths
      stateHome = "/path/to/state";
      cacheHome = "/path/to/cache";
      configHome = "/path/to/config";
    };
  };
}
```

## Verification

After applying changes, verify your setup:

1. Check directory structure:
```bash
ls ~/Documents/10-19\ Personal/11\ Finance/
```

2. Verify state files:
```bash
# Check state
cat ~/.local/state/johnny-mnemonix/state.json

# Check change history
cat ~/.local/state/johnny-mnemonix/structure-changes.log

# Check cache
cat ~/.cache/johnny-mnemonix/cache.json
```