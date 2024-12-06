# Configuration Guide

This guide explains how to configure Johnny-Mnemonix for your document management needs.

## Basic Configuration

The minimal configuration requires:
1. Adding Johnny-Mnemonix to your flake inputs
2. Enabling the module in your Home Manager configuration
3. Configuring basic options

```nix
{
  johnny-mnemonix = {
    enable = true;
    baseDir = "~/Documents";
    shell = {
      enable = true;
      prefix = "jm";  # Optional: customize command prefix
      aliases = true;
      functions = true;
    };
  };
}
```

## Configuration Options

### Top-Level Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `false` | Enable Johnny Mnemonix |
| `baseDir` | string | `"$HOME/Documents"` | Base directory for document structure |

### Shell Integration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `shell.enable` | boolean | `false` | Enable shell integration |
| `shell.prefix` | string | `"jm"` | Command prefix for shell functions |
| `shell.aliases` | boolean | `false` | Enable shell aliases |
| `shell.functions` | boolean | `false` | Enable shell functions |

## Shell Commands

When shell integration is enabled, the following commands become available (assuming default prefix `jm`):

### Navigation Commands
| Command | Description |
|---------|-------------|
| `jm` | Navigate to document root |
| `jm <pattern>` | Navigate to directory matching pattern |
| `jm-up` | Navigate up one directory |

### Listing Commands
| Command | Description |
|---------|-------------|
| `jmls` | List contents of document root |
| `jml` | List contents in long format |
| `jmll` | List all contents in long format |
| `jmla` | List all contents including hidden files |

### Search Commands
| Command | Description |
|---------|-------------|
| `jmfind <pattern>` | Find directories matching pattern |

## Shell Completion

Johnny-Mnemonix provides command completion for both Bash and Zsh:

- Directory completion for navigation commands
- Command completion for all shell functions
- Pattern completion for search commands

## Example Configuration

Here's a complete example showing how to integrate Johnny-Mnemonix into your Home Manager configuration:

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

  outputs = { self, nixpkgs, home-manager, johnny-mnemonix }: {
    homeManagerConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [
        johnny-mnemonix.homeManagerModules.default
        {
          home = {
            username = "example";
            homeDirectory = "/home/example";
            stateVersion = "24.05";
          };

          johnny-mnemonix = {
            enable = true;
            baseDir = "~/Documents";
            shell = {
              enable = true;
              prefix = "jm";
              aliases = true;
              functions = true;
            };
          };
        }
      ];
    };
  };
}
```

## Best Practices

1. **Shell Integration**
   - Use the default prefix unless you have conflicts
   - Enable both aliases and functions for full functionality
   - Add shell completion for better usability

2. **Directory Structure**
   - Use the standard `~/Documents` location when possible
   - Keep paths XDG-compliant
   - Use absolute paths for critical locations

3. **Command Usage**
   - Use the shell functions for navigation
   - Leverage completion for faster directory access
   - Use search commands for quick location finding

## Integration with Other Tools

Johnny-Mnemonix is designed to work seamlessly with:
- Home Manager
- Nix Flakes
- Git version control
- XDG Base Directory specification

For more examples and advanced configurations, see the [examples](../examples) directory. 