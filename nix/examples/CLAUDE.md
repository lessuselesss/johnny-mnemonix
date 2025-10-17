# Examples Cell - Johnny Declarative Decimal

**Cell Type**: `examples`
**Purpose**: Real-world example systems and configurations
**Blocks**: `configs.nix`

---

## Phase 1: Requirements

### Cell Overview

The `examples` cell provides complete, working examples demonstrating how to use johnny-declarative-decimal at different complexity levels. Each example is a fully-functional flake that can be used as a template.

### User Stories

#### US-EX-1: Quick Start Examples
**As a** new user
**I want** to see working examples I can copy
**So that** I can get started quickly

**Acceptance Criteria**:
- Example using classic framework (simplest)
- Example using builders (moderate)
- Example using composition (advanced)
- Example using primitives (expert)
- All examples fully documented

#### US-EX-2: Real-World Scenarios
**As a** user
**I want** to see how others solve similar problems
**So that** I can adapt solutions to my needs

**Acceptance Criteria**:
- Software project organization
- Document management
- Research/academic organization
- Product development workflow
- Creative work organization

---

## Phase 2: Design

### Cell Structure

```
nix/examples/
├── CLAUDE.md                           # This file
├── configs.nix                         # Block: Example exports
├── 01-classic-johnny-decimal/
│   ├── flake.nix                       # Complete example flake
│   ├── home.nix                        # Home-manager config
│   └── README.md                       # Usage instructions
├── 02-hexadecimal-variant/
│   ├── flake.nix
│   ├── home.nix
│   └── README.md
├── 03-custom-builder/
│   ├── flake.nix
│   ├── home.nix
│   └── README.md
├── 04-from-scratch/
│   ├── flake.nix
│   ├── custom-system.nix               # Built from primitives
│   ├── home.nix
│   └── README.md
└── real-world/
    ├── software-project/
    │   ├── flake.nix
    │   └── README.md
    ├── document-management/
    │   ├── flake.nix
    │   └── README.md
    └── research-lab/
        ├── flake.nix
        └── README.md
```

### Example 1: Classic Framework (Easiest)

```nix
# 01-classic-johnny-decimal/flake.nix
{
  description = "Johnny Decimal using classic framework";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    johnny-dd.url = "github:user/johnny-declarative-decimal";
  };

  outputs = {nixpkgs, home-manager, johnny-dd, ...}: {
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {system = "x86_64-linux";};

      modules = [
        # Just import the framework!
        johnny-dd.frameworks.x86_64-linux.johnny-decimal-classic.homeManagerModule

        # Configure
        {
          johnny-mnemonix = {
            enable = true;
            baseDir = "~/Documents";
            areas = {
              "10-19" = {
                name = "Projects";
                categories = {
                  "10" = {
                    name = "Code";
                    items = {
                      "10.01" = "Website";
                      "10.02" = "CLI-Tool";
                    };
                  };
                };
              };
            };
          };
        }
      ];
    };
  };
}
```

### Example 2: Custom Builder (Moderate)

```nix
# 03-custom-builder/flake.nix
{
  description = "Custom system using builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    johnny-dd.url = "github:user/johnny-declarative-decimal";
  };

  outputs = {nixpkgs, johnny-dd, ...}: let
    system = "x86_64-linux";
    lib = johnny-dd.lib.${system};

    # Build custom system
    mySystem = lib.builders.mkJohnnyDecimal {
      base = 16;  # Hexadecimal
      area_span = 16;  # 0x00-0x0F, 0x10-0x1F, etc.
      digits = 2;
    };
  in {
    # Use custom system
    packages.${system}.default = /* ... */;
  };
}
```

### Example 3: From Scratch (Expert)

```nix
# 04-from-scratch/custom-system.nix
{lib}: let
  prim = lib.primitives;
  comp = lib.composition;

  # Define a departmental project numbering system
  # Format: DEPT-YY-NNN (e.g., ENG-24-001)

  # Create number systems
  alphabetic = prim.numberSystems.alphabetic;
  decimal = prim.numberSystems.decimal;

  # Define fields
  deptField = prim.fields.mk {
    system = alphabetic;
    width = 3;
    padding = "none";
  };

  yearField = prim.fields.mk {
    system = decimal;
    width = 2;
    padding = "zeros";
  };

  seqField = prim.fields.mk {
    system = decimal;
    width = 3;
    padding = "zeros";
  };

  # Compose identifier
  projectId = comp.identifiers.mk {
    octets = [deptField yearField seqField];
    separator = "-";
  };

  # Add constraints
  deptConstraint = prim.constraints.enum ["ENG" "DES" "OPS" "MKT"];
  yearConstraint = prim.constraints.range {min = 24; max = 30;};

  validator = comp.validators.mk [
    deptConstraint
    yearConstraint
  ];
in {
  # Exportable system
  inherit projectId validator;

  # Convenience functions
  parse = comp.identifiers.parse projectId;
  format = comp.identifiers.format projectId;
  validate = validator;
}
```

---

## Phase 3: Implementation

### Example Testing

Each example should be testable:

```nix
# Test: Classic example evaluates
testClassicEvaluates = {
  expr = (import ./01-classic-johnny-decimal/flake.nix).outputs ? homeConfigurations;
  expected = true;
};

# Test: Classic example creates correct structure
testClassicStructure = let
  config = (import ./01-classic-johnny-decimal/flake.nix).outputs.homeConfigurations.user;
  areas = config.johnny-mnemonix.areas;
in {
  expr = areas."10-19".name;
  expected = "Projects";
};

# Test: Custom builder example works
testCustomBuilderWorks = let
  flake = import ./03-custom-builder/flake.nix;
in {
  expr = flake.outputs ? packages;
  expected = true;
};
```

### Documentation Requirements

Each example must have:

1. **README.md** with:
   - What this example demonstrates
   - Prerequisites
   - How to use it
   - How to customize it
   - Common pitfalls

2. **Complete working code**:
   - Can be copied and run immediately
   - No placeholders or TODOs
   - Properly formatted and commented

3. **Comments explaining**:
   - Why each choice was made
   - What alternatives exist
   - How to extend it

### Implementation Checklist

**Basic Examples**:
- [ ] 01-classic-johnny-decimal (framework)
- [ ] 02-hexadecimal-variant (framework variant)
- [ ] 03-custom-builder (using builders)
- [ ] 04-from-scratch (using primitives/composition)

**Real-World Examples**:
- [ ] Software project organization
- [ ] Document management system
- [ ] Research/academic workflow
- [ ] Product development
- [ ] Creative work organization

**Documentation**:
- [ ] README.md for each example
- [ ] Comments in all example code
- [ ] Links to relevant documentation
- [ ] Migration guides where applicable

---

## Next Steps

1. Create examples after frameworks are implemented
2. Test all examples work end-to-end
3. Gather feedback from real users
4. Add more real-world scenarios based on demand
