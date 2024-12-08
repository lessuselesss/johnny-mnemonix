# Integration Guide

This guide covers how to integrate Johnny-Mnemonix with other tools and systems in your development environment.

## Home Manager Integration

### Basic Integration

Add Johnny-Mnemonix to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    johnny-mnemonix.url = "github:lessuselesss/johnny-mnemonix";
  };
}
```

Import the module in your Home Manager configuration:

```nix
{
  imports = [
    johnny-mnemonix.homeManagerModules.default
  ];
}
```

### Multiple User Configurations

For systems with multiple users:

```nix
{
  homeManagerConfigurations = {
    user1 = home-manager.lib.homeManagerConfiguration {
      modules = [
        johnny-mnemonix.homeManagerModules.default
        {
          johnny-mnemonix = {
            enable = true;
            baseDir = "~/Documents";
          };
        }
      ];
    };
    user2 = home-manager.lib.homeManagerConfiguration {
      modules = [
        johnny-mnemonix.homeManagerModules.default
        {
          johnny-mnemonix = {
            enable = true;
            baseDir = "~/workspace";  # Different base directory
          };
        }
      ];
    };
  };
}
```

## Shell Integration

Johnny-Mnemonix provides intuitive shell commands:

```bash
# Navigate to document root
jm

# Jump to specific locations
jm 11.01   # Goes to first item in category 11
jm finance  # Fuzzy finds finance-related directories

# List and search
jmls        # List document root
jmfind tax  # Find tax-related directories
```

### Zsh Integration

Johnny-Mnemonix automatically integrates with Zsh when enabled:

```nix
{
  johnny-mnemonix.shell = {
    enable = true;
    prefix = "jm";  # Default prefix
  };

  programs.zsh.enable = true;  # Required for Zsh integration
}
```

### Bash Integration

Similar configuration for Bash users:

```nix
{
  johnny-mnemonix.shell = {
    enable = true;
    prefix = "jm";
  };

  programs.bash.enable = true;  # Required for Bash integration
}
```

### Custom Shell Functions

You can extend the shell integration with custom functions:

```nix
{
  programs.zsh.initExtra = ''
    # Custom function to create new document
    ${config.johnny-mnemonix.shell.prefix}-new() {
      local id="$1"
      local name="$2"
      if [[ -z "$id" || -z "$name" ]]; then
        echo "Usage: jm-new <id> <name>"
        return 1
      fi
      mkdir -p "$(${config.johnny-mnemonix.shell.prefix}find "$id")/$name"
    }
  '';
}
```

## Git Integration

### Repository Structure

Johnny-Mnemonix works well with Git-managed documents. Recommended structure:

```
Documents/
├── .git/
├── 10-19 Personal/
│   └── .gitignore  # Category-specific ignores
├── 20-29 Work/
│   └── .gitignore
└── .gitignore      # Global ignores
```

### Example .gitignore

```gitignore
# Global ignores
.DS_Store
*.log
*.tmp

# Category-specific patterns
10-19 Personal/11 Finance/**/*.pdf
20-29 Work/21 Projects/**/*.secret
```

## XDG Integration

Johnny-Mnemonix follows XDG Base Directory specifications:

```nix
{
  johnny-mnemonix = {
    enable = true;
    # Configuration stored in $XDG_CONFIG_HOME/johnny-mnemonix
    # Cache stored in $XDG_CACHE_HOME/johnny-mnemonix
    # Data stored in $XDG_DATA_HOME/johnny-mnemonix
  };
}
```

## Development Tools Integration

### Pre-commit Hooks

Johnny-Mnemonix includes pre-commit hooks for maintaining code quality:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: johnny-mnemonix-check
        name: Check Johnny-Mnemonix structure
        entry: nix run .#check
        language: system
        pass_filenames: false
```

### Direnv Integration

For project-specific environment variables:

```nix
# .envrc
use flake
export JOHNNY_MNEMONIX_BASE="$PWD"
```

## Testing Integration

Johnny-Mnemonix includes a test suite that can be integrated into your CI/CD pipeline:

```nix
{
  checks = forAllSystems (system: {
    vm-test = import ./tests {
      pkgs = pkgsForSystem system;
    };
  });
}
```

### Running Tests Locally

```bash
# Run all tests
nix flake check

# Run specific test
nix eval .#checks.x86_64-linux.vm-test
```

## IDE Integration

### VSCode Settings

Recommended settings for VSCode:

```json
{
  "files.associations": {
    "*.jd": "markdown"
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true,
    "**/.[0-9][0-9].*": true
  }
}
```

### Emacs Configuration

For Emacs users:

```elisp
(use-package johnny-mnemonix
  :mode ("\\.jd\\'" . markdown-mode)
  :hook (markdown-mode . johnny-mnemonix-mode))
```

## Future Integrations

We're working on integrations with:
- Typst document processor
- NixOS container support
- Remote filesystem synchronization
- Additional shell environments

For more information on upcoming integrations, see our [roadmap](./roadmap.md).
