# Frequently Asked Questions

## General Questions

### What is Johnny-Mnemonix?
Johnny-Mnemonix is a declarative document management system built on the Johnny Decimal system, implemented as a Nix Home Manager module. It helps you organize your documents in a consistent, maintainable way using a numeric system for easy reference and navigation.

### Why use Johnny-Mnemonix?
- **Declarative Configuration**: Your document structure is defined in code
- **Version Control**: Track changes to your organization system
- **Reproducible**: Easy to recreate on different machines
- **Consistent**: Enforces Johnny Decimal system rules
- **Extensible**: Plugin system for additional functionality

### How does it differ from regular folders?
1. **Structure Validation**: Enforces correct naming and organization
2. **Automated Creation**: Generates directory structure from configuration
3. **Shell Integration**: Quick navigation using numeric codes
4. **Plugin System**: Extensible functionality
5. **Version Control**: Track structural changes

## Setup and Installation

### How do I install Johnny-Mnemonix?
```nix
# flake.nix
{
  inputs.johnny-mnemonix.url = "github:lessuselesss/johnny-mnemonix";
  
  outputs = { self, nixpkgs, home-manager, johnny-mnemonix }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      # ...
      modules = [
        johnny-mnemonix.homeManagerModules.default
        # ...
      ];
    };
  };
}
```

### What are the system requirements?
- Nix package manager
- Home Manager
- Linux or macOS
- Basic understanding of the Johnny Decimal system

### Can I use it without Nix?
No, Johnny-Mnemonix is specifically designed as a Nix Home Manager module to leverage the benefits of declarative configuration and reproducible builds.

## Usage Questions

### How do I start organizing my documents?

1. Plan your areas (XX-YY):
```nix
areas = {
  "10-19" = { name = "Personal"; };
  "20-29" = { name = "Work"; };
};
```

2. Define categories (XX):
```nix
"10-19" = {
  name = "Personal";
  categories = {
    "11" = { name = "Finance"; };
    "12" = { name = "Health"; };
  };
};
```

3. Add items (XX.YY):
```nix
"11" = {
  name = "Finance";
  items = {
    "11.01" = "Budget";
    "11.02" = "Investments";
  };
};
```

### How do I navigate the structure?

Use the provided shell commands:
```bash
# Go to document root
jd

# Go to specific area/category/item
jj 10-19    # Go to Personal area
jj 11       # Go to Finance category
jj 11.01    # Go to Budget item
```

### Can I rename directories?
Don't rename directories manually. Instead, update your configuration:

```nix
# Before
"11.01" = "Budget";

# After
"11.01" = "Monthly Budget";
```

Then run `home-manager switch` to apply changes.

## Structure Questions

### How many areas should I create?
- Start with 3-5 main areas
- Leave gaps for future expansion
- Common structure:
  - 10-19: Personal
  - 20-29: Work
  - 30-39: Projects
  - 90-99: Archive

### What's the maximum depth?
The Johnny Decimal system uses three levels:
1. Areas (XX-YY)
2. Categories (XX)
3. Items (XX.YY)

### Can I move items between categories?
Yes, update your configuration:
```nix
# Before
"11" = {
  items."11.01" = "Budget";
};

# After
"12" = {
  items."12.01" = "Budget";
};
```

## Plugin Questions

### How do I enable plugins?
```nix
{
  johnny-mnemonix = {
    enable = true;
    plugins = {
      tags.enable = true;
      sync.enable = true;
    };
  };
}
```

### Can I write my own plugins?
Yes, create a plugin module:
```nix
# plugins/my-plugin/default.nix
{ config, lib, ... }: {
  options.johnny-mnemonix.plugins.my-plugin = {
    enable = lib.mkEnableOption "My plugin";
  };
  
  config = lib.mkIf config.johnny-mnemonix.plugins.my-plugin.enable {
    # Plugin implementation
  };
}
```

## Troubleshooting

### Why aren't my directories created?
1. Check module is enabled:
```nix
johnny-mnemonix.enable = true;
```

2. Verify configuration syntax
3. Check permissions
4. Run with verbose output:
```bash
home-manager switch -v
```

### How do I fix permission errors?
1. Check directory ownership:
```bash
ls -la ~/Documents
```

2. Fix permissions:
```bash
chmod 755 ~/Documents
```

3. Update configuration:
```nix
johnny-mnemonix.security.defaultPermissions = "0755";
```

### Why are my changes not applying?
1. Run `home-manager switch`
2. Check configuration changes
3. Verify no manual changes
4. Check error messages

## Migration

### How do I migrate existing documents?
1. Plan your structure
2. Create configuration
3. Move files gradually:
```bash
# Example migration script
for dir in ~/OldDocs/*; do
  # Move to appropriate JD location
  mv "$dir" ~/Documents/10-19\ Personal/11\ Finance/
done
```

### Can I import existing structures?
Yes, map your existing structure to Johnny Decimal:
1. Analyze current organization
2. Create mapping document
3. Configure Johnny-Mnemonix
4. Migrate files

## Best Practices

### Should I version 