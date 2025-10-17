# Johnny Mnemonix Unitype - Universal Type Transformation

## Concept

A **universal type transformation system** that can convert between any two Nix types defined in our system by routing through a canonical intermediate representation (IR).

## Category Theory Foundation

```
Type A ──────transform────→ Type B
   │                           ▲
   │ encode                    │ decode
   │                           │
   └──→ [Canonical IR] ────────┘
```

Instead of defining `N × (N-1)` direct transformations between N types, we define:
- `N` encoders (Type → IR)
- `N` decoders (IR → Type)

Total: `2N` transformations instead of `N²`

## Canonical Intermediate Representation (IR)

The IR is a Johnny Decimal-structured universal data model:

```nix
{
  # Identity
  id = "10.01-web-server";              # JD identifier
  kind = "nixosConfiguration";          # Type discriminator

  # Metadata
  meta = {
    system = "x86_64-linux";
    description = "Web server configuration";
    tags = ["production" "web"];
    source = "/path/to/config.nix";
  };

  # Hierarchical structure (JD-organized)
  structure = {
    "10-19" = {                         # Area
      name = "Servers";
      "10" = {                          # Category
        name = "Web Servers";
        "10.01" = {                     # Item
          name = "Primary";
          data = { /* type-specific */ };
        };
      };
    };
  };

  # Type-specific payload
  payload = {
    # Configuration data in normalized form
    modules = [ /* ... */ ];
    specialArgs = { /* ... */ };
  };

  # Transformation hints
  hints = {
    # Metadata for decoders
    canTransformTo = ["iso" "vmware" "docker"];
    requiresValidation = true;
  };
}
```

## Type Transformations

### Example: nixosConfiguration → ISO

```nix
# Encode: nixosConfiguration → IR
nixosConfig = {
  system = "x86_64-linux";
  modules = [ ./config.nix ];
};

ir = unitype.encode "nixosConfiguration" nixosConfig;
# Result: Canonical IR with kind = "nixosConfiguration"

# Transform: IR → ISO
isoImage = unitype.decode "iso" ir;
# Result: Bootable ISO derivation
```

### Example: homeConfiguration → nixosConfiguration

```nix
# Home-manager config
homeConfig = {
  programs.git = {
    enable = true;
    userName = "user";
  };
};

# Transform through IR
ir = unitype.encode "homeConfiguration" homeConfig;
nixosConfig = unitype.decode "nixosConfiguration" ir;
# Result: NixOS config with home-manager module
```

### Example: typstDocument → ISO (embedded docs)

```nix
# Typst document
typstDoc = {
  src = ./thesis;
  entrypoint = "main.typ";
};

# Transform to ISO with embedded PDF
ir = unitype.encode "typstDocument" typstDoc;
# IR contains compiled PDF
isoWithDocs = unitype.decode "iso" ir;
# Result: ISO containing the compiled document
```

## Architecture

### 1. Type Registry

```nix
# nix/unitype/registry.nix
{
  # All types we know about
  types = {
    # System configurations
    nixosConfiguration = {
      encoder = ./encoders/nixos.nix;
      decoder = ./decoders/nixos.nix;
      validator = ./validators/nixos.nix;
    };

    homeConfiguration = {
      encoder = ./encoders/home-manager.nix;
      decoder = ./decoders/home-manager.nix;
      validator = ./validators/home-manager.nix;
    };

    darwinConfiguration = { /* ... */ };

    # Image formats
    iso = {
      encoder = ./encoders/iso.nix;
      decoder = ./decoders/iso.nix;
      validator = ./validators/iso.nix;
    };

    vmware = { /* ... */ };
    docker = { /* ... */ };

    # Documents
    typstDocument = {
      encoder = ./encoders/typst.nix;
      decoder = ./decoders/typst.nix;
      validator = ./validators/typst.nix;
    };

    # Organizational
    jdHierarchy = {
      encoder = ./encoders/jd-hierarchy.nix;
      decoder = ./decoders/jd-hierarchy.nix;
      validator = ./validators/jd-hierarchy.nix;
    };
  };

  # Compatibility matrix
  transformations = {
    nixosConfiguration = {
      canTransformTo = ["iso" "vmware" "docker" "qcow2" "amazon" "azure"];
      canTransformFrom = ["homeConfiguration"];
    };

    iso = {
      canTransformFrom = ["nixosConfiguration"];
    };

    typstDocument = {
      canTransformTo = ["pdf" "iso"];  # Embed in ISO
    };
  };
}
```

### 2. Core Transform Function

```nix
# nix/unitype/lib/transform.nix
{
  lib,
  registry,
}: {
  # Main transformation function
  # transform :: SourceTypeName -> TargetTypeName -> SourceValue -> TargetValue
  transform = sourceType: targetType: value: let
    # 1. Validate source type exists
    sourceSpec = registry.types.${sourceType} or (throw "Unknown source type: ${sourceType}");
    targetSpec = registry.types.${targetType} or (throw "Unknown target type: ${targetType}");

    # 2. Check if transformation is allowed
    canTransform = builtins.elem targetType (registry.transformations.${sourceType}.canTransformTo or []);

    # 3. Validate source value
    sourceValidation = import sourceSpec.validator { inherit lib; };
    validatedValue = sourceValidation.validate value;

    # 4. Encode to IR
    encoder = import sourceSpec.encoder { inherit lib; };
    ir = encoder.encode validatedValue;

    # 5. Decode from IR
    decoder = import targetSpec.decoder { inherit lib; };
    result = decoder.decode ir;

    # 6. Validate result
    targetValidation = import targetSpec.validator { inherit lib; };
    finalResult = targetValidation.validate result;
  in
    if !canTransform
    then throw "Cannot transform ${sourceType} to ${targetType}"
    else finalResult;

  # Convenience: encode to IR
  encode = sourceType: value: let
    sourceSpec = registry.types.${sourceType} or (throw "Unknown type: ${sourceType}");
    encoder = import sourceSpec.encoder { inherit lib; };
  in encoder.encode value;

  # Convenience: decode from IR
  decode = targetType: ir: let
    targetSpec = registry.types.${targetType} or (throw "Unknown type: ${targetType}");
    decoder = import targetSpec.decoder { inherit lib; };
  in decoder.decode ir;

  # Query: can we transform between these types?
  canTransform = sourceType: targetType:
    builtins.elem targetType (registry.transformations.${sourceType}.canTransformTo or []);

  # Query: what can this type transform to?
  getTargets = sourceType:
    registry.transformations.${sourceType}.canTransformTo or [];

  # Query: what can transform to this type?
  getSources = targetType:
    lib.filter (src: builtins.elem targetType (registry.transformations.${src}.canTransformTo or []))
      (builtins.attrNames registry.types);
}
```

### 3. Example Encoder (NixOS → IR)

```nix
# nix/unitype/encoders/nixos.nix
{lib}: {
  encode = nixosConfig: let
    # Extract JD identifier if present
    jdId = nixosConfig.meta.jdId or (
      if nixosConfig ? config.networking.hostName
      then nixosConfig.config.networking.hostName
      else "unknown"
    );
  in {
    # Identity
    id = jdId;
    kind = "nixosConfiguration";

    # Metadata
    meta = {
      system = nixosConfig.system or "x86_64-linux";
      description = nixosConfig.meta.description or "NixOS configuration";
      tags = nixosConfig.meta.tags or [];
      source = builtins.unsafeDiscardStringContext (toString nixosConfig.meta.source or "");
    };

    # Structure (if JD-organized)
    structure = extractJDStructure jdId;

    # Payload
    payload = {
      inherit (nixosConfig) system modules;
      specialArgs = nixosConfig.specialArgs or {};
      config = nixosConfig.config or {};
    };

    # Hints
    hints = {
      canTransformTo = ["iso" "vmware" "docker" "qcow2" "amazon"];
      requiresValidation = true;
    };
  };
}
```

### 4. Example Decoder (IR → ISO)

```nix
# nix/unitype/decoders/iso.nix
{
  lib,
  nixos-generators,
}: {
  decode = ir: let
    # Validate IR kind
    _ = assert ir.kind == "nixosConfiguration" || ir.kind == "darwinConfiguration";
      "IR must be a system configuration";

    # Extract payload
    config = {
      inherit (ir.payload) system modules specialArgs;
    };

    # Generate ISO using nixos-generators
    iso = nixos-generators.nixosGenerate {
      inherit (config) system modules specialArgs;
      format = "iso";
    };
  in {
    # Result is a derivation
    derivation = iso;

    # Metadata from IR
    meta = ir.meta // {
      format = "iso";
      originalId = ir.id;
    };
  };
}
```

## Johnny Decimal Integration

The Unitype system is **inherently JD-aware**:

1. **IR uses JD structure**: All transformations preserve JD hierarchy
2. **Type names follow JD**: `10.01-web-server` becomes part of artifact names
3. **Batch transformations**: Transform entire JD hierarchies at once

```nix
# Transform entire JD hierarchy
jdHierarchy = {
  "10-19" = {
    "10.01" = nixosConfig1;
    "10.02" = nixosConfig2;
  };
  "20-29" = {
    "20.01" = darwinConfig1;
  };
};

# Batch transform to ISOs
isos = unitype.transformHierarchy {
  source = "nixosConfiguration";
  target = "iso";
  hierarchy = jdHierarchy;
};
# Result: Same JD structure, but all values are ISOs
```

## Advanced: Multi-Step Transformations

The system can chain transformations:

```nix
# typstDocument → PDF → ISO (with embedded PDF)
typstDoc = { src = ./thesis; };

# Automatic chaining
iso = unitype.transform "typstDocument" "iso" typstDoc;
# Internally:
#   1. typstDocument → typstPDF
#   2. typstPDF → embedInISO
#   3. embedInISO → iso
```

## Type Compatibility Graph

```
                     [Canonical IR]
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   nixosConfig       homeConfig        darwinConfig
        │                  │                  │
        ├─────────┬────────┼────────┬─────────┤
        │         │        │        │         │
      iso     vmware    docker   amazon    azure
        │         │        │        │         │
        └─────────┴────────┴────────┴─────────┘
                     (bootable images)

         typstDoc ────→ PDF ────→ embed in any image
```

## Benefits

1. **Composability**: Chain transformations freely
2. **Extensibility**: Add new types by implementing encoder/decoder
3. **Type Safety**: Validation at every step
4. **JD Native**: Preserves organizational structure
5. **DRY**: `2N` instead of `N²` implementations

## Use Cases

### 1. Cross-Platform Deployment
```nix
# Single config → multiple platforms
config = ./my-server.nix;
ir = unitype.encode "nixosConfiguration" config;

aws = unitype.decode "amazon" ir;
azure = unitype.decode "azure" ir;
gce = unitype.decode "gce" ir;
```

### 2. Home-Manager → NixOS
```nix
# Lift home config to system config
homeConfig = {
  programs.git.enable = true;
};

ir = unitype.encode "homeConfiguration" homeConfig;
nixosConfig = unitype.decode "nixosConfiguration" ir;
# Automatically wraps in home-manager module
```

### 3. Documentation Integration
```nix
# Embed docs in system image
typstDocs = { src = ./manual; };
nixosConfig = { /* ... */ };

# Combine
ir = unitype.encode "nixosConfiguration" nixosConfig;
ir' = unitype.embedDocs ir typstDocs;
isoWithDocs = unitype.decode "iso" ir';
```

## Implementation Priority

1. **Week 1**: Core transform infrastructure + IR definition
2. **Week 2**: nixosConfiguration encoders/decoders
3. **Week 3**: Image format decoders (ISO, VMware, Docker)
4. **Week 4**: home-manager integration
5. **Week 5**: Multi-step transformations + batch operations

## Philosophical Note

This system embodies the **Liskov Substitution Principle** for Nix types: any transformation preserves the essential "meaning" of the data through the canonical IR, while adapting its "form" to different contexts. The Johnny Decimal structure ensures semantic coherence across transformations.
