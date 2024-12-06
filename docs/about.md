# About Johnny-Mnemonix

## Philosophy

Johnny-Mnemonix combines two powerful ideas:
1. The organizational clarity of the Johnny.Decimal system
2. The reproducibility and declarative nature of Nix

The goal is to make document management both systematic and reproducible across systems, while maintaining the flexibility to adapt to individual needs.

## Core Concepts

### Johnny.Decimal System

The Johnny.Decimal system organizes information into a three-level hierarchy:

1. **Areas (10-19, 20-29, etc.)**
   - High level and distinct domains of your information
   - Like shelves in a bookcase
   - Each spans a range of numbers, the first number being the constant among the range (e.g., 10-19)

2. **Categories (11.xx, 12.xx, etc.)**
   - Specific groupings within areas
   - Like boxes (box-sets) on the shelves
   - Two-digit numbers within the area's range

3. **IDs (11.01, 11.02, etc.)**
   - Individual locations for items
   - Like books in the boxes
   - Format: Category.Index (e.g., 11.01)

### Nix Integration

Johnny-Mnemonix leverages Nix to make this system:

- **Declarative**: Your entire document structure is defined in code
- **Reproducible**: The same structure can be recreated on any system
- **Verifiable**: Built-in tests ensure your structure remains valid
- **Portable**: Works across Linux and Darwin systems
- **Integrated**: Works seamlessly with Home Manager

### Shell Integration

The project provides intuitive shell commands for navigation:

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

## Why "Mnemonix"?

The name combines three elements:
1. **Johnny** - From Johnny.Decimal, the organizational system
2. **Mnemonic** - Greek for "memory aid" (the system helps remember locations)
3. **Nix** - The package manager and system configuration tool

It's also a nod to William Gibson's "Johnny Mnemonic" - a character who, like our system, helps manage and organize digital information.

## Design Principles

1. **Non-destructive**
   - Never deletes existing files
   - Safely merges with existing structures
   - Preserves user data

2. **Minimal Configuration**
   - Sensible defaults
   - Only configure what you need
   - Clear, focused options

3. **Shell-First**
   - Fast command-line navigation
   - Tab completion
   - Fuzzy finding

4. **XDG Compliant**
   - Follows XDG Base Directory specification
   - Respects system conventions
   - Clean home directory

## Getting Started

See our [Configuration Guide](./configuration.md) for detailed setup instructions, or check out the [examples](../examples) directory for quick-start configurations.
