# Types Layer Testing Strategy

**Purpose**: Comprehensive testing of type definitions against real-world community flakes and modules

**Approach**: Test against actual community projects to ensure our types work in production, not just synthetic test harnesses

---

## Testing Philosophy

### 1. Real-World Validation

We test against **actual community flakes and modules**, not synthetic examples:
- Ensures types work with production code
- Catches edge cases from real usage
- Validates against established patterns
- Prevents bias from synthetic test data

### 2. Three-Level Testing

**Level 1: Unit Tests** - Individual type definitions
- Test each module type validates correctly
- Test each schema validates/rejects appropriately
- Pure, fast, isolated

**Level 2: Integration Tests** - Type system integration
- Test module types work in real modules
- Test flake types work with flake-parts
- Test schemas validate real flake outputs

**Level 3: Real-World Tests** - Community flake validation
- Import actual community flakes
- Validate their outputs with our schemas
- Ensure compatibility with established patterns

---

## Real-World Test Targets

### Meta Framework: flake-parts

**Test Targets**:
- https://github.com/hercules-ci/flake-parts (official examples)
- https://github.com/hercules-ci/flake-parts/tree/main/examples
- Any flake using flake-parts (most modern flakes)

**What We Test**:
- `flakePartsModule` type validates flake-parts modules
- `flakeModules` schema validates flakeModules output
- `modules` schema validates flake.modules organization

**Test Files**:
- `nix/tests/types/unit/flake-parts-module-types.nix`
- `nix/tests/types/integration/flake-parts-real-world.nix`

### Standard: NixOS

**Test Targets**:
- https://github.com/nixos/nixpkgs (nixosModules from nixpkgs)
- https://github.com/nix-community/home-manager (has nixosModules)
- https://github.com/nix-community/impermanence (popular nixosModule)
- https://github.com/lnl7/nix-darwin (for comparison with darwin types)

**What We Test**:
- `nixosModulePath`, `systemService` types validate real NixOS modules
- `nixosModules` schema validates nixpkgs modules
- `nixosConfigurations` schema validates system configs

**Test Files**:
- `nix/tests/types/unit/nixos-module-types.nix`
- `nix/tests/types/integration/nixos-real-world.nix`

### Standard: home-manager

**Test Targets**:
- https://github.com/nix-community/home-manager (official modules)
- https://github.com/nix-community/home-manager/tree/master/modules
- https://github.com/Misterio77/nix-config (popular dotfiles)
- https://github.com/Misterio77/nix-starter-configs (starter templates)

**What We Test**:
- `homeDirectory`, `xdgConfigFile`, `dotfile` types
- `homeModules`/`homeManagerModules` schemas
- `homeConfigurations` schema

**Test Files**:
- `nix/tests/types/unit/home-manager-module-types.nix`
- `nix/tests/types/integration/home-manager-real-world.nix`

### Standard: nix-darwin

**Test Targets**:
- https://github.com/LnL7/nix-darwin (official)
- https://github.com/LnL7/nix-darwin/tree/master/modules
- https://github.com/dustinlyons/nixos-config (popular darwin config)

**What We Test**:
- `darwinConfiguration`, `brewPackage`, `brewCask` types
- `darwinModules` schema
- `darwinConfigurations` schema

**Test Files**:
- `nix/tests/types/unit/darwin-module-types.nix`
- `nix/tests/types/integration/darwin-real-world.nix`

### Custom: Dendrix

**Test Targets**:
- https://github.com/vic/dendrix (official dendrix)
- https://github.com/vic/dendrix/tree/main/home (vic's home config)
- https://github.com/vic/dendrix/tree/main/nixos (vic's nixos aspects)

**What We Test**:
- `aspectName`, `aspectModule`, `repositoryImport` types
- `dendrixModules` schema validates aspect-oriented structure
- Import-tree patterns work correctly

**Test Files**:
- `nix/tests/types/unit/dendrix-module-types.nix`
- `nix/tests/types/integration/dendrix-real-world.nix`

**Note**: May need to contact @vic for permission/guidance on testing against his repos

### Custom: system-manager

**Test Targets**:
- https://github.com/numtide/system-manager (official)
- https://github.com/numtide/system-manager/tree/main/examples
- Any project using system-manager (search GitHub)

**What We Test**:
- `systemConfig`, `systemService`, `systemFile` types
- `systemManagerModules`/`smModules` schemas
- Works on non-NixOS Linux

**Test Files**:
- `nix/tests/types/unit/system-manager-module-types.nix`
- `nix/tests/types/integration/system-manager-real-world.nix`

### Custom: Typix

**Test Targets**:
- https://github.com/loqusion/typix (official typix)
- https://github.com/typst/packages (typst community packages)
- Any typst project using Nix (search "typst nix")

**What We Test**:
- `typixProject`, `typixBuild`, `typixWatch` types
- `typixModules`/`typixProjects` schemas
- Watch mode configurations

**Test Files**:
- `nix/tests/types/unit/typix-module-types.nix`
- `nix/tests/types/integration/typix-real-world.nix`

### Custom: Johnny-Mnemonix (Dogfood)

**Test Targets**:
- **THIS PROJECT** - johnny-mnemonix itself!
- Our own modules in `modules/johnny-mnemonix.nix`
- Our own flake configuration

**What We Test**:
- `jmConfiguration`, `jmModule` types (with common JD types)
- `jmModules`/`jmConfigurations` schemas
- Self-documenting JD filename validation

**Test Files**:
- `nix/tests/types/unit/jm-module-types.nix`
- `nix/tests/types/integration/jm-dogfood.nix`

**Dogfooding**: This is critical - if our types don't work with our own project, they're wrong!

### Custom: divnix/std

**Test Targets**:
- https://github.com/divnix/std (official std)
- https://github.com/divnix/std/tree/main/examples
- https://github.com/divnix/hive (uses std)
- **THIS PROJECT** - we use std for cell organization!

**What We Test**:
- `cellName`, `blockType`, `cellBlock`, `stdCell` types
- `growOnConfig`, `harvestConfig` types
- `stdModules`/`stdCells` schemas

**Test Files**:
- `nix/tests/types/unit/std-module-types.nix`
- `nix/tests/types/integration/std-real-world.nix`
- `nix/tests/types/integration/std-dogfood.nix` (test against our own std usage)

### Custom: Hive/Colmena

**Test Targets**:
- https://github.com/zhaofengli/colmena (official colmena)
- https://github.com/zhaofengli/colmena/tree/main/examples
- https://github.com/divnix/hive (divnix variant)
- Search GitHub for "colmena" deployment configs

**What We Test**:
- `hiveNode`, `colmenaConfig`, `deploymentKey` types
- `hiveModules`/`colmenaModules`/`hive` schemas
- Deployment target validation

**Test Files**:
- `nix/tests/types/unit/hive-module-types.nix`
- `nix/tests/types/integration/hive-real-world.nix`

---

## Test Structure

### Directory Organization

```
nix/tests/types/
├── README.md                               # Testing overview
├── unit/                                   # Level 1: Unit tests
│   ├── common-types.nix                    # Test common JD types
│   ├── flake-parts-module-types.nix
│   ├── nixos-module-types.nix
│   ├── home-manager-module-types.nix
│   ├── darwin-module-types.nix
│   ├── dendrix-module-types.nix
│   ├── system-manager-module-types.nix
│   ├── typix-module-types.nix
│   ├── jm-module-types.nix
│   ├── std-module-types.nix
│   └── hive-module-types.nix
├── integration/                            # Level 2: Integration tests
│   ├── flake-types-with-flake-parts.nix    # Test flake types with flake-parts
│   ├── schemas-validate-outputs.nix        # Test schemas validate correctly
│   └── types-block-export.nix              # Test types.nix aggregation
├── real-world/                             # Level 3: Community flake tests
│   ├── flake-parts-examples.nix
│   ├── nixos-community.nix
│   ├── home-manager-community.nix
│   ├── darwin-community.nix
│   ├── dendrix-vic.nix
│   ├── system-manager-examples.nix
│   ├── typix-projects.nix
│   ├── jm-dogfood.nix                      # Test against ourselves
│   ├── std-dogfood.nix                     # Test against our std usage
│   └── colmena-deployments.nix
└── fixtures/                               # Test data/helpers
    ├── sample-modules/                     # Minimal test modules
    └── community-flakes.nix                # Flake inputs for real-world tests
```

### Test File Format

Each test file follows TDD methodology:

```nix
# unit/nixos-module-types.nix
{
  lib,
  types,  # Our types from lib.types.moduleTypes
}: let
  inherit (lib) mkOption;
in {
  # Test: nixosModulePath accepts valid paths
  testNixosModulePathValid = {
    expr = let
      testOption = mkOption {
        type = types.nixos.nixosModulePath;
        default = ./test-module.nix;
      };
    in lib.types.check testOption.type ./test-module.nix;
    expected = true;
  };

  # Test: systemService validates correctly
  testSystemServiceValid = {
    expr = let
      service = {
        enable = true;
        description = "Test Service";
        wantedBy = ["multi-user.target"];
      };
    in lib.types.check types.nixos.systemService service;
    expected = true;
  };

  # ... more unit tests
}
```

---

## Implementation Plan

### Phase 1: Test Infrastructure (Week 1)

**Day 1-2: Setup**
- Create `nix/tests/types/` directory structure
- Create test runner infrastructure
- Create fixtures for common test patterns

**Day 3-5: Unit Test Framework**
- Write unit tests for all module types
- Focus on type validation (accepts valid, rejects invalid)
- Test edge cases

**Day 6-7: Integration Test Framework**
- Test flake types with flake-parts
- Test schemas validate/reject appropriately
- Test types.nix aggregation

### Phase 2: Real-World Tests (Week 2)

**Day 1: Standard Ecosystem**
- Test against nixpkgs modules
- Test against home-manager modules
- Test against nix-darwin modules

**Day 2: Dendrix + system-manager**
- Test against vic/dendrix (if permitted)
- Test against numtide/system-manager examples

**Day 3: Typix + Hive**
- Test against typix projects
- Test against colmena deployments

**Day 4: Dogfooding**
- Test against our own johnny-mnemonix
- Test against our own std cell structure

**Day 5-7: Refinement**
- Fix issues found in real-world testing
- Update type definitions as needed
- Document any limitations

### Phase 3: CI Integration (Week 3)

- Add types tests to flake checks
- Set up automated testing against community flakes
- Create test report generation

---

## Required External Permissions

### Repos We Should Contact Maintainers About

1. **vic/dendrix**
   - Contact: @vic (https://github.com/vic)
   - Ask: Permission to test against dendrix repos in our test suite
   - Why: Ensures our dendrix types work with the canonical implementation

2. **loqusion/typix**
   - Contact: @loqusion (https://github.com/loqusion)
   - Ask: Permission to use as test target, feedback on type definitions
   - Why: Typix creator can validate our understanding

3. **zhaofengli/colmena**
   - Contact: @zhaofengli (https://github.com/zhaofengli)
   - Ask: Permission to test against colmena examples
   - Why: Validate hive/colmena type accuracy

### Public Repos (No Permission Needed)

These are public and designed to be used as examples:
- nixpkgs
- home-manager
- nix-darwin
- system-manager (Apache 2.0)
- divnix/std (Unlicense)
- divnix/hive
- Misterio77/nix-configs (MIT)
- hercules-ci/flake-parts (MIT)

---

## Success Criteria

**All tests passing** means:
- ✅ All module types validate real module options
- ✅ All flake types work with flake-parts
- ✅ All schemas correctly validate real flake outputs
- ✅ Works with at least 3 community flakes per type
- ✅ Dogfooding: Works with our own johnny-mnemonix and std usage
- ✅ No false positives (valid configs rejected)
- ✅ No false negatives (invalid configs accepted)

**Coverage targets**:
- Unit tests: 100% of all type definitions
- Integration tests: All flake types + schemas
- Real-world tests: Minimum 3 community flakes per type

---

## Next Steps

1. Create test infrastructure
2. Write unit tests for all module types
3. Write integration tests for flake types
4. Identify and reach out about repos needing permission
5. Implement real-world tests
6. Fix issues and iterate
7. Document findings and limitations

**Let me know which repos we need explicit permission for and I'll help draft the messages!**
