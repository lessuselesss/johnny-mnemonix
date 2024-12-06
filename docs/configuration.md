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

## Verification

After configuration:

1. Run your system update command:
   - For NixOS: `nixos-rebuild switch`
   - For Darwin: `darwin-rebuild switch`
   - For Home Manager: `home-manager switch`

2. Verify directory creation:
   ```bash
   ls ~/Documents/10-19\ Personal/11\ Finance/
   ```

3. Test shell commands (if enabled):
   ```bash
   jm          # Navigate to base directory
   jmls        # List contents
   jm 11.01    # Navigate to specific item
   ```