[![CI](https://github.com/lessuselesss/johnny-mnemonix/actions/workflows/ci.yml/badge.svg)](https://github.com/lessuselesss/johnny-mnemonix/actions/workflows/ci.yml)

# Johnny-Mnemonix

> Declarative document management using the Johnny Decimal system, powered by Nix Flakes

Johnny-Mnemonix is a Home Manager module that brings the power of declarative configuration to your document management, implementing the [Johnny Decimal](https://johnnydecimal.com/) system in a Nix-native way. It provides a structured, reproducible approach to organizing your `$HOME/Documents` directory (aka your `$HOMEOFFICE`).

**Note**: Johnny-Mnemonix is designed exclusively for Nix Flakes and does not support legacy Nix usage.

## Features

- 🏗️ **Declarative Structure**: Define your entire document hierarchy in Nix, ensuring consistency across systems
- 📁 **Johnny Decimal Implementation**: First-class support for the [Johnny Decimal](https://johnnydecimal.com/) organizational system
- 🔄 **XDG Compliance**:
  - Follows XDG Base Directory specifications for configuration and cache data
  - Maintains state tracking under `${XDG_STATE_HOME}/johnny-mnemonix`
  - Handles directory structure changes gracefully
- 🔄 **Version Control Ready**:
  - Designed to work well with Git for document versioning
  - Native support for Git repositories in the document structure
  - Symlink support for shared resources
- 🏠 **Home Manager Native**: Integrates naturally with your existing Home Manager configuration

## Requirements

- Nix with flakes enabled:

```nix
{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
```

## Directory Structure

When enabled, Johnny-Mnemonix creates the following structure:


```
$HOMEOFFICE/ #($HOME/Documents/)
├── 10-19 Area/
│   ├── ...
│   ├── 15.XX Category/
│   │   ├── ...
│   │   ├── 15.51 ...
│   │   └── 15.52 ID/
│   └── ...
├── x0-x9 Area/
│   ├── ...
│   ├── x0.XX Category/
│   │   ├── ...
│   │   ├── x0.01 ID/
│   │   ├── x0.XX ...
│   │   └── x0.99 ID/
│   └── ...
└── ...
```
<img src="https://johnnydecimal.com/img/v6/11.01A-Diagram_1552_NYC--dtop-1_resize-dark-cx-1000x609.png" style="max-width: 800px; width: 100%" alt="Johnny.Decimal system diagram">

Each component follows the Johnny Decimal system, `analogizing a Book Case`

`shelf`

- **Areas**: Groupings of categories (10-19, 20-29, etc.)

`box`

- **Categories**: Groupings of items (11, 12, etc.)

`book`

- **IDs**: Counter starting at 01 (11.01, 11.02, etc.)

## Development

### Prerequisites

- Nix with flakes enabled
- Git

### Development Environment

To get started:

```bash
# Clone the repository
git clone https://github.com/lessuselesss/johnny-mnemonix
cd johnny-mnemonix

# Enter development environment
nix develop
```

The development environment provides:
- Pre-commit hooks for code quality
- Nix formatting with Alejandra
- Static analysis with Statix
- Dead code detection with Deadnix
- Nix LSP (nil) for better IDE integration

### Code Quality Tools

Pre-commit hooks are automatically installed and run on each commit. They check for:
- Proper formatting (Alejandra)
- Static analysis (Statix)
- Dead code (Deadnix)
- Basic file hygiene (trailing whitespace, file endings, etc.)
- Nix flake correctness

To run checks manually:

```bash
pre-commit run --all-files
```

### Continuous Integration

Our CI pipeline (powered by [Determinate Systems](https://determinate.systems/)) runs:
1. Pre-commit checks
2. Multi-platform builds (NixOS, nix-darwin)
3. Flake checks
4. Dependency updates

## Installation & Usage

### 1. Add to Flake Inputs
In your system's `flake.nix`, add Johnny-Mnemonix to your inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    johnny-mnemonix.url = "github:lessuselesss/johnny-mnemonix";
  };

  outputs = { self, nixpkgs, home-manager, johnny-mnemonix }: {
    homeManagerConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      # Your existing config...
      modules = [
        johnny-mnemonix.homeManagerModules.default
        ./home.nix
      ];
    };
  };
}
```

### 2. Configure Your Document Structure
In your `home.nix` (or other Home Manager configuration file), define your document structure:

```nix
{
  johnny-mnemonix = {
    enable = true;
    # Optional: customize base directory
    baseDir = "${config.home.homeDirectory}/Documents";
    # Optional: customize the spacer character used in directory names
    spacer = " ";  # Default is a single space

    areas = {
      "10-19" = {
        name = "Personal";
        categories = {
          "11" = {
            name = "Finance";
            items = {
              "11.01" = "Budget";
              "11.02" = {
                name = "Investment Tracker";
                url = "git@github.com:user/investments.git";
                ref = "main";  # Optional: specify branch/ref
                sparse = [];   # Optional: sparse checkout patterns
              };
              "11.03" = {
                name = "Shared Documents";
                target = "/path/to/shared/docs";  # Symlink target
              };
            };
          };
          "12" = {
            name = "Health";
            items = {
              "12.01" = "Medical Records";
              "12.02" = "Fitness Plans";
            };
          };
        };
      };
      "20-29" = {
        name = "Work";
        categories = {
          "21" = {
            name = "Projects";
            items = {
              "21.01" = {
                name = "Current Project";
                url = "https://github.com/company/project.git";
              };
              "21.02" = "Project Archive";
            };
          };
        };
      };
    };
  };
}
```

### 3. Apply Configuration
Run Home Manager to create your directory structure:

```bash
home-manager switch
```

This will create a directory structure like:

```
Documents/
├── 10-19 Personal/
│   ├── 11 Finance/
│   │   ├── 11.01 Budget/
│   │   └── 11.02 Investments/
│   └── 12 Health/
│       ├── 12.01 Medical Records/
│       └── 12.02 Fitness Plans/
└── 20-29 Work/
    └── 21 Projects/
        ├── 21.01 Current Project/
        └── 21.02 Project Archive/
```

### 4. Navigate Your Structure
After installation, you can use the provided shell alias to navigate to your document root:

```bash
# Navigate to your document root
jd

# Or navigate to specific directories using standard cd commands
cd ~/Documents/10-19\ Personal/11\ Finance/11.01\ Budget
```

### Important Notes

- The directory structure is created non-destructively (won't overwrite existing directories)
- All directory names must follow the Johnny Decimal format:
  - Areas: XX-YY format (e.g., "10-19")
  - Categories: XX format (e.g., "11")
  - Items: XX.YY format (e.g., "11.01")
- The `jd` alias is available in both bash and zsh
- You can modify the structure by updating your configuration and running `home-manager switch` again

## Roadmap

Future enhancements planned for Johnny-Mnemonix:

### Near-term
- [ ] Shell navigation commands (`jm`, `jmls`, etc.)
- [ ] Smart search functionality
- [ ] Integration with [Typix](https://github.com/loqusion/typix) for deterministic document compilation
- [ ] Integration with [ragenix](https://github.com/yaxitech/ragenix) for encrypted documents
- [ ] Git repository management within the document structure
- [ ] Automatic backup configuration

### Mid-term
- [ ] Document templates system
- [ ] Integration with popular document editors
- [ ] Document metadata management
- [ ] Advanced search capabilities with filtering and tagging

### Long-term
- [ ] AI-powered document organization suggestions
- [ ] Extended encryption options and key management
- [ ] Document integrity verification
- [ ] Version control policy management

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

Before submitting a PR:
1. Enter the development environment: `cached-nix-shell`
2. Ensure all pre-commit hooks pass: `pre-commit run --all-files`
3. Verify CI checks pass locally: `nix flake check`

## License

MIT License - See [LICENSE](./LICENSE) for details.
