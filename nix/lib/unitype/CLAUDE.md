# Unitype - Universal Type Transformation System

**Layer**: 5 (Transformation)
**Purpose**: Universal transformation between any Nix types through canonical IR
**Location**: `nix/lib/unitype/`
**Status**: 🔄 In Development
**Methodology**: Strict TDD (RED → GREEN → REFACTOR)

> This file follows the kiro.dev specification format with comprehensive TDD methodology.

---

## Phase 1: Requirements

### System Overview

Unitype provides **universal type transformation** for all Nix configurations in the johnny-mnemonix ecosystem. Instead of implementing `N × (N-1)` direct transformations between N types, we implement `2N` transformations (N encoders + N decoders) through a canonical intermediate representation (IR).

**Core Principle**: Any type → Canonical IR → Any compatible type

### User Stories

#### US-UNIT-1: Universal Transformation
**As a** DevOps engineer
**I want to** transform any Nix configuration type to any compatible target type
**So that** I can adapt my configs to different frameworks without rewriting

**Acceptance Criteria**:
- Transform nixosConfiguration → dendrix modules
- Transform nixosConfiguration → ISO/VMware/Docker images
- Transform homeConfiguration → nixosConfiguration
- Transform flake-parts modules → Hive blocks
- Validate compatibility before transformation
- Preserve Johnny Decimal structure across transformations

#### US-UNIT-2: Lossless Round-Trip
**As a** system administrator
**I want** transformations to be reversible without data loss
**So that** I can migrate between frameworks confidently

**Acceptance Criteria**:
- Type A → IR → Type A preserves all data
- Type A → Type B → Type A is lossless where possible
- Metadata tracked through transformations
- Clear indication when information must be discarded

#### US-UNIT-3: Batch Hierarchy Transformation
**As a** configuration manager
**I want to** transform entire JD-organized hierarchies at once
**So that** I can migrate complete systems efficiently

**Acceptance Criteria**:
- Transform entire `configurations/` directory
- Preserve JD area/category/item structure
- Process 100+ configs in reasonable time (<30s)
- Generate transformation reports

#### US-UNIT-4: Type-Safe Validation
**As a** developer
**I want** transformations validated against type schemas
**So that** I get clear errors for incompatible transforms

**Acceptance Criteria**:
- Pre-transform validation using existing type layer
- Post-transform validation of results
- Clear error messages with source location
- Suggested fixes for common issues

#### US-UNIT-5: Extensibility
**As a** library developer
**I want to** add new types with minimal code
**So that** the system grows with the ecosystem

**Acceptance Criteria**:
- Add encoder + decoder + register = new type supported
- No modification to core transform logic required
- Type compatibility automatically derived
- Test templates for new types

### Dependencies

**Required**:
- Layer 4 (types) - For validation schemas
- Layer 3 (builders) - For constructing transformed configs
- Layer 2 (composition) - For JD structure operations
- Layer 1 (primitives) - For base operations

**External**:
- nixos-generators (for image format generation)
- flake-parts, divnix/hive (for framework integration)

### Constraints

1. **Performance**: Transform 100 configs in <30 seconds
2. **Memory**: IR size must be <2× source config size
3. **Compatibility**: All transformations must be documented in matrix
4. **Testing**: 100% test coverage on core transform logic

---

## Phase 2: Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     User Level                          │
│  unitype.transform "nixosConfiguration" "dendrix" cfg   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│                  Transform Engine                        │
│                                                          │
│  1. Validate source (using types layer)                 │
│  2. Encode: Source Type → IR                            │
│  3. Validate IR                                         │
│  4. Decode: IR → Target Type                            │
│  5. Validate result (using types layer)                 │
└─────────────────────────────────────────────────────────┘
           │              │              │
           ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ Encoders │   │    IR    │   │ Decoders │
    │          │   │          │   │          │
    │ nixos    │──→│ Canonical│──→│ dendrix  │
    │ dendrix  │──→│  Format  │──→│ iso      │
    │ home-mgr │──→│          │──→│ vmware   │
    │ typix    │──→│ JD-aware │──→│ docker   │
    └──────────┘   └──────────┘   └──────────┘
```

### Canonical IR Structure

The IR is the "Rosetta Stone" - all types encode to this structure:

```nix
{
  # Identity (always present)
  id = "10.01-web-server";              # JD identifier
  kind = "nixosConfiguration";           # Type discriminator

  # Metadata (always present)
  meta = {
    system = "x86_64-linux";             # Target architecture
    description = "Web server config";   # Human description
    tags = ["production" "web"];         # Classification tags
    source = "/path/to/config.nix";      # Original source

    # JD structure
    jdStructure = {
      area = { id = "10-19"; name = "Servers"; };
      category = { id = "10"; name = "Web"; };
      item = { id = "01"; name = "Primary"; };
    };
  };

  # Hierarchical structure (JD-organized)
  structure = {
    "10-19" = {                          # Area
      name = "Servers";
      "10" = {                           # Category
        name = "Web Servers";
        "10.01" = {                      # Item
          name = "Primary";
          data = { /* payload */ };
        };
      };
    };
  };

  # Type-specific payload
  payload = {
    # Normalized configuration data
    # Structure varies by kind but follows conventions
    modules = [ /* ... */ ];
    specialArgs = { /* ... */ };
    config = { /* ... */ };
  };

  # Transformation hints
  hints = {
    # What types can this IR be decoded to?
    canTransformTo = ["dendrix" "iso" "vmware"];

    # Does this require special handling?
    requiresValidation = true;
    hasSecrets = false;

    # Classification for aspect-oriented systems
    aspects = {
      networking = true;
      graphics = false;
      development = true;
    };
  };

  # Provenance tracking
  provenance = {
    originalType = "nixosConfiguration";
    transformationChain = [];
    timestamp = "2025-10-17T12:00:00Z";
  };
}
```

### Type Registry

```nix
# nix/lib/unitype/registry.nix
{
  types = {
    nixosConfiguration = {
      encoder = ./encoders/nixos.nix;
      decoder = ./decoders/nixos.nix;
      validator = lib.types.flakeTypes.nixos.schemas.nixosConfigurations;
    };

    dendrix = {
      encoder = ./encoders/dendrix.nix;
      decoder = ./decoders/dendrix.nix;
      validator = lib.types.flakeTypes.dendrix.schemas.dendrixModules;
    };

    homeConfiguration = {
      encoder = ./encoders/home-manager.nix;
      decoder = ./decoders/home-manager.nix;
      validator = lib.types.flakeTypes.homeManager.schemas.homeConfigurations;
    };

    iso = {
      decoder = ./decoders/iso.nix;  # One-way: can only decode to ISO
      validator = null;  # Images don't have input validation
    };
  };

  # Compatibility matrix (auto-derived from hints + explicit rules)
  compatibility = {
    nixosConfiguration = {
      canTransformTo = ["dendrix" "iso" "vmware" "docker" "amazon" "azure"];
      canTransformFrom = ["dendrix" "homeConfiguration"];
    };

    dendrix = {
      canTransformTo = ["nixosConfiguration" "iso" "vmware"];
      canTransformFrom = ["nixosConfiguration"];
    };

    homeConfiguration = {
      canTransformTo = ["nixosConfiguration"];
      canTransformFrom = [];  # Can't construct home config from system config
    };

    iso = {
      canTransformFrom = ["nixosConfiguration" "dendrix"];
    };
  };
}
```

### Core Transform Function

```nix
# nix/lib/unitype/transform.nix
{
  lib,
  registry,
  validators,
}: {
  # Main transformation function
  # transform :: SourceTypeName -> TargetTypeName -> SourceValue -> TargetValue
  transform = sourceType: targetType: value:
    let
      # 1. Validate types exist
      sourceSpec = registry.types.${sourceType} or (throw "Unknown source type: ${sourceType}");
      targetSpec = registry.types.${targetType} or (throw "Unknown target type: ${targetType}");

      # 2. Check compatibility
      canTransform = builtins.elem targetType (registry.compatibility.${sourceType}.canTransformTo or []);
      _ = assert canTransform; "Cannot transform ${sourceType} to ${targetType}";

      # 3. Validate source value
      validatedValue =
        if sourceSpec.validator != null
        then validators.validate sourceSpec.validator value
        else value;

      # 4. Encode to IR
      encoder = import sourceSpec.encoder { inherit lib; };
      ir = encoder.encode validatedValue;

      # 5. Validate IR structure
      validatedIR = validators.validateIR ir;

      # 6. Decode from IR
      decoder = import targetSpec.decoder { inherit lib; };
      result = decoder.decode validatedIR;

      # 7. Validate result
      finalResult =
        if targetSpec.validator != null
        then validators.validate targetSpec.validator result
        else result;
    in
      finalResult;

  # Encode to IR (for inspection/debugging)
  encode = sourceType: value:
    let
      sourceSpec = registry.types.${sourceType} or (throw "Unknown type: ${sourceType}");
      encoder = import sourceSpec.encoder { inherit lib; };
    in
      encoder.encode value;

  # Decode from IR (for inspection/debugging)
  decode = targetType: ir:
    let
      targetSpec = registry.types.${targetType} or (throw "Unknown type: ${targetType}");
      decoder = import targetSpec.decoder { inherit lib; };
    in
      decoder.decode ir;

  # Query compatibility
  canTransform = sourceType: targetType:
    builtins.elem targetType (registry.compatibility.${sourceType}.canTransformTo or []);

  # Get all possible targets for a source type
  getTargets = sourceType:
    registry.compatibility.${sourceType}.canTransformTo or [];

  # Get all possible sources for a target type
  getSources = targetType:
    lib.filter (src: builtins.elem targetType (registry.compatibility.${src}.canTransformTo or []))
      (builtins.attrNames registry.types);

  # Batch transform hierarchy
  transformHierarchy = { source, target, hierarchy }:
    lib.mapAttrsRecursive (path: value:
      transform source target value
    ) hierarchy;
}
```

---

## Phase 3: Implementation (TDD)

### Week 1: Foundation + IR

#### Task 1.1: IR Definition Tests (RED)

```nix
# tests/unitype/ir.test.nix
{ lib, unitype }: {
  # Test: IR has required top-level fields
  testIRHasRequiredFields = {
    expr = let
      ir = unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      ir ? id && ir ? kind && ir ? meta && ir ? payload && ir ? hints;
    expected = true;
  };

  # Test: IR validation catches missing id
  testIRValidationCatchesMissingId = {
    expr = let
      invalidIR = { kind = "nixosConfiguration"; };
      result = builtins.tryEval (unitype.ir.validate invalidIR);
    in result.success;
    expected = false;
  };

  # Test: IR validation catches invalid kind
  testIRValidationCatchesInvalidKind = {
    expr = let
      invalidIR = { id = "10.01"; kind = "not-a-real-type"; };
      result = builtins.tryEval (unitype.ir.validate invalidIR);
    in result.success;
    expected = false;
  };

  # Test: JD structure extraction
  testIRExtractsJDStructure = {
    expr = let
      ir = unitype.ir.mk {
        id = "10.01-web-server";
        kind = "nixosConfiguration";
        payload = {};
      };
    in
      ir.meta.jdStructure.category.id == "10" &&
      ir.meta.jdStructure.item.id == "01";
    expected = true;
  };
}
```

**Action**: Run tests (they will fail - RED phase)
**Expected**: All tests fail because IR structure doesn't exist yet

#### Task 1.2: Implement IR Structure (GREEN)

```nix
# nix/lib/unitype/ir/definition.nix
{ lib }: {
  # Create IR from minimal input
  mk = { id, kind, payload, meta ? {}, hints ? {} }:
    let
      # Extract JD structure from id
      jdStructure = extractJDStructure id;

      # Merge provided meta with defaults
      fullMeta = {
        system = meta.system or "x86_64-linux";
        description = meta.description or "";
        tags = meta.tags or [];
        source = meta.source or null;
        inherit jdStructure;
      } // meta;

      # Default hints
      fullHints = {
        canTransformTo = hints.canTransformTo or [];
        requiresValidation = hints.requiresValidation or true;
        hasSecrets = hints.hasSecrets or false;
        aspects = hints.aspects or {};
      } // hints;

    in {
      inherit id kind payload;
      meta = fullMeta;
      hints = fullHints;

      # Structure built from JD
      structure = buildJDStructure id payload;

      # Provenance
      provenance = {
        originalType = kind;
        transformationChain = [];
        timestamp = builtins.currentTime;
      };
    };

  # Extract JD components from identifier
  extractJDStructure = id:
    # Implementation in next iteration
    {};

  # Build hierarchical structure from JD id
  buildJDStructure = id: payload:
    # Implementation in next iteration
    {};
}
```

**Action**: Run tests again
**Expected**: Basic tests pass (GREEN phase)

#### Task 1.3: Refactor IR (REFACTOR)

- Add comprehensive JD extraction
- Improve structure building
- Add IR serialization helpers
- Optimize memory usage

### Week 2: nixosConfiguration Encoder

#### Task 2.1: Encoder Tests (RED)

```nix
# tests/unitype/encoders/nixos.test.nix
{ lib, unitype }: {
  # Test: Encoder produces valid IR
  testNixosEncoderProducesValidIR = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ ./test-module.nix ];
      };
      ir = unitype.encoders.nixos.encode config;
      validation = unitype.ir.validate ir;
    in validation.valid;
    expected = true;
  };

  # Test: Encoder sets correct kind
  testNixosEncoderSetsKind = {
    expr = let
      config = { system = "x86_64-linux"; modules = []; };
      ir = unitype.encoders.nixos.encode config;
    in ir.kind == "nixosConfiguration";
    expected = true;
  };

  # Test: Encoder preserves modules
  testNixosEncoderPreservesModules = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [ { services.nginx.enable = true; } ];
      };
      ir = unitype.encoders.nixos.encode config;
    in
      builtins.length ir.payload.modules == 1;
    expected = true;
  };

  # Test: Encoder classifies modules by aspect
  testNixosEncoderClassifiesAspects = {
    expr = let
      config = {
        system = "x86_64-linux";
        modules = [
          { services.nginx.enable = true; }
          { programs.git.enable = true; }
        ];
      };
      ir = unitype.encoders.nixos.encode config;
    in
      ir.hints.aspects.networking == true &&
      ir.hints.aspects.development == true;
    expected = true;
  };
}
```

**Action**: Run tests (RED)

#### Task 2.2: Implement nixos Encoder (GREEN)

```nix
# nix/lib/unitype/encoders/nixos.nix
{ lib }: {
  encode = nixosConfig:
    let
      # Classify modules by aspect
      moduleClassification = classifyModules nixosConfig.modules;

      # Build IR
      ir = lib.unitype.ir.mk {
        id = nixosConfig.meta.jdId or (
          nixosConfig.config.networking.hostName or "unknown"
        );
        kind = "nixosConfiguration";

        payload = {
          inherit (nixosConfig) system modules;
          specialArgs = nixosConfig.specialArgs or {};
          config = nixosConfig.config or {};
        };

        hints = {
          canTransformTo = ["dendrix" "iso" "vmware" "docker"];
          aspects = moduleClassification.aspects;
        };
      };
    in ir;

  # Classify which aspects are present in modules
  classifyModules = modules:
    # Heuristic classification based on module content
    {
      aspects = {
        networking = hasNetworkingConfig modules;
        graphics = hasGraphicsConfig modules;
        development = hasDevelopmentConfig modules;
      };
    };
}
```

**Action**: Run tests (GREEN)

#### Task 2.3: Refactor Encoder

- Improve aspect classification heuristics
- Add module dependency analysis
- Handle edge cases (empty modules, complex configs)

### Week 3: Dendrix Decoder

#### Task 3.1: Decoder Tests (RED)

```nix
# tests/unitype/decoders/dendrix.test.nix
{ lib, unitype }: {
  # Test: Decoder produces valid dendrix modules
  testDendrixDecoderProducesValidOutput = {
    expr = let
      ir = unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          modules = [
            { services.nginx.enable = true; }
          ];
        };
        hints.aspects.networking = true;
      };
      dendrix = unitype.decoders.dendrix.decode ir;
      # Validate against dendrix schema
      validation = lib.types.flakeTypes.dendrix.schemas.dendrixModules.inventory dendrix;
    in builtins.tryEval validation.success;
    expected = true;
  };

  # Test: Decoder organizes by aspect
  testDendrixDecoderOrganizesByAspect = {
    expr = let
      ir = unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          modules = [
            { services.nginx.enable = true; }
            { programs.git.enable = true; }
          ];
        };
        hints.aspects = {
          networking = true;
          development = true;
        };
      };
      dendrix = unitype.decoders.dendrix.decode ir;
    in
      dendrix ? networking && dendrix ? development;
    expected = true;
  };

  # Test: Decoder creates proper aspect modules
  testDendrixDecoderCreatesProperModules = {
    expr = let
      ir = unitype.ir.mk {
        id = "10.01";
        kind = "nixosConfiguration";
        payload = {
          modules = [ { services.nginx.enable = true; } ];
        };
        hints.aspects.networking = true;
      };
      dendrix = unitype.decoders.dendrix.decode ir;
      networkingModule = dendrix.networking;
    in
      builtins.isFunction networkingModule ||
      (builtins.isAttrs networkingModule && networkingModule ? imports);
    expected = true;
  };
}
```

**Action**: Run tests (RED)

#### Task 3.2: Implement Dendrix Decoder (GREEN)

```nix
# nix/lib/unitype/decoders/dendrix.nix
{ lib }: {
  decode = ir:
    let
      # Validate IR is compatible
      _ = assert ir.kind == "nixosConfiguration";
        "Can only decode nixosConfiguration IR to dendrix";

      # Split modules by aspect based on hints
      modulesByAspect = splitModulesByAspect ir.payload.modules ir.hints.aspects;

      # Create dendrix aspect modules
      dendrixModules = lib.mapAttrs (aspect: modules:
        # Create dendrix aspect module structure
        {
          imports = [];
          exports = mergeModules modules;
        }
      ) modulesByAspect;
    in
      dendrixModules;

  # Split NixOS modules into aspect-organized groups
  splitModulesByAspect = modules: aspectHints:
    lib.foldl (acc: module:
      let
        # Determine which aspect this module belongs to
        aspect = determineAspect module aspectHints;
      in
        acc // {
          ${aspect} = (acc.${aspect} or []) ++ [ module ];
        }
    ) {} modules;

  # Determine aspect from module content
  determineAspect = module: hints:
    # Heuristic-based aspect determination
    if module ? services && (module.services ? nginx || module.services ? networking)
    then "networking"
    else if module ? programs && (module.programs ? git || module.programs ? vim)
    then "development"
    else "default";
}
```

**Action**: Run tests (GREEN)

#### Task 3.3: Refactor Decoder

- Improve aspect determination heuristics
- Handle cross-cutting concerns
- Add aspect priority/ordering
- Support dendrix imports from repositories

### Week 4-5: Additional Features

- Bidirectional transforms (dendrix → nixos)
- Image format decoders (ISO, VMware, Docker)
- Batch transformation utilities
- Integration tests
- Documentation

---

## Test Coverage Matrix

| Component | Unit Tests | Integration Tests | Real-World Tests |
|-----------|-----------|-------------------|------------------|
| IR Definition | 20 | - | - |
| nixos Encoder | 25 | 5 | 3 |
| dendrix Decoder | 25 | 5 | 3 |
| Transform Engine | 15 | 10 | 5 |
| Registry | 10 | - | - |
| **Total** | **95** | **20** | **11** |

**Total Tests**: 126+

**Coverage Goal**: 100% on core transform logic, 95%+ on encoders/decoders

---

## API Surface (Public Exports)

```nix
# From lib.unitype
{
  # Core transformation
  transform = sourceType: targetType: value: result;

  # Inspection
  encode = sourceType: value: ir;
  decode = targetType: ir: result;

  # Queries
  canTransform = sourceType: targetType: bool;
  getTargets = sourceType: [targetTypes];
  getSources = targetType: [sourceTypes];

  # Batch operations
  transformHierarchy = { source, target, hierarchy }: transformedHierarchy;

  # Utilities
  ir = {
    mk = { id, kind, payload, ... }: ir;
    validate = ir: validation;
  };

  # Registry access
  registry = { types, compatibility };

  # Direct encoder/decoder access (for advanced use)
  encoders = { nixos, dendrix, home-manager, ... };
  decoders = { nixos, dendrix, iso, vmware, ... };
}
```

---

## Related Documentation

- **Design Documents**: `/DESIGN_UNITYPE.md`, `/DESIGN_UNITYPE_FLAKEPARTS_TO_HIVE.md`
- **IR Specification**: `./ir/CLAUDE.md`
- **Encoders Specification**: `./encoders/CLAUDE.md`
- **Decoders Specification**: `./decoders/CLAUDE.md`
- **Type System**: `../types/CLAUDE.md` (Layer 4)
- **Project Root**: `../../../CLAUDE.md`

---

## Next Steps

1. ✅ Create root specification (this file)
2. 🔄 Create IR specification with TDD plan
3. ⏳ Implement IR definition (RED → GREEN → REFACTOR)
4. ⏳ Create nixos encoder tests
5. ⏳ Implement nixos encoder
6. ⏳ Create dendrix decoder tests
7. ⏳ Implement dendrix decoder
8. ⏳ Integration tests and examples

**Status**: Foundation laid, ready for IR implementation
