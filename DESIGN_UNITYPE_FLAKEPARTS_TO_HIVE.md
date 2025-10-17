# Unitype Transformation: flake-parts Module → Hive Block

## Transformation Overview

```
flake-parts Module ──encode──→ [Canonical IR] ──decode──→ Hive Block
```

## Example Input: flake-parts Module

```nix
# modules/[10.01]{10-19 Servers}__(10 Web)__[01 Nginx].nix
{ config, lib, pkgs, ... }: {
  # flake-parts perSystem module
  perSystem = { config, pkgs, ... }: {
    packages.nginx-config = pkgs.writeText "nginx.conf" ''
      server {
        listen 80;
        root /var/www;
      }
    '';
  };

  # flake-parts flake-level module
  flake.nixosModules.nginx = {
    services.nginx = {
      enable = true;
      virtualHosts."example.com" = {
        root = "/var/www";
      };
    };
  };
}
```

## Example Output: Hive Block Configuration

```nix
# cells/web/hosts/10.01-nginx.nix
# Automatically converted to divnix/std + hive structure
{ inputs, cell }: {
  # Hive nixosConfiguration
  bee = {
    system = "x86_64-linux";
    pkgs = inputs.nixpkgs;
  };

  # NixOS configuration (from flake.nixosModules.nginx)
  imports = [
    ({ config, lib, pkgs, ... }: {
      services.nginx = {
        enable = true;
        virtualHosts."example.com" = {
          root = "/var/www";
        };
      };
    })
  ];
}
```

## Canonical IR Structure

```nix
{
  # Identity (from JD filename)
  id = "10.01";
  kind = "flake-parts-module";

  # Metadata
  meta = {
    source = "modules/[10.01]{10-19 Servers}__(10 Web)__[01 Nginx].nix";
    jdStructure = {
      area = { id = "10-19"; name = "Servers"; };
      category = { id = "10"; name = "Web"; };
      item = { id = "01"; name = "Nginx"; };
    };
  };

  # Extracted components
  structure = {
    # Per-system outputs
    perSystem = {
      packages = {
        nginx-config = { type = "derivation"; /* ... */ };
      };
    };

    # Flake-level outputs
    flake = {
      nixosModules = {
        nginx = { /* NixOS module definition */ };
      };
    };
  };

  # Transformation hints
  hints = {
    canTransformTo = [
      "hive-block"
      "nixosConfiguration"
      "std-cell-block"
    ];
    preferredSystem = "x86_64-linux";
    hasNixOSModule = true;
  };
}
```

## Encoder: flake-parts → IR

```nix
# nix/unitype/encoders/flake-parts.nix
{ lib }: {
  encode = flakePartsModule: let
    # Evaluate the module to extract its structure
    evaluated = lib.evalModules {
      modules = [ flakePartsModule ];
    };

    # Extract perSystem outputs
    perSystemOutputs = evaluated.config.perSystem or {};

    # Extract flake-level outputs
    flakeOutputs = evaluated.config.flake or {};

    # Detect what outputs are available
    hasPackages = perSystemOutputs ? packages;
    hasApps = perSystemOutputs ? apps;
    hasDevShells = perSystemOutputs ? devShells;
    hasNixOSModules = flakeOutputs ? nixosModules;
    hasNixOSConfigurations = flakeOutputs ? nixosConfigurations;

    # Extract JD metadata from source if available
    jdMeta = extractJDMetadata flakePartsModule;

  in {
    id = jdMeta.itemId or "unknown";
    kind = "flake-parts-module";

    meta = {
      source = toString flakePartsModule;
      jdStructure = jdMeta;
    };

    structure = {
      perSystem = perSystemOutputs;
      flake = flakeOutputs;
    };

    hints = {
      canTransformTo =
        (if hasNixOSModules || hasNixOSConfigurations then ["hive-block" "nixosConfiguration"] else []) ++
        ["std-cell-block"];
      hasNixOSModule = hasNixOSModules;
      hasPackages = hasPackages;
    };
  };
}
```

## Decoder: IR → Hive Block

```nix
# nix/unitype/decoders/hive-block.nix
{ lib, hive }: {
  decode = ir: let
    # Validate IR can be converted to Hive block
    _ = assert ir.hints.hasNixOSModule or false;
      "IR must contain a NixOS module to convert to Hive block";

    # Extract NixOS module from flake outputs
    nixosModule =
      if ir.structure.flake ? nixosModules.default
      then ir.structure.flake.nixosModules.default
      else if ir.structure.flake ? nixosModules
      then builtins.head (builtins.attrValues ir.structure.flake.nixosModules)
      else throw "No NixOS module found in flake-parts module";

    # Determine system
    system = ir.hints.preferredSystem or "x86_64-linux";

    # Generate Hive block structure
    hiveBlock = { inputs, cell }: {
      # Hive bee configuration (system metadata)
      bee = {
        inherit system;
        pkgs = inputs.nixpkgs;
      };

      # Import the extracted NixOS module
      imports = [ nixosModule ];

      # Add perSystem packages as system packages if available
      environment.systemPackages =
        if ir.structure.perSystem ? packages
        then builtins.attrValues (ir.structure.perSystem.packages.${system} or {})
        else [];
    };

    # Return with metadata
  in {
    # The Hive block function
    block = hiveBlock;

    # Metadata for organization
    meta = ir.meta // {
      targetKind = "hive-block";
      cellName = ir.meta.jdStructure.category.name or "default";
      blockName = ir.id;
    };

    # Suggested file path
    suggestedPath = let
      cellName = lib.toLower (lib.replaceStrings [" "] ["-"] (ir.meta.jdStructure.category.name or "default"));
      blockName = "${ir.id}-${lib.toLower (lib.replaceStrings [" "] ["-"] (ir.meta.jdStructure.item.name or "host"))}";
    in "cells/${cellName}/hosts/${blockName}.nix";
  };
}
```

## Complete Transformation Example

```nix
# Input: flake-parts module
flakePartsModule = ./modules/[10.01]{10-19 Servers}__(10 Web)__[01 Nginx].nix;

# Step 1: Encode to IR
ir = unitype.encode "flake-parts-module" flakePartsModule;

# IR Result:
# {
#   id = "10.01";
#   kind = "flake-parts-module";
#   structure = {
#     perSystem.packages.nginx-config = ...;
#     flake.nixosModules.nginx = ...;
#   };
#   hints.hasNixOSModule = true;
# }

# Step 2: Decode to Hive block
hiveBlock = unitype.decode "hive-block" ir;

# Hive Block Result:
# {
#   block = { inputs, cell }: {
#     bee = { system = "x86_64-linux"; pkgs = inputs.nixpkgs; };
#     imports = [ <nginx-module> ];
#   };
#   meta.suggestedPath = "cells/web/hosts/10.01-nginx.nix";
# }

# Step 3: Write to suggested location
builtins.trace "Write to: ${hiveBlock.meta.suggestedPath}" hiveBlock.block;
```

## Automatic Batch Transformation

Transform an entire flake-parts modules directory to Hive structure:

```nix
# Transform all modules/*.nix to cells/**/hosts/*.nix
flakePartsModules = {
  "10.01-nginx" = ./modules/10.01-nginx.nix;
  "10.02-postgres" = ./modules/10.02-postgres.nix;
  "20.01-monitoring" = ./modules/20.01-monitoring.nix;
};

# Batch transform
hiveStructure = unitype.transformHierarchy {
  source = "flake-parts-module";
  target = "hive-block";
  hierarchy = flakePartsModules;
};

# Result: JD-organized Hive structure
# {
#   "web" = {                     # From category "10 Web"
#     "10.01-nginx" = <hive-block>;
#     "10.02-postgres" = <hive-block>;
#   };
#   "monitoring" = {              # From category "20 Monitoring"
#     "20.01-monitoring" = <hive-block>;
#   };
# }
```

## Reverse Transformation: Hive Block → flake-parts

The system also supports the reverse:

```nix
# Hive block
hiveBlock = { inputs, cell }: {
  bee.system = "x86_64-linux";
  services.nginx.enable = true;
};

# Encode to IR
ir = unitype.encode "hive-block" hiveBlock;

# Decode to flake-parts
flakePartsModule = unitype.decode "flake-parts-module" ir;

# Result: flake-parts module
# {
#   flake.nixosModules.default = {
#     services.nginx.enable = true;
#   };
# }
```

## Migration Use Case

### Scenario: Migrating from flake-parts to Hive

```nix
# Before: flake-parts structure
# flake.nix with many perSystem modules

# After: Use Unitype to migrate
let
  # Discover all flake-parts modules
  modules = lib.filesystem.listFilesRecursive ./modules;

  # Transform each to Hive
  hiveBlocks = lib.mapAttrs (name: path:
    unitype.transform "flake-parts-module" "hive-block" path
  ) modules;

  # Organize by category (from JD structure)
  hiveStructure = lib.foldl (acc: block:
    let
      cellName = block.meta.cellName;
      blockName = block.meta.blockName;
    in acc // {
      ${cellName} = (acc.${cellName} or {}) // {
        ${blockName} = block.block;
      };
    }
  ) {} (builtins.attrValues hiveBlocks);

in {
  # New Hive-based flake structure
  cells = hiveStructure;
}
```

## Type Compatibility Matrix

```
flake-parts-module
    │
    ├─→ hive-block              (if has nixosModule)
    ├─→ nixosConfiguration       (if has nixosModule)
    ├─→ std-cell-block           (always)
    ├─→ home-configuration       (if has homeModule)
    └─→ ISO/VMware/Docker        (via nixosConfiguration)

hive-block
    │
    ├─→ flake-parts-module       (always)
    ├─→ nixosConfiguration       (always)
    └─→ ISO/VMware/Docker        (via nixosConfiguration)
```

## Integration with divnix/std

The Unitype system respects std's cell/block structure:

```nix
# Transformation preserves std organization
ir = unitype.encode "flake-parts-module" module;

# Metadata extraction
jdCategory = ir.meta.jdStructure.category;  # "10 Web"
cellName = lib.toLower (lib.replaceStrings [" "] ["-"] jdCategory.name);  # "web"

# Decoder uses this to generate proper std paths
hiveBlock = unitype.decode "hive-block" ir;
# hiveBlock.meta.suggestedPath = "cells/web/hosts/10.01-nginx.nix"
```

## Benefits

1. **Seamless Migration**: Move between flake-parts and Hive without rewriting configs
2. **JD Preservation**: Johnny Decimal structure maintained across transformations
3. **Bidirectional**: Go back and forth as needed
4. **Type Safety**: Validation ensures only compatible transformations
5. **Batch Operations**: Transform entire module hierarchies at once

## Implementation Priority

1. **Phase 1**: Core IR + flake-parts encoder
2. **Phase 2**: Hive block decoder
3. **Phase 3**: Reverse transformations (hive → flake-parts)
4. **Phase 4**: Batch transformation utilities
5. **Phase 5**: Auto-migration CLI tool

This transformation is a **killer feature** - it means users can organize their configs in whichever framework they prefer, and trivially convert to another if their needs change!
