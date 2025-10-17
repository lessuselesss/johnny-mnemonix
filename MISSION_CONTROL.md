# Mission Control Scripts - Unitype Helper Composition

This project uses [mission-control](https://github.com/Platonic-Systems/mission-control) to provide composed transformation workflows accessible via development shell scripts.

## Quick Start

```bash
# Enter the development shell
nix develop

# All scripts are prefixed with comma (,)
# List available helpers
, list-helpers

# Transform a config to dendrix
, transform-to-dendrix

# Inspect a remote flake
, inspect-flake github:dustinlyons/nixos-config
```

## Script Categories

### Transform

**Compose call-flake + encoders + decoders for complete transformation pipelines**

- `, transform-to-dendrix` - Transform nixosConfiguration to dendrix aspect modules
  - Uses: `inspect-flake` app
  - Output: `./dendrix-output/` with auto-loading flake.nix

### Inspect

**Analyze flakes using call-flake and nix eval**

- `, inspect-flake <flake-url>` - Inspect a flake's configurations
  - Example: `, inspect-flake github:dustinlyons/nixos-config`
  - Shows: nixosConfigurations, homeConfigurations, metadata

### Extract

**Extract configuration data from any flake**

- `, extract-nixos-configs <flake-url>` - List all nixosConfigurations

  - Example: `, extract-nixos-configs github:dustinlyons/nixos-config`
  - Output: List of configuration names (garfield, aarch64-linux, etc.)

- `, extract-config-details <flake-url> <config-name>` - Get config details

  - Example: `, extract-config-details github:dustinlyons/nixos-config garfield`
  - Output: Hostname, system architecture, module count

### Generate

**Create aspect modules and classifications**

- `, generate-aspect-list` - Analyze config for aspects
  - Uses: Unitype encoder's aspect classification
  - Output: List of detected aspects (boot, networking, graphics, etc.)

### Test

**Test transformation pipelines**

- `, test-transformation` - Test transformation with mock data
  - Validates: Encoder → IR → Decoder pipeline
  - Output: List of generated aspects

### Helpers

**Documentation and reference**

- `, list-helpers` - Show all available unitype helpers
  - Lists: flake-utils, flake-utils-plus, call-flake, nosys, incl APIs

### Development

**Development workflow utilities**

- `, run-tests` - Run all unitype tests

  - Executes: `nix flake check --print-build-logs --keep-going`

- `, fmt` - Format all project files (Nix, Markdown, JSON)

  - Uses: treefmt (alejandra + mdformat + prettier + statix + deadnix)

- `, lint` - Lint Nix code for anti-patterns and dead code

  - Uses: statix (anti-patterns) + deadnix (unused code)

## Helper Composition Examples

### Example 1: Full Transformation Pipeline

```bash
# 1. Inspect target flake
, inspect-flake github:dustinlyons/nixos-config

# 2. Extract specific config
, extract-config-details github:dustinlyons/nixos-config garfield

# 3. Transform to dendrix
, transform-to-dendrix

# 4. Verify output
cd dendrix-output && nix flake show
```

### Example 2: Batch Config Analysis

```bash
# List all configs
, extract-nixos-configs github:dustinlyons/nixos-config

# For each config, get details
for config in garfield aarch64-linux x86_64-linux; do
  , extract-config-details github:dustinlyons/nixos-config $config
done
```

### Example 3: Development Workflow

```bash
# Test transformation
, test-transformation

# Run full test suite
, run-tests

# Format code
, fmt
```

## Composing Custom Scripts

Mission-control scripts are defined in `flake.nix` under `mission-control.scripts`. Each script can:

1. **Call helper functions**: Access unitype helpers via flake lib
1. **Compose pipelines**: Chain extract → encode → decode → generate
1. **Use Nix eval**: Run arbitrary Nix expressions for complex logic
1. **Wrap apps**: Call existing apps like `inspect-flake` and `transform-to-dendrix`

Example custom script:

```nix
my-custom-transform = {
  description = "Custom transformation workflow";
  exec = ''
    FLAKE="$1"
    CONFIG="$2"

    # Extract config using call-flake helper
    ${pkgs.nix}/bin/nix eval --impure --expr '
      let
        helpers = lib.unitype.helpers.callFlake;
        config = helpers.extractNixosConfig "'$FLAKE'" "'$CONFIG'";
        ir = lib.unitype.encoders.nixos.encode config;
        output = lib.unitype.decoders.custom.decode ir;
      in
        output
    '
  '';
  category = "Custom";
};
```

## Benefits

### 1. Discoverable Workflows

No need to remember complex `nix run` or `nix eval` commands - scripts are listed in the dev shell welcome banner.

### 2. Composable by Default

Scripts compose helpers from:

- flake-utils (multi-system)
- flake-utils-plus (flake construction)
- call-flake (config extraction)
- nosys (system-agnostic)
- incl (file filtering)

### 3. Executable Documentation

Scripts serve as living examples of how to use the helpers together.

### 4. Development Velocity

Common workflows become one-liners: `, transform-to-dendrix` instead of long nix commands.

## Architecture

```
Mission Control Scripts
        │
        ├─→ Transform
        │     └─→ Uses: transform-to-dendrix app
        │         Composes: call-flake + encode + decode
        │
        ├─→ Extract
        │     └─→ Uses: call-flake helper
        │         Composes: nix eval + jq
        │
        ├─→ Generate
        │     └─→ Uses: unitype encoders
        │         Composes: aspect classification
        │
        └─→ Test
              └─→ Uses: unitype IR
                  Composes: mock → encode → decode
```

## Related Documentation

- **Helpers**: See `nix/lib/unitype/CLAUDE.md` for helper API reference
- **Apps**: See `nix/apps/` for transformation apps
- **Mission Control**: https://github.com/Platonic-Systems/mission-control

______________________________________________________________________

**Tip**: Run `, list-helpers` anytime to see available composition functions!
