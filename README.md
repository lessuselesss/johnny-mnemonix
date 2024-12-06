# Johnny-Mnemonix

> Declarative document management using the Johnny Decimal system, powered by Nix

Johnny-Mnemonix is a Home Manager module that brings the power of declarative configuration to your document management, implementing the [Johnny Decimal](https://johnnydecimal.com/) system in a Nix-native way. It provides a structured, reproducible approach to organizing your `$HOME/Documents` directory (aka your `$HOMEOFFICE`).

## Features

- 🏗️ **Declarative Structure**: Define your entire document hierarchy in Nix, ensuring consistency across systems
- 📁 **Johnny Decimal Implementation**: First-class support for the [Johnny Decimal](https://johnnydecimal.com/) organizational system
- 🔄 **XDG Compliance**: Follows XDG Base Directory specifications for configuration and cache data
- 📝 **Typst Integration**: Seamless integration with [Typix](https://github.com/loqusion/typix) for deterministic document compilation
- 🔍 **Smart Search**: Quick document location using Johnny Decimal codes
- 🔄 **Version Control Ready**: Designed to work well with Git for document versioning
- 🏠 **Home Manager Native**: Integrates naturally with your existing Home Manager configuration

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

## Configuration

See our [documentation](./docs/configuration.md) for detailed configuration options and examples.

## Why Johnny-Mnemonix?

The name combines "Johnny Decimal" with "Nix" and pays homage to William Gibson's "Johnny Mnemonic" - a character who stores digital data in his brain. Similarly, Johnny-Mnemonix helps you store and organize your digital life in a structured, reproducible way.

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
              "21.01" = "Current Project";
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

## Integration with Typix

Johnny-Mnemonix seamlessly integrates with Typix for document compilation. Define your Typst documents within your Johnny Decimal structure:

```nix
{
  mnemonic.documents = {
    "11.01.budget-2024" = {
      source = ./documents/budget-2024.typ;
      engine = "typst";
      dependencies = {
        fonts = [ pkgs.inter ];
        data = [ ./data/expenses.csv ];
      };
    };
  };
}
```

## Directory Navigation

Johnny-Mnemonix provides simple, fast navigation to your documents using Johnny Decimal codes. Once configured, you can quickly navigate to any location in your document hierarchy:

```bash
# Navigate directly to a specific ID location
cd ~$11.01   # Goes to $HOMEOFFICE/10-19 Personal/11 Finance/11.01 Budget/

# Or use the full path including document name
cd ~$11.01.annual-budget   # Goes to the specific document location
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](./LICENSE) for details.
